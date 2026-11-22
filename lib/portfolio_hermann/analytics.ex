defmodule PortfolioHermann.Analytics do
  @moduledoc """
  Compteur de vues persistant.

  Optimisation principale : les vues ne sont plus écrites sur disque à chaque
  chargement de page. Elles sont agrégées en mémoire puis écrites par lots
  toutes les 5 s (paramétrable via `:flush_interval`), et une dernière fois à
  l'arrêt propre du serveur (`terminate/2`). Un `File.write/3` + `:sync` par
  vue (re-encodage complet du fichier) devient donc au pire une écriture
  toutes les 5 s, ce qui réduit fortement l'I/O et l'usure du volume sur une
  machine Fly.io 512 Mo / 1 vCPU.

  `get_stats/1` renvoie toujours l'état en mémoire : les statistiques affichées
  restent cohérentes même si le fichier n'est pas encore réécrit.

  La croissance du fichier est bornée : les jours de plus de 365 jours sont
  élagués lors du flush, sans toucher au total de vues (`views`).
  """

  use GenServer

  require Logger

  alias PortfolioHermann.Projects

  @flush_interval 5_000
  @max_days 365

  @doc false
  def flush_interval, do: @flush_interval

  @doc false
  def max_days, do: @max_days

  # API publique

  def start_link(opts \\ []) do
    config = %{
      data_dir: Keyword.get(opts, :data_dir) || Projects.data_dir(),
      flush_interval: Keyword.get(opts, :flush_interval, @flush_interval)
    }

    case Keyword.get(opts, :name, __MODULE__) do
      nil -> GenServer.start_link(__MODULE__, config)
      name -> GenServer.start_link(__MODULE__, config, name: name)
    end
  end

  @doc """
  Enregistre une vue pour `path`.

  L'écriture sur disque est différée (batch), sauf si `flush/1` est appelé.
  `server` est paramétrable pour les tests.
  """
  def increment_page_view(path, server \\ __MODULE__) do
    GenServer.cast(server, {:increment_view, path})
  end

  @doc """
  Renvoie les statistiques en mémoire : `%{views: integer, visits: %{Date.t => %{total: integer, paths: map}}}`.
  """
  def get_stats(server \\ __MODULE__) do
    GenServer.call(server, :get_stats)
  end

  @doc """
  Force l'écriture immédiate des vues en attente (utile avant un arrêt ou dans
  les tests). Renvoie `:ok`.
  """
  def flush(server \\ __MODULE__) do
    GenServer.call(server, :flush, 15_000)
  end

  # Callbacks

  @impl true
  def init(config) do
    # Permet à terminate/2 de faire le flush final lors d'un arrêt propre.
    Process.flag(:trap_exit, true)
    %{views: views, visits: visits} = load_state(config.data_dir)

    {:ok,
     Map.merge(config, %{
       views: views,
       visits: visits,
       dirty: false,
       flush_timer: nil
     })}
  end

  @impl true
  def handle_cast({:increment_view, path}, state) do
    state = state |> apply_view(path) |> Map.put(:dirty, true)
    {:noreply, schedule_flush(state)}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    {:reply, %{views: state.views, visits: state.visits}, state}
  end

  def handle_call(:flush, _from, state) do
    {:reply, :ok, flush_now(state)}
  end

  @impl true
  def handle_info(:flush, state) do
    {:noreply, flush_now(%{state | flush_timer: nil})}
  end

  @impl true
  def terminate(_reason, state) do
    if state.dirty do
      # Flush final : on ne perd pas les vues accumulées depuis le dernier batch.
      persist_state(%{state | visits: prune_visits(state.visits, Date.utc_today())})
    end

    :ok
  end

  # Logique pure (testable sans GenServer ni fichier)

  @doc """
  Incrémente une vue pour `path` à `date` (par défaut aujourd'hui).

  Fonction pure : renvoie un nouvel état sans toucher au disque.
  Le chemin est normalisé en chaîne pour rester cohérent entre l'état en
  mémoire (atomes de `live_action`) et le fichier relu après redémarrage.
  """
  def apply_view(state, path, date \\ Date.utc_today()) do
    path = path_to_string(path)

    visits =
      Map.update(state.visits, date, %{total: 1, paths: %{path => 1}}, fn day ->
        paths = Map.update(day.paths, path, 1, &(&1 + 1))
        %{day | total: day.total + 1, paths: paths}
      end)

    %{state | views: state.views + 1, visits: visits}
  end

  @doc """
  Sérialise un état analytics en JSON (fonction pure).
  """
  def encode_state(%{views: views, visits: visits}) do
    encoded_visits =
      Map.new(visits, fn {date, stats} ->
        {date_to_iso8601(date),
         %{"total" => normalize_count(stats.total), "paths" => normalize_paths(stats.paths)}}
      end)

    Jason.encode!(%{"views" => normalize_count(views), "visits" => encoded_visits}, pretty: true)
  end

  @doc """
  Décode le contenu JSON d'un fichier analytics (fonction pure).

  Tolérant : les jours invalides sont ignorés et une structure inattendue
  renvoie `{:error, reason}` au lieu de faire planter l'appelant.
  """
  def decode_state(content) when is_binary(content) do
    case Jason.decode(content) do
      {:ok, %{"views" => views, "visits" => visits}} when is_integer(views) and is_map(visits) ->
        {:ok, %{views: max(views, 0), visits: decode_visits(visits)}}

      {:ok, _other} ->
        {:error, :invalid_shape}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Ne conserve que les `max_days` derniers jours de visites (par défaut 365
  jours). Le total de vues n'est pas modifié : seules les statistiques
  journalières anciennes sont élaguées, ce qui borne la taille du fichier.
  """
  def prune_visits(visits, today \\ Date.utc_today(), max_days \\ @max_days)

  def prune_visits(visits, today, max_days)
      when is_map(visits) and is_integer(max_days) and max_days > 0 do
    cutoff = Date.add(today, -(max_days - 1))

    visits
    |> Enum.filter(fn {date, _stats} -> Date.compare(date, cutoff) != :lt end)
    |> Map.new()
  end

  def prune_visits(visits, _today, _max_days), do: visits

  @doc """
  Classe des pages populaires par nombre de vues décroissant, en gérant les
  valeurs `nil` et les clés non binaires. Retourne au plus `limit` entrées.
  """
  def popular_pages(paths, limit \\ 5)

  def popular_pages(paths, limit) when is_map(paths) and is_integer(limit) and limit >= 0 do
    paths
    |> Enum.map(fn {path, views} -> {path_to_string(path), normalize_count(views)} end)
    |> Enum.sort_by(fn {path, views} -> {-views, path} end)
    |> Enum.take(limit)
  end

  def popular_pages(_paths, _limit), do: []

  # Implémentation privée

  defp flush_now(state) do
    state = cancel_flush_timer(state)

    if state.dirty do
      persist_flushed(state)
    else
      state
    end
  end

  defp persist_flushed(state) do
    visits = prune_visits(state.visits, Date.utc_today())
    state = %{state | visits: visits}

    case persist_state(state) do
      :ok ->
        %{state | dirty: false}

      {:error, _reason} ->
        # On garde `dirty` et on retente au prochain cycle plutôt que de
        # perdre des vues en silence.
        schedule_flush(state)
    end
  end

  defp schedule_flush(%{flush_timer: nil} = state) do
    ref = Process.send_after(self(), :flush, state.flush_interval)
    %{state | flush_timer: ref}
  end

  defp schedule_flush(state), do: state

  defp cancel_flush_timer(%{flush_timer: nil} = state), do: state

  defp cancel_flush_timer(%{flush_timer: ref} = state) do
    if is_reference(ref), do: Process.cancel_timer(ref)
    %{state | flush_timer: nil}
  end

  defp file_path(data_dir), do: Path.join(data_dir, "analytics.json")

  defp load_state(data_dir) do
    path = file_path(data_dir)

    case File.read(path) do
      {:ok, content} ->
        case decode_state(content) do
          {:ok, state} ->
            state

          {:error, reason} ->
            Logger.warning("Could not load analytics from #{path}: #{inspect(reason)}")
            %{views: 0, visits: %{}}
        end

      {:error, :enoent} ->
        %{views: 0, visits: %{}}

      {:error, reason} ->
        Logger.warning("Could not read analytics file #{path}: #{inspect(reason)}")
        %{views: 0, visits: %{}}
    end
  end

  defp persist_state(state) do
    path = file_path(state.data_dir)

    with :ok <- File.mkdir_p(Path.dirname(path)),
         :ok <- atomic_write(path, encode_state(state)) do
      :ok
    else
      {:error, reason} ->
        Logger.warning("Could not persist analytics to #{path}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp atomic_write(path, content) do
    temp_path = path <> ".tmp.#{System.unique_integer([:positive])}"

    with :ok <- File.write(temp_path, content, [:binary, :sync]) do
      case File.rename(temp_path, path) do
        :ok ->
          :ok

        {:error, reason} ->
          File.rm(temp_path)
          {:error, reason}
      end
    else
      {:error, reason} ->
        File.rm(temp_path)
        {:error, reason}
    end
  end

  defp decode_visits(visits) do
    Enum.reduce(visits, %{}, fn
      {day, %{"total" => total, "paths" => paths}}, acc
      when is_integer(total) and is_map(paths) ->
        case Date.from_iso8601(day) do
          {:ok, date} ->
            Map.put(acc, date, %{total: normalize_count(total), paths: normalize_paths(paths)})

          _ ->
            acc
        end

      {_day, _stats}, acc ->
        acc
    end)
  end

  defp normalize_paths(paths) when is_map(paths) do
    Map.new(paths, fn {path, views} -> {path_to_string(path), normalize_count(views)} end)
  end

  defp normalize_paths(_paths), do: %{}

  defp normalize_count(count) when is_integer(count) and count >= 0, do: count
  defp normalize_count(_count), do: 0

  defp path_to_string(path) when is_binary(path), do: path
  defp path_to_string(path) when is_atom(path), do: Atom.to_string(path)
  defp path_to_string(path), do: inspect(path)

  defp date_to_iso8601(%Date{} = date), do: Date.to_iso8601(date)
  defp date_to_iso8601(date) when is_binary(date), do: date
end
