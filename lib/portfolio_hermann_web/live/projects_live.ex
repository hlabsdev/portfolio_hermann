defmodule PortfolioHermannWeb.ProjectsLive do
  use PortfolioHermannWeb, :live_view
  alias PortfolioHermann.Projects
  import PortfolioHermannWeb.ProjectCard

  @impl true
  def mount(_params, _session, socket) do
    all_projects = Projects.list_projects()
    techs = extract_technologies(all_projects)

    socket = socket
    |> assign(:projects, all_projects)
    |> assign(:all_projects, all_projects)
    |> assign(:techs, techs)
    |> assign(:selected_tech, nil)
    |> assign(:search_query, "")
    |> assign(:selected_project, nil)
    |> assign(:show_modal, false)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    project = Enum.find(socket.assigns.all_projects, &(&1["id"] == id))
    {:noreply, assign(socket, selected_project: project, show_modal: true)}
  end

  def handle_params(_, _uri, socket) do
    {:noreply, assign(socket, selected_project: nil, show_modal: false)}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/projects")}
  end

  @impl true
  def handle_event("filter_tech", %{"tech" => tech}, socket) do
    tech = if tech == socket.assigns.selected_tech, do: nil, else: tech
    filtered_projects = filter_projects(socket.assigns.all_projects, tech, socket.assigns.search_query)
    {:noreply, assign(socket, projects: filtered_projects, selected_tech: tech)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    filtered_projects = filter_projects(socket.assigns.all_projects, socket.assigns.selected_tech, query)
    {:noreply, assign(socket, projects: filtered_projects, search_query: query)}
  end

  def render(assigns) do
    ~H"""
    <section class="max-w-7xl mx-auto py-16 px-6">
      <h1 class="text-4xl font-bold mb-8 text-center">Mes projets</h1>

      <div class="mb-8 space-y-4">
        <div class="flex justify-center gap-2 flex-wrap">
          <%= for tech <- @techs do %>
            <button
              phx-click="filter_tech"
              phx-value-tech={tech}
              class={"px-3 py-1 rounded-full text-sm #{if @selected_tech == tech, do: 'bg-indigo-500 text-white', else: 'bg-gray-100 text-gray-700 hover:bg-gray-200'}"}
            >
              <%= tech %>
            </button>
          <% end %>
        </div>

        <div class="max-w-md mx-auto">
          <form phx-change="search" class="relative">
            <input
              type="text"
              name="query"
              value={@search_query}
              placeholder="Rechercher un projet..."
              class="w-full px-4 py-2 rounded-xl border border-gray-300 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
            />
            <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
              <svg class="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </div>
          </form>
        </div>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        <%= for project <- @projects do %>
          <.project_card
            id={project["id"]}
            title={project["title"]}
            tech={project["tech"]}
            desc={project["desc"]}
            logo_url={project["logo_url"]}
            demo_urls={project["demo_urls"]}
            source_urls={project["source_urls"]}
          />
        <% end %>
      </div>

      <%= if @show_modal do %>
        <div class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center">
          <div class="bg-white dark:bg-gray-800 w-full max-w-3xl max-h-[90vh] overflow-y-auto rounded-xl p-6 relative">
            <button
              phx-click="close_modal"
              class="absolute top-4 right-4 text-gray-500 hover:text-gray-700"
            >
              <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>

            <div class="flex items-start space-x-6 mb-6">
              <%= if @selected_project["logo_url"] do %>
                <img
                  src={@selected_project["logo_url"]}
                  alt={@selected_project["title"]}
                  class="w-24 h-24 object-contain rounded-xl"
                />
              <% end %>
              <div>
                <h2 class="text-3xl font-bold mb-2"><%= @selected_project["title"] %></h2>
                <p class="text-gray-600 dark:text-gray-300 font-mono"><%= @selected_project["tech"] %></p>
              </div>
            </div>

            <div class="prose dark:prose-invert max-w-none mb-6">
              <p><%= @selected_project["desc"] %></p>
            </div>

            <div class="space-y-4">
              <%= if length(@selected_project["demo_urls"]) > 0 do %>
                <div>
                  <h3 class="text-lg font-semibold mb-2">Démos</h3>
                  <div class="flex flex-wrap gap-2">
                    <%= for demo <- @selected_project["demo_urls"] do %>
                      <a
                        href={demo["url"]}
                        target="_blank"
                        rel="noopener noreferrer"
                        class="inline-flex items-center px-4 py-2 bg-indigo-100 text-indigo-700 rounded-xl hover:bg-indigo-200"
                      >
                        <%= demo["label"] %>
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 ml-2" viewBox="0 0 20 20" fill="currentColor">
                          <path d="M11 3a1 1 0 100 2h2.586l-6.293 6.293a1 1 0 101.414 1.414L15 6.414V9a1 1 0 102 0V4a1 1 0 00-1-1h-5z" />
                          <path d="M5 5a2 2 0 00-2 2v8a2 2 0 002 2h8a2 2 0 002-2v-3a1 1 0 10-2 0v3H5V7h3a1 1 0 000-2H5z" />
                        </svg>
                      </a>
                    <% end %>
                  </div>
                </div>
              <% end %>

              <%= if length(@selected_project["source_urls"]) > 0 do %>
                <div>
                  <h3 class="text-lg font-semibold mb-2">Code source</h3>
                  <div class="flex flex-wrap gap-2">
                    <%= for source <- @selected_project["source_urls"] do %>
                      <a
                        href={source["url"]}
                        target="_blank"
                        rel="noopener noreferrer"
                        class="inline-flex items-center px-4 py-2 bg-gray-100 text-gray-700 rounded-xl hover:bg-gray-200"
                      >
                        <%= source["label"] %>
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 ml-2" viewBox="0 0 20 20" fill="currentColor">
                          <path fill-rule="evenodd" d="M2.5 4A1.5 1.5 0 001 5.5v9A1.5 1.5 0 002.5 16h12a1.5 1.5 0 001.5-1.5v-9A1.5 1.5 0 0014.5 4h-12zM14 7a1 1 0 11-2 0 1 1 0 012 0zm-8 5a1 1 0 100-2 1 1 0 000 2z" />
                        </svg>
                      </a>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>
    </section>
    """
  end

  defp extract_technologies(projects) do
    projects
    |> Enum.flat_map(&(String.split(&1["tech"], ", ")))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp filter_projects(projects, nil, ""), do: projects
  defp filter_projects(projects, tech, query) do
    projects
    |> Enum.filter(fn project ->
      tech_matches = if tech, do: String.contains?(project["tech"], tech), else: true
      query_matches = if query != "", do: String.contains?(String.downcase(project["title"]), String.downcase(query)) or
                                       String.contains?(String.downcase(project["desc"]), String.downcase(query)), else: true
      tech_matches and query_matches
    end)
  end
end
