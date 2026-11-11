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
    if valid_admin_password?(password) do
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

  defp valid_admin_password?(password) when is_binary(password) do
    case System.fetch_env("ADMIN_PASSWORD") do
      {:ok, expected} when expected != "" -> Plug.Crypto.secure_compare(password, expected)
      _ -> false
    end
  end

  defp valid_admin_password?(_), do: false

  def delete(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "Déconnecté avec succès.")
    |> redirect(to: ~p"/")
  end
end
