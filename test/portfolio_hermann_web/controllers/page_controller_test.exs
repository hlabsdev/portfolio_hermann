defmodule PortfolioHermannWeb.PageControllerTest do
  use PortfolioHermannWeb.ConnCase

  test "GET / rend la page d'accueil", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)
    assert html =~ "Je fais avancer le logiciel"
    assert html =~ "Komi K. Hermann GOLO"
  end
end
