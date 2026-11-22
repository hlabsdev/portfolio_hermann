defmodule PortfolioHermannWeb.ContactLive do
  use PortfolioHermannWeb, :live_view

  @contact_address "kekeligolo@gmail.com"

  @impl true
  def mount(_params, _session, socket) do
    host = System.get_env("PHX_HOST") || "portfolio-hermann.fly.dev"

    {:ok,
     socket
     |> assign(:page_title, "Me contacter")
     |> assign(:contact_action, "https://formsubmit.co/#{@contact_address}")
     |> assign(:thanks_url, "https://#{host}/contact/merci")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="mx-auto max-w-5xl px-5 py-16 sm:px-8 lg:py-24">
      <div class="grid gap-12 lg:grid-cols-[0.75fr_1.25fr]">
        <section>
          <p class="text-xs font-semibold uppercase tracking-[0.22em] text-orange-700">Contact</p>
          <h1 class="mt-3 text-4xl font-semibold tracking-tight text-slate-950 dark:text-white sm:text-5xl">Parlons de votre projet.</h1>
          <p class="mt-5 text-lg leading-8 text-slate-600 dark:text-slate-300">Décrivez brièvement le besoin, le contexte et la prochaine étape souhaitée. Je vous répondrai par courriel.</p>
          <div class="mt-8 rounded-xl border border-slate-200 bg-white p-5 text-sm leading-6 text-slate-600 dark:border-slate-800 dark:bg-slate-900 dark:text-slate-300">
            Les messages sont acheminés par courriel via FormSubmit. Au premier envoi, le destinataire doit confirmer l’activation depuis sa boîte de réception.
          </div>
        </section>

        <section class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900 sm:p-8">
          <form action={@contact_action} method="post" class="space-y-5">
            <input type="hidden" name="_subject" value="Nouveau message depuis le portfolio Hermann GOLO" />
            <input type="hidden" name="_next" value={@thanks_url} />
            <div style="display:none" aria-hidden="true"><label>Ne pas remplir<input type="text" name="_honey" tabindex="-1" autocomplete="off" /></label></div>

            <div class="grid gap-5 sm:grid-cols-2">
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-200">Nom
                <input type="text" name="name" required autocomplete="name" maxlength="120" class="mt-1 block w-full rounded-lg border-slate-300 bg-white shadow-sm focus:border-orange-700 focus:ring-orange-700 dark:border-slate-700 dark:bg-slate-950" />
              </label>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-200">Adresse e-mail
                <input type="email" name="email" required autocomplete="email" maxlength="254" class="mt-1 block w-full rounded-lg border-slate-300 bg-white shadow-sm focus:border-orange-700 focus:ring-orange-700 dark:border-slate-700 dark:bg-slate-950" />
              </label>
            </div>

            <label class="block text-sm font-medium text-slate-700 dark:text-slate-200">Sujet
              <select name="subject" required class="mt-1 block w-full rounded-lg border-slate-300 bg-white shadow-sm focus:border-orange-700 focus:ring-orange-700 dark:border-slate-700 dark:bg-slate-950">
                <option value="" disabled selected>Choisissez un sujet</option>
                <option>Collaboration ou mission</option>
                <option>Conseil DevOps ou ingénierie logicielle</option>
                <option>Recrutement</option>
                <option>Autre demande</option>
              </select>
            </label>

            <label class="block text-sm font-medium text-slate-700 dark:text-slate-200">Votre message
              <textarea name="message" rows="7" required minlength="20" maxlength="10000" placeholder="Quelques lignes sur votre besoin, vos contraintes et le calendrier…" class="mt-1 block w-full rounded-lg border-slate-300 bg-white shadow-sm focus:border-orange-700 focus:ring-orange-700 dark:border-slate-700 dark:bg-slate-950"></textarea>
            </label>

            <button type="submit" class="inline-flex items-center rounded-lg bg-slate-950 px-5 py-3 text-sm font-semibold text-white transition hover:bg-slate-800 dark:bg-white dark:text-slate-950 dark:hover:bg-slate-200">Envoyer le message <.icon name="hero-arrow-right" class="ml-2 h-4 w-4" /></button>
            <p class="text-xs leading-5 text-slate-500 dark:text-slate-400">Votre adresse sert uniquement à pouvoir vous répondre. Évitez d’inclure des informations sensibles dans le message.</p>
          </form>
        </section>
      </div>
    </main>
    """
  end
end
