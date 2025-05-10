defmodule PortfolioHermannWeb.Components.VisitStats do
  use Phoenix.Component
  alias PortfolioHermann.Analytics

  def stats(assigns) do
    stats = Analytics.get_stats()
    today = Date.utc_today()
    today_stats = stats.visits[today] || %{total: 0, paths: %{}}

    assigns = assign(assigns,
      total_views: stats.views,
      today_views: today_stats.total,
      popular_pages: get_popular_pages(today_stats.paths)
    )

    ~H"""
    <div class="space-y-6">
      <div class="grid grid-cols-2 gap-4">
        <div class="card-soft text-center">
          <h3 class="text-lg font-semibold mb-2">Vues totales</h3>
          <p class="text-3xl font-bold text-indigo-600"><%= @total_views %></p>
        </div>
        <div class="card-soft text-center">
          <h3 class="text-lg font-semibold mb-2">Vues aujourd'hui</h3>
          <p class="text-3xl font-bold text-indigo-600"><%= @today_views %></p>
        </div>
      </div>

      <div class="card-soft">
        <h3 class="text-lg font-semibold mb-4">Pages populaires aujourd'hui</h3>
        <div class="space-y-2">
          <%= for {path, views} <- @popular_pages do %>
            <div class="flex justify-between items-center">
              <span class="text-gray-600"><%= path %></span>
              <span class="font-semibold"><%= views %> vues</span>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp get_popular_pages(paths) do
    paths
    |> Enum.sort_by(fn {path, views} -> {path, views} end, :desc)
    |> Enum.take(5)
  end
end
