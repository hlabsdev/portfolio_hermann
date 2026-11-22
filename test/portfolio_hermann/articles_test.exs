defmodule PortfolioHermann.ArticlesTest do
  use ExUnit.Case, async: true

  alias PortfolioHermann.Articles

  describe "publication_due?/1" do
    test "un article sans date de publication est visible" do
      assert Articles.publication_due?(nil)
    end

    test "un article dont la date est passee est visible" do
      past = DateTime.utc_now() |> DateTime.add(-3600, :second) |> DateTime.to_iso8601()
      assert Articles.publication_due?(past)
    end

    test "un article programme dans le futur n'est pas visible" do
      future = DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.to_iso8601()
      refute Articles.publication_due?(future)
    end

    test "une date invalide n'est jamais consideree comme publiee" do
      refute Articles.publication_due?("pas une date")
      refute Articles.publication_due?("")
    end
  end
end

defmodule PortfolioHermann.ArticlesPersistenceTest do
  # Ces tests écrivent des fichiers JSON : ils ne peuvent pas tourner en
  # parallèle des autres tests.
  use ExUnit.Case, async: false

  alias PortfolioHermann.Articles

  setup do
    data_dir =
      Path.join(System.tmp_dir!(), "portfolio_articles_#{System.unique_integer([:positive])}")

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

  describe "save/1 avec statut draft" do
    test "enregistre un brouillon non publié et ignore published_at" do
      future = future_iso()

      assert {:ok, article} =
               save_article(%{"status" => "draft", "published_at" => future})

      assert article["published"] == false
      assert article["published_at"] == nil
      assert Articles.status(article) == "draft"
      assert Enum.any?(Articles.list(), &(&1["id"] == article["id"]))
      assert Articles.list_published() == []
    end
  end

  describe "save/1 avec statut scheduled" do
    test "exige une date de publication" do
      assert {:error, :published_at_required} = save_article(%{"status" => "scheduled"})

      assert {:error, :published_at_required} =
               save_article(%{"status" => "scheduled", "published_at" => "  "})
    end

    test "refuse une date passée" do
      past = DateTime.utc_now() |> DateTime.add(-3600, :second) |> DateTime.to_iso8601()

      assert {:error, :published_at_in_past} =
               save_article(%{"status" => "scheduled", "published_at" => past})
    end

    test "refuse une date invalide" do
      assert {:error, :published_at_invalid} =
               save_article(%{"status" => "scheduled", "published_at" => "pas une date"})
    end

    test "programme un article publié dans le futur" do
      future = future_iso()

      assert {:ok, article} = save_article(%{"status" => "scheduled", "published_at" => future})

      assert article["published"] == true
      assert article["published_at"] == future
      assert Articles.status(article) == "scheduled"
      refute Articles.publication_due?(article["published_at"])
      assert Articles.list_published() == []
    end
  end

  describe "save/1 avec statut published" do
    test "sans date, publie immédiatement" do
      assert {:ok, article} = save_article(%{"status" => "published"})

      assert article["published"] == true
      assert Articles.status(article) == "published"
      assert Articles.publication_due?(article["published_at"])
      assert DateTime.compare(parse!(article["published_at"]), DateTime.utc_now()) != :gt
      assert Enum.any?(Articles.list_published(), &(&1["id"] == article["id"]))
    end

    test "une date passée est normalisée à maintenant" do
      past = DateTime.utc_now() |> DateTime.add(-86_400, :second) |> DateTime.to_iso8601()

      assert {:ok, article} = save_article(%{"status" => "published", "published_at" => past})

      assert Articles.status(article) == "published"
      assert Articles.publication_due?(article["published_at"])
      refute article["published_at"] == past
    end

    test "une date future explicite reste une programmation" do
      future = future_iso()

      assert {:ok, article} = save_article(%{"status" => "published", "published_at" => future})

      assert article["published"] == true
      assert article["published_at"] == future
      assert Articles.status(article) == "scheduled"
    end

    test "republie immédiatement un article auparavant programmé" do
      future = future_iso()

      assert {:ok, scheduled} = save_article(%{"status" => "scheduled", "published_at" => future})
      assert Articles.status(scheduled) == "scheduled"

      assert {:ok, published} =
               save_article(%{
                 "id" => scheduled["id"],
                 "slug" => scheduled["slug"],
                 "status" => "published"
               })

      assert published["id"] == scheduled["id"]
      assert published["published"] == true
      assert published["published_at"] != future
      assert Articles.publication_due?(published["published_at"])
      assert Articles.status(published) == "published"
      assert Enum.any?(Articles.list_published(), &(&1["id"] == scheduled["id"]))
    end

    test "éditer un article déjà publié conserve sa date de publication" do
      assert {:ok, article} = save_article(%{"status" => "published"})

      old_date =
        DateTime.utc_now()
        |> DateTime.add(-3 * 86_400, :second)
        |> DateTime.truncate(:second)
        |> DateTime.to_iso8601()

      # Simule un article publié depuis plusieurs jours (écriture directe du
      # stockage, le statut "published" sans date résolvant sinon à maintenant).
      path = Path.join(System.fetch_env!("PORTFOLIO_DATA_DIR"), "articles.json")
      stored = path |> File.read!() |> Jason.decode!()
      File.write!(path, Jason.encode!(Enum.map(stored, &Map.put(&1, "published_at", old_date))))

      assert {:ok, edited} =
               save_article(%{
                 "id" => article["id"],
                 "slug" => article["slug"],
                 "status" => "published"
               })

      assert edited["published_at"] == old_date
      assert Articles.status(edited) == "published"
    end
  end

  describe "compatibilité sans statut explicite" do
    test "published: true sans date publie immédiatement (même si l'article était programmé)" do
      future = future_iso()

      assert {:ok, scheduled} =
               save_article(%{"published" => true, "published_at" => future})

      assert Articles.status(scheduled) == "scheduled"

      assert {:ok, published} =
               save_article(%{
                 "id" => scheduled["id"],
                 "slug" => scheduled["slug"],
                 "published" => true
               })

      assert published["published"] == true
      assert Articles.publication_due?(published["published_at"])
      assert Articles.status(published) == "published"
    end

    test "published: true avec date future reste programmé" do
      future = future_iso()

      assert {:ok, article} =
               save_article(%{"published" => true, "published_at" => future})

      assert Articles.status(article) == "scheduled"
    end

    test "sans published, l'article est un brouillon" do
      assert {:ok, article} = save_article(%{})

      assert article["published"] == false
      assert article["published_at"] == nil
      assert Articles.status(article) == "draft"
    end
  end

  describe "publish_now/1" do
    test "publie immédiatement un article programmé et rafraîchit updated_at" do
      future = future_iso()

      assert {:ok, scheduled} = save_article(%{"status" => "scheduled", "published_at" => future})
      assert Articles.status(scheduled) == "scheduled"

      assert {:ok, published} = Articles.publish_now(scheduled["id"])

      assert published["id"] == scheduled["id"]
      assert published["published"] == true
      assert published["published_at"] != future
      assert Articles.publication_due?(published["published_at"])
      assert Articles.status(published) == "published"
      assert published["updated_at"] >= scheduled["updated_at"]

      reloaded = Articles.get_by_slug(scheduled["slug"])
      assert reloaded["published_at"] == published["published_at"]
      assert Enum.any?(Articles.list_published(), &(&1["id"] == scheduled["id"]))
    end

    test "publie immédiatement un brouillon" do
      assert {:ok, draft} = save_article(%{"status" => "draft"})
      assert Articles.status(draft) == "draft"

      assert {:ok, published} = Articles.publish_now(draft["id"])

      assert published["published"] == true
      assert Articles.status(published) == "published"
      assert Articles.publication_due?(published["published_at"])
    end

    test "retourne :not_found pour un identifiant inconnu" do
      assert {:error, :not_found} = Articles.publish_now("inexistant")
    end
  end

  describe "unpublish/1" do
    test "repasse un article publié en brouillon" do
      assert {:ok, published} = save_article(%{"status" => "published"})

      assert {:ok, draft} = Articles.unpublish(published["id"])

      assert draft["published"] == false
      assert draft["published_at"] == nil
      assert Articles.status(draft) == "draft"
      assert draft["updated_at"] >= published["updated_at"]
      refute Enum.any?(Articles.list_published(), &(&1["id"] == published["id"]))
    end

    test "retourne :not_found pour un identifiant inconnu" do
      assert {:error, :not_found} = Articles.unpublish("inexistant")
    end
  end

  defp save_article(overrides) do
    attrs =
      Map.merge(
        %{
          "title" => "Un article de test",
          "slug" => "un-article-de-test",
          "summary" => "Résumé.",
          "body" => "# Titre\n\nContenu de test."
        },
        overrides
      )

    Articles.save(attrs)
  end

  defp future_iso(seconds \\ 3600) do
    DateTime.utc_now()
    |> DateTime.add(seconds, :second)
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601()
  end

  defp parse!(value) do
    {:ok, datetime, _offset} = DateTime.from_iso8601(value)
    datetime
  end
end
