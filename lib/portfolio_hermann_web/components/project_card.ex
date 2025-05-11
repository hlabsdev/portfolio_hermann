defmodule PortfolioHermannWeb.ProjectCard do
  use Phoenix.Component
  use PortfolioHermannWeb, :html
  import Phoenix.VerifiedRoutes

  attr :title, :string, required: true
  attr :tech, :string, required: true
  attr :desc, :string, required: true
  attr :id, :string, required: true
  attr :logo_url, :string, default: nil
  attr :demo_urls, :list, default: []
  attr :source_urls, :list, default: []

  def project_card(assigns) do
    ~H"""
    <div class="card-soft hover:shadow-xl transition duration-300">
      <div class="flex items-start space-x-4 mb-4">
        <div class="flex-1">
          <h2 class="text-xl font-bold mb-2"><%= @title %></h2>
          <p class="text-sm text-gray-600 mb-2 italic"><%= @tech %></p>
        </div>
        <%= if @logo_url do %>
          <img src={@logo_url} alt={@title} class="w-16 h-16 object-contain rounded-lg" />
        <% end %>
      </div>

      <p class="text-base mb-4 line-clamp-3"><%= @desc %></p>

      <div class="flex flex-wrap gap-2 mt-4">
        <%= for demo <- @demo_urls do %>
          <a
            href={demo["url"]}
            target="_blank"
            rel="noopener noreferrer"
            class="inline-flex items-center px-3 py-1 text-sm bg-indigo-100 text-indigo-700 rounded-full hover:bg-indigo-200"
          >
            <%= demo["label"] %>
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 ml-1" viewBox="0 0 20 20" fill="currentColor">
              <path d="M11 3a1 1 0 100 2h2.586l-6.293 6.293a1 1 0 101.414 1.414L15 6.414V9a1 1 0 102 0V4a1 1 0 00-1-1h-5z" />
              <path d="M5 5a2 2 0 00-2 2v8a2 2 0 002 2h8a2 2 0 002-2v-3a1 1 0 10-2 0v3H5V7h3a1 1 0 000-2H5z" />
            </svg>
          </a>
        <% end %>
        <%= for source <- @source_urls do %>
          <a
            href={source["url"]}
            target="_blank"
            rel="noopener noreferrer"
            class="inline-flex items-center px-3 py-1 text-sm bg-gray-100 text-gray-700 rounded-full hover:bg-gray-200"
          >
            <%= source["label"] %>
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 ml-1" viewBox="0 0 20 20" fill="currentColor">
                <path d="M10 0C4.477 0 0 4.477 0 10c0 4.42 2.87 8.17 6.84 9.5.5.08.66-.23.66-.5v-1.69c-2.77.6-3.36-1.34-3.36-1.34-.46-1.16-1.11-1.47-1.11-1.47-.91-.62.07-.6.07-.6 1 .07 1.53 1.03 1.53 1.03.87 1.52 2.34 1.07 2.91.83.09-.65.35-1.09.63-1.34-2.22-.25-4.55-1.11-4.55-4.92 0-1.11.38-2 1.03-2.71-.1-.25-.45-1.29.1-2.64 0 0 .84-.27 2.75 1.02.79-.22 1.65-.33 2.5-.33.85 0 1.71.11 2.5.33 1.91-1.29 2.75-1.02 2.75-1.02.55 1.35.2 2.39.1 2.64.65.71 1.03 1.6 1.03 2.71 0 3.82-2.34 4.66-4.57 4.91.36.31.69.92.69 1.85V19c0 .27.16.59.67.5C17.14 18.16 20 14.42 20 10A10 10 0 0010 0z" />
            </svg>
          </a>
        <% end %>
      </div>

      <div class="mt-4 flex justify-end">
        <.link patch={~p"/projects/#{@id}"} class="btn-soft px-4 py-2 hover:bg-indigo-100 dark:hover:bg-indigo-900/20">
          Voir les détails
        </.link>
      </div>
    </div>
    """
  end
end
