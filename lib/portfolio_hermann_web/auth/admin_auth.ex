defmodule PortfolioHermannWeb.AdminAuth do
  use PortfolioHermannWeb, :verified_routes
  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:default, _params, session, socket) do
    if Map.get(session, "admin") do
      {:cont, socket}
    else
      socket =
        socket
        |> put_flash(:error, "Veuillez vous connecter d'abord")
        |> redirect(to: ~p"/admin/login")

      {:halt, socket}
    end
  end
end
