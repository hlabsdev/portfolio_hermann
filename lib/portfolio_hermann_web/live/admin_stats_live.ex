defmodule PortfolioHermannWeb.AdminStatsLive do
  use PortfolioHermannWeb, :live_view
  import PortfolioHermannWeb.Components.VisitStats

  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(5000, self(), :update_stats)
    end

    {:ok, socket}
  end

  def handle_info(:update_stats, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto py-16 px-6">
      <div class="flex justify-between items-center mb-8">
        <h1 class="text-3xl font-bold">Statistiques du site</h1>
        <div class="flex gap-4">
          <.link navigate={~p"/admin/projects"} class="btn-soft px-4 py-2">
            Gérer les projets
          </.link>
          <.link href={~p"/admin/logout"} method="delete" data-confirm="Se deconnecter de l'Admin?" class="btn-soft text-red-600 hover:underline px-4 py-2">
            Logout
          </.link>
        </div>
      </div>

      <.stats />
    </div>
    """
  end
end
