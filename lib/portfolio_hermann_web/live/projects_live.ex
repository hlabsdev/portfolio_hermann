defmodule PortfolioHermannWeb.ProjectsLive do
  use PortfolioHermannWeb, :live_view
  alias PortfolioHermann.Projects
  import PortfolioHermannWeb.ProjectCard
  import PortfolioHermannWeb.Helpers
  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, _session, socket) do
    projects = Projects.list_projects()
    all_tags = get_all_tags(projects)
    all_years = projects |> Enum.map(& &1["year"]) |> Enum.uniq() |> Enum.sort(:desc)
    all_techs = get_all_techs(projects)

    socket =
      socket
      |> assign(:projects, projects)
      |> assign(:filtered_projects, projects)
      |> assign(:all_tags, all_tags)
      |> assign(:all_years, all_years)
      |> assign(:all_techs, all_techs)
      |> assign(:selected_tags, [])
      |> assign(:selected_techs, [])
      |> assign(:selected_year, "all")
      |> assign(:view_mode, :grid)
      |> assign(:sort_by, :recent)
      |> assign(:search_query, "")

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_view", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, :view_mode, String.to_atom(mode))}
  end

  @impl true
  def handle_event("toggle_tag", %{"tag" => tag}, socket) do
    selected_tags = toggle_tag(socket.assigns.selected_tags, tag)

    filtered_projects =
      filter_projects(
        socket.assigns.projects,
        selected_tags,
        socket.assigns.selected_year,
        socket.assigns.search_query,
        socket.assigns.selected_techs
      )

    {:noreply, assign(socket, selected_tags: selected_tags, filtered_projects: filtered_projects)}
  end

  @impl true
  def handle_event("filter_year", %{"year" => year}, socket) do
    filtered_projects =
      filter_projects(
        socket.assigns.projects,
        socket.assigns.selected_tags,
        year,
        socket.assigns.search_query,
        socket.assigns.selected_techs
      )

    {:noreply, assign(socket, selected_year: year, filtered_projects: filtered_projects)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    filtered_projects =
      filter_projects(
        socket.assigns.projects,
        socket.assigns.selected_tags,
        socket.assigns.selected_year,
        query,
        socket.assigns.selected_techs
      )

    {:noreply, assign(socket, search_query: query, filtered_projects: filtered_projects)}
  end

  @impl true
  def handle_event("sort", %{"by" => sort_by}, socket) do
    sorted_projects = sort_projects(socket.assigns.filtered_projects, String.to_atom(sort_by))

    {:noreply,
     assign(socket, sort_by: String.to_atom(sort_by), filtered_projects: sorted_projects)}
  end

  @impl true
  def handle_event("like_project", %{"id" => id}, socket) do
    Projects.increment_like(id)
    projects = Projects.list_projects()
    filtered_projects = filter_projects(
      projects,
      socket.assigns.selected_tags,
      socket.assigns.selected_year,
      socket.assigns.search_query,
      socket.assigns.selected_techs
    )
    {:noreply, assign(socket, projects: projects, filtered_projects: filtered_projects)}
  end

  @impl true
  def handle_event("toggle_tech", %{"tech" => tech}, socket) do
    selected_techs = toggle_tech(socket.assigns.selected_techs, tech)

    filtered_projects =
      filter_projects(
        socket.assigns.projects,
        socket.assigns.selected_tags,
        socket.assigns.selected_year,
        socket.assigns.search_query,
        selected_techs
      )

    {:noreply,
     assign(socket, selected_techs: selected_techs, filtered_projects: filtered_projects)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <!-- Filtres et contrôles -->
      <div class="mb-8 space-y-4">
        <div class="flex flex-wrap items-center justify-between gap-4">
          <h1 class="text-3xl font-bold text-gray-900 dark:text-white">Mes Projets</h1>

          <div class="flex items-center space-x-4">
            <button
              type="button"
              phx-click={JS.push("toggle_view", value: %{mode: "grid"})}
              class={"p-2 rounded-lg #{if @view_mode == :grid, do: "bg-indigo-100 text-indigo-700 dark:bg-indigo-900 dark:text-indigo-300", else: "text-gray-500 hover:text-indigo-600 dark:hover:text-indigo-400"}"}
            >
              <.icon name="hero-squares-2x2" class="w-6 h-6" />
            </button>

            <button
              type="button"
              phx-click={JS.push("toggle_view", value: %{mode: "list"})}
              class={"p-2 rounded-lg #{if @view_mode == :list, do: "bg-indigo-100 text-indigo-700 dark:bg-indigo-900 dark:text-indigo-300", else: "text-gray-500 hover:text-indigo-600 dark:hover:text-indigo-400"}"}
            >
              <.icon name="hero-bars-3" class="w-6 h-6" />
            </button>
          </div>
        </div>

        <!-- Filtres -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <!-- Recherche -->
          <div>
            <form phx-change="search" class="relative">
              <input
                type="text"
                name="query"
                value={@search_query}
                placeholder="Rechercher..."
                class="w-full px-4 py-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-indigo-500 dark:focus:ring-indigo-400 focus:border-indigo-500 dark:focus:border-indigo-400"
              />
              <div class="absolute right-3 top-2.5 text-gray-400">
                <.icon name="hero-magnifying-glass" class="w-5 h-5" />
              </div>
            </form>
          </div>

          <!-- Année -->
          <div>
            <select
              phx-change="filter_year"
              name="year"
              class="w-full px-4 py-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-indigo-500 dark:focus:ring-indigo-400 focus:border-indigo-500 dark:focus:border-indigo-400"
            >
              <option value="all">Toutes les années</option>

              <%=for year <- @all_years do%>
                <option value={year} selected={@selected_year == to_string(year)}>
                  <%=year%>
                </option>
              <%=end%>
            </select>
          </div>

          <!-- Technologies -->
          <div class="space-y-2">
            <div class="flex flex-wrap gap-2">
              <%=for tech <- @all_techs do%>
                <button
                  type="button"
                  phx-click={JS.push("toggle_tech", value: %{tech: tech})}
                  class={"px-3 py-1 rounded-full text-sm font-medium
                    #{if tech in @selected_techs,
                      do: "bg-indigo-100 text-indigo-700 dark:bg-indigo-900 dark:text-indigo-300",
                      else: "bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300 hover:bg-indigo-50 dark:hover:bg-indigo-900/50"}"}
                >
                  <%=tech%>
                </button>
              <%=end%>
            </div>
          </div>

          <!-- Tri -->
          <div class="flex gap-2">
            <button
              type="button"
              phx-click={JS.push("sort", value: %{by: "recent"})}
              class={"px-3 py-1 rounded-full text-sm font-medium
                #{if @sort_by == :recent,
                  do: "bg-indigo-100 text-indigo-700 dark:bg-indigo-900 dark:text-indigo-300",
                  else: "bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300"}"}
            >
              Plus récent
            </button>

            <button
              type="button"
              phx-click={JS.push("sort", value: %{by: "popular"})}
              class={"px-3 py-1 rounded-full text-sm font-medium
                #{if @sort_by == :popular,
                  do: "bg-indigo-100 text-indigo-700 dark:bg-indigo-900 dark:text-indigo-300",
                  else: "bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300"}"}
            >
              Populaire
            </button>

            <button
              type="button"
              phx-click={JS.push("sort", value: %{by: "likes"})}
              class={"px-3 py-1 rounded-full text-sm font-medium
                #{if @sort_by == :likes,
                  do: "bg-indigo-100 text-indigo-700 dark:bg-indigo-900 dark:text-indigo-300",
                  else: "bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300"}"}
            >
              Likes
            </button>
          </div>
        </div>

        <!-- Tags -->
        <div class="flex flex-wrap gap-2">
          <%=for tag <- @all_tags do%>
            <button
              type="button"
              phx-click={JS.push("toggle_tag", value: %{tag: tag})}
              class={"px-3 py-1 rounded-full text-sm font-medium
                #{if tag in @selected_tags,
                  do: "bg-[#f39d8d] text-white dark:bg-[#8B4513] dark:text-white",
                  else: "bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300 hover:bg-[#f39d8d]/10 dark:hover:bg-[#8B4513]/20"}"}
            >
              <%=tag%>
            </button>
          <%=end%>
        </div>
      </div>

      <!-- Liste des projets -->
      <%=if @view_mode == :grid do%>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <%=for project <- @filtered_projects do%>
            <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg overflow-hidden hover:shadow-xl transition-shadow duration-300">
              <div class="relative aspect-[4/3] bg-gray-200 dark:bg-gray-700">
                <img
                  src={project["logo_url"]}
                  alt={project["title"]}
                  class="w-full h-full object-cover"
                />
              </div>
              <div class="p-6">
                <h3 class="text-xl font-semibold text-gray-900 dark:text-white mb-2">
                  <%=project["title"]%>
                </h3>
                <p class="text-gray-600 dark:text-gray-400 mb-4 line-clamp-2">
                  <%=project["desc"]%>
                </p>

                <div class="flex flex-wrap gap-2 mb-4">
                  <%=for tag <- project["tags"] || [] do%>
                    <span class="px-2 py-1 text-xs font-medium bg-[#f39d8d]/10 text-[#8B4513] dark:bg-[#8B4513]/20 dark:text-[#f39d8d] rounded">
                      <%=tag%>
                    </span>
                  <%=end%>
                </div>

                <div class="flex justify-between items-center">
                  <div class="flex items-center space-x-2 text-sm text-gray-600 dark:text-gray-400">
                    <div class="flex items-center space-x-1">
                      <.icon name="hero-eye" class="w-4 h-4" />
                      <span>{project["stats"]["views"]}</span>
                    </div>

                    <button
                      type="button"
                      phx-click={JS.push("like_project", value: %{id: project["id"]})}
                      class="ml-2 flex items-center space-x-1 hover:text-[#f39d8d] dark:hover:text-[#f39d8d] transition-colors duration-200"
                    >
                      <.icon name="hero-heart" class="w-4 h-4" />
                      <span>{project["stats"]["likes"]}</span>
                    </button>
                  </div>

                  <%=if project["source_urls"] && length(project["source_urls"]) > 0 do%>
                    <a
                      href={hd(project["source_urls"])["url"]}
                      target="_blank"
                      rel="noopener noreferrer"
                      class="text-indigo-600 hover:text-indigo-700 dark:text-indigo-400 dark:hover:text-indigo-300 transition-colors duration-200"
                    >
                      Voir le code →
                    </a>
                  <%=end%>
                </div>

                <%=if project["demo_urls"] && length(project["demo_urls"]) > 0 do%>
                  <div class="mt-4 flex flex-wrap gap-2">
                    <%=for demo <- project["demo_urls"] do%>
                      <a
                        href={demo["url"]}
                        target="_blank"
                        rel="noopener noreferrer"
                        class="flex items-center px-3 py-1 rounded-full bg-indigo-100 text-indigo-700 dark:bg-indigo-900 dark:text-indigo-300 hover:bg-indigo-200 dark:hover:bg-indigo-800 text-sm transition-colors duration-200"
                      >
                        <.icon name="hero-play" class="w-4 h-4 mr-1" />
                        <%=demo["label"]%>
                      </a>
                    <%=end%>
                  </div>
                <%=end%>
              </div>
            </div>
          <%=end%>
        </div>
      <%=else%>
        <div class="bg-white dark:bg-gray-800 overflow-hidden shadow rounded-lg">
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
              <thead class="bg-gray-50 dark:bg-gray-900">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Projet
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Technologies
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Année
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Stats
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Liens
                  </th>
                </tr>
              </thead>

              <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                <%=for project <- @filtered_projects do%>
                  <tr class="hover:bg-gray-50 dark:hover:bg-gray-900 transition-colors duration-200">
                    <td class="px-6 py-4 whitespace-nowrap">
                      <div class="flex items-center">
                        <div class="h-10 w-10 flex-shrink-0">
                          <img
                            class="h-10 w-10 rounded object-cover"
                            src={project["logo_url"]}
                            alt=""
                          />
                        </div>
                        <div class="ml-4">
                          <div class="text-sm font-medium text-gray-900 dark:text-white">
                            <%=project["title"]%>
                          </div>
                          <div class="text-sm text-gray-500 dark:text-gray-400 line-clamp-1">
                            <%=project["desc"]%>
                          </div>
                        </div>
                      </div>
                    </td>
                    <td class="px-6 py-4">
                      <div class="text-sm text-gray-900 dark:text-white max-w-xs overflow-hidden">
                        <%=project["tech"]%>
                      </div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <div class="text-sm text-gray-900 dark:text-white">
                        <%=project["year"]%>
                      </div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                      <div class="flex items-center space-x-4">
                        <div class="flex items-center space-x-1">
                          <.icon name="hero-eye" class="w-4 h-4" />
                          <span><%=project["stats"]["views"]%></span>
                        </div>

                        <button
                          type="button"
                          phx-click={JS.push("like_project", value: %{id: project["id"]})}
                          class="flex items-center space-x-1 hover:text-[#f39d8d] dark:hover:text-[#f39d8d] transition-colors duration-200"
                        >
                          <.icon name="hero-heart" class="w-4 h-4" />
                          <span><%=project["stats"]["likes"]%></span>
                        </button>
                      </div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                      <div class="flex space-x-2">
                        <%=if project["source_urls"] && length(project["source_urls"]) > 0 do%>
                          <a
                            href={hd(project["source_urls"])["url"]}
                            target="_blank"
                            rel="noopener noreferrer"
                            class="text-indigo-600 hover:text-indigo-700 dark:text-indigo-400 dark:hover:text-indigo-300 transition-colors duration-200"
                            title="Voir le code source"
                          >
                            <.icon name="hero-code-bracket" class="w-5 h-5" />
                          </a>
                        <%=end%>

                        <%=if project["demo_urls"] && length(project["demo_urls"]) > 0 do%>
                          <%=for demo <- project["demo_urls"] do%>
                            <a
                              href={demo["url"]}
                              target="_blank"
                              rel="noopener noreferrer"
                              class="text-indigo-600 hover:text-indigo-700 dark:text-indigo-400 dark:hover:text-indigo-300 transition-colors duration-200"
                              title={demo["label"]}
                            >
                              <.icon name="hero-play" class="w-5 h-5" />
                            </a>
                          <%=end%>
                        <%=end%>
                      </div>
                    </td>
                  </tr>
                <%=end%>
              </tbody>
            </table>
          </div>
        </div>
      <%=end%>
    </div>
    """
  end

  defp get_all_tags(projects) do
    projects
    |> Enum.flat_map(& &1["tags"])
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp get_all_techs(projects) do
    projects
    |> Enum.flat_map(&String.split(&1["tech"], ","))
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp toggle_tag(selected_tags, tag) do
    if tag in selected_tags do
      List.delete(selected_tags, tag)
    else
      [tag | selected_tags]
    end
  end

  defp toggle_tech(selected_techs, tech) do
    if tech in selected_techs do
      List.delete(selected_techs, tech)
    else
      [tech | selected_techs]
    end
  end

  defp filter_projects(projects, tags, year, query, techs) do
    projects
    |> filter_by_tags(tags)
    |> filter_by_year(year)
    |> filter_by_search(query)
    |> filter_by_techs(techs)
  end

  defp filter_by_tags(projects, []), do: projects

  defp filter_by_tags(projects, tags) do
    Enum.filter(projects, fn project ->
      Enum.all?(tags, &(&1 in (project["tags"] || [])))
    end)
  end

  defp filter_by_year(projects, "all"), do: projects

  defp filter_by_year(projects, year) when is_binary(year) do
    year = String.to_integer(year)
    Enum.filter(projects, &(&1["year"] == year))
  end

  defp filter_by_search(projects, ""), do: projects

  defp filter_by_search(projects, query) do
    query = String.downcase(query)

    Enum.filter(projects, fn project ->
      String.contains?(String.downcase(project["title"]), query) ||
        String.contains?(String.downcase(project["desc"]), query) ||
        String.contains?(String.downcase(project["tech"]), query) ||
        Enum.any?(project["tags"] || [], &String.contains?(String.downcase(&1), query))
    end)
  end

  defp filter_by_techs(projects, []), do: projects

  defp filter_by_techs(projects, techs) do
    Enum.filter(projects, fn project ->
      project_techs = project["tech"] |> String.split(",") |> Enum.map(&String.trim/1)
      Enum.all?(techs, &(&1 in project_techs))
    end)
  end

  defp sort_projects(projects, :recent) do
    Enum.sort_by(projects, & &1["year"], :desc)
  end

  defp sort_projects(projects, :popular) do
    Enum.sort_by(projects, & &1["stats"]["views"], :desc)
  end

  defp sort_projects(projects, :likes) do
    Enum.sort_by(projects, & &1["stats"]["likes"], :desc)
  end
end
