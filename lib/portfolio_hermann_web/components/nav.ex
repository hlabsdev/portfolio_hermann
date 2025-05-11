defmodule PortfolioHermannWeb.Components.Nav do
  use Phoenix.Component
  use PortfolioHermannWeb, :verified_routes
  alias Phoenix.LiveView.JS
  import PortfolioHermannWeb.CoreComponents

  def nav(assigns) do
    ~H"""
    <nav class="fixed top-0 left-0 right-0 z-50 bg-white/80 dark:bg-gray-900/80 backdrop-blur-lg border-b border-gray-200 dark:border-gray-800">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between h-16">
          <div class="flex-1 flex items-center justify-between">
            <div class="flex items-center">
              <.link href={~p"/"} class="text-lg font-bold">
                <.icon name="code_bracket" class="h-8 w-8 inline-block mr-2" /> Hermann GOLO
              </.link>
            </div>

    <!-- Navigation items -->
            <nav class="hidden md:flex items-center space-x-8">
              <%= for {label, path} <- main_menu_items() do %>
                <.link
                  href={path}
                  class="text-gray-600 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white transition-colors"
                >
                  {label}
                </.link>
              <% end %>

              <button
                phx-hook="DarkMode"
                id="dark-mode-toggle"
                class="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
              >
                <Heroicons.sun class="h-5 w-5 hidden dark:block text-gray-300 hover:text-white" />
                <Heroicons.moon class="h-5 w-5 block dark:hidden text-gray-600 hover:text-gray-900" />
              </button>
            </nav>
          </div>
        </div>
      </div>

    <!-- Mobile menu -->
      <div class="md:hidden hidden" id="mobile-menu">
        <div class="px-2 pt-2 pb-3 space-y-1">
          <%= for {label, path} <- main_menu_items() do %>
            <.link
              href={path}
              class="block px-3 py-2 text-gray-600 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white transition-colors"
            >
              {label}
            </.link>
          <% end %>
        </div>
      </div>
    </nav>
    """
  end

  defp main_menu_items do
    [
      {"Accueil", ~p"/"},
      {"Projets", ~p"/projects"},
      {"Blog", ~p"/blog"},
      {"Contact", ~p"/contact"}
    ]
  end
end
