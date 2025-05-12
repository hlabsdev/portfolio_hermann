defmodule PortfolioHermannWeb.AboutLive do
  use PortfolioHermannWeb, :live_view
  import PortfolioHermannWeb.Components.Timeline
  alias Jason
  alias File

  def mount(_params, _session, socket) do
    experiences =
      "priv/experiences.json"
      |> File.read!()
      |> Jason.decode!()

    # Liste les images dans le dossier me/
    images =
      "priv/static/images/me"
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, [".jpg", ".jpeg", ".png"]))
      |> Enum.sort()
      |> Enum.map(&%{
        path: "/images/me/#{&1}",
        alt: "Hermann GOLO - Photo"
      })

    {:ok,
     assign(socket,
       experiences: experiences,
       images: images,
       selected_image: nil
     )}
  end

  def handle_event("view-image", %{"path" => path}, socket) do
    {:noreply, assign(socket, selected_image: path)}
  end

  def handle_event("close-modal", _, socket) do
    {:noreply, assign(socket, selected_image: nil)}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto py-16 px-6">
      <!-- Section Introduction -->
      <section class="mb-16">
        <h1 class="text-4xl font-bold bg-gradient-to-r from-[#f39d8d] to-[#8B4513] bg-clip-text text-transparent mb-8 text-center">
          À propos de moi
        </h1>

        <!-- Photos de profil -->
        <div class="flex justify-center gap-8 mb-12 grid grid-cols-1 md:grid-cols-2">
          <%= for {image, index} <- Enum.with_index(@images) do %>
            <div class={"relative group transform #{if rem(index, 2) == 0, do: "hover:rotate-2", else: "hover:-rotate-2"} transition-transform duration-300"}>
              <div class={"absolute -inset-1 bg-gradient-to-r #{if rem(index, 2) == 0, do: "from-[#f39d8d] to-[#8B4513]", else: "from-[#8B4513] to-[#f39d8d]"} rounded-2xl blur opacity-25 group-hover:opacity-50 transition duration-1000 group-hover:duration-200"}></div>
              <div class="relative w-48 h-64 rounded-2xl overflow-hidden ring-4 ring-white dark:ring-gray-800 shadow-xl cursor-pointer"
                   phx-click="view-image"
                   phx-value-path={image.path}>
                <img
                  src={image.path}
                  alt={image.alt}
                  class="w-full h-full object-cover transform group-hover:scale-110 transition duration-500"
                />
              </div>
            </div>
          <% end %>
        </div>

        <!-- Modal pour l'affichage de l'image -->
        <%= if @selected_image do %>
          <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
               phx-click="close-modal">
            <div class="relative max-w-4xl max-h-[90vh] mx-4 overflow-hidden"
                 phx-click-away="close-modal">
              <img
                src={@selected_image}
                alt="Image en plein écran"
                class="w-full h-full object-contain rounded-lg"
              />
              <button
                class="absolute top-4 right-4 text-white hover:text-[#f39d8d] transition-colors duration-200"
                phx-click="close-modal"
              >
                <.icon name="hero-x-mark" class="w-8 h-8" />
              </button>
            </div>
          </div>
        <% end %>

        <div class="card-soft text-lg leading-relaxed space-y-6 mb-12">
          <p>
            Je m'appelle <strong class="text-[#8B4513] dark:text-[#f39d8d]">Hermann Komi Kekeli GOLO</strong>, ingénieur logiciel passionné par la data science, le développement backend et les systèmes intelligents.
            Avec plus de 6 ans d'expérience, j'ai contribué à des projets pour des institutions privées comme: Sanlam Allianz; publiques comme: Le ministere de la sante (DSNISI) du Togo, L'assemble nationale Togoalaise, La DGID du Senegal; des institutions internationales comme: l'OIF, l'ANPE, l'UGP.
          </p>

          <p>
            <strong class="text-[#8B4513] dark:text-[#f39d8d]">Mon expertise en developpement</strong>
            couvre Python (Django, FastAPI), Flutter, Angular, Elixir (Phoenix, LiveView) et les bases de données relationnelles ou NoSQL.
            Je suis particulièrement intéressé par l'architecture de solutions cloud-native et les systèmes distribués.
            Je suis également passionné par l'optimisation des performances et la sécurité des applications, et je m'efforce de rester à jour avec les dernières tendances technologiques.
          </p>

          <p>
            <strong class="text-[#8B4513] dark:text-[#f39d8d]">Mon expertise en data science</strong>
            inclut l'analyse de données, le machine learning et l'integration de solution IA dans des projeet externes grace a des APIs.
            J'ai travaillé sur des projets d'analyse prédictive et de traitement du langage naturel.
            Je suis également familiarisé avec les pipelines de données et l'ingénierie des données, ce qui me permet de créer des solutions complètes allant de la collecte de données à l'analyse avancée.
          </p>

          <p>
            Ma passion pour l'innovation technologique me pousse à toujours rester à jour avec les dernières avancées du secteur.
          </p>
        </div>

    <!-- Compétences clés -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-16">

          <div class="card-soft p-6">
            <div class="flex items-center gap-3 mb-4">
              <div class="p-2 bg-indigo-100 dark:bg-indigo-900/50 rounded-lg">
                <.icon
                  name="hero-code-bracket-square"
                  class="w-6 h-6 text-indigo-600 dark:text-indigo-400"
                />
              </div>

              <h3 class="text-xl font-semibold text-indigo-600 dark:text-indigo-400">
                Langages & Frameworks
              </h3>
            </div>

            <div class="grid grid-cols-1 gap-2">
              <%= for skill <- @experiences["skills"]["programming"] do %>
                <div class="flex items-center gap-2">
                  <.icon name="hero-check-circle" class="w-5 h-5 text-green-500 flex-shrink-0" />
                  <span class="text-gray-700 dark:text-gray-300">{skill}</span>
                </div>
              <% end %>
            </div>
          </div>

          <div class="card-soft p-6">
            <div class="flex items-center gap-3 mb-4">
              <div class="p-2 bg-purple-100 dark:bg-purple-900/50 rounded-lg">
                <.icon name="hero-circle-stack" class="w-6 h-6 text-purple-600 dark:text-purple-400" />
              </div>

              <h3 class="text-xl font-semibold text-purple-600 dark:text-purple-400">
                Bases de données
              </h3>
            </div>

            <ul class="space-y-2">
              <%= for skill <- @experiences["skills"]["databases"] do %>
                <li class="flex items-center gap-2">
                  <.icon name="hero-check-circle" class="w-5 h-5 text-green-500 flex-shrink-0" />
                  <span class="text-gray-700 dark:text-gray-300">{skill}</span>
                </li>
              <% end %>
            </ul>
          </div>

          <div class="card-soft p-6">
            <div class="flex items-center gap-3 mb-4">
              <div class="p-2 bg-pink-100 dark:bg-pink-900/50 rounded-lg">
                <.icon name="hero-cloud" class="w-6 h-6 text-pink-600 dark:text-pink-400" />
              </div>

              <h3 class="text-xl font-semibold text-pink-600 dark:text-pink-400">Cloud & DevOps</h3>
            </div>

            <ul class="space-y-2">
              <%= for skill <- @experiences["skills"]["cloud"] do %>
                <li class="flex items-center gap-2">
                  <.icon name="hero-check-circle" class="w-5 h-5 text-green-500 flex-shrink-0" />
                  <span class="text-gray-700 dark:text-gray-300">{skill}</span>
                </li>
              <% end %>
            </ul>
          </div>
        </div>
      </section>

    <!-- Section Parcours -->
      <section class="mb-16">
        <h2 class="text-3xl font-bold text-gray-900 dark:text-white mb-8">Parcours professionnel</h2>

        <div class="relative">
          <div class="absolute left-4 h-full w-0.5 bg-gradient-to-b from-[#f39d8d] to-[#8B4513] dark:from-[#8B4513] dark:to-[#f39d8d]">
          </div>
           <.timeline experiences={@experiences["workExperiences"]} />
        </div>
      </section>

    <!-- Section Éducation -->
      <section class="mb-16">
        <h2 class="text-3xl font-bold text-gray-900 dark:text-white mb-8">Formation</h2>

        <div class="grid grid-cols-1 gap-6">
          <%= for edu <- @experiences["education"] do %>
            <div class="card-soft p-6 relative">
              <div class="flex justify-between items-start mb-4">
                <div>
                  <h3 class="text-xl font-semibold text-[#8B4513] dark:text-[#f39d8d]">
                    {edu["degree"]}
                  </h3>

                  <p class="text-gray-600 dark:text-gray-400">
                    {edu["school"]}, {edu["location"]}
                  </p>
                </div>

                <div class="text-right">
                  <span class="text-gray-500 dark:text-gray-400">{edu["period"]}</span>
                </div>
              </div>

              <p class="text-gray-700 dark:text-gray-300 mb-4">{edu["description"]}</p>

              <ul class="list-disc list-inside space-y-1">
                <%= for achievement <- edu["achievements"] do %>
                  <li class="text-gray-600 dark:text-gray-400">{achievement}</li>
                <% end %>
              </ul>
            </div>
          <% end %>
        </div>
      </section>

    <!-- Section Méthodologies -->
      <section class="mb-16">
        <h2 class="text-3xl font-bold text-gray-900 dark:text-white mb-8">Méthodologies & Pratiques</h2>

        <div class="card-soft p-6">
          <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            <%= for method <- @experiences["skills"]["methodologies"] do %>
              <div class="flex items-center gap-2 p-3 bg-gray-50 dark:bg-gray-800/50 rounded-lg">
                <.icon name="hero-check-circle" class="w-5 h-5 text-green-500 flex-shrink-0" />
                <span class="text-gray-700 dark:text-gray-300">{method}</span>
              </div>
            <% end %>
          </div>
        </div>
      </section>

    <!-- Section Langues -->
      <section class="mb-16">
        <h2 class="text-3xl font-bold text-gray-900 dark:text-white mb-8">Langues</h2>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <%= for lang <- @experiences["languages"] do %>
            <div class="card-soft p-6">
              <h3 class="text-xl font-semibold text-[#8B4513] dark:text-[#f39d8d] mb-2">
                {lang["name"]}
              </h3>

              <p class="text-gray-600 dark:text-gray-400">{lang["level"]}</p>
            </div>
          <% end %>
        </div>
      </section>

    <!-- Section Certifications -->
      <section class="mb-16">
        <h2 class="text-3xl font-bold text-gray-900 dark:text-white mb-8">Certifications</h2>

        <div class="grid grid-cols-1 gap-6">
          <%= for cert <- @experiences["certifications"] do %>
            <div class="card-soft p-6">
              <div class="flex justify-between items-start mb-2">
                <h3 class="text-xl font-semibold text-[#8B4513] dark:text-[#f39d8d]">
                  {cert["name"]}
                </h3>
                 <span class="text-gray-500 dark:text-gray-400">{cert["year"]}</span>
              </div>

              <p class="text-gray-600 dark:text-gray-400">
                {cert["issuer"]}
              </p>
            </div>
          <% end %>
        </div>
      </section>

    <!-- Section Centres d'intérêts -->
      <section>
        <h2 class="text-3xl font-bold text-gray-900 dark:text-white mb-8">Centres d'intérêts</h2>

        <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
          <%= for interest <- @experiences["interests"] do %>
            <div class="card-soft p-2 m-0 text-center items-center">
              <.icon name="hero-sparkles" class="w-66 h- text-[#8B4513] dark:text-[#f39d8d] mb-1" />
              <h3 class="text-md font-semibold text-gray-700 dark:text-gray-300">
                {interest}</h3>
              <%!-- <span class="text-gray-700 dark:text-gray-300">{interest}</span> --%>
            </div>
          <% end %>
        </div>
      </section>
    </div>
    """
  end
end
