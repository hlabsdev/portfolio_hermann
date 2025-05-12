defmodule PortfolioHermannWeb.Components.Timeline do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  attr :experiences, :list, required: true
  attr :type, :string, default: "work"

  def timeline(assigns) do
    ~H"""
    <div class="space-y-6">
      <%= for exp <- @experiences do %>
        <div class="timeline-item">
          <div class="timeline-dot"></div>
          <div class="ml-4">
            <div class="flex justify-between items-start">
              <div>
                <h3 class="text-xl font-bold"><%= exp["title"] %></h3>
                <p class="text-gray-600 dark:text-gray-300">
                  <%= exp["company"] %> · <%= exp["location"] %>
                </p>
              </div>
              <div class="text-right text-gray-500">
                <p><%= exp["start_date"] %> - <%= exp["end_date"] || "Present" %></p>
                <%= if exp["duration"] do %>
                  <p class="text-sm"><%= exp["duration"] %></p>
                <% end %>
              </div>
            </div>

            <div class="mt-4 prose prose-sm dark:prose-invert max-w-none">
              <p class="text-gray-700 dark:text-gray-200"><%= exp["description"] %></p>

              <%= if Enum.any?(exp["achievements"] || []) do %>
                <div class="mt-2">
                  <ul class="list-disc list-inside">
                    <%= for achievement <- exp["achievements"] do %>
                      <li class="text-gray-700 dark:text-gray-300"><%= achievement %></li>
                    <% end %>
                  </ul>
                </div>
              <% end %>

              <%= if Enum.any?(exp["keywords"] || []) do %>
                <div class="mt-4 flex flex-wrap gap-2">
                  <%= for keyword <- exp["keywords"] do %>
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-indigo-100 dark:bg-indigo-900 text-indigo-800 dark:text-indigo-200">
                      <%= keyword %>
                    </span>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
