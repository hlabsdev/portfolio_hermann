defmodule PortfolioHermannWeb.AdminExperiencesLive do
  use PortfolioHermannWeb, :live_view

  alias PortfolioHermann.Projects

  @impl true
  def mount(_params, _session, socket) do
    experiences = Projects.list_experiences()

    {:ok,
     socket
     |> assign(:page_title, "Parcours professionnel")
     |> assign(:work_experiences, experiences["workExperiences"] || [])
     |> assign(:editing, nil)}
  end

  @impl true
  def handle_event("new", _params, socket), do: {:noreply, assign(socket, :editing, %{})}

  def handle_event("edit", %{"id" => id}, socket) do
    experience = Enum.find(socket.assigns.work_experiences, &(&1["id"] == id))
    {:noreply, assign(socket, :editing, experience)}
  end

  def handle_event("cancel", _params, socket), do: {:noreply, assign(socket, :editing, nil)}

  def handle_event("save", %{"experience" => params}, socket) do
    existing = socket.assigns.work_experiences
    id = params["id"] || UUID.uuid4()

    experience = %{
      "id" => id,
      "title" => String.trim(params["title"] || ""),
      "company" => String.trim(params["company"] || ""),
      "location" => String.trim(params["location"] || ""),
      "start_date" => String.trim(params["start_date"] || ""),
      "end_date" => blank_to_nil(params["end_date"]),
      "description" => String.trim(params["description"] || ""),
      "achievements" => parse_lines(params["achievements"]),
      "keywords" => parse_csv(params["keywords"])
    }

    work_experiences =
      if Enum.any?(existing, &(&1["id"] == id)) do
        Enum.map(existing, fn item -> if item["id"] == id, do: experience, else: item end)
      else
        [experience | existing]
      end

    data = Map.put(Projects.list_experiences(), "workExperiences", work_experiences)

    case Projects.save_experiences(data) do
      :ok ->
        {:noreply,
         socket
         |> assign(:work_experiences, work_experiences)
         |> assign(:editing, nil)
         |> put_flash(:info, "Le parcours a été enregistré.")}

      _ ->
        {:noreply, put_flash(socket, :error, "L’enregistrement a échoué. Réessaie.")}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    work_experiences = Enum.reject(socket.assigns.work_experiences, &(&1["id"] == id))
    data = Map.put(Projects.list_experiences(), "workExperiences", work_experiences)

    case Projects.save_experiences(data) do
      :ok ->
        {:noreply,
         socket
         |> assign(:work_experiences, work_experiences)
         |> put_flash(:info, "L’expérience a été supprimée.")}

      _ ->
        {:noreply, put_flash(socket, :error, "La suppression a échoué.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-6xl px-5 py-12 sm:px-8">
      <div class="mb-10 flex flex-wrap items-end justify-between gap-5">
        <div>
          <p class="mb-2 text-xs font-semibold uppercase tracking-[0.22em] text-orange-700">Administration</p>
          <h1 class="text-3xl font-semibold tracking-tight text-slate-950 dark:text-white">Parcours professionnel</h1>
          <p class="mt-2 max-w-2xl text-sm leading-6 text-slate-600 dark:text-slate-300">
            Modifie les expériences affichées sur la page À propos. Les changements sont enregistrés sur le volume Fly.
          </p>
        </div>
        <div class="flex flex-wrap gap-3">
          <.link navigate={~p"/admin/projects"} class="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800">Projets</.link>
          <button type="button" phx-click="new" class="rounded-lg bg-slate-950 px-4 py-2 text-sm font-semibold text-white hover:bg-slate-800 dark:bg-white dark:text-slate-950">Ajouter une expérience</button>
        </div>
      </div>

      <div class="space-y-4">
        <%= for experience <- @work_experiences do %>
          <article class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900">
            <div class="flex flex-wrap items-start justify-between gap-4">
              <div>
                <p class="text-xs font-medium uppercase tracking-wide text-slate-500"><%= experience["start_date"] %> · <%= experience["end_date"] || "En cours" %></p>
                <h2 class="mt-2 text-xl font-semibold text-slate-950 dark:text-white"><%= experience["title"] %></h2>
                <p class="mt-1 text-sm text-slate-600 dark:text-slate-300"><%= experience["company"] %> · <%= experience["location"] %></p>
              </div>
              <div class="flex gap-2">
                <button type="button" phx-click="edit" phx-value-id={experience["id"]} class="rounded-lg border border-slate-300 px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800">Modifier</button>
                <button type="button" phx-click="delete" phx-value-id={experience["id"]} data-confirm="Supprimer cette expérience ?" class="rounded-lg border border-rose-200 px-3 py-2 text-sm font-medium text-rose-700 hover:bg-rose-50 dark:border-rose-900 dark:text-rose-300">Supprimer</button>
              </div>
            </div>
            <p class="mt-4 max-w-4xl text-sm leading-6 text-slate-700 dark:text-slate-300"><%= experience["description"] %></p>
            <ul class="mt-4 list-inside list-disc space-y-1 text-sm leading-6 text-slate-600 dark:text-slate-300">
              <%= for achievement <- experience["achievements"] || [] do %><li><%= achievement %></li><% end %>
            </ul>
          </article>
        <% end %>
      </div>

      <%= if @editing do %>
        <div class="fixed inset-0 z-50 overflow-y-auto bg-slate-950/60 p-4 sm:p-8">
          <section class="mx-auto my-8 max-w-3xl rounded-2xl bg-white p-6 shadow-2xl dark:bg-slate-900" phx-click-away="cancel">
            <div class="mb-6 flex items-start justify-between gap-4">
              <div><p class="text-xs font-semibold uppercase tracking-[0.2em] text-orange-700">Parcours</p><h2 class="mt-2 text-2xl font-semibold text-slate-950 dark:text-white"><%= if @editing["id"], do: "Modifier l’expérience", else: "Ajouter une expérience" %></h2></div>
              <button type="button" phx-click="cancel" aria-label="Fermer" class="rounded-lg px-3 py-2 text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800">Fermer</button>
            </div>
            <.form for={%{}} as={:experience} phx-submit="save" class="space-y-5">
              <input type="hidden" name="experience[id]" value={@editing["id"]} />
              <div class="grid gap-4 sm:grid-cols-2">
                <.field label="Intitulé" name="experience[title]" value={@editing["title"]} required />
                <.field label="Entreprise ou organisation" name="experience[company]" value={@editing["company"]} required />
                <.field label="Lieu" name="experience[location]" value={@editing["location"]} />
                <.field label="Début (ex. Février 2022)" name="experience[start_date]" value={@editing["start_date"]} required />
                <.field label="Fin (laisser vide si en cours)" name="experience[end_date]" value={@editing["end_date"]} />
              </div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-200">Résumé
                <textarea name="experience[description]" rows="3" required class="mt-1 block w-full rounded-lg border-slate-300 bg-white text-sm shadow-sm focus:border-orange-700 focus:ring-orange-700 dark:border-slate-700 dark:bg-slate-950"><%= @editing["description"] %></textarea>
              </label>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-200">Responsabilités et réalisations (une par ligne)
                <textarea name="experience[achievements]" rows="6" class="mt-1 block w-full rounded-lg border-slate-300 bg-white text-sm shadow-sm focus:border-orange-700 focus:ring-orange-700 dark:border-slate-700 dark:bg-slate-950"><%= Enum.join(@editing["achievements"] || [], "\n") %></textarea>
              </label>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-200">Technologies et domaines (séparés par des virgules)
                <input name="experience[keywords]" value={Enum.join(@editing["keywords"] || [], ", ")} class="mt-1 block w-full rounded-lg border-slate-300 bg-white text-sm shadow-sm focus:border-orange-700 focus:ring-orange-700 dark:border-slate-700 dark:bg-slate-950" />
              </label>
              <div class="flex justify-end gap-3 border-t border-slate-200 pt-5 dark:border-slate-800">
                <button type="button" phx-click="cancel" class="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 dark:border-slate-700 dark:text-slate-200">Annuler</button>
                <button type="submit" class="rounded-lg bg-slate-950 px-5 py-2 text-sm font-semibold text-white dark:bg-white dark:text-slate-950">Enregistrer</button>
              </div>
            </.form>
          </section>
        </div>
      <% end %>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :name, :string, required: true
  attr :value, :string, default: nil
  attr :required, :boolean, default: false
  defp field(assigns) do
    ~H"""
    <label class="block text-sm font-medium text-slate-700 dark:text-slate-200"><%= @label %>
      <input name={@name} value={@value} required={@required} class="mt-1 block w-full rounded-lg border-slate-300 bg-white text-sm shadow-sm focus:border-orange-700 focus:ring-orange-700 dark:border-slate-700 dark:bg-slate-950" />
    </label>
    """
  end

  defp parse_lines(text), do: (text || "") |> String.split("\n") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
  defp parse_csv(text), do: (text || "") |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(text) do
    case String.trim(text) do
      "" -> nil
      value -> value
    end
  end
end
