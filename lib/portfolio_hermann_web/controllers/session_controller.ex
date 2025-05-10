defmodule PortfolioHermannWeb.SessionController do
  use PortfolioHermannWeb, :controller

  def new(conn, _params) do
    render(conn, "login.html")
  end

  def create(conn, %{"password" => "topsecret"}) do
    conn
    |> put_session(:admin, true)
    |> redirect(to: ~p"/admin/projects")
  end

  def create(conn, _params) do
    conn
    |> put_flash(:error, "Mot de passe incorrect")
    |> render("login.html")
  end
end
