defmodule PortfolioHermannWeb.ProjectsLive do
  use PortfolioHermannWeb, :live_view
  import PortfolioHermannWeb.ProjectCard

  def render(assigns) do
    ~H"""
    <section class="max-w-7xl mx-auto py-16 px-6">
      <h1 class="text-4xl font-bold mb-8 text-center">Mes projets</h1>
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        <.project_card
          title="FastSMS"
          tech="Elixir, Phoenix LiveView, API SMS"
          desc="Plateforme de gestion de contacts et d’envoi de SMS programmés avec API dynamique."
        />
        <.project_card
          title="App Flutter de gestion de stock"
          tech="Flutter, ObjectBox, Google Drive"
          desc="Application mobile offline-first avec backup Google Drive, pour commerçants."
        />
        <.project_card
          title="Auto-diagnostic export"
          tech="Django, PDF, Radar Chart"
          desc="Plateforme d’auto-évaluation pour PME avec synthèses en PDF et visualisations."
        />
        <.project_card
          title="OIFPPL"
          tech="Python, Vue.js, PostgreSQL"
          desc="Système de gestion des concours littéraires internationaux de l’OIF."
        />
        <.project_card
          title="SGF Sénégal"
          tech="Angular, Node.js, Figma"
          desc="Système de gestion foncière pour la DGID du Sénégal avec design UX/UI complet."
        />
        <.project_card
          title="Microfinance Pro"
          tech="Laravel, Flutter"
          desc="Plateforme de gestion financière pour institutions de microfinance en Afrique."
        />
      </div>
    </section>
    """
  end
end
