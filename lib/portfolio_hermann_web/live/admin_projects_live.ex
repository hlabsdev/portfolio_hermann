defmodule PortfolioHermannWeb.AdminProjectsLive do
  use PortfolioHermannWeb, :live_view
  alias PortfolioHermann.Projects
  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, _session, socket) do

    all_years = Projects.list_projects() |> Enum.map(& &1["year"]) |> Enum.uniq() |> Enum.sort(:desc)
    socket =
      socket
      |> assign(:projects, Projects.list_projects())
      |> assign(:all_techs, Projects.list_techs())
      |> assign(:all_tags, Projects.list_tags())
      |> assign(:all_years, all_years)
      |> assign(:editing_project, nil)
      |> assign(:logo_type, "url")
      |> assign(:form_mode, :none)
      |> assign(:view_mode, :list)
      |> assign(:year_filter, "all")
      |> assign(:type_filter, "all")
      |> assign(:search_query, "")
      |> allow_upload(:logo,
        accept: ~w(.jpg .jpeg .png .gif),
        max_entries: 1,
        max_file_size: 5_000_000,
        auto_upload: true
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("new", _, socket) do
    {:noreply, assign(socket, editing_project: nil, form_mode: :new)}
  end

  @impl true
  def handle_event("add", %{"project" => project_params}, socket) do
    project_params = handle_logo_upload(socket, project_params)

    project = %{
      "id" => UUID.uuid4(),
      "title" => project_params["title"],
      "techs" => parse_techs(project_params["techs"]),
      "desc" => project_params["desc"],
      "logo_url" => project_params["logo_url"],
      "demo_urls" => parse_urls(project_params["demo_urls"]),
      "source_urls" => parse_urls(project_params["source_urls"]),
      "year" => String.to_integer(project_params["year"] || "2024"),
      "type" => project_params["type"],
      "tags" => parse_tags(project_params["tags"]),
      "featured" => project_params["featured"] == "true",
      "stats" => %{
        "views" => 0,
        "likes" => 0
      }
    }

    Projects.add_project(project)

    {:noreply,
     assign(socket,
       projects: Projects.list_projects(),
       editing_project: nil,
       form_mode: :none
     )}
  end

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    project = Enum.find(socket.assigns.projects, &(&1["id"] == id))
    {:noreply, assign(socket, editing_project: project, form_mode: :edit)}
  end

  @impl true
  def handle_event("update", %{"project" => project_params}, socket) do
    project_params = handle_logo_upload(socket, project_params)

    updates = %{
      "title" => project_params["title"],
      "techs" => parse_techs(project_params["techs"]),
      "desc" => project_params["desc"],
      "logo_url" => project_params["logo_url"],
      "demo_urls" => parse_urls(project_params["demo_urls"]),
      "source_urls" => parse_urls(project_params["source_urls"]),
      "year" => String.to_integer(project_params["year"] || "2024"),
      "type" => project_params["type"],
      "tags" => parse_tags(project_params["tags"]),
      "featured" => project_params["featured"] == "true",
      "stats" => socket.assigns.editing_project["stats"]
    }

    Projects.update_project(socket.assigns.editing_project["id"], updates)

    {:noreply,
     assign(socket,
       projects: Projects.list_projects(),
       editing_project: nil,
       form_mode: :none
     )}
  end

  @impl true
  def handle_event("cancel_edit", _, socket) do
    {:noreply, assign(socket, editing_project: nil, form_mode: :none)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    Projects.delete_project(id)
    {:noreply, assign(socket, :projects, Projects.list_projects())}
  end

  @impl true
  def handle_event("switch_logo_type", %{"type" => type}, socket) do
    {:noreply, assign(socket, :logo_type, type)}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_view", %{"view" => view}, socket) do
    {:noreply, assign(socket, :view_mode, String.to_atom(view))}
  end

  @impl true
  def handle_event("filter_year", %{"year" => year}, socket) do
    {:noreply, assign(socket, :year_filter, year)}
  end

  @impl true
  def handle_event("filter_type", %{"type" => type}, socket) do
    {:noreply, assign(socket, :type_filter, type)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, assign(socket, :search_query, query)}
  end

  @impl true
  def handle_event("toggle_featured", %{"id" => id}, socket) do
    project = Enum.find(socket.assigns.projects, &(&1["id"] == id))
    updates = %{"featured" => !project["featured"]}
    Projects.update_project(id, updates)
    {:noreply, assign(socket, :projects, Projects.list_projects())}
  end

  defp handle_logo_upload(socket, project_params) do
    uploaded_files =
      consume_uploaded_entries(socket, :logo, fn %{path: path}, _entry ->
        ext = Path.extname(path)
        filename = "#{UUID.uuid4()}#{ext}"
        dest = Path.join("priv/static/uploads", filename)
        File.mkdir_p!(Path.dirname(dest))
        File.cp!(path, dest)
        {:ok, "/uploads/" <> filename}
      end)

    case uploaded_files do
      [url | _] -> Map.put(project_params, "logo_url", url)
      _ -> project_params
    end
  end

  defp error_to_string(:too_large), do: "Fichier trop volumineux"
  defp error_to_string(:too_many_files), do: "Trop de fichiers"
  defp error_to_string(:not_accepted), do: "Format de fichier non accepté"

  defp parse_urls(urls_string) when is_binary(urls_string) do
    urls_string
    |> String.split("\n")
    |> Enum.map(&parse_url_line/1)
    |> Enum.reject(&is_nil/1)
  end
  defp parse_urls(_), do: []

  defp parse_url_line(line) do
    case String.split(line, ":") do
      [url, label] -> %{"url" => String.trim(url), "label" => String.trim(label)}
      # [url] -> %{"url" => String.trim(url), "label" => String.trim(label)}
      _ -> nil
    end
  end

  defp parse_tags(tags) when is_list(tags), do: tags

  defp parse_tags(tags_string) when is_binary(tags_string) do
    tags_string
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end
  defp parse_tags(_), do: []

  defp parse_techs(techs) when is_list(techs), do: techs
  defp parse_techs(techs_string) when is_binary(techs_string) do
    techs_string
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end
  defp parse_techs(_), do: []

  defp filter_projects(projects, year_filter, type_filter, search_query) do
    projects
    |> filter_by_year(year_filter)
    |> filter_by_type(type_filter)
    |> filter_by_search(search_query)
  end

  defp filter_by_year(projects, "all"), do: projects
  defp filter_by_year(projects, year) do
    year = String.to_integer(year)
    Enum.filter(projects, &(&1["year"] == year))
  end

  defp filter_by_type(projects, "all"), do: projects
  defp filter_by_type(projects, type) do
    Enum.filter(projects, &(&1["type"] == type))
  end

  defp filter_by_search(projects, ""), do: projects
  defp filter_by_search(projects, query) do
    query = String.downcase(query)
    Enum.filter(projects, fn project ->
      String.contains?(String.downcase(project["title"]), query) ||
      String.contains?(String.downcase(project["desc"]), query) ||
      String.contains?(String.downcase(project["techs"]), query) ||
      Enum.any?(project["tags"], &String.contains?(String.downcase(&1), query))
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8">
      <div class="sm:flex sm:items-center">
        <div class="sm:flex-auto">
          <h1 class="text-xl font-semibold text-gray-900 dark:text-white mt-8">Projets</h1>
          <p class="mt-2 text-sm text-gray-700 dark:text-gray-300">Liste de tous vos projets avec options de gestion.</p>
        </div>
      </div>

      <div class="mt-4 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <!-- Contrôles de vue -->
        <div class="flex items-center gap-2">
          <button phx-click="toggle_view" phx-value-view="grid"
            class={"px-3 py-2 text-sm rounded-md #{if @view_mode == :grid, do: "bg-indigo-600 text-white", else: "bg-white text-gray-700 hover:bg-gray-50"}"}>
            <.icon name="hero-squares-2x2" class="w-5 h-5" />
          </button>
          <button phx-click="toggle_view" phx-value-view="list"
            class={"px-3 py-2 text-sm rounded-md #{if @view_mode == :list, do: 'bg-indigo-600 text-white', else: 'bg-white text-gray-700 hover:bg-gray-50'}"}>
            <.icon name="hero-bars-4" class="w-5 h-5" />
          </button>
          <button phx-click="new"
            class="inline-flex items-center px-3 py-2 text-sm bg-blue-600 text-white rounded-md hover:bg-blue-500">
              <.icon name="hero-plus" class="w-5 h-5" />
              Ajouter un projet
          </button>
        </div>

        <!-- Filtres -->
        <div class="flex flex-wrap items-center gap-4">
          <form phx-change="filter_year" class="flex items-center gap-2">
            <select name="year" class="rounded-md border-gray-300 text-sm text-gray-600 dark:text-gray-400">
              <option value="all">Toutes années</option>
              <%= for year <- @all_years do %>
                <option value={year} selected={@year_filter == to_string(year)}><%= year %></option>
              <% end %>
            </select>
          </form>

          <form phx-change="filter_type" class="flex items-center gap-2">
            <select name="type" class="rounded-md border-gray-300 text-sm text-gray-600 dark:text-gray-400">
              <option value="all">Tous types</option>
              <option value="Application Web">Application Web</option>
              <option value="Mobile">Mobile</option>
              <option value="SaaS">SaaS</option>
              <option value="Dashboard">Dashboard</option>
              <option value="Plateforme">Plateforme</option>
              <option value="SIG">SIG</option>
            </select>
          </form>

          <form phx-change="search" class="flex items-center gap-2 text-gray-600 dark:text-gray-400">
            <input type="text" name="query" value={@search_query}
              placeholder="Rechercher..."
              class="rounded-md border-gray-300 text-sm" />
          </form>
        </div>
      </div>

      <%= if @view_mode == :grid do %>
        <div class="mt-8 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          <%= for project <- filter_projects(@projects, @year_filter, @type_filter, @search_query) do %>
            <div class="relative group card-soft p-6 p-6 focus-within:ring-2 focus-within:ring-inset focus-within:ring-indigo-500">
              <div class="flex items-center justify-between">
                <div>
                  <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                    <span class="absolute inset-0" aria-hidden="true"></span>
                    <%= project["title"] %>
                  </h3>
                  <p class="text-sm text-gray-500"><%= project["year"] %> · <%= project["type"] %></p>
                </div>
                <button phx-click="toggle_featured" phx-value-id={project["id"]}
                  class={"#{if project["featured"], do: 'text-yellow-400', else: 'text-gray-300'} hover:text-yellow-400"}>
                  <.icon name="hero-star" class="w-6 h-6" />
                </button>
              </div>
              <div class="mt-2">
                <p class="text-sm text-gray-500 line-clamp-3"><%= project["desc"] %></p>
              </div>
              <div class="mt-4">
                <div class="flex flex-wrap gap-2">
                  <%= for tag <- project["tags"] || [] do %>
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800">
                      <%= tag %>
                    </span>
                  <% end %>
                </div>
              </div>
              <div class="mt-6 flex gap-2">
                <button phx-click="edit" phx-value-id={project["id"]}
                  class="inline-flex items-center px-3 py-2 text-sm font-medium text-indigo-700 bg-indigo-100 rounded-md hover:bg-indigo-200">
                  <.icon name="hero-pencil-square" class="w-5 h-5 mr-2" />
                  Modifier
                </button>
                <button phx-click="delete" phx-value-id={project["id"]}
                  data-confirm="Êtes-vous sûr de vouloir supprimer ce projet ?"
                  class="inline-flex items-center px-3 py-2 text-sm font-medium text-red-700 bg-red-100 rounded-md hover:bg-red-200">
                  <.icon name="hero-trash" class="w-5 h-5 mr-2" />
                  Supprimer
                </button>
              </div>
            </div>
          <% end %>
        </div>
      <% else %>
        <div class="mt-8 flow-root">
          <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
            <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
              <table class="min-w-full divide-y divide-gray-300">
                <thead>
                  <tr>
                    <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 dark:text-white">Projet</th>
                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900 dark:text-white">Type</th>
                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900 dark:text-white">Année</th>
                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900 dark:text-white">Mis en avant</th>
                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900 dark:text-white">Tags</th>
                    <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-0">
                      <span class="sr-only">Actions</span>
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-200">
                  <%= for project <- filter_projects(@projects, @year_filter, @type_filter, @search_query) do %>
                    <tr>
                      <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm">
                        <div>
                          <div class="font-medium text-gray-900 dark:text-white"><%= project["title"] %></div>
                          <div class="text-gray-500 line-clamp-1">
                            <%= String.slice(project["desc"], 0..60) <> "..." %>
                        </div>
                        </div>
                      </td>
                      <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500"><%= project["type"] %></td>
                      <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500"><%= project["year"] %></td>
                      <td class="whitespace-nowrap px-3 py-4 text-sm">
                        <button phx-click="toggle_featured" phx-value-id={project["id"]}
                          class={"#{if project["featured"], do: 'text-yellow-400', else: 'text-gray-300'} hover:text-yellow-400"}>
                          <.icon name="hero-star" class="w-6 h-6" />
                        </button>
                      </td>
                      <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                        <div class="flex flex-wrap gap-2">
                          <%= for tag <- project["tags"] || [] do %>
                            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800">
                              <%= tag %>
                            </span>
                          <% end %>
                        </div>
                      </td>
                      <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-0">
                        <div class="flex justify-end gap-2">
                          <button phx-click="edit" phx-value-id={project["id"]}
                            class="text-indigo-600 hover:text-indigo-900">
                            <.icon name="hero-pencil-square" class="w-5 h-5" />
                          </button>
                          <button phx-click="delete" phx-value-id={project["id"]}
                            data-confirm="Êtes-vous sûr de vouloir supprimer ce projet ?"
                            class="text-red-600 hover:text-red-900">
                            <.icon name="hero-trash" class="w-5 h-5" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      <% end %>
    </div>

    <%= cond do %>
      <% @form_mode == :edit -> %>
      <%= render_edit_modal(assigns) %>
      <% @form_mode == :new -> %>
      <%= render_add_modal(assigns) %>
      <% true -> %>
    <% end %>
    """
  end

  defp render_add_modal(assigns) do
    ~H"""
    <.modal id="add-project-modal" show={@form_mode == :new} on_cancel={JS.push("cancel_edit")}>
      <:title>Ajouter un projet</:title>

      <.form for={%{}} phx-submit="add">
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700">Titre</label>
            <input type="text" name="project[title]" required
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700">Description</label>
            <textarea name="project[desc]" rows="3" required
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"></textarea>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700">Technologies</label>
            <div class="mt-2 flex flex-wrap gap-2">
              <%= for tech <- @all_techs do %>
                <label class="inline-flex items-center">
                  <input
                    type="checkbox"
                    name="project[techs][]"
                    value={tech}
                    class="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                  />
                  <span class="ml-2 text-sm text-gray-600 dark:text-gray-400"><%= tech %></span>
                </label>
              <% end %>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700">Type de projet</label>
            <select name="project[type]" required
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm">
              <option value="Application Web">Application Web</option>
              <option value="Mobile">Mobile</option>
              <option value="SaaS">SaaS</option>
              <option value="Dashboard">Dashboard</option>
              <option value="Plateforme">Plateforme</option>
              <option value="SIG">SIG</option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700">Année</label>
            <select name="project[year]" required
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm">
              <%= for year <- @all_years do %>
                <option value={year}><%= year %></option>
              <% end %>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700">Tags</label>
            <div class="mt-2 flex flex-wrap gap-2">
              <%= for tag <- @all_tags do %>
                <label class="inline-flex items-center">
                  <input
                    type="checkbox"
                    name="project[tags][]"
                    value={tag}
                    class="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                  />
                  <span class="ml-2 text-sm text-gray-600 dark:text-gray-400"><%= tag %></span>
                </label>
              <% end %>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700">Logo</label>
            <div class="mt-2 flex items-center gap-4">
              <button type="button" phx-click="switch_logo_type" phx-value-type="url"
                class={"px-3 py-2 text-sm rounded-md #{if @logo_type == "url", do: 'bg-indigo-600 text-white', else: 'bg-white text-gray-700 hover:bg-gray-50'}"}>
                URL
              </button>
              <button type="button" phx-click="switch_logo_type" phx-value-type="upload"
                class={"px-3 py-2 text-sm rounded-md #{if @logo_type == "upload", do: 'bg-indigo-600 text-white', else: 'bg-white text-gray-700 hover:bg-gray-50'}"}>
                Upload
              </button>
            </div>

            <%= if @logo_type == "url" do %>
              <input type="text" name="project[logo_url]"
                class="mt-2 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                placeholder="https://..." />
            <% else %>
              <div class="mt-2">
                <.live_file_input upload={@uploads.logo} />
              </div>
            <% end %>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700">URLs de démo</label>
            <input type="text" name="project[demo_urls]"
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              placeholder="label:url, label2:url2" />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700">URLs du code source</label>
            <input type="text" name="project[source_urls]"
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              placeholder="label:url, label2:url2" />
          </div>

          <div>
            <label class="flex items-center gap-2">
              <input type="checkbox" name="project[featured]" value="true"
                class="h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500" />
              <span class="text-sm font-medium text-gray-700">Mettre en avant</span>
            </label>
          </div>
        </div>

        <div class="mt-5 sm:mt-6 sm:grid sm:grid-flow-row-dense sm:grid-cols-2 sm:gap-3">
          <button type="submit"
            class="inline-flex w-full justify-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-base font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 sm:col-start-2 sm:text-sm">
            Ajouter
          </button>
          <button type="button" phx-click={JS.push("cancel_edit")}
            class="mt-3 inline-flex w-full justify-center rounded-md border border-gray-300 bg-white px-4 py-2 text-base font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 sm:col-start-1 sm:mt-0 sm:text-sm">
            Annuler
          </button>
        </div>
      </.form>
    </.modal>
    """
  end

  defp render_edit_modal(assigns) do
    ~H"""
    <.modal id="edit-project-modal" show={@form_mode == :edit} on_cancel={JS.push("cancel_edit")}>
      <:title>Modifier le projet</:title>

      <.form for={%{}} phx-submit="update">
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700">Titre</label>
            <input type="text" name="project[title]" value={@editing_project["title"]} required
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700">Description</label>
            <textarea name="project[desc]" rows="3" required
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm">
              <%= @editing_project["desc"] %>
            </textarea>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700">Technologies</label>
            <div class="mt-2 flex flex-wrap gap-2">
              <%= for tech <- @all_techs do %>
                <label class="inline-flex items-center">
                  <input
                    type="checkbox"
                    name="project[techs][]"
                    value={tech}
                    checked={tech in (@editing_project && @editing_project["techs"] || [])}
                    class="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                  />
                  <span class="ml-2 text-sm text-gray-600 dark:text-gray-400"><%= tech %></span>
                </label>
              <% end %>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700">Type de projet</label>
            <select name="project[type]" required
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm">
              <%= for type <- ["Application Web", "Mobile", "SaaS", "Dashboard", "Plateforme", "SIG"] do %>
                <option value={type} selected={@editing_project["type"] == type}><%= type %></option>
              <% end %>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700">Année</label>
            <select name="project[year]" required
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm">
              <%= for year <- @all_years do %>
                <option value={year} selected={@editing_project["year"] == year}><%= year %></option>
              <% end %>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700">Tags</label>
            <div class="mt-2 flex flex-wrap gap-2">
              <%= for tag <- @all_tags do %>
                <label class="inline-flex items-center">
                  <input
                    type="checkbox"
                    name="project[tags][]"
                    value={tag}
                    checked={tag in (@editing_project && @editing_project["tags"] || [])}
                    class="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                  />
                  <span class="ml-2 text-sm text-gray-600 dark:text-gray-400"><%= tag %></span>
                </label>
              <% end %>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700">Logo</label>
            <div class="mt-2 flex items-center gap-4">
              <button type="button" phx-click="switch_logo_type" phx-value-type="url"
                class={"px-3 py-2 text-sm rounded-md #{if @logo_type == "url", do: 'bg-indigo-600 text-white', else: 'bg-white text-gray-700 hover:bg-gray-50'}"}>
                URL
              </button>
              <button type="button" phx-click="switch_logo_type" phx-value-type="upload"
                class={"px-3 py-2 text-sm rounded-md #{if @logo_type == "upload", do: 'bg-indigo-600 text-white', else: 'bg-white text-gray-700 hover:bg-gray-50'}"}>
                Upload
              </button>
            </div>

            <%= if @logo_type == "url" do %>
              <input type="text" name="project[logo_url]" value={@editing_project["logo_url"]}
                class="mt-2 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                placeholder="https://..." />
            <% else %>
              <div class="mt-2">
                <.live_file_input upload={@uploads.logo} />
              </div>
            <% end %>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700">URLs de démo</label>
            <input type="text" name="project[demo_urls]"
              value={format_urls(@editing_project["demo_urls"])}
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              placeholder="label:url, label2:url2" />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700">URLs du code source</label>
            <input type="text" name="project[source_urls]"
              value={format_urls(@editing_project["source_urls"])}
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              placeholder="label:url, label2:url2" />
          </div>

          <div>
            <label class="flex items-center gap-2">
              <input type="checkbox" name="project[featured]" value="true"
                checked={@editing_project["featured"]}
                class="h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500" />
              <span class="text-sm font-medium text-gray-700">Mettre en avant</span>
            </label>
          </div>
        </div>

        <div class="mt-5 sm:mt-6 sm:grid sm:grid-flow-row-dense sm:grid-cols-2 sm:gap-3">
          <button type="submit"
            class="inline-flex w-full justify-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-base font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 sm:col-start-2 sm:text-sm">
            Enregistrer
          </button>
          <button type="button" phx-click={JS.push("cancel_edit")}
            class="mt-3 inline-flex w-full justify-center rounded-md border border-gray-300 bg-white px-4 py-2 text-base font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 sm:col-start-1 sm:mt-0 sm:text-sm">
            Annuler
          </button>
        </div>
      </.form>
    </.modal>
    """
  end

  defp format_urls(urls) when is_list(urls) do
    urls
    |> Enum.map(fn %{"label" => label, "url" => url} -> "#{label}:#{url}" end)
    |> Enum.join(", ")
  end
  defp format_urls(_), do: ""
end
