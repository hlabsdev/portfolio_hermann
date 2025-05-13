defmodule PortfolioHermannWeb.HomeLive do
  use PortfolioHermannWeb, :live_view
  alias PortfolioHermann.Projects

  @impl true
  def mount(_params, _session, socket) do
    featured_projects =
      Projects.list_projects()
      |> Enum.filter(& &1["featured"])
      |> Enum.take(6)

    socket =
      socket
      |> assign(:featured_projects, featured_projects)
      |> assign(:current_slide, 0)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 bg-transparent">
      <!-- Hero Section -->
      <section class="relative py-24 overflow-hidden">
        <div class="absolute inset-0 bg-gradient-to-br from-indigo-50 to-white dark:from-gray-900 dark:to-gray-800 -z-10">
        </div>

        <div class="relative text-center">
           <div class="space-y-4 mb-8">
            <h1 class="text-4xl font-extrabold tracking-tight sm:text-5xl lg:text-6xl bg-gradient-to-r from-[#f39d8d] to-[#8B4513] bg-clip-text text-transparent">
              Hermann Kekeil GOLO (💻 Hlabs)
            </h1>

            <p class="mx-auto max-w-3xl text-xl text-gray-600 dark:text-gray-300 typing-effect">Ingénieur Logiciel & Data Engineer</p>
            <p class="text-xl text-gray-700 dark:text-gray-300 max-w-3xl mx-auto leading-relaxed">
              Expert en développement d'applications web performantes avec <span class="font-semibold text-indigo-600 dark:text-indigo-400">Elixir & Phoenix</span>,
              et en solutions data-driven avec <span class="font-semibold text-purple-600 dark:text-purple-400">Python & Flutter</span>.
            </p>
          </div>

          <div class="flex justify-center gap-6">
            <.link
              navigate={~p"/projects"}
              class="px-8 py-4 tracking-tight bg-gradient-to-r from-[#f39d8d] to-[#8B4513] text-white rounded-xl hover:from-[#f39d8d]/50 hover:to-[#8B4513]/70 transform hover:scale-110 transition duration-200 shadow-lg hover:shadow-xl"
            >
              <div class="flex items-center gap-2">
                <.icon name="hero-rocket-launch" class="w-5 h-5" /> <span>Voir mes projets</span>
              </div>
            </.link>

            <.link
              navigate={~p"/contact"}
              class="px-8 py-4 bg-white dark:bg-gray-800 text-gray-800 dark:text-white rounded-xl hover:bg-gray-50 dark:hover:bg-gray-700 transform hover:scale-110 transition duration-200 shadow-lg hover:shadow-xl border border-gray-200 dark:border-gray-700"
            >
              <div class="flex items-center gap-2">
                <.icon name="hero-envelope" class="w-5 h-5" /> <span>Me contacter</span>
              </div>
            </.link>
          </div>
        </div>
      </section>

      <!-- Technologies Section -->
      <section class="py-20 bg-gradient-to-b from-transparent via-indigo-50/50 to-transparent dark:from-transparent dark:via-gray-800/50 dark:to-transparent">
        <div class="max-w-7xl mx-auto">
          <h2 class="text-3xl font-bold mb-2 text-center bg-gradient-to-r from-indigo-600 to-purple-600 dark:from-indigo-400 dark:to-purple-400 text-transparent bg-clip-text">
            Technologies & Expertise
          </h2>

          <p class="text-center text-gray-600 dark:text-gray-400 mb-12">
            Un ensemble diversifié de technologies modernes pour des solutions performantes
          </p>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-8">

            <div class="group hover:scale-110 transition-transform duration-300">
              <div class="card-soft bg-white dark:bg-gray-800 relative overflow-hidden">
                <div class="absolute inset-0 bg-gradient-to-br from-indigo-600/5 to-purple-600/5 dark:from-indigo-600/10 dark:to-purple-600/10">
                </div>

                <div class="relative p-6">
                  <div class="flex items-center gap-3 mb-6">
                    <div class="p-2 bg-indigo-100 dark:bg-indigo-900/50 rounded-lg">
                      <.icon name="hero-server" class="w-6 h-6 text-indigo-600 dark:text-indigo-400" />
                    </div>

                    <h3 class="text-xl font-semibold text-indigo-600 dark:text-indigo-400">
                      Backend
                    </h3>
                  </div>

                  <ul class="space-y-3 text-gray-600 dark:text-gray-300">
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
                      Elixir & Phoenix LiveView
                    </li>

                    <li class="flex items-center gap-2">
                      <.icon name="hero-check-circle" class="w-5 h-5 text-green-500" />
                      PostgreSQL & MongoDB
                    </li>
                  </ul>
                </div>
              </div>
            </div>

            <div class="group hover:scale-110 transition-transform duration-300">
              <div class="card-soft bg-white dark:bg-gray-800 relative overflow-hidden">
                <div class="absolute inset-0 bg-gradient-to-br from-purple-600/5 to-pink-600/5 dark:from-purple-600/10 dark:to-pink-600/10">
                </div>

                <div class="relative p-6">
                  <div class="flex items-center gap-3 mb-6">
                    <div class="p-2 bg-purple-100 dark:bg-purple-900/50 rounded-lg">
                      <.icon
                        name="hero-computer-desktop"
                        class="w-6 h-6 text-purple-600 dark:text-purple-400"
                      />
                    </div>

                    <h3 class="text-xl font-semibold text-purple-600 dark:text-purple-400">
                      Frontend
                    </h3>
                  </div>

                  <ul class="space-y-3 text-gray-600 dark:text-gray-300">
                    <li class="flex items-center gap-2">
                      <.icon name="hero-check-circle" class="w-5 h-5 text-green-500" /> Angular & Vue.js
                    </li>

                    <li class="flex items-center gap-2">
                      <.icon name="hero-check-circle" class="w-5 h-5 text-green-500" /> Flutter & Dart
                    </li>
                    <li class="flex items-center gap-2">
                      <.icon name="hero-check-circle" class="w-5 h-5 text-green-500" />
                      TailwindCSS & Alpine.js
                    </li>

                    <li class="flex items-center gap-2">
                      <.icon name="hero-check-circle" class="w-5 h-5 text-green-500" /> HTML5 & CSS3
                    </li>
                  </ul>
                </div>
              </div>
            </div>

            <div class="group hover:scale-110 transition-transform duration-300">
              <div class="card-soft bg-white dark:bg-gray-800 relative overflow-hidden">
                <div class="absolute inset-0 bg-gradient-to-br from-pink-600/5 to-rose-600/5 dark:from-pink-600/10 dark:to-rose-600/10">
                </div>

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

    <!-- Projets en vedette -->
      <section class="py-12">
        <div class="text-center mb-12">
          <h2 class="text-3xl font-bold tracking-tight text-gray-900 dark:text-white sm:text-4xl">
            Projets en vedette
          </h2>

          <p class="mt-3 max-w-2xl mx-auto text-xl text-gray-500 dark:text-gray-400 sm:mt-4">
            Découvrez une sélection de mes projets les plus significatifs
          </p>
        </div>

        <div class="mt-12 grid grid-cols-2 gap-8 lg:grid-cols-3 lg:gap-x-8 lg:gap-y-12">
          <%= for project <- @featured_projects do %>
            <div class="group relative bg-white dark:bg-gray-800 rounded-2xl shadow-lg overflow-hidden hover:scale-110 hover:shadow-xl transition-all duration-300">
              <div class="relative aspect-[4/3] bg-gray-200 dark:bg-gray-700">
                <%= if project["logo_url"] && project["logo_url"] !="" do %>
                  <img
                    src={project["logo_url"]}
                    alt={project["title"]}
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
                  {project["title"]}
                </h3>

                <p class="text-gray-600 dark:text-gray-400 line-clamp-3 mb-4">
                  {project["desc"]}
                </p>

                <div class="flex flex-wrap gap-2 mb-4">
                  <%= for tech <- project["techs"] || [] do %>
                    <span class="px-2 py-1 text-xs bg-indigo-100 text-indigo-700 dark:bg-indigo-900/50 dark:text-indigo-300 rounded">
                      {tech}
                    </span>
                  <% end %>
                </div>

                <div class="flex justify-between items-center">
                  <div class="flex items-center space-x-2 text-sm text-gray-600 dark:text-gray-400">
                    <.icon name="hero-eye" class="w-4 h-4" /> <span>{project["stats"]["views"]}</span>
                    <button
                      type="button"
                      phx-click={JS.push("like_project", value: %{id: project["id"]})}
                      class="ml-2 flex items-center hover:text-[#f39d8d] dark:hover:text-[#f39d8d] transition-colors duration-200"
                    >
                      <.icon name="hero-heart" class="w-4 h-4" />
                      <span class="ml-1">{project["stats"]["likes"]}</span>
                    </button>
                  </div>

                  <.link
                    navigate={~p"/projects"}
                    class="text-indigo-600 hover:text-indigo-700 dark:text-indigo-400 dark:hover:text-indigo-300"
                  >
                    Voir les détails →
                  </.link>
                </div>
              </div>
            </div>
          <% end %>
        </div>

        <div class="mt-12 text-center">
          <.link
            navigate={~p"/about"}
            class="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-white bg-[#f39d8d] hover:bg-[#8B4513] dark:bg-[#8B4513] dark:hover:bg-[#f39d8d] transition-colors duration-200"
          >
            A propos de Hermann <.icon name="hero-arrow-right" class="ml-2 w-5 h-5" />
          </.link>
        </div>
      </section>
    </div>
    """
  end

  @impl true
  def handle_event("like_project", %{"id" => id}, socket) do
    Projects.increment_like(id)

    featured_projects =
      Projects.list_projects()
      |> Enum.filter(& &1["featured"])
      |> Enum.take(3)

    {:noreply, assign(socket, featured_projects: featured_projects)}
  end
end
