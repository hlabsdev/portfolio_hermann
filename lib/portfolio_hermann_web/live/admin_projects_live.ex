defmodule PortfolioHermannWeb.AdminProjectsLive do
  use PortfolioHermannWeb, :live_view
  alias PortfolioHermann.Projects

  @impl true
  def mount(_params, _session, socket) do
    socket = socket
    |> assign(:projects, Projects.list_projects())
    |> assign(:editing_project, nil)
    |> assign(:logo_type, "url")
    |> assign(:form_mode, :new)
    |> allow_upload(:logo,
      accept: ~w(.jpg .jpeg .png .gif),
      max_entries: 1,
      max_file_size: 5_000_000,
      auto_upload: true
    )

    {:ok, socket}
  end

  @impl true
  def handle_event("add", %{"project" => project_params}, socket) do
    project_params = handle_logo_upload(socket, project_params)

    project = %{
      "id" => UUID.uuid4(),
      "title" => project_params["title"],
      "tech" => project_params["tech"],
      "desc" => project_params["desc"],
      "logo_url" => project_params["logo_url"],
      "demo_urls" => parse_urls(project_params["demo_urls"]),
      "source_urls" => parse_urls(project_params["source_urls"])
    }

    Projects.add_project(project)
    {:noreply, assign(socket, :projects, Projects.list_projects())}
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
      "tech" => project_params["tech"],
      "desc" => project_params["desc"],
      "logo_url" => project_params["logo_url"],
      "demo_urls" => parse_urls(project_params["demo_urls"]),
      "source_urls" => parse_urls(project_params["source_urls"])
    }

    Projects.update_project(socket.assigns.editing_project["id"], updates)

    {:noreply, assign(socket,
      projects: Projects.list_projects(),
      editing_project: nil,
      form_mode: :new
    )}
  end

  @impl true
  def handle_event("cancel_edit", _, socket) do
    {:noreply, assign(socket, editing_project: nil, form_mode: :new)}
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
    case String.split(line, "|") do
      [url, label] -> %{"url" => String.trim(url), "label" => String.trim(label)}
      [url] -> %{"url" => String.trim(url), "label" => "Voir"}
      _ -> nil
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto py-16 px-6">
      <div class="flex justify-between items-center mb-8">
        <h1 class="text-3xl font-bold">Gestion des projets</h1>
        <div class="flex gap-4">
          <.link navigate={~p"/admin/stats"} class="btn-soft px-4 py-2">
            Voir les stats
          </.link>
          <.link href={~p"/admin/logout"} method="delete" class="btn-soft text-red-600 px-4 py-2">
            Déconnexion
          </.link>
        </div>
      </div>

      <div class="card-soft mb-8">
        <h2 class="text-xl font-bold mb-4">
          <%= if @form_mode == :edit, do: "Modifier le projet", else: "Ajouter un projet" %>
        </h2>

        <.form
          for={%{}}
          phx-submit={if @form_mode == :edit, do: "update", else: "add"}
          phx-change="validate"
          class="space-y-4"
        >
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium mb-1">Titre</label>
              <input type="text" name="project[title]" value={@editing_project && @editing_project["title"]} required
                     class="w-full px-3 py-2 border rounded-lg focus:ring-1 focus:ring-indigo-500" />
            </div>
            <div>
              <label class="block text-sm font-medium mb-1">Technologies</label>
              <input type="text" name="project[tech]" value={@editing_project && @editing_project["tech"]} required
                     placeholder="Ex: Elixir, Phoenix LiveView, API SMS"
                     class="w-full px-3 py-2 border rounded-lg focus:ring-1 focus:ring-indigo-500" />
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium mb-1">Description</label>
            <textarea name="project[desc]" required rows="3"
                      class="w-full px-3 py-2 border rounded-lg focus:ring-1 focus:ring-indigo-500"><%= @editing_project && @editing_project["desc"] %></textarea>
          </div>

          <div>
            <label class="block text-sm font-medium mb-1">Logo</label>
            <div class="flex gap-4 mb-2">
              <label class="flex items-center">
                <input type="radio" name="logo_type" value="url" checked={@logo_type == "url"}
                       phx-click="switch_logo_type" phx-value-type="url" class="mr-2" />
                URL externe
              </label>
              <label class="flex items-center">
                <input type="radio" name="logo_type" value="file" checked={@logo_type == "file"}
                       phx-click="switch_logo_type" phx-value-type="file" class="mr-2" />
                Upload de fichier
              </label>
            </div>

            <%= if @logo_type == "url" do %>
              <input type="url" name="project[logo_url]" value={@editing_project && @editing_project["logo_url"]}
                     placeholder="https://example.com/logo.png"
                     class="w-full px-3 py-2 border rounded-lg focus:ring-1 focus:ring-indigo-500" />
            <% else %>
              <div class="flex items-center gap-4">
                <div class="w-full">
                  <.live_file_input upload={@uploads.logo} class="block w-full text-sm text-gray-500
                    file:mr-4 file:py-2 file:px-4
                    file:rounded-full file:border-0
                    file:text-sm file:font-semibold
                    file:bg-indigo-50 file:text-indigo-700
                    hover:file:bg-indigo-100
                  "/>
                </div>
              </div>

              <%= for entry <- @uploads.logo.entries do %>
                <div class="mt-2">
                  <.live_img_preview entry={entry} class="w-20 h-20 object-contain rounded-xl" />
                  <%= if entry.progress < 100 do %>
                    <div class="w-full h-2 bg-gray-200 rounded-full mt-2">
                      <div class="h-2 bg-indigo-600 rounded-full" style={"width: #{entry.progress}%"}></div>
                    </div>
                  <% end %>
                  <div class="text-sm text-gray-600">
                    <%= entry.client_name %> - <%= entry.client_size |> :erlang.float_to_binary(decimals: 2) %> KB
                  </div>
                  <%= for err <- upload_errors(@uploads.logo, entry) do %>
                    <div class="text-red-500 text-sm"><%= error_to_string(err) %></div>
                  <% end %>
                </div>
              <% end %>

              <%= for err <- upload_errors(@uploads.logo) do %>
                <div class="text-red-500 text-sm"><%= error_to_string(err) %></div>
              <% end %>
            <% end %>
          </div>

          <div>
            <label class="block text-sm font-medium mb-1">URLs des démos (une par ligne, format: URL|Label)</label>
            <textarea name="project[demo_urls]" rows="2"
                      class="w-full px-3 py-2 border rounded-lg focus:ring-1 focus:ring-indigo-500"><%= @editing_project && Enum.map_join(@editing_project["demo_urls"] || [], "\n", &("#{&1["url"]}|#{&1["label"]}")) %></textarea>
          </div>

          <div>
            <label class="block text-sm font-medium mb-1">URLs des sources (une par ligne, format: URL|Label)</label>
            <textarea name="project[source_urls]" rows="2"
                      class="w-full px-3 py-2 border rounded-lg focus:ring-1 focus:ring-indigo-500"><%= @editing_project && Enum.map_join(@editing_project["source_urls"] || [], "\n", &("#{&1["url"]}|#{&1["label"]}")) %></textarea>
          </div>

          <div class="flex justify-end gap-4">
            <%= if @form_mode == :edit do %>
              <button type="button" phx-click="cancel_edit" class="px-4 py-2 text-gray-600 hover:underline">
                Annuler
              </button>
            <% end %>
            <button type="submit" class="btn-soft bg-indigo-500 text-white px-6 py-2">
              <%= if @form_mode == :edit, do: "Mettre à jour", else: "Ajouter" %>
            </button>
          </div>
        </.form>
      </div>

      <div class="space-y-4">
        <h2 class="text-xl font-bold mb-4">Projets existants</h2>
        <%= for project <- @projects do %>
          <div class="card-soft">
            <div class="flex items-start space-x-4">
              <%= if project["logo_url"] do %>
                <img src={project["logo_url"]} alt={project["title"]} class="w-16 h-16 object-contain rounded-lg" />
              <% end %>
              <div class="flex-1">
                <h3 class="text-lg font-bold"><%= project["title"] %></h3>
                <p class="text-sm text-gray-600 mb-2"><%= project["tech"] %></p>
                <p class="text-sm"><%= project["desc"] %></p>
              </div>
              <div class="flex gap-2">
                <button phx-click="edit" phx-value-id={project["id"]} class="text-indigo-600 hover:underline">
                  Modifier
                </button>
                <button phx-click="delete" phx-value-id={project["id"]}
                        data-confirm="Êtes-vous sûr de vouloir supprimer ce projet ?"
                        class="text-red-600 hover:underline">
                  Supprimer
                </button>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
