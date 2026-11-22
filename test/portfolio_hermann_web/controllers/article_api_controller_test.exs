defmodule PortfolioHermannWeb.ArticleApiControllerTest do
  # L'API écrit des fichiers JSON via PORTFOLIO_DATA_DIR : pas d'exécution
  # parallèle avec les autres tests qui touchent au stockage.
  use PortfolioHermannWeb.ConnCase, async: false

  alias PortfolioHermann.Articles

  @token "jeton-de-test-api"

  setup do
    data_dir =
      Path.join(System.tmp_dir!(), "portfolio_api_#{System.unique_integer([:positive])}")

    File.mkdir_p!(data_dir)
    File.write!(Path.join(data_dir, "articles.json"), "[]")

    previous_data = System.get_env("PORTFOLIO_DATA_DIR")
    previous_token = System.get_env("BLOG_PUBLISH_TOKEN")
    System.put_env("PORTFOLIO_DATA_DIR", data_dir)
    System.put_env("BLOG_PUBLISH_TOKEN", @token)

    on_exit(fn ->
      restore_env("PORTFOLIO_DATA_DIR", previous_data)
      restore_env("BLOG_PUBLISH_TOKEN", previous_token)
      File.rm_rf(data_dir)
    end)

    {:ok, data_dir: data_dir}
  end

  test "status published sans published_at publie immédiatement un article programmé", %{
    conn: conn
  } do
    future =
      DateTime.utc_now()
      |> DateTime.add(3600, :second)
      |> DateTime.truncate(:second)
      |> DateTime.to_iso8601()

    assert {:ok, scheduled} =
             Articles.save(%{
               "title" => "Article programmé",
               "slug" => "article-programme",
               "summary" => "Résumé.",
               "body" => "# Programmé\n\nContenu.",
               "status" => "scheduled",
               "published_at" => future
             })

    assert Articles.status(scheduled) == "scheduled"

    conn =
      post_json(conn, %{
        "title" => "Article programmé",
        "slug" => scheduled["slug"],
        "summary" => "Résumé.",
        "body_markdown" => "# Programmé\n\nContenu.",
        "status" => "published"
      })

    assert %{"ok" => true, "article" => article} = json_response(conn, 200)
    assert article["status"] == "published"
    assert article["published_at"] != future

    stored = Articles.get_by_slug(scheduled["slug"])
    assert Articles.status(stored) == "published"
    assert Articles.publication_due?(stored["published_at"])
    assert Enum.any?(Articles.list_published(), &(&1["slug"] == scheduled["slug"]))
  end

  test "status scheduled exige une date future", %{conn: conn} do
    conn =
      post_json(conn, %{
        "title" => "Programmé",
        "slug" => "programme",
        "body_markdown" => "# Programmé\n\nContenu.",
        "status" => "scheduled"
      })

    assert %{"ok" => false, "error" => %{"code" => "scheduled_date_required"}} =
             json_response(conn, 422)

    past =
      DateTime.utc_now()
      |> DateTime.add(-3600, :second)
      |> DateTime.truncate(:second)
      |> DateTime.to_iso8601()

    conn =
      build_conn()
      |> post_json(%{
        "title" => "Programmé",
        "slug" => "programme",
        "body_markdown" => "# Programmé\n\nContenu.",
        "status" => "scheduled",
        "published_at" => past
      })

    assert %{"ok" => false, "error" => %{"code" => "scheduled_date_in_past"}} =
             json_response(conn, 422)
  end

  test "un brouillon reste invisible", %{conn: conn} do
    conn =
      post_json(conn, %{
        "title" => "Brouillon",
        "slug" => "brouillon",
        "body_markdown" => "# Brouillon\n\nContenu.",
        "status" => "draft"
      })

    assert %{"ok" => true, "article" => %{"status" => "draft"}} = json_response(conn, 200)
    assert Articles.list_published() == []
  end

  test "refuse un jeton absent ou invalide", %{conn: conn} do
    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> post(~p"/api/articles", Jason.encode!(%{"title" => "X", "body_markdown" => "Corps"}))

    assert %{"ok" => false, "error" => %{"code" => "unauthorized"}} = json_response(conn, 401)

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer mauvais-jeton")
      |> put_req_header("content-type", "application/json")
      |> post(~p"/api/articles", Jason.encode!(%{"title" => "X", "body_markdown" => "Corps"}))

    assert %{"ok" => false, "error" => %{"code" => "unauthorized"}} = json_response(conn, 401)
  end

  defp post_json(conn, payload) do
    conn
    |> put_req_header("authorization", "Bearer #{@token}")
    |> put_req_header("content-type", "application/json")
    |> post(~p"/api/articles", Jason.encode!(payload))
  end

  defp restore_env(name, nil), do: System.delete_env(name)
  defp restore_env(name, value), do: System.put_env(name, value)
end
