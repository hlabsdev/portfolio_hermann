defmodule PortfolioHermannWeb.AdminArticlesLive do
  use PortfolioHermannWeb, :live_view

  alias PortfolioHermann.Articles

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Gestion des articles")
     |> assign(:articles, Articles.list())
     |> assign(:editing, nil)}
  end

  @impl true
  def handle_event("new", _params, socket) do
    {:noreply, assign(socket, :editing, %{"status" => "published", "published" => true})}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    case Enum.find(socket.assigns.articles, &(&1["id"] == id)) do
      nil ->
        {:noreply, put_flash(socket, :error, "Article introuvable.")}

      article ->
        {:noreply, assign(socket, :editing, Map.put(article, "status", Articles.status(article)))}
    end
  end

  def handle_event("cancel", _params, socket), do: {:noreply, assign(socket, :editing, nil)}

  def handle_event("save", %{"article" => params}, socket) do
    case Articles.save(article_attrs(params)) do
      {:ok, article} ->
        {:noreply,
         socket
         |> assign(:articles, Articles.list())
         |> assign(:editing, nil)
         |> put_flash(:info, save_message(article))}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:editing, merge_form(socket.assigns.editing, params))
         |> put_flash(:error, save_error(reason))}
    end
  end

  def handle_event("publish_now", %{"id" => id}, socket) do
    case Articles.publish_now(id) do
      {:ok, article} ->
        {:noreply,
         socket
         |> assign(:articles, Articles.list())
         |> close_editor_if_editing(id)
         |> put_flash(:info, "Article « #{article["title"]} » publié immédiatement.")}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Article introuvable.")}

      _ ->
        {:noreply, put_flash(socket, :error, "La publication immédiate a échoué.")}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    case Articles.delete(id) do
      :ok ->
        {:noreply,
         socket
         |> assign(:articles, Articles.list())
         |> put_flash(:info, "Article supprimé.")}

      _ ->
        {:noreply, put_flash(socket, :error, "La suppression a échoué.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="mx-auto max-w-6xl px-5 py-12 sm:px-8">
      <header class="mb-10 flex flex-wrap items-end justify-between gap-5">
        <div>
          <p class="mb-2 text-xs font-semibold uppercase tracking-[0.22em] text-orange-700">
            Administration
          </p>
          <h1 class="text-3xl font-semibold tracking-tight text-slate-950 dark:text-white">
            Articles
          </h1>
          <p class="mt-2 max-w-2xl text-sm leading-6 text-slate-600 dark:text-slate-300">
            Écris en Markdown, enregistre un brouillon, programme une date ou publie immédiatement. Les articles restent sur le volume persistant Fly.
          </p>
        </div>
        <div class="flex flex-wrap gap-3">
          <.link
            href={~p"/blog"}
            class="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
          >Voir le blog</.link>
          <button
            type="button"
            phx-click="new"
            class="rounded-lg bg-slate-950 px-4 py-2 text-sm font-semibold text-white hover:bg-slate-800 dark:bg-white dark:text-slate-950"
          >Nouvel article</button>
        </div>
      </header>

      <div class="space-y-3">
        <%= for article <- @articles do %>
          <% article_status = Articles.status(article) %>
          <article class="flex flex-wrap items-center justify-between gap-4 rounded-2xl border border-slate-200 bg-white p-5 dark:border-slate-800 dark:bg-slate-900">
            <div class="min-w-0 flex-1">
              <div class="flex flex-wrap items-center gap-2">
                <h2 class="truncate text-lg font-semibold text-slate-950 dark:text-white">
                  {article["title"]}
                </h2>
                <span class={status_badge_class(article_status)}>{status_label(article_status)}</span>
              </div>
              <p class="mt-1 truncate text-sm text-slate-500">
                /blog/{article["slug"]} · Modifié le {format_date(article["updated_at"])}
              </p>
              <%= if article_status == "scheduled" do %>
                <p class="mt-1 text-sm font-medium text-amber-700 dark:text-amber-300">
                  Publication programmée le {format_datetime(article["published_at"])}
                </p>
              <% end %>
              <%= if article_status == "published" and article["published_at"] do %>
                <p class="mt-1 text-sm text-emerald-700 dark:text-emerald-300">
                  Publié le {format_datetime(article["published_at"])}
                </p>
              <% end %>
            </div>
            <div class="flex flex-wrap gap-2">
              <%= if article_status == "published" do %>
                <.link
                  href={~p"/blog/#{article["slug"]}"}
                  class="rounded-lg border border-slate-300 px-3 py-2 text-sm font-medium text-slate-700 dark:border-slate-700 dark:text-slate-200"
                >Aperçu</.link>
              <% end %>
              <%= if article_status != "published" do %>
                <button
                  type="button"
                  phx-click="publish_now"
                  phx-value-id={article["id"]}
                  data-confirm="Publier immédiatement cet article ?"
                  class="rounded-lg bg-emerald-600 px-3 py-2 text-sm font-semibold text-white hover:bg-emerald-700"
                >Publier maintenant</button>
              <% end %>
              <button
                type="button"
                phx-click="edit"
                phx-value-id={article["id"]}
                class="rounded-lg border border-slate-300 px-3 py-2 text-sm font-medium text-slate-700 dark:border-slate-700 dark:text-slate-200"
              >Modifier</button>
              <button
                type="button"
                phx-click="delete"
                phx-value-id={article["id"]}
                data-confirm="Supprimer cet article ?"
                class="rounded-lg border border-rose-200 px-3 py-2 text-sm font-medium text-rose-700 dark:border-rose-900 dark:text-rose-300"
              >Supprimer</button>
            </div>
          </article>
        <% end %>
        <%= if Enum.empty?(@articles) do %>
          <div class="rounded-2xl border border-dashed border-slate-300 p-10 text-center text-sm text-slate-500 dark:border-slate-700">
            Aucun article pour l’instant. Crée un brouillon ou publie ton premier article.
          </div>
        <% end %>
      </div>

      <%= if @editing do %>
        <div class="fixed inset-0 z-50 overflow-y-auto bg-slate-950/60 p-3 sm:p-8">
          <section
            class="mx-auto my-5 max-w-5xl rounded-2xl bg-white p-5 shadow-2xl dark:bg-slate-900 sm:p-8"
            phx-click-away="cancel"
          >
            <div class="mb-6 flex items-start justify-between gap-4">
              <div>
                <p class="text-xs font-semibold uppercase tracking-[0.2em] text-orange-700">
                  Éditeur Markdown
                </p><h2 class="mt-2 text-2xl font-semibold text-slate-950 dark:text-white">
                  {if @editing["id"], do: "Modifier l’article", else: "Nouvel article"}
                </h2>
              </div>
              <button
                type="button"
                phx-click="cancel"
                class="rounded-lg px-3 py-2 text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800"
              >Fermer</button>
            </div>
            <.form for={%{}} as={:article} id="article-form" phx-submit="save" class="space-y-5">
              <input type="hidden" name="article[id]" value={@editing["id"]} />
              <div class="grid gap-4 md:grid-cols-2">
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-200">
                  Titre
                  <input
                    name="article[title]"
                    value={@editing["title"]}
                    required
                    class="mt-1 block w-full rounded-lg border-slate-300 bg-white shadow-sm dark:border-slate-700 dark:bg-slate-950"
                  />
                </label>
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-200">
                  Adresse (slug, facultatif)
                  <input
                    name="article[slug]"
                    value={@editing["slug"]}
                    placeholder="généré depuis le titre"
                    class="mt-1 block w-full rounded-lg border-slate-300 bg-white shadow-sm dark:border-slate-700 dark:bg-slate-950"
                  />
                </label>
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-200 md:col-span-2">
                  Résumé <textarea
                    name="article[summary]"
                    rows="2"
                    class="mt-1 block w-full rounded-lg border-slate-300 bg-white shadow-sm dark:border-slate-700 dark:bg-slate-950"
                  ><%= @editing["summary"] %></textarea>
                </label>
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-200">
                  Mots-clés (séparés par des virgules)
                  <input
                    name="article[tags]"
                    value={Enum.join(@editing["tags"] || [], ", ")}
                    class="mt-1 block w-full rounded-lg border-slate-300 bg-white shadow-sm dark:border-slate-700 dark:bg-slate-950"
                  />
                </label>
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-200">
                  Image de couverture (URL facultative)
                  <input
                    name="article[cover_url]"
                    value={@editing["cover_url"]}
                    placeholder="https://… ou /uploads/…"
                    class="mt-1 block w-full rounded-lg border-slate-300 bg-white shadow-sm dark:border-slate-700 dark:bg-slate-950"
                  />
                </label>
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-200">
                  Statut
                  <select
                    name="article[status]"
                    class="mt-1 block w-full rounded-lg border-slate-300 bg-white shadow-sm dark:border-slate-700 dark:bg-slate-950"
                  >
                    <option value="draft" selected={status_value(@editing) == "draft"}>
                      Brouillon
                    </option>
                    <option value="scheduled" selected={status_value(@editing) == "scheduled"}>
                      Programmé
                    </option>
                    <option value="published" selected={status_value(@editing) == "published"}>
                      Publié (maintenant)
                    </option>
                  </select>
                </label>
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-200">
                  Publication programmée (date et heure UTC)
                  <input
                    type="datetime-local"
                    name="article[published_at]"
                    value={datetime_local_value(@editing["published_at"])}
                    class="mt-1 block w-full rounded-lg border-slate-300 bg-white shadow-sm dark:border-slate-700 dark:bg-slate-950"
                  />
                  <span class="mt-1 block text-xs font-normal text-slate-500">Obligatoire pour le statut « Programmé ». Ignorée pour « Publié (maintenant) ».</span>
                </label>
              </div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-200">
                Contenu de l’article (Markdown) <textarea
                  name="article[body]"
                  rows="18"
                  required
                  placeholder="# Un titre\n\nÉcris ton article ici. Utilise **Markdown** pour la mise en forme."
                  class="mt-1 block w-full rounded-lg border-slate-300 bg-white font-mono text-sm leading-6 shadow-sm dark:border-slate-700 dark:bg-slate-950"
                ><%= @editing["body"] %></textarea>
              </label>
              <div class="flex justify-end gap-3 border-t border-slate-200 pt-5 dark:border-slate-800">
                <button
                  type="button"
                  phx-click="cancel"
                  class="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 dark:border-slate-700 dark:text-slate-200"
                >Annuler</button>
                <button
                  type="submit"
                  class="rounded-lg bg-slate-950 px-5 py-2 text-sm font-semibold text-white dark:bg-white dark:text-slate-950"
                >Enregistrer</button>
              </div>
            </.form>
          </section>
        </div>
      <% end %>
    </main>
    """
  end

  defp article_attrs(params) do
    status = normalize_status(params["status"])

    %{
      "id" => blank_to_nil(params["id"]),
      "title" => params["title"],
      "slug" => params["slug"],
      "summary" => params["summary"],
      "body" => params["body"],
      "tags" => parse_csv(params["tags"]),
      "cover_url" => params["cover_url"],
      "status" => status,
      "published_at" =>
        if(status == "scheduled", do: normalize_datetime_input(params["published_at"]), else: nil)
    }
  end

  # Conserve la saisie en cours quand l'enregistrement échoue.
  defp merge_form(editing, params) do
    Map.merge(editing || %{}, %{
      "id" => blank_to_nil(params["id"]),
      "title" => params["title"],
      "slug" => params["slug"],
      "summary" => params["summary"],
      "body" => params["body"],
      "tags" => parse_csv(params["tags"]),
      "cover_url" => params["cover_url"],
      "status" => normalize_status(params["status"]),
      "published_at" => blank_to_nil(params["published_at"])
    })
  end

  defp save_message(article) do
    case Articles.status(article) do
      "draft" -> "Brouillon enregistré."
      "scheduled" -> "Article programmé pour le #{format_datetime(article["published_at"])}."
      _ -> "Article publié."
    end
  end

  defp save_error(:title_required), do: "Le titre est obligatoire."
  defp save_error(:body_required), do: "Le contenu Markdown est obligatoire."
  defp save_error(:slug_taken), do: "Cette adresse existe déjà. Choisis un autre slug."

  defp save_error(:published_at_required),
    do: "Choisis une date de publication pour un article programmé."

  defp save_error(:published_at_in_past),
    do: "La date de publication programmée doit être dans le futur."

  defp save_error(:published_at_invalid), do: "La date de publication est invalide."
  defp save_error(_reason), do: "L’enregistrement a échoué."

  defp close_editor_if_editing(%{assigns: %{editing: %{"id" => id}}} = socket, id),
    do: assign(socket, :editing, nil)

  defp close_editor_if_editing(socket, _id), do: socket

  defp status_value(editing) do
    case editing["status"] do
      status when status in ["draft", "scheduled", "published"] -> status
      _ -> if(editing["published"] == false, do: "draft", else: Articles.status(editing))
    end
  end

  defp normalize_status(status) when status in ["draft", "scheduled", "published"], do: status
  defp normalize_status(_status), do: "draft"

  defp normalize_datetime_input(nil), do: nil

  defp normalize_datetime_input(value) when is_binary(value) do
    case String.trim(value) do
      "" ->
        nil

      trimmed ->
        cond do
          Regex.match?(~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/, trimmed) -> trimmed <> ":00Z"
          Regex.match?(~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/, trimmed) -> trimmed <> "Z"
          true -> trimmed
        end
    end
  end

  defp parse_csv(nil), do: []

  defp parse_csv(text),
    do: text |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(value), do: if(String.trim(value) == "", do: nil, else: String.trim(value))

  defp datetime_local_value(nil), do: ""

  defp datetime_local_value(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> Calendar.strftime(datetime, "%Y-%m-%dT%H:%M")
      _ -> String.slice(value, 0, 16)
    end
  end

  defp format_date(nil), do: "—"
  defp format_date(value), do: String.slice(value, 0, 10)

  defp format_datetime(nil), do: "—"

  defp format_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> Calendar.strftime(datetime, "%d/%m/%Y à %H:%M UTC")
      _ -> format_date(value)
    end
  end

  defp status_badge_class("published"),
    do:
      "rounded-full bg-emerald-100 px-2.5 py-1 text-xs font-medium text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300"

  defp status_badge_class(_status),
    do:
      "rounded-full bg-amber-100 px-2.5 py-1 text-xs font-medium text-amber-800 dark:bg-amber-950 dark:text-amber-300"

  defp status_label("draft"), do: "Brouillon"
  defp status_label("scheduled"), do: "Programmé"
  defp status_label(_), do: "Publié"
end
