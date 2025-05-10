defmodule PortfolioHermannWeb.Hooks.Analytics do
  import Phoenix.LiveView
  alias PortfolioHermann.Analytics

  def on_mount(:default, _params, _session, socket) do
    if connected?(socket) do
      Analytics.increment_page_view(socket.assigns.live_action)
    end

    {:cont, socket}
  end
end
