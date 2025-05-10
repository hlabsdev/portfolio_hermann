defmodule PortfolioHermannWeb.AdminProjectsLive do
  use PortfolioHermannWeb, :live_view
  alias PortfolioHermann.Projects

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :projects, Projects.list_projects())}
  end

  def handle_event("add", %{"title" => t, "tech" => te, "desc" => d}, socket) do
    id = UUID.uuid4()
    Projects.add_project(%{"id" => id, "title" => t, "tech" => te, "desc" => d})
    {:noreply, assign(socket, :projects, Projects.list_projects())}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    Projects.delete_project(id)
    {:noreply, assign(socket, :projects, Projects.list_projects())}
  end

  def render(assigns) do
    ~H"""
    <section class="max-w-4xl mx-auto py-16">
      <h1 class="text-3xl font-bold mb-6">Gestion des projets</h1>

      <form phx-submit="add" class="space-y-2 card-soft mb-6">
        <input name="title" placeholder="Titre" class="w-full p-2 rounded-xl border" />
        <input name="tech" placeholder="Technos" class="w-full p-2 rounded-xl border" />
        <textarea name="desc" placeholder="Description" rows="3" class="w-full p-2 rounded-xl border"></textarea>
        <button class="btn-soft px-4 py-2">Ajouter</button>
      </form>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <%= for project <- @projects do %>
          <div class="card-soft relative">
            <h2 class="text-xl font-bold"><%= project["title"] %></h2>
            <p class="italic text-sm"><%= project["tech"] %></p>
            <p class="mb-2"><%= project["desc"] %></p>
            <button phx-click="delete" phx-value-id={project["id"]} class="absolute top-2 right-2 text-red-600 hover:underline">✕</button>
          </div>
        <% end %>
      </div>
    </section>
    """
  end
end
