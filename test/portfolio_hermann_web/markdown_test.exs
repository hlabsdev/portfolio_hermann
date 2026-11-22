defmodule PortfolioHermannWeb.MarkdownTest do
  @moduledoc """
  Vérifie le rendu Markdown -> HTML des articles (renderer central
  `PortfolioHermannWeb.Helpers.md_to_html/1`) et son intégration dans
  `PortfolioHermannWeb.BlogLive`.

  Le test d'intégration utilise un répertoire de données temporaire
  (`PORTFOLIO_DATA_DIR`) pour ne jamais toucher aux articles de production.
  """

  # async: false : le test d'intégration modifie PORTFOLIO_DATA_DIR.
  use PortfolioHermannWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias PortfolioHermann.Articles
  alias PortfolioHermannWeb.Helpers

  defp to_html(markdown), do: Helpers.md_to_html(markdown)

  describe "md_to_html/1 : structures GFM" do
    test "les tableaux GFM sont rendus avec en-tête et cellules" do
      markdown = """
      | Langage | Usage |
      | ------- | ----- |
      | Elixir  | API   |
      | Rust    | NIF   |
      """

      html = to_html(markdown)

      assert html =~ "<table>"
      assert html =~ "<thead>"
      assert html =~ "<th>Langage</th>"
      assert html =~ "<td>Elixir</td>"
    end

    test "les tableaux sont enveloppés pour défiler horizontalement sur mobile" do
      html = to_html("| Colonne |\n| --- |\n| valeur |")

      assert html =~ ~s(class="md-table-wrap")
      assert html =~ ~r{<div class="md-table-wrap">\s*<table>}
      assert html =~ ~r{</table>\s*</div>}
    end

    test "les listes non ordonnées rendent des puces (<ul><li>)" do
      html = to_html("- Premier point\n- Second point\n")

      assert html =~ "<ul>"
      assert html =~ "<li>Premier point</li>"
      assert html =~ "<li>Second point</li>"
    end

    test "les listes ordonnées rendent <ol><li>" do
      html = to_html("1. Étape un\n2. Étape deux\n")

      assert html =~ "<ol>"
      assert html =~ "<li>Étape un</li>"
      assert html =~ "<li>Étape deux</li>"
    end

    test "le texte barré rend <del>" do
      assert to_html("Ceci est ~~obsolète~~.") =~ "<del>obsolète</del>"
    end

    test "les listes de tâches rendent une case à cocher" do
      html = to_html("- [x] Fait\n- [ ] À faire\n")

      assert html =~ ~s(type="checkbox")
      assert html =~ "checked"
      assert html =~ "task-list-item"
      assert html =~ "Fait"
    end

    test "les blocs de code clôturés gardent la langue" do
      markdown = """
      ```elixir
      def hello, do: :world
      ```
      """

      html = to_html(markdown)

      assert html =~ ~s(<pre lang="elixir">)
      assert html =~ "<code>"
      assert html =~ "def hello"
    end

    test "un bloc de code sans langue rend <pre><code>" do
      html = to_html("```\nligne de code\n```\n")

      assert html =~ "<pre>"
      assert html =~ "<code>ligne de code"
    end

    test "le code inline rend <code>" do
      assert to_html("Utiliser `mix test`.") =~ "<code>mix test</code>"
    end

    test "les citations rendent <blockquote>" do
      html = to_html("> Une citation\n")

      assert html =~ "<blockquote>"
      assert html =~ "Une citation"
    end

    test "les liens automatiques (autolink) rendent un <a>" do
      html = to_html("Voir https://example.com pour la doc.")

      assert html =~ ~s(<a href="https://example.com">https://example.com</a>)
    end

    test "les traits de séparation rendent <hr>" do
      assert to_html("Avant\n\n---\n\nAprès\n") =~ "<hr"
    end

    test "les images rendent <img> avec src et alt" do
      html = to_html("![Logo](/images/logo.svg)")

      assert html =~ ~s(src="/images/logo.svg")
      assert html =~ ~s(alt="Logo")
    end

    test "les notes de bas de page sont rendues" do
      html = to_html("Un texte[^1].\n\n[^1]: Le détail de la note.\n")

      assert html =~ "footnote-ref"
      assert html =~ "Le détail de la note."
    end

    test "les alertes GitHub et les émoticônes sont rendues" do
      html = to_html("> [!NOTE]\n> Une remarque\n\nUn :smile: test")

      assert html =~ "markdown-alert"
      assert html =~ "Une remarque"
      assert html =~ "😄"
    end
  end

  describe "md_to_html/1 : sécurité du HTML brut" do
    test "un <script> présent dans le Markdown n'est jamais exécutable" do
      html = to_html("Avant\n\n<script>alert('xss')</script>\n\nAprès")

      refute html =~ "<script"
      assert html =~ "raw HTML omitted"
    end

    test "un <img onerror=...> présent dans le Markdown n'est pas rendu" do
      html = to_html(~S|Avant <img src=x onerror="alert(1)"> après|)

      refute html =~ "<img src=x"
      refute html =~ "onerror="
      assert html =~ "raw HTML omitted"
    end

    test "un lien javascript: ne produit pas de href dangereux" do
      html = to_html(~S|[clic](javascript:alert(1))|)

      refute html =~ "javascript:"
      assert html =~ "clic"
    end
  end

  describe "md_to_html/1 : entrées vides" do
    test "nil rend une chaîne vide" do
      assert Helpers.md_to_html(nil) == ""
    end

    test "une chaîne vide rend une chaîne vide" do
      assert Helpers.md_to_html("") == ""
    end

    test "une chaîne composée d'espaces rend une chaîne vide" do
      assert Helpers.md_to_html("  \n\n  ") == ""
    end
  end

  describe "BlogLive" do
    setup do
      data_dir =
        Path.join(
          System.tmp_dir!(),
          "portfolio_hermann_md_test_#{System.unique_integer([:positive])}"
        )

      File.mkdir_p!(data_dir)
      previous = System.get_env("PORTFOLIO_DATA_DIR")
      System.put_env("PORTFOLIO_DATA_DIR", data_dir)

      on_exit(fn ->
        if previous do
          System.put_env("PORTFOLIO_DATA_DIR", previous)
        else
          System.delete_env("PORTFOLIO_DATA_DIR")
        end

        File.rm_rf(data_dir)
      end)

      :ok
    end

    test "le HTML d'un article publié contient les structures GFM", %{conn: conn} do
      body = """
      ## Un tableau

      | Langage | Usage |
      | ------- | ----- |
      | Elixir  | API   |

      - Premier point
      - Second point

      Ceci est ~~obsolète~~ et voici `du code`.

      <script>alert('xss')</script>
      """

      assert {:ok, article} =
               Articles.save(%{
                 "title" => "Article de test Markdown",
                 "slug" => "article-test-markdown",
                 "summary" => "Résumé de test",
                 "body" => body,
                 "published" => true,
                 "published_at" =>
                   DateTime.utc_now()
                   |> DateTime.add(-3600, :second)
                   |> DateTime.to_iso8601()
               })

      {:ok, view, html} = live(conn, "/blog/#{article["slug"]}")

      assert html =~ "Article de test Markdown"
      assert html =~ "<table>"
      assert html =~ ~s(class="md-table-wrap")
      assert html =~ "<ul>"
      assert html =~ "<li>Premier point</li>"
      assert html =~ "<del>obsolète</del>"

      # Le HTML brut de l'article n'est jamais rendu ni exécuté par le navigateur.
      refute html =~ "<script>alert('xss')</script>"
      assert html =~ "raw HTML omitted"
      assert render(view) =~ "<table>"
    end

    test "un article absent affiche la page Articles", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/blog/inexistant")

      assert html =~ "Les premiers articles arrivent bientôt"
    end
  end
end
