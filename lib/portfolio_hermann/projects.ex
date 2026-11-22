defmodule PortfolioHermann.Projects do
  @moduledoc """
  Gestion des projets avec persistance dans des fichiers JSON.
  Version optimisée pour le déploiement en production.

  Les lectures sont mises en cache dans `:persistent_term` : un seul
  `File.stat/2` (mtime + taille) suffit pour servir un fichier déjà décodé au
  lieu de le relire et de le redécoder à chaque requête. Le cache est invalidé :

    * explicitement après chaque écriture faite par ce module (write-through),
    * automatiquement si `mtime` ou la taille du fichier change (édition
      externe, seed, redéploiement).

  Les écritures restent atomiques (fichier temporaire + `File.rename/2`) et
  sérialisées par le verrou global `:global.trans/2`.
  """

  require Logger

  # Toutes les entrées de cache de ce module vivent sous cette clé racine.
  @cache_key_prefix {__MODULE__, :json}

  # Fly.io's root filesystem is replaced during deploys. Point PORTFOLIO_DATA_DIR
  # at a mounted volume in production; local development keeps using priv/.
  def data_dir do
    case System.get_env("PORTFOLIO_DATA_DIR") do
      nil -> to_string(:code.priv_dir(:portfolio_hermann))
      "" -> to_string(:code.priv_dir(:portfolio_hermann))
      path -> Path.expand(path)
    end
  end

  def uploads_dir, do: Path.join(data_dir(), "uploads")

  defp data_path(filename), do: Path.join(data_dir(), filename)

  @doc """
  Récupère la liste des projets avec gestion d'erreur améliorée.
  """
  def list_projects do
    case read_json_file(
           data_path("projects.json"),
           Path.join(:code.priv_dir(:portfolio_hermann), "projects.json")
         ) do
      {:ok, data} when is_list(data) -> data
      _ -> []
    end
  end

  @doc """
  Récupère la liste des technologies.
  """
  def list_techs do
    case read_json_file(
           data_path("techs.json"),
           Path.join(:code.priv_dir(:portfolio_hermann), "techs.json")
         ) do
      {:ok, %{"techs" => techs}} -> techs
      _ -> []
    end
  end

  @doc """
  Récupère la liste des tags.
  """
  def list_tags do
    case read_json_file(
           data_path("techs.json"),
           Path.join(:code.priv_dir(:portfolio_hermann), "techs.json")
         ) do
      {:ok, %{"tags" => tags}} -> tags
      _ -> []
    end
  end

  def list_experiences do
    seed = Path.join(:code.priv_dir(:portfolio_hermann), "experiences.json")

    case read_json_file(data_path("experiences.json"), seed) do
      {:ok, data} when is_map(data) -> data
      _ -> %{}
    end
  end

  def save_experiences(experiences) when is_map(experiences) do
    path = data_path("experiences.json")

    :global.trans({{__MODULE__, path}, self()}, fn ->
      write_json_file_unlocked(path, experiences)
    end)
  end

  @doc """
  Incrémente le compteur de likes d'un projet.
  """
  def increment_like(id) do
    update_projects(&update_project_stats(&1, id, "likes"), :update_failed)
  end

  @doc """
  Incrémente le compteur de vues d'un projet.
  """
  def increment_view(id) do
    update_projects(&update_project_stats(&1, id, "views"), :update_failed)
  end

  @doc """
  Ajoute un nouveau projet.
  """
  def add_project(project) do
    update_projects(&[project | &1], :add_failed)
  end

  @doc """
  Met à jour un projet existant.
  """
  def update_project(id, updates) do
    update_projects(
      &Enum.map(&1, fn project -> maybe_update_project(project, id, updates) end),
      :update_failed
    )
  end

  @doc """
  Supprime un projet.
  """
  def delete_project(id) do
    update_projects(&Enum.reject(&1, fn project -> project["id"] == id end), :delete_failed)
  end

  @doc """
  Vide le cache de lecture JSON.

  Utile après une modification externe non détectable par mtime/taille (très
  rare) ou pour isoler des tests. Alternative non intrusive : attendre le
  prochain changement de `mtime`/taille du fichier.
  """
  def clear_cache do
    for {{{__MODULE__, :json}, path}, _value} <- :persistent_term.get() do
      :persistent_term.erase({{__MODULE__, :json}, path})
    end

    :ok
  end

  @doc false
  # Exposé uniquement pour vérifier le comportement du cache dans les tests.
  def cache_entry(filename) when is_binary(filename) do
    :persistent_term.get(cache_key(data_path(filename)), nil)
  end

  # Fonctions privées

  defp cache_key(path), do: {@cache_key_prefix, path}

  defp read_json_file(path, seed_path) do
    case read_cached(path) do
      {:ok, data} ->
        {:ok, data}

      :miss ->
        path = ensure_seed_file(path, seed_path)
        read_from_disk_and_cache(path)
    end
  end

  # Une entrée de cache est valide tant que la signature du fichier
  # (mtime/seconde, taille, inode) n'a pas bougé. L'inode détecte en plus les
  # remplacements atomiques (rename) qui conserveraient taille et mtime.
  # Les écritures faites via l'API sont de toute façon invalidées explicitement
  # (write-through), cette vérification couvre les éditions externes.
  defp read_cached(path) do
    with signature when signature != nil <- file_signature(File.stat(path, time: :posix)),
         %{signature: ^signature, data: data} <- :persistent_term.get(cache_key(path), nil) do
      {:ok, data}
    else
      _ -> :miss
    end
  end

  defp read_from_disk_and_cache(path) do
    # Signature avant lecture : si le fichier change entre la lecture et la
    # mise en cache, on ne met pas en cache une paire (données, signature)
    # incohérente.
    signature_before = file_signature(File.stat(path, time: :posix))

    case File.read(path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, data} ->
            maybe_cache(path, data, signature_before)
            {:ok, data}

          {:error, reason} ->
            Logger.warning("Failed to decode JSON from #{path}: #{inspect(reason)}")
            {:error, reason}
        end

      {:error, reason} ->
        Logger.warning("Could not read file #{path}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp maybe_cache(path, data, signature_before) do
    signature_after = file_signature(File.stat(path, time: :posix))

    if signature_before != nil and signature_before == signature_after do
      :persistent_term.put(cache_key(path), %{signature: signature_after, data: data})
    else
      :persistent_term.erase(cache_key(path))
    end

    :ok
  end

  defp put_cache(path, data) do
    case file_signature(File.stat(path, time: :posix)) do
      nil ->
        :persistent_term.erase(cache_key(path))

      signature ->
        :persistent_term.put(cache_key(path), %{signature: signature, data: data})
    end

    :ok
  end

  defp file_signature({:ok, %File.Stat{mtime: mtime, size: size, inode: inode}}),
    do: {mtime, size, inode}

  defp file_signature(_error), do: nil

  defp update_projects(update_fun, failure) do
    path = data_path("projects.json")

    :global.trans({{__MODULE__, path}, self()}, fn ->
      with {:ok, projects} <-
             read_json_file(path, Path.join(:code.priv_dir(:portfolio_hermann), "projects.json")),
           true <- is_list(projects) do
        write_json_file_unlocked(path, update_fun.(projects))
      else
        _ -> {:error, failure}
      end
    end)
  end

  defp write_json_file_unlocked(path, data) do
    with :ok <- File.mkdir_p(Path.dirname(path)),
         {:ok, content} <- encode_json(data),
         :ok <- atomic_write(path, content) do
      # Write-through : les prochaines lectures n'ont même pas besoin de relire
      # le fichier, et le cache ne peut pas rester en retard sur l'écriture.
      put_cache(path, data)
      :ok
    else
      {:error, reason} ->
        Logger.warning("Failed to write to #{path}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp encode_json(data) do
    {:ok, Jason.encode!(data, pretty: true)}
  rescue
    error -> {:error, Exception.message(error)}
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

  defp ensure_seed_file(path, seed_path) do
    if File.exists?(path) do
      path
    else
      with :ok <- File.mkdir_p(Path.dirname(path)),
           {:ok, contents} <- File.read(seed_path),
           :ok <- atomic_write(path, contents) do
        path
      else
        error ->
          Logger.warning("Could not seed #{path} from #{seed_path}: #{inspect(error)}")
          seed_path
      end
    end
  end

  defp update_project_stats(projects, id, field) do
    Enum.map(projects, fn project ->
      if project["id"] == id do
        stats = Map.get(project, "stats", %{})
        Map.put(project, "stats", Map.put(stats, field, Map.get(stats, field, 0) + 1))
      else
        project
      end
    end)
  end

  defp maybe_update_project(project, id, updates) do
    if project["id"] == id do
      Map.merge(project, updates)
    else
      project
    end
  end
end
