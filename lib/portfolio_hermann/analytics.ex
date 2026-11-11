defmodule PortfolioHermann.Analytics do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{views: 0, visits: %{}}, name: __MODULE__)
  end

  def init(state) do
    {:ok, load_state(state)}
  end

  # API publique
  def increment_page_view(path) do
    GenServer.cast(__MODULE__, {:increment_view, path})
  end

  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  # Callbacks
  def handle_cast({:increment_view, path}, state) do
    today = Date.utc_today()
    visits = Map.update(
      state.visits,
      today,
      %{total: 1, paths: %{path => 1}},
      fn day_stats ->
        paths = Map.update(day_stats.paths, path, 1, &(&1 + 1))
        %{day_stats | total: day_stats.total + 1, paths: paths}
      end
    )

    updated_state = %{state | views: state.views + 1, visits: visits}
    persist_state(updated_state)
    {:noreply, updated_state}
  end

  def handle_call(:get_stats, _from, state) do
    {:reply, state, state}
  end

  defp file_path, do: Path.join(PortfolioHermann.Projects.data_dir(), "analytics.json")

  defp load_state(default) do
    with {:ok, content} <- File.read(file_path()),
         {:ok, %{"views" => views, "visits" => visits}} <- Jason.decode(content),
         true <- is_integer(views) and is_map(visits) do
      parsed_visits =
        Enum.reduce(visits, %{}, fn {day, stats}, acc ->
          with {:ok, date} <- Date.from_iso8601(day),
               total when is_integer(total) <- stats["total"],
               paths when is_map(paths) <- stats["paths"] do
            Map.put(acc, date, %{total: total, paths: paths})
          else
            _ -> acc
          end
        end)

      %{views: views, visits: parsed_visits}
    else
      _ -> default
    end
  end

  defp persist_state(state) do
    visits =
      Map.new(state.visits, fn {date, stats} ->
        {Date.to_iso8601(date), %{"total" => stats.total, "paths" => stats.paths}}
      end)

    content = Jason.encode!(%{"views" => state.views, "visits" => visits}, pretty: true)
    path = file_path()
    temp_path = path <> ".tmp"

    with :ok <- File.mkdir_p(Path.dirname(path)),
         :ok <- File.write(temp_path, content, [:binary, :sync]),
         :ok <- File.rename(temp_path, path) do
      :ok
    else
      {:error, reason} -> IO.warn("Could not persist analytics: #{inspect(reason)}")
    end
  end
end
