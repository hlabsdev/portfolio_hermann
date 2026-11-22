defmodule PortfolioHermannWeb.HomeLive do
  use PortfolioHermannWeb, :live_view

  alias PortfolioHermann.Projects
  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, _session, socket) do
    portfolio = Projects.list_experiences()
    profile = if is_map(portfolio["profile"]), do: portfolio["profile"], else: %{}

    # `list_projects/0` est servi depuis le cache `:persistent_term` : pas de
    # relecture ni de redécodage JSON entre le rendu statique et le mount LiveView.
    featured_projects =
      Projects.list_projects()
      |> Enum.filter(&(is_map(&1) and &1["featured"]))
      |> Enum.sort_by(&{&1["featured_priority"] || 0, &1["year"] || 0}, :desc)
      |> Enum.take(3)

    {:ok,
     socket
     |> assign(:page_title, "Ingénieur logiciel, DevOps et Lead Developer")
     |> assign(:profile, profile)
     |> assign(:featured_projects, featured_projects)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <section class="relative overflow-hidden bg-slate-950 text-white">
        <div class="absolute -right-24 -top-40 h-[34rem] w-[34rem] rounded-full bg-orange-500/10 blur-3xl">
        </div>
        <div class="relative mx-auto grid max-w-7xl gap-16 px-5 py-24 sm:px-8 sm:py-32 lg:grid-cols-[1fr_0.62fr] lg:items-center lg:py-36">
          <div>
            <p class="mb-6 flex items-center gap-3 text-xs font-semibold uppercase tracking-[0.24em] text-orange-300">
              <span class="h-px w-9 bg-orange-400"></span>{@profile["headline"] ||
                "Ingénieur logiciel · DevOps · Lead Developer"}
            </p>
            <h1 class="max-w-4xl text-5xl font-semibold leading-[1.03] tracking-tight sm:text-7xl">
              Je fais avancer le logiciel, de l’idée jusqu’à la production.
            </h1>
            <p class="mt-8 max-w-2xl text-lg leading-8 text-slate-300 sm:text-xl">
              Je conçois des applications web et mobiles, je pilote leur livraison et je veille à leur fonctionnement en production. J’interviens aussi sur la donnée et l’IA appliquée.
            </p>
            <div class="mt-10 flex flex-wrap gap-3">
              <.link
                navigate={~p"/projects"}
                class="rounded-lg bg-orange-400 px-5 py-3 text-sm font-semibold text-slate-950 transition hover:bg-orange-300"
              >Parcourir les projets <.icon name="hero-arrow-up-right" class="ml-2 inline h-4 w-4" /></.link>
              <.link
                navigate={~p"/contact"}
                class="rounded-lg border border-white/20 px-5 py-3 text-sm font-semibold text-white transition hover:bg-white/10"
              >Parler d’un projet</.link>
            </div>
            <div class="mt-12 flex flex-wrap items-center gap-x-6 gap-y-2 text-sm text-slate-400">
              <span class="inline-flex items-center gap-2"><span class="h-2 w-2 rounded-full bg-emerald-400"></span>Basé à Lomé, Togo</span>
              <a
                href={@profile["linkedin"] || "https://www.linkedin.com/in/komi-golo"}
                target="_blank"
                rel="noopener noreferrer"
                class="transition hover:text-white"
              >LinkedIn <.icon name="hero-arrow-up-right" class="ml-1 inline h-3.5 w-3.5" /></a>
              <a
                href={@profile["github"] || "https://github.com/hlabsdev"}
                target="_blank"
                rel="noopener noreferrer"
                class="transition hover:text-white"
              >GitHub <.icon name="hero-arrow-up-right" class="ml-1 inline h-3.5 w-3.5" /></a>
            </div>
          </div>

          <div class="relative">
            <div class="absolute -inset-4 rounded-[2rem] border border-white/10"></div>
            <div class="relative rounded-2xl border border-white/10 bg-white/[0.04] p-7 backdrop-blur sm:p-9">
              <div class="flex items-center justify-between border-b border-white/10 pb-5">
                <span class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">En pratique</span><span class="font-mono text-xs text-orange-300">01 / 03</span>
              </div>
              <div class="space-y-7 py-7">
                <div class="flex gap-4">
                  <span class="font-mono text-sm text-orange-300">01</span><div>
                    <h2 class="font-semibold">Construire</h2><p class="mt-1 text-sm leading-6 text-slate-400">
                      Backend, interfaces et applications mobiles adaptées au besoin.
                    </p>
                  </div>
                </div>
                <div class="flex gap-4">
                  <span class="font-mono text-sm text-orange-300">02</span><div>
                    <h2 class="font-semibold">Mettre en production</h2><p class="mt-1 text-sm leading-6 text-slate-400">
                      Automatisation des livraisons, conteneurs et environnements fiables.
                    </p>
                  </div>
                </div>
                <div class="flex gap-4">
                  <span class="font-mono text-sm text-orange-300">03</span><div>
                    <h2 class="font-semibold">Faire évoluer</h2><p class="mt-1 text-sm leading-6 text-slate-400">
                      Supervision, amélioration continue et coordination avec les équipes produit.
                    </p>
                  </div>
                </div>
              </div>
              <div class="grid grid-cols-2 gap-3 border-t border-white/10 pt-5">
                <div>
                  <p class="text-2xl font-semibold">6+</p><p class="mt-1 text-xs text-slate-400">
                    ans en ingénierie logicielle
                  </p>
                </div>
                <div>
                  <p class="text-2xl font-semibold">4+</p><p class="mt-1 text-xs text-slate-400">
                    ans de livraison en production
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section class="mx-auto max-w-7xl px-5 py-20 sm:px-8 sm:py-28">
        <div class="grid gap-8 border-b border-slate-200 pb-14 dark:border-slate-800 lg:grid-cols-[0.7fr_1.3fr]">
          <p class="text-xs font-semibold uppercase tracking-[0.22em] text-orange-700">
            Collaborations
          </p>
          <div>
            <p class="text-lg leading-8 text-slate-700 dark:text-slate-200">
              J’ai contribué à des produits numériques pour des organisations internationales, des institutions publiques et des acteurs de l’assurance.
            </p><div class="mt-6 flex flex-wrap gap-x-8 gap-y-3 text-sm font-semibold tracking-wide text-slate-500 dark:text-slate-400">
              <span>OIF</span><span>Sanlam Allianz</span><span>DSNISI Togo</span><span>Assemblée nationale du Togo</span><span>ANPE Togo</span>
            </div>
          </div>
        </div>

        <div class="mt-16 flex flex-wrap items-end justify-between gap-6">
          <div>
            <p class="text-xs font-semibold uppercase tracking-[0.22em] text-orange-700">
              Projets sélectionnés
            </p><h2 class="mt-3 text-3xl font-semibold tracking-tight text-slate-950 dark:text-white sm:text-4xl">
              Du concret, en contexte.
            </h2>
          </div>
          <.link
            navigate={~p"/projects"}
            class="text-sm font-semibold text-slate-700 underline decoration-slate-300 underline-offset-4 transition hover:text-orange-700 dark:text-slate-200 dark:decoration-slate-700"
          >Voir tous les projets <.icon name="hero-arrow-right" class="ml-1 inline h-4 w-4" /></.link>
        </div>

        <div class="mt-8 grid gap-4 lg:grid-cols-3">
          <%= for {project, index} <- Enum.with_index(@featured_projects) do %>
            <article class="group flex min-h-[22rem] flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white transition hover:-translate-y-1 hover:shadow-lg dark:border-slate-800 dark:bg-slate-900">
              <div class={"relative flex h-40 items-end overflow-hidden p-6 #{if rem(index, 2) == 0, do: "bg-slate-100 dark:bg-slate-800", else: "bg-orange-50 dark:bg-orange-950/30"}"}>
                <span class="absolute -right-3 -top-12 select-none font-mono text-[10rem] font-semibold leading-none text-slate-200/70 dark:text-white/[0.04]">0{index +
                  1}</span>
                <%= if is_binary(project["logo_url"]) and project["logo_url"] != "" do %>
                  <img
                    src={project["logo_url"]}
                    alt={project["title"]}
                    class="absolute inset-0 h-full w-full object-cover"
                    loading="lazy"
                  />
                <% else %>
                  <span class="relative font-mono text-xs uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">{project[
                    "type"
                  ]}{if project["year"], do: " · #{project["year"]}"}</span>
                <% end %>
              </div>
              <div class="flex flex-1 flex-col p-6">
                <h3 class="text-xl font-semibold text-slate-950 dark:text-white">
                  {project["title"]}
                </h3>
                <p class="mt-3 flex-1 text-sm leading-6 text-slate-600 dark:text-slate-300">
                  {project["desc"]}
                </p>
                <div class="mt-5 flex flex-wrap gap-2">
                  <%= for tech <- Enum.take(project["techs"] || [], 4) do %>
                    <span class="rounded-md bg-slate-100 px-2 py-1 text-xs font-medium text-slate-600 dark:bg-slate-800 dark:text-slate-300">{tech}</span>
                  <% end %>
                </div>
                <div class="mt-6 flex items-center justify-between border-t border-slate-100 pt-4 dark:border-slate-800">
                  <span class="text-xs text-slate-500">{project["client"] || project["type"]}</span><button
                    type="button"
                    phx-click={JS.push("like_project", value: %{id: project["id"]})}
                    class="inline-flex items-center gap-1.5 text-xs font-medium text-slate-500 transition hover:text-orange-700"
                  ><.icon name="hero-heart" class="h-4 w-4" />{get_in(project, ["stats", "likes"]) ||
                    0}</button>
                </div>
              </div>
            </article>
          <% end %>
        </div>
      </section>

      <section class="bg-orange-50 dark:bg-orange-950/20">
        <div class="mx-auto grid max-w-7xl gap-8 px-5 py-16 sm:px-8 lg:grid-cols-[1fr_auto] lg:items-center lg:py-20">
          <div>
            <p class="text-xs font-semibold uppercase tracking-[0.22em] text-orange-800 dark:text-orange-300">
              Pour la suite
            </p><h2 class="mt-3 max-w-3xl text-3xl font-semibold tracking-tight text-slate-950 dark:text-white sm:text-4xl">
              Un projet à concevoir, livrer ou stabiliser ?
            </h2><p class="mt-4 max-w-2xl text-base leading-7 text-slate-600 dark:text-slate-300">
              Échangeons sur le contexte, les objectifs et l’équipe avec laquelle le faire avancer.
            </p>
          </div>
          <.link
            navigate={~p"/contact"}
            class="inline-flex items-center justify-center rounded-lg bg-slate-950 px-5 py-3 text-sm font-semibold text-white transition hover:bg-slate-800 dark:bg-white dark:text-slate-950"
          >Me contacter <.icon name="hero-arrow-right" class="ml-2 h-4 w-4" /></.link>
        </div>
      </section>
    </div>
    """
  end

  @impl true
  def handle_event("like_project", %{"id" => id}, socket) do
    Projects.increment_like(id)
    projects = Projects.list_projects()
    ids = MapSet.new(Enum.map(socket.assigns.featured_projects, & &1["id"]))
    featured = Enum.filter(projects, &MapSet.member?(ids, &1["id"]))
    {:noreply, assign(socket, :featured_projects, featured)}
  end
end
