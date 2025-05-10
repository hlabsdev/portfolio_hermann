defmodule PortfolioHermannWeb.AdminAuth do
  use PortfolioHermannWeb, :verified_routes
  import Phoenix.LiveView

  def on_mount(:default, _params, session, socket) do
    if Map.get(session, "admin") do
      {:cont, socket}
    else
      socket =
        socket
        |> put_flash(:error, "Veuillez vous connecter d'abord")
        |> redirect(to: "/admin/login")

      {:halt, socket}
    end
  end
end
