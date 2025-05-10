defmodule PortfolioHermannWeb.Components.ProjectCarousel do
  use Phoenix.Component
  use PortfolioHermannWeb, :html
  import Phoenix.VerifiedRoutes
  alias Phoenix.LiveView.JS

  def carousel(assigns) do
    ~H"""
    <div class="relative">
      <div class="overflow-hidden">
        <div class="flex transition-transform duration-500" style={"transform: translateX(-#{@current_slide * 100}%)"}>
          <%= for {project, index} <- Enum.with_index(@projects) do %>
            <div class={"carousel-item flex-none w-full #{if index == @current_slide, do: "active"}"}>
              <div class="flex items-start space-x-6 mb-6">
                <%= if project["logo_url"] do %>
                  <img
                    src={project["logo_url"]}
                    alt={project["title"]}
                    class="w-20 h-20 object-contain rounded-xl"
                  />
                <% end %>
                <div class="flex-1">
                  <h2 class="text-2xl font-bold mb-4"><%= project["title"] %></h2>
                  <p class="text-gray-600 dark:text-gray-300 mb-2 font-mono"><%= project["tech"] %></p>
                </div>
              </div>

              <p class="mb-6"><%= project["desc"] %></p>

              <div class="flex flex-wrap gap-2 mb-8">
                <%= for demo <- (project["demo_urls"] || []) do %>
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

              <div class="absolute bottom-6 right-6">
                <.link
                  navigate={~p"/projects/#{project["id"]}"}
                  class="btn-soft px-4 py-2 hover:bg-indigo-100 dark:hover:bg-indigo-900/20"
                >
                  Voir le projet
                </.link>
              </div>
            </div>
          <% end %>
        </div>
      </div>
      <button
        phx-click={JS.push("prev-slide")}
        class="absolute left-4 top-1/2 -translate-y-1/2 bg-white/50 dark:bg-gray-800/50 p-2 rounded-full hover:bg-white/70 dark:hover:bg-gray-800/70"
      >←</button>
      <button
        phx-click={JS.push("next-slide")}
        class="absolute right-4 top-1/2 -translate-y-1/2 bg-white/50 dark:bg-gray-800/50 p-2 rounded-full hover:bg-white/70 dark:hover:bg-gray-800/70"
      >→</button>
    </div>
    """
  end
end
