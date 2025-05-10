defmodule PortfolioHermannWeb.Components.Timeline do
  use Phoenix.Component

  def timeline(assigns) do
    ~H"""
    <div class="space-y-4">
      <%= for {year, experiences} <- @experiences do %>
        <div class="timeline-item">
          <div class="timeline-dot"></div>
          <div class="ml-4">
            <h3 class="text-xl font-bold"><%= year %></h3>
            <%= for exp <- experiences do %>
              <div class="mt-2">
                <h4 class="font-semibold"><%= exp.title %></h4>
                <p class="text-gray-600 dark:text-gray-300"><%= exp.company %></p>
                <p class="text-sm"><%= exp.description %></p>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
