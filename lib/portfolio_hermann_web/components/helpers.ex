defmodule PortfolioHermannWeb.Helpers do
  import Phoenix.HTML

  def md_to_html(markdown) when is_binary(markdown) do
    markdown
    # Or other flavours like :commonmark
    # |> MDEx.to_html!(flavour: :github)
    |> MDEx.to_html!(flavour: :commonmark)
    |> raw()
  end

  # def md_to_html(nil), do: safe_to_string("")

  def limit_text(text, limit) do
    if String.length(text) > limit do
      String.slice(text, 0..limit) <> "..."
    else
      text
    end
  end
end
