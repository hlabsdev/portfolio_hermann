defmodule PortfolioHermannWeb.HealthController do
  use PortfolioHermannWeb, :controller

  def index(conn, _params) do
    send_resp(conn, 200, "OK")
  end
end
