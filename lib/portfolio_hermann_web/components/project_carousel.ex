defmodule PortfolioHermannWeb.Components.ProjectCarousel do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  def carousel(assigns) do
    ~H"""
    <div class="relative">
      <div class="overflow-hidden">
        <div class="flex transition-transform duration-500" style={"transform: translateX(-#{@current_slide * 100}%)"}>
          <%= for {project, index} <- Enum.with_index(@projects) do %>
            <div class={"carousel-item flex-none w-full #{if index == @current_slide, do: "active"}"}>
              <h2 class="text-2xl font-bold mb-4"><%= project["title"] %></h2>
              <p class="text-gray-600 dark:text-gray-300 mb-2 font-mono"><%= project["tech"] %></p>
              <p class="mb-4"><%= project["desc"] %></p>
              <div class="absolute bottom-6 right-6">
                <button class="btn-soft px-4 py-2">Voir le projet</button>
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
