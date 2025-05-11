defmodule PortfolioHermannWeb.HomeLive do
  use PortfolioHermannWeb, :live_view
  alias PortfolioHermann.Projects

  @impl true
  def mount(_params, _session, socket) do
    featured_projects =
      Projects.list_projects()
      |> Enum.filter(& &1["featured"])
      |> Enum.take(3)

    socket = socket
    |> assign(:featured_projects, featured_projects)
    |> assign(:current_slide, 0)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 bg-transparent">      <!-- Hero Section -->
      <section class="relative py-24 overflow-hidden">
        <div class="absolute inset-0 bg-gradient-to-br from-indigo-50 to-white dark:from-gray-900 dark:to-gray-800 -z-10"></div>
        <div class="relative text-center">
          <div class="space-y-4 mb-8">
            <h2 class="text-lg font-semibold text-indigo-600 dark:text-indigo-400">
              Bonjour, je suis Hermann Kekeil GOLO 👋 Alis Hlabs
            </h2>
            <h1 class="text-5xl font-bold mb-6 bg-gradient-to-r from-indigo-600 to-purple-600 dark:from-indigo-400 dark:to-purple-400 text-transparent bg-clip-text">
              Développeur Full-Stack & Data Engineer
            </h1>
            <p class="text-xl text-gray-700 dark:text-gray-300 max-w-3xl mx-auto leading-relaxed">
              Expert en développement d'applications web performantes avec
              <span class="font-semibold text-indigo-600 dark:text-indigo-400">Elixir & Phoenix</span>,
              et en solutions data-driven avec
              <span class="font-semibold text-purple-600 dark:text-purple-400">Python & Flutter</span>.
            </p>
          </div>
          <div class="flex justify-center gap-6">
            <.link
              navigate={~p"/projects"}
              class="px-8 py-4 bg-gradient-to-r from-indigo-600 to-purple-600 text-white rounded-xl hover:from-indigo-700 hover:to-purple-700 transform hover:scale-105 transition duration-200 shadow-lg hover:shadow-xl"
            >
              <div class="flex items-center gap-2">
                <.icon name="hero-rocket-launch" class="w-5 h-5" />
                <span>Voir mes projets</span>
              </div>
            </.link>
            <.link
              navigate={~p"/contact"}
              class="px-8 py-4 bg-white dark:bg-gray-800 text-gray-800 dark:text-white rounded-xl hover:bg-gray-50 dark:hover:bg-gray-700 transform hover:scale-105 transition duration-200 shadow-lg hover:shadow-xl border border-gray-200 dark:border-gray-700"
            >
              <div class="flex items-center gap-2">
                <.icon name="hero-envelope" class="w-5 h-5" />
                <span>Me contacter</span>
              </div>
            </.link>
          </div>
        </div>
      </section>      <!-- Technologies Section -->
      <section class="py-20 bg-gradient-to-b from-transparent via-indigo-50/50 to-transparent dark:from-transparent dark:via-gray-800/50 dark:to-transparent">
        <div class="max-w-7xl mx-auto">
          <h2 class="text-3xl font-bold mb-2 text-center bg-gradient-to-r from-indigo-600 to-purple-600 dark:from-indigo-400 dark:to-purple-400 text-transparent bg-clip-text">
            Technologies & Expertise
          </h2>
          <p class="text-center text-gray-600 dark:text-gray-400 mb-12">
            Un ensemble diversifié de technologies modernes pour des solutions performantes
          </p>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div class="group hover:scale-105 transition-transform duration-300">
              <div class="card-soft bg-white dark:bg-gray-800 relative overflow-hidden">
                <div class="absolute inset-0 bg-gradient-to-br from-indigo-600/5 to-purple-600/5 dark:from-indigo-600/10 dark:to-purple-600/10"></div>
                <div class="relative p-6">
                  <div class="flex items-center gap-3 mb-6">
                    <div class="p-2 bg-indigo-100 dark:bg-indigo-900/50 rounded-lg">
                      <.icon name="hero-server" class="w-6 h-6 text-indigo-600 dark:text-indigo-400" />
                    </div>
                    <h3 class="text-xl font-semibold text-indigo-600 dark:text-indigo-400">Backend</h3>
                  </div>
                  <ul class="space-y-3 text-gray-600 dark:text-gray-300">
                    <li class="flex items-center gap-2">
                      <.icon name="hero-check-circle" class="w-5 h-5 text-green-500" />
                      Elixir & Phoenix LiveView
                    </li>
                    <li class="flex items-center gap-2">
                      <.icon name="hero-check-circle" class="w-5 h-5 text-green-500" />
                      Python & Django/FastAPI
                    </li>
                    <li class="flex items-center gap-2">
                      <.icon name="hero-check-circle" class="w-5 h-5 text-green-500" />
                      Node.js & Express
                    </li>
                    <li class="flex items-center gap-2">
                      <.icon name="hero-check-circle" class="w-5 h-5 text-green-500" />
                      PostgreSQL & MongoDB
                    </li>
                  </ul>
                </div>
              </div>
            </div>
            <div class="group hover:scale-105 transition-transform duration-300">
              <div class="card-soft bg-white dark:bg-gray-800 relative overflow-hidden">
                <div class="absolute inset-0 bg-gradient-to-br from-purple-600/5 to-pink-600/5 dark:from-purple-600/10 dark:to-pink-600/10"></div>
                <div class="relative p-6">
                  <div class="flex items-center gap-3 mb-6">
                    <div class="p-2 bg-purple-100 dark:bg-purple-900/50 rounded-lg">
                      <.icon name="hero-computer-desktop" class="w-6 h-6 text-purple-600 dark:text-purple-400" />
                    </div>
                    <h3 class="text-xl font-semibold text-purple-600 dark:text-purple-400">Frontend</h3>
                  </div>
                  <ul class="space-y-3 text-gray-600 dark:text-gray-300">
                    <li class="flex items-center gap-2">
                      <.icon name="hero-check-circle" class="w-5 h-5 text-green-500" />
                      TailwindCSS & Alpine.js
                    </li>
                    <li class="flex items-center gap-2">
                      <.icon name="hero-check-circle" class="w-5 h-5 text-green-500" />
                      Vue.js & React
                    </li>
                    <li class="flex items-center gap-2">
                      <.icon name="hero-check-circle" class="w-5 h-5 text-green-500" />
                      Flutter & Dart
                    </li>
                    <li class="flex items-center gap-2">
                      <.icon name="hero-check-circle" class="w-5 h-5 text-green-500" />
                      HTML5 & CSS3
                    </li>
                  </ul>
                </div>
              </div>
            </div>
            <div class="group hover:scale-105 transition-transform duration-300">
              <div class="card-soft bg-white dark:bg-gray-800 relative overflow-hidden">
                <div class="absolute inset-0 bg-gradient-to-br from-pink-600/5 to-rose-600/5 dark:from-pink-600/10 dark:to-rose-600/10"></div>
                <div class="relative p-6">
                  <div class="flex items-center gap-3 mb-6">
                    <div class="p-2 bg-pink-100 dark:bg-pink-900/50 rounded-lg">
                      <.icon name="hero-chart-bar" class="w-6 h-6 text-pink-600 dark:text-pink-400" />
                    </div>
                    <h3 class="text-xl font-semibold text-pink-600 dark:text-pink-400">Data</h3>
                  </div>
                  <ul class="space-y-3 text-gray-600 dark:text-gray-300">
                    <li class="flex items-center gap-2">
                      <.icon name="hero-check-circle" class="w-5 h-5 text-green-500" />
                      Machine Learning & IA
                    </li>
                    <li class="flex items-center gap-2">
                      <.icon name="hero-check-circle" class="w-5 h-5 text-green-500" />
                      Data Engineering
                    </li>
                    <li class="flex items-center gap-2">
                      <.icon name="hero-check-circle" class="w-5 h-5 text-green-500" />
                      Data Visualization
                    </li>
                    <li class="flex items-center gap-2">
                      <.icon name="hero-check-circle" class="w-5 h-5 text-green-500" />
                      Business Intelligence
                    </li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <!-- Featured Projects -->
      <section class="py-16">
        <div class="flex justify-between items-center mb-8">
          <h2 class="text-3xl font-bold text-gray-900 dark:text-white">Projets mis en avant</h2>
          <.link
            navigate={~p"/projects"}
            class="text-indigo-600 hover:text-indigo-700 dark:text-indigo-400 dark:hover:text-indigo-300"
          >
            Voir tous les projets →
          </.link>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          <%= for project <- @featured_projects do %>
            <div class="card-soft hover:shadow-xl transition duration-300">
              <div class="relative">
                <%= if project["logo_url"] do %>
                  <img src={project["logo_url"]} alt={project["title"]} class="w-full h-48 object-cover rounded-t-lg" />
                <% end %>
                <div class="absolute top-2 right-2 flex items-center space-x-2">
                  <span class="bg-white/90 dark:bg-gray-800/90 rounded-full px-3 py-1 text-sm text-gray-700 dark:text-gray-300">
                    <%= project["year"] %>
                  </span>
                </div>
              </div>
              <div class="p-6">
                <h3 class="text-xl font-bold mb-2 text-gray-900 dark:text-white">
                  <%= project["title"] %>
                </h3>
                <p class="text-gray-600 dark:text-gray-300 mb-4 line-clamp-2">
                  <%= project["desc"] %>
                </p>
                <div class="flex flex-wrap gap-2 mb-4">
                  <%= for tag <- project["tags"] || [] do %>
                    <span class="px-2 py-1 text-sm bg-indigo-100 text-indigo-700 dark:bg-indigo-900 dark:text-indigo-300 rounded">
                      <%= tag %>
                    </span>
                  <% end %>
                </div>
                <div class="flex justify-between items-center">
                  <div class="flex space-x-4 text-gray-600 dark:text-gray-300">
                    <span class="flex items-center">
                      <.icon name="hero-eye" class="w-5 h-5 mr-1" />
                      <%= project["stats"]["views"] %>
                    </span>
                    <span class="flex items-center">
                      <.icon name="hero-heart" class="w-5 h-5 mr-1" />
                      <%= project["stats"]["likes"] %>
                    </span>
                  </div>
                  <.link
                    navigate={~p"/projects/#{project["id"]}"}
                    class="text-indigo-600 hover:text-indigo-700 dark:text-indigo-400 dark:hover:text-indigo-300"
                  >
                    En savoir plus →
                  </.link>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </section>
    </div>
    """
  end
end
