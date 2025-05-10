defmodule PortfolioHermann.Analytics do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{views: 0, visits: %{}}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
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

    {:noreply, %{state | views: state.views + 1, visits: visits}}
  end

  def handle_call(:get_stats, _from, state) do
    {:reply, state, state}
  end
end
