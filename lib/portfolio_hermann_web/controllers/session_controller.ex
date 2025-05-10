defmodule PortfolioHermannWeb.SessionController do
  use PortfolioHermannWeb, :controller

  def new(conn, _params) do
    if get_session(conn, :admin) do
      redirect(conn, to: ~p"/admin/projects")
    else
      render(conn, :new)
    end
  end

  def create(conn, %{"login" => %{"password" => password}}) do
    if password == System.get_env("ADMIN_PASSWORD", "25091999") do
      conn
      |> put_session(:admin, true)
      |> put_flash(:info, "Connecté avec succès!")
      |> redirect(to: ~p"/admin/projects")
    else
      conn
      |> put_flash(:error, "Mot de passe incorrect")
      |> render(:new)
    end
  end

  def delete(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "Déconnecté avec succès.")
    |> redirect(to: ~p"/")
  end
end
