defmodule PortfolioHermannWeb.Helpers do
  @moduledoc """
  Helpers partagés : rendu Markdown -> HTML sûr et formatage de texte.
  """

  @markdown_options [
    extension: [
      alerts: true,
      autolink: true,
      footnotes: true,
      shortcodes: true,
      strikethrough: true,
      table: true,
      tagfilter: true,
      tasklist: true
    ],
    parse: [
      relaxed_autolinks: true,
      relaxed_tasklist_matching: true
    ],
    render: [
      github_pre_lang: true,
      full_info_string: true,
      tasklist_classes: true
    ]
  ]

  @doc """
  Convertit du Markdown en HTML prêt à être affiché dans une page.

  Active les extensions GitHub Flavored Markdown utiles au blog :

    * tableaux GFM (`table`) ;
    * texte barré (`strikethrough`) ;
    * listes de tâches avec cases à cocher (`tasklist`) ;
    * liens automatiques (`autolink`) ;
    * notes de bas de page (`footnotes`) ;
    * alertes de style GitHub (`alerts`) et émoticônes `:smile:` (`shortcodes`).

  Les structures CommonMark restent prises en charge : titres, listes
  ordonnées et non ordonnées, citations, blocs de code clôturés par des
  backticks (avec langue, rendus en `<pre lang="...">`), traits de séparation,
  liens et images.

  Sécurité : le HTML brut présent dans le Markdown n'est jamais rendu ni
  exécuté. MDEx le remplace par un commentaire `<!-- raw HTML omitted -->` ;
  `<script>`, `onerror` et compagnie n'arrivent donc jamais dans la page. Le
  HTML renvoyé ne contient que le balisage généré par le parseur et peut être
  inséré tel quel avec `Phoenix.HTML.raw/1`.

  Les tableaux sont enveloppés dans un conteneur scrollable
  (`div.md-table-wrap`) afin de rester lisibles sur mobile.

  `nil` et la chaîne vide renvoient `""`.
  """
  @spec md_to_html(String.t() | nil) :: String.t()
  def md_to_html(nil), do: ""

  def md_to_html(markdown) when is_binary(markdown) do
    markdown
    |> MDEx.to_html!(@markdown_options)
    |> wrap_tables()
  end

  # MDEx rend les tableaux GFM sous la forme `<table>...</table>`. Pour qu'un
  # tableau large défile horizontalement au lieu de déborder de l'article sur
  # mobile, on l'enveloppe dans un conteneur scrollable.
  #
  # Le HTML brut écrit par l'auteur n'est pas rendu par MDEx (il est remplacé
  # par `<!-- raw HTML omitted -->`), donc `"<table>"` ne peut apparaître ici
  # que pour un tableau réellement généré par le parseur : le remplacement ne
  # peut pas être détourné par le contenu.
  defp wrap_tables(html) do
    html
    |> String.replace("<table>", ~s(<div class="md-table-wrap">\n<table>))
    |> String.replace("</table>", "</table>\n</div>")
  end

  @doc """
  Tronque `text` à `limit` caractères et ajoute des points de suspension.
  """
  def limit_text(text, limit) do
    if String.length(text) > limit do
      String.slice(text, 0..limit) <> "..."
    else
      text
    end
  end
end
