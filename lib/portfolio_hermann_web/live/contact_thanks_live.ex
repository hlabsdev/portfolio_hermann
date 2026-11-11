defmodule PortfolioHermannWeb.ContactThanksLive do
  use PortfolioHermannWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Message envoyé")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="mx-auto max-w-3xl px-5 py-24 text-center sm:px-8">
      <div class="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300"><.icon name="hero-check" class="h-7 w-7" /></div>
      <h1 class="mt-6 text-3xl font-semibold tracking-tight text-slate-950 dark:text-white">Merci pour votre message.</h1>
      <p class="mx-auto mt-4 max-w-xl leading-7 text-slate-600 dark:text-slate-300">Votre demande a été transmise. Je reviendrai vers vous à l’adresse indiquée.</p>
      <.link href={~p"/"} class="mt-8 inline-flex rounded-lg bg-slate-950 px-5 py-3 text-sm font-semibold text-white dark:bg-white dark:text-slate-950">Retour à l’accueil</.link>
    </main>
    """
  end
end
