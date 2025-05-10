defmodule PortfolioHermannWeb.AboutLive do
  use PortfolioHermannWeb, :live_view

  def render(assigns) do
    ~H"""
    <section class="max-w-5xl mx-auto py-16 px-6">
      <h1 class="text-4xl font-bold mb-8 text-center">À propos de moi</h1>

      <div class="card-soft text-lg leading-relaxed space-y-4">
        <p>
          Je m'appelle <strong>Hermann GOLO</strong>, ingénieur logiciel passionné par la data science, le développement backend et les systèmes intelligents.
          Avec plus de 5 ans d’expérience, j’ai contribué à des projets pour des institutions internationales comme l’OIF, l’ANPE, ou encore Sanlam Allianz.
        </p>
        <p>
          Mon expertise couvre Python (Django, FastAPI), Elixir (Phoenix, LiveView), Flutter, Vue.js, Angular, et les bases de données relationnelles ou NoSQL.
        </p>
        <p>
          J’ai aussi co-fondé une fintech et conçu des systèmes d’information complets pour des administrations publiques, entreprises privées et startups.
        </p>
        <p>
          En dehors du code, je lis, joue au piano et m’intéresse à tout ce qui touche à la science-fiction, à la spiritualité et à l’innovation technologique.
        </p>
      </div>
    </section>
    """
  end
end
