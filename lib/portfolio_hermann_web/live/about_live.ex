defmodule PortfolioHermannWeb.AboutLive do
  use PortfolioHermannWeb, :live_view

  alias PortfolioHermann.Projects
  import PortfolioHermannWeb.Components.Timeline

  @impl true
  def mount(_params, _session, socket) do
    # Une seule lecture du fichier experiences.json (mise en cache dans
    # Projects) pour tous les blocs de la page.
    data = Projects.list_experiences()

    {:ok,
     socket
     |> assign(:page_title, "À propos")
     |> assign(:profile, map_field(data, "profile"))
     |> assign(:experiences, list_field(data, "workExperiences"))
     |> assign(:education, list_field(data, "education"))
     |> assign(:skills, map_field(data, "skills"))
     |> assign(:certifications, list_field(data, "certifications"))
     |> assign(:languages, list_field(data, "languages"))
     |> assign(:interests, list_field(data, "interests"))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-6xl px-5 py-16 sm:px-8 lg:py-24">
      <section class="grid gap-12 lg:grid-cols-[1.3fr_0.7fr] lg:items-end">
        <div>
          <p class="mb-4 text-xs font-semibold uppercase tracking-[0.24em] text-orange-700">Profil</p>
          <h1 class="max-w-3xl text-4xl font-semibold leading-tight tracking-tight text-slate-950 dark:text-white sm:text-6xl">
            Logiciel, exploitation et produit : du premier commit à la production.
          </h1>
          <p class="mt-7 max-w-2xl text-lg leading-8 text-slate-600 dark:text-slate-300">
            {@profile["summary"]}
          </p>
          <div class="mt-8 flex flex-wrap gap-3">
            <.link
              navigate={~p"/projects"}
              class="rounded-lg bg-slate-950 px-5 py-3 text-sm font-semibold text-white hover:bg-slate-800 dark:bg-white dark:text-slate-950"
            >Voir les projets</.link>
            <.link
              navigate={~p"/contact"}
              class="rounded-lg border border-slate-300 px-5 py-3 text-sm font-semibold text-slate-800 hover:bg-white dark:border-slate-700 dark:text-slate-100 dark:hover:bg-slate-900"
            >Me contacter</.link>
          </div>
        </div>
        <div class="grid grid-cols-2 gap-3">
          <div class="rounded-2xl bg-slate-950 p-5 text-white dark:bg-slate-800">
            <p class="text-3xl font-semibold">6+</p><p class="mt-2 text-sm text-slate-300">
              ans en ingénierie logicielle
            </p>
          </div>
          <div class="rounded-2xl bg-orange-50 p-5 text-slate-950 dark:bg-orange-950/40 dark:text-white">
            <p class="text-3xl font-semibold">4+</p><p class="mt-2 text-sm text-slate-600 dark:text-slate-300">
              ans de déploiements en production
            </p>
          </div>
          <div class="col-span-2 rounded-2xl border border-slate-200 bg-white p-5 dark:border-slate-800 dark:bg-slate-900">
            <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">Domaines</p><p class="mt-2 text-sm leading-6 text-slate-700 dark:text-slate-200">
              Logiciel · DevOps · IA appliquée · santé numérique · services publics · fintech
            </p>
          </div>
        </div>
      </section>

      <section class="mt-24 grid gap-8 lg:grid-cols-[0.7fr_1.3fr]">
        <div>
          <p class="text-xs font-semibold uppercase tracking-[0.2em] text-orange-700">Expérience</p><h2 class="mt-3 text-3xl font-semibold tracking-tight text-slate-950 dark:text-white">
            Livrer. Exploiter. Améliorer.
          </h2><p class="mt-4 text-sm leading-6 text-slate-600 dark:text-slate-300">
            Je travaille aussi bien sur l’architecture et le code que sur les mises en production, le suivi opérationnel et la coordination des équipes.
          </p>
        </div>
        <div class="rounded-2xl border border-slate-200 bg-white p-6 dark:border-slate-800 dark:bg-slate-900 sm:p-8">
          <.timeline experiences={@experiences} />
        </div>
      </section>

      <section class="mt-24">
        <div class="max-w-2xl">
          <p class="text-xs font-semibold uppercase tracking-[0.2em] text-orange-700">Compétences</p><h2 class="mt-3 text-3xl font-semibold tracking-tight text-slate-950 dark:text-white">
            Un profil transversal, ancré dans la pratique.
          </h2>
        </div>
        <div class="mt-8 grid gap-4 md:grid-cols-2">
          <%= for {key, title, icon} <- [{"programming", "Développement", "hero-code-bracket"}, {"databases", "Données", "hero-circle-stack"}, {"cloud", "DevOps et plateformes", "hero-cloud"}, {"methodologies", "Produit et delivery", "hero-clipboard-document-check"}] do %>
            <article class="rounded-2xl border border-slate-200 bg-white p-6 dark:border-slate-800 dark:bg-slate-900">
              <div class="flex items-center gap-3">
                <.icon name={icon} class="h-5 w-5 text-orange-700" /><h3 class="font-semibold text-slate-950 dark:text-white">
                  {title}
                </h3>
              </div>
              <div class="mt-4 flex flex-wrap gap-2">
                <%= for skill <- @skills[key] || [] do %>
                  <span class="rounded-md bg-slate-100 px-2.5 py-1.5 text-xs font-medium text-slate-700 dark:bg-slate-800 dark:text-slate-200">{skill}</span>
                <% end %>
              </div>
            </article>
          <% end %>
        </div>
      </section>

      <section class="mt-24 grid gap-8 lg:grid-cols-2">
        <div>
          <p class="text-xs font-semibold uppercase tracking-[0.2em] text-orange-700">Formation</p><h2 class="mt-3 text-3xl font-semibold tracking-tight text-slate-950 dark:text-white">
            Des bases solides en génie logiciel.
          </h2>
          <div class="mt-6 space-y-3">
            <%= for item <- @education do %>
              <article class="rounded-xl border border-slate-200 bg-white p-5 dark:border-slate-800 dark:bg-slate-900">
                <div class="flex justify-between gap-4">
                  <h3 class="font-semibold text-slate-950 dark:text-white">{item["degree"]}</h3><span class="shrink-0 text-sm text-slate-500">{item[
                    "period"
                  ]}</span>
                </div><p class="mt-1 text-sm text-slate-600 dark:text-slate-300">
                  {item["school"]} · {item["location"]}
                </p>
              </article>
            <% end %>
          </div>
        </div>
        <div>
          <p class="text-xs font-semibold uppercase tracking-[0.2em] text-orange-700">
            Certifications et langues
          </p><h2 class="mt-3 text-3xl font-semibold tracking-tight text-slate-950 dark:text-white">
            Apprendre en continu.
          </h2>
          <div class="mt-6 space-y-3">
            <%= for cert <- @certifications do %>
              <article class="flex justify-between gap-4 rounded-xl border border-slate-200 bg-white p-4 dark:border-slate-800 dark:bg-slate-900">
                <div>
                  <h3 class="text-sm font-semibold text-slate-950 dark:text-white">{cert["name"]}</h3><p class="mt-1 text-xs text-slate-500">
                    {cert["issuer"]}
                  </p>
                </div><span class="shrink-0 text-sm text-slate-500">{cert["year"]}</span>
              </article>
            <% end %>
          </div>
          <div class="mt-5 flex flex-wrap gap-2">
            <%= for lang <- @languages do %>
              <span class="rounded-md bg-orange-50 px-3 py-2 text-sm text-slate-700 dark:bg-orange-950/40 dark:text-slate-100"><strong>{lang[
                "name"
              ]}</strong>
              · {lang["level"]}</span>
            <% end %>
          </div>
        </div>
      </section>

      <section class="mt-24 border-t border-slate-200 pt-8 dark:border-slate-800">
        <p class="text-xs font-semibold uppercase tracking-[0.2em] text-orange-700">
          En dehors du travail
        </p><div class="mt-4 flex flex-wrap gap-2">
          <%= for interest <- @interests do %>
            <span class="rounded-full border border-slate-300 px-3 py-2 text-sm text-slate-600 dark:border-slate-700 dark:text-slate-300">{interest}</span>
          <% end %>
        </div>
      </section>
    </div>
    """
  end

  # Tolérance aux données partielles : la page ne crashe pas si un champ
  # manque ou a un type inattendu dans experiences.json.
  defp map_field(data, field) when is_map(data) do
    case Map.get(data, field) do
      value when is_map(value) -> value
      _ -> %{}
    end
  end

  defp list_field(data, field) when is_map(data) do
    case Map.get(data, field) do
      value when is_list(value) -> value
      _ -> []
    end
  end
end
