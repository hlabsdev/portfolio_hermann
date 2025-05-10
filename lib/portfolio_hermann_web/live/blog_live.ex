defmodule PortfolioHermannWeb.BlogLive do
  use PortfolioHermannWeb, :live_view

  def render(assigns) do
    ~H"""
    <section class="max-w-4xl mx-auto py-16 px-6 text-center">
      <h1 class="text-4xl font-bold mb-4">Blog technique</h1>
      <p class="text-gray-600 text-lg">
        À venir : articles sur Elixir, Python, Flutter, data science, etc.
      </p>
    </section>
    """
  end
end
