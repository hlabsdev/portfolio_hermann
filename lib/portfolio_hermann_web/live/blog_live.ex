defmodule PortfolioHermannWeb.BlogLive do
  use PortfolioHermannWeb, :live_view

  alias PortfolioHermann.Articles

  @impl true
  def mount(params, _session, socket) do
    case params["slug"] && Articles.get_by_slug(params["slug"]) do
      %{"published" => true} = article ->
        {:ok,
         socket
         |> assign(:page_title, article["title"])
         |> assign(:article, article)
         |> assign(:article_html, MDEx.to_html!(article["body"] || ""))
         |> assign(:articles, [])}

      nil ->
        {:ok,
         socket
         |> assign(:page_title, "Articles")
         |> assign(:article, nil)
         |> assign(:article_html, nil)
         |> assign(:articles, Articles.list_published())}

      _draft_or_missing ->
        {:ok,
         socket
         |> assign(:page_title, "Article introuvable")
         |> assign(:article, nil)
         |> assign(:article_html, nil)
         |> assign(:articles, [])
         |> put_flash(:error, "Cet article n’existe pas ou n’est pas encore publié.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="mx-auto max-w-6xl px-5 py-16 sm:px-8 lg:py-24">
      <%= if @article do %>
        <article class="mx-auto max-w-3xl">
          <.link href={~p"/blog"} class="text-sm font-semibold text-orange-800 hover:text-orange-600 dark:text-orange-300">← Tous les articles</.link>
          <%= if @article["cover_url"] do %>
            <img src={@article["cover_url"]} alt="" class="mt-8 max-h-[28rem] w-full rounded-2xl object-cover" />
          <% end %>
          <header class="mt-8 border-b border-slate-200 pb-8 dark:border-slate-800">
            <div class="flex flex-wrap items-center gap-x-4 gap-y-2 text-xs text-slate-500">
              <time datetime={@article["published_at"]}><%= format_date(@article["published_at"]) %></time>
              <span><%= Articles.reading_time(@article["body"] || "") %> min de lecture</span>
            </div>
            <h1 class="mt-4 text-4xl font-semibold leading-tight tracking-tight text-slate-950 dark:text-white sm:text-5xl"><%= @article["title"] %></h1>
            <p class="mt-5 text-lg leading-8 text-slate-600 dark:text-slate-300"><%= @article["summary"] %></p>
            <div class="mt-5 flex flex-wrap gap-2"><%= for tag <- @article["tags"] || [] do %><span class="rounded-full bg-orange-50 px-3 py-1 text-xs font-medium text-orange-900 dark:bg-orange-950/40 dark:text-orange-200"><%= tag %></span><% end %></div>
          </header>
          <div class="prose prose-slate mt-10 max-w-none dark:prose-invert prose-headings:tracking-tight prose-a:text-orange-800 dark:prose-a:text-orange-300 prose-pre:rounded-xl"><%= Phoenix.HTML.raw(@article_html) %></div>
          <footer class="mt-14 border-t border-slate-200 pt-7 dark:border-slate-800"><.link href={~p"/contact"} class="font-semibold text-orange-800 hover:text-orange-600 dark:text-orange-300">Une question ou une idée ? Parlons-en →</.link></footer>
        </article>
      <% else %>
        <section>
          <div class="max-w-3xl">
            <p class="text-xs font-semibold uppercase tracking-[0.22em] text-orange-700">Notes et retours d’expérience</p>
            <h1 class="mt-3 text-4xl font-semibold tracking-tight text-slate-950 dark:text-white sm:text-6xl">Articles</h1>
            <p class="mt-5 text-lg leading-8 text-slate-600 dark:text-slate-300">Développement logiciel, DevOps, données, produit et enseignements tirés des projets.</p>
          </div>

          <%= if Enum.empty?(@articles) do %>
            <div class="mt-12 rounded-2xl border border-dashed border-slate-300 bg-white/70 px-6 py-12 text-center dark:border-slate-700 dark:bg-slate-900/50">
              <p class="text-lg font-semibold text-slate-900 dark:text-white">Les premiers articles arrivent bientôt.</p>
              <p class="mt-2 text-sm text-slate-600 dark:text-slate-300">En attendant, découvre les projets et les sujets sur lesquels je travaille.</p>
              <.link href={~p"/projects"} class="mt-5 inline-flex rounded-lg bg-slate-950 px-4 py-2.5 text-sm font-semibold text-white dark:bg-white dark:text-slate-950">Voir les projets</.link>
            </div>
          <% else %>
            <div class="mt-12 grid gap-5 md:grid-cols-2">
              <%= for article <- @articles do %>
                <article class="group overflow-hidden rounded-2xl border border-slate-200 bg-white transition hover:-translate-y-1 hover:shadow-lg dark:border-slate-800 dark:bg-slate-900">
                  <%= if article["cover_url"] do %><a href={~p"/blog/#{article["slug"]}"}><img src={article["cover_url"]} alt="" loading="lazy" class="h-52 w-full object-cover" /></a><% end %>
                  <div class="p-6">
                    <div class="flex items-center gap-3 text-xs text-slate-500"><time datetime={article["published_at"]}><%= format_date(article["published_at"]) %></time><span>·</span><span><%= Articles.reading_time(article["body"] || "") %> min</span></div>
                    <h2 class="mt-3 text-2xl font-semibold tracking-tight text-slate-950 group-hover:text-orange-800 dark:text-white dark:group-hover:text-orange-300"><a href={~p"/blog/#{article["slug"]}"}><%= article["title"] %></a></h2>
                    <p class="mt-3 text-sm leading-6 text-slate-600 dark:text-slate-300"><%= article["summary"] %></p>
                    <div class="mt-5 flex flex-wrap gap-2"><%= for tag <- article["tags"] || [] do %><span class="rounded-md bg-slate-100 px-2.5 py-1 text-xs font-medium text-slate-600 dark:bg-slate-800 dark:text-slate-300"><%= tag %></span><% end %></div>
                    <a href={~p"/blog/#{article["slug"]}"} class="mt-6 inline-flex items-center text-sm font-semibold text-orange-800 dark:text-orange-300">Lire l’article <span class="ml-2 transition group-hover:translate-x-1">→</span></a>
                  </div>
                </article>
              <% end %>
            </div>
          <% end %>
        </section>
      <% end %>
    </main>
    """
  end

  defp format_date(nil), do: ""
  defp format_date(value) do
    case Date.from_iso8601(String.slice(value, 0, 10)) do
      {:ok, date} -> Calendar.strftime(date, "%d/%m/%Y")
      _ -> value
    end
  end
end
