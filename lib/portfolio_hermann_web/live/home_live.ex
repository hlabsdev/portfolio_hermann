defmodule PortfolioHermannWeb.HomeLive do
  use PortfolioHermannWeb, :live_view
  alias PortfolioHermann.Projects
  import PortfolioHermannWeb.Components.ProjectCarousel
  import PortfolioHermannWeb.Components.Timeline

  @impl true

  def mount(_params, _session, socket) do
    experiences = [
      {2025, [
        %{title: "Lead Developer", company: "FastSMS", description: "Architecture et développement de la plateforme SMS"},
        %{title: "Consultant Senior", company: "Sanlam Allianz", description: "Transformation digitale et IA"}
      ]},
      {2024, [
        %{title: "Data Scientist", company: "ANPE", description: "Modélisation prédictive et tableaux de bord"},
        %{title: "Tech Lead", company: "OIF", description: "Système de gestion des concours littéraires"}
      ]}
    ]

    socket = socket
    |> assign(:projects, Projects.list_projects())
    |> assign(:current_slide, 0)
    |> assign(:experiences, experiences)

    {:ok, socket}
  end

  def handle_event("next-slide", _, socket) do
    current = socket.assigns.current_slide
    total = length(socket.assigns.projects) - 1
    new_slide = if current >= total, do: 0, else: current + 1
    {:noreply, assign(socket, :current_slide, new_slide)}
  end

  def handle_event("prev-slide", _, socket) do
    current = socket.assigns.current_slide
    total = length(socket.assigns.projects) - 1
    new_slide = if current <= 0, do: total, else: current - 1
    {:noreply, assign(socket, :current_slide, new_slide)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-20">
      <section class="text-center py-20 animate-fadeIn dark:text-white">
        <h1 class="text-5xl font-bold mb-4 animate-slideUp delay-100">Bonjour, je suis Hermann</h1>
        <p class="text-xl max-w-xl mx-auto mb-6 typing-effect">
          Ingénieur Logiciel, Data Scientist & Créateur d'outils intelligents
        </p>
        <div class="flex gap-4 justify-center mt-8">
          <.link navigate={~p"/projects"} class="btn-soft px-6 py-3 text-lg">
            Découvrir mes projets
          </.link>
          <.link navigate={~p"/contact"} class="btn-soft bg-indigo-500/30 hover:bg-indigo-500/50 px-6 py-3 text-lg text-white">
            Me contacter
          </.link>
        </div>
      </section>

      <section class="max-w-4xl mx-auto px-6">
        <h2 class="text-3xl font-bold mb-8 text-center dark:text-white">Projets en vedette</h2>
        <.carousel projects={@projects} current_slide={@current_slide} />
      </section>

      <section class="max-w-2xl mx-auto px-6">
        <h2 class="text-3xl font-bold mb-8 text-center dark:text-white">Mon parcours</h2>
        <.timeline experiences={@experiences} />
      </section>

      <section class="max-w-4xl mx-auto px-6 py-12 card-soft text-center">
        <h2 class="text-3xl font-bold mb-4 dark:text-white">Envie de collaborer ?</h2>
        <p class="text-xl mb-6 dark:text-gray-200">Je suis toujours intéressé par de nouveaux projets passionnants.</p>
        <.link navigate={~p"/contact"} class="btn-soft px-8 py-4 text-lg inline-block">
          Parlons de votre projet
        </.link>
      </section>
    </div>
    """
  end
end
