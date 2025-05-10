defmodule PortfolioHermannWeb.ContactLive do
  use PortfolioHermannWeb, :live_view

  def render(assigns) do
    ~H"""
    <section class="max-w-xl mx-auto py-16 px-6">
      <h1 class="text-4xl font-bold mb-6 text-center">Me contacter</h1>

      <form class="space-y-4 card-soft">
        <input type="text" placeholder="Votre nom" class="w-full p-3 rounded-xl border border-gray-300" />
        <input type="email" placeholder="Votre e-mail" class="w-full p-3 rounded-xl border border-gray-300" />
        <textarea placeholder="Votre message" rows="5" class="w-full p-3 rounded-xl border border-gray-300"></textarea>
        <button type="submit" class="btn-soft px-6 py-3">Envoyer</button>
      </form>
    </section>
    """
  end
end
