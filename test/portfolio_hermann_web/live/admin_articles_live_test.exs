defmodule PortfolioHermannWeb.AdminArticlesLiveTest do
  # Les tests écrivent des fichiers JSON via PORTFOLIO_DATA_DIR : pas d'exécution
  # parallèle.
  use PortfolioHermannWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias PortfolioHermann.Articles

  setup do
    data_dir =
      Path.join(
        System.tmp_dir!(),
        "portfolio_admin_articles_#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(data_dir)
    File.write!(Path.join(data_dir, "articles.json"), "[]")

    previous = System.get_env("PORTFOLIO_DATA_DIR")
    System.put_env("PORTFOLIO_DATA_DIR", data_dir)

    on_exit(fn ->
      case previous do
        nil -> System.delete_env("PORTFOLIO_DATA_DIR")
        value -> System.put_env("PORTFOLIO_DATA_DIR", value)
      end

      File.rm_rf(data_dir)
    end)

    {:ok, data_dir: data_dir}
  end

  test "affiche la liste et l'éditeur avec un statut explicite", %{conn: conn} do
    {:ok, view, html} = mount_admin(conn)

    assert html =~ "Articles"
    assert has_element?(view, "button", "Nouvel article")

    view |> element("button", "Nouvel article") |> render_click()

    assert has_element?(view, "select[name='article[status]']")
    assert has_element?(view, "input[name='article[published_at]'][type='datetime-local']")
    assert has_element?(view, "form[phx-submit='save']")
  end

  test "crée un brouillon puis le publie immédiatement depuis la liste", %{conn: conn} do
    {:ok, view, _html} = mount_admin(conn)

    view |> element("button", "Nouvel article") |> render_click()

    html =
      view
      |> form("form[phx-submit='save']", %{
        "article" => %{
          "title" => "Brouillon à publier",
          "slug" => "brouillon-a-publier",
          "summary" => "Résumé du brouillon.",
          "tags" => "Elixir, Phoenix",
          "cover_url" => "",
          "body" => "# Brouillon\n\nUn contenu en Markdown.",
          "status" => "draft"
        }
      })
      |> render_submit()

    assert html =~ "Brouillon enregistré."
    assert html =~ "Brouillon"

    article = Articles.get_by_slug("brouillon-a-publier")
    assert article != nil
    assert Articles.status(article) == "draft"
    assert has_element?(view, "button[phx-click='publish_now'][phx-value-id='#{article["id"]}']")

    html =
      view
      |> element("button[phx-click='publish_now'][phx-value-id='#{article["id"]}']")
      |> render_click()

    assert html =~ "publié immédiatement"
    assert html =~ "Publié"
    assert has_element?(view, "a[href='/blog/brouillon-a-publier']")
    refute has_element?(view, "button[phx-click='publish_now'][phx-value-id='#{article["id"]}']")

    published = Articles.get_by_slug("brouillon-a-publier")
    assert published["published"] == true
    assert Articles.publication_due?(published["published_at"])
    assert Articles.status(published) == "published"
    assert Enum.any?(Articles.list_published(), &(&1["id"] == article["id"]))
  end

  test "affiche la date programmee, pré-remplit l'éditeur et publie maintenant", %{conn: conn} do
    article = create_scheduled_article("Article programmé", "article-programme")

    {:ok, view, html} = mount_admin(conn)

    assert html =~ "Programmé"
    assert html =~ "Publication programmée le"
    assert has_element?(view, "button[phx-click='publish_now'][phx-value-id='#{article["id"]}']")

    # L'éditeur pré-remplit le statut et la date existante.
    view |> element("button[phx-click='edit'][phx-value-id='#{article["id"]}']") |> render_click()

    expected_datetime = String.slice(article["published_at"], 0, 16)
    assert has_element?(view, "option[value='scheduled'][selected]")
    assert has_element?(view, "input[name='article[published_at]'][value='#{expected_datetime}']")

    view |> element("button", "Fermer") |> render_click()

    # Publication immédiate depuis la liste.
    html =
      view
      |> element("button[phx-click='publish_now'][phx-value-id='#{article["id"]}']")
      |> render_click()

    assert html =~ "publié immédiatement"
    refute html =~ "Publication programmée le"

    published = Articles.get_by_slug("article-programme")
    assert Articles.status(published) == "published"
    assert Articles.publication_due?(published["published_at"])
    assert published["published_at"] != article["published_at"]
  end

  test "passer un article programmé en statut Publié le publie immédiatement (case historique)",
       %{conn: conn} do
    article = create_scheduled_article("Reprogrammé en publié", "reprogramme-en-publie")

    {:ok, view, _html} = mount_admin(conn)

    view |> element("button[phx-click='edit'][phx-value-id='#{article["id"]}']") |> render_click()

    # L'utilisateur choisit "Publié (maintenant)" alors que le champ date est
    # encore rempli avec l'ancienne date future : la publication doit être
    # immédiate et ne pas conserver la programmation.
    html =
      view
      |> form("form[phx-submit='save']", %{
        "article" => %{
          "title" => "Reprogrammé en publié",
          "status" => "published",
          "published_at" => String.slice(article["published_at"], 0, 16)
        }
      })
      |> render_submit()

    assert html =~ "Article publié."

    published = Articles.get_by_slug("reprogramme-en-publie")
    assert published["published"] == true
    assert published["published_at"] != article["published_at"]
    assert Articles.publication_due?(published["published_at"])
    assert Articles.status(published) == "published"
  end

  test "programmer depuis l'éditeur exige une date future", %{conn: conn} do
    article = create_scheduled_article("À republier", "a-republier")

    {:ok, view, _html} = mount_admin(conn)

    view |> element("button[phx-click='edit'][phx-value-id='#{article["id"]}']") |> render_click()

    html =
      view
      |> form("form[phx-submit='save']", %{
        "article" => %{"title" => "À republier", "status" => "scheduled", "published_at" => ""}
      })
      |> render_submit()

    assert html =~ "Choisis une date de publication"
    assert has_element?(view, "form[phx-submit='save']")

    past =
      DateTime.utc_now() |> DateTime.add(-3600, :second) |> Calendar.strftime("%Y-%m-%dT%H:%M")

    html =
      view
      |> form("form[phx-submit='save']", %{
        "article" => %{"title" => "À republier", "status" => "scheduled", "published_at" => past}
      })
      |> render_submit()

    assert html =~ "doit être dans le futur"
  end

  defp mount_admin(conn) do
    conn
    |> init_test_session(%{"admin" => true})
    |> live(~p"/admin/articles")
  end

  defp create_scheduled_article(title, slug) do
    future =
      DateTime.utc_now()
      |> DateTime.add(3600, :second)
      |> DateTime.truncate(:second)
      |> DateTime.to_iso8601()

    {:ok, article} =
      Articles.save(%{
        "title" => title,
        "slug" => slug,
        "summary" => "Résumé.",
        "body" => "# Programmé\n\nContenu.",
        "status" => "scheduled",
        "published_at" => future
      })

    article
  end
end
