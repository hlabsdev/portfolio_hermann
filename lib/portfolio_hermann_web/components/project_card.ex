defmodule PortfolioHermannWeb.ProjectCard do
  use Phoenix.Component
  import PortfolioHermannWeb.CoreComponents
  alias Phoenix.LiveView.JS

  attr :project, :map, required: true

  def project_card(assigns) do
    ~H"""
    <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-lg overflow-hidden hover:shadow-xl transition-all duration-300">
      <div class="relative aspect-[4/3] bg-gray-200 dark:bg-gray-700">
        <%= if @project["logo_url"] && @project["logo_url"] != "" do %>
          <img
            src={@project["logo_url"]}
            alt={@project["title"]}
            class="w-full h-full object-cover"
          />
        <% else %>
          <div class="absolute inset-0 flex items-center justify-center text-gray-400 dark:text-gray-500">
            <.icon name="hero-computer-desktop" class="w-16 h-16" />
          </div>
        <% end %>
      </div>

      <div class="p-6">
        <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-2">
          {@project["title"]}
        </h3>

        <p class="text-gray-600 dark:text-gray-400 line-clamp-3 mb-4">
          {@project["desc"]}
        </p>

        <div class="flex flex-wrap gap-2 mb-4">
          <%=for tech <- @project["techs"] || [] do %>
            <span class="px-2 py-1 text-xs bg-indigo-100 text-indigo-700 dark:bg-indigo-900/50 dark:text-indigo-300 rounded">
              {tech}
            </span>
          <% end %>
        </div>

        <div class="flex flex-wrap gap-2 mb-4">
          <%=for tag <- @project["tags"] || [] do %>
            <span class="px-2 py-1 text-xs bg-[#f39d8d]/10 text-[#8B4513] dark:bg-[#8B4513]/20 dark:text-[#f39d8d] rounded">
              {tag}
            </span>
          <% end %>
        </div>

        <div class="flex justify-between items-center">
          <div class="flex items-center space-x-2 text-sm text-gray-600 dark:text-gray-400">
            <.icon name="hero-eye" class="w-4 h-4" />
            <span>{@project["stats"]["views"]}</span>
            <button
              type="button"
              phx-click={JS.push("like_project", value: %{id: @project["id"]})}
              class="ml-2 flex items-center hover:text-[#f39d8d] dark:hover:text-[#f39d8d] transition-colors duration-200"
            >
              <.icon name="hero-heart" class="w-4 h-4" />
              <span class="ml-1">{@project["stats"]["likes"]}</span>
            </button>
          </div>

          <div class="flex items-center space-x-2">
            <%=if @project["source_urls"] && length(@project["source_urls"]) > 0 do %>
              <a
                href={hd(@project["source_urls"])["url"]}
                target="_blank"
                rel="noopener noreferrer"
                class="inline-flex items-center text-indigo-600 hover:text-indigo-700 dark:text-indigo-400 dark:hover:text-indigo-300"
              >
                <.icon name="hero-code-bracket" class="w-5 h-5" />
              </a>
            <% end %>

            <%=if @project["demo_urls"] && length(@project["demo_urls"]) > 0 do %>
              <%= for demo <- @project["demo_urls"] do %>
                <a
                  href={demo["url"]}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="inline-flex items-center text-indigo-600 hover:text-indigo-700 dark:text-indigo-400 dark:hover:text-indigo-300"
                  title={demo["label"]}
                >
                  <.icon name="hero-play" class="w-5 h-5" />
                </a>
              <% end %>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
