defmodule PortfolioHermann.Articles do
  @moduledoc "Gestion des articles Markdown, persistés sur le volume de données du site."

  alias PortfolioHermann.Projects

  def list do
    case read_articles() do
      {:ok, articles} when is_list(articles) -> articles
      _ -> []
    end
  end

  def list_published do
    list()
    |> Enum.filter(&(&1["published"] == true and publication_due?(&1["published_at"])))
    |> Enum.sort_by(& &1["published_at"], :desc)
  end

  def get_by_slug(slug) do
    Enum.find(list(), &(&1["slug"] == slug))
  end

  def save(attrs) when is_map(attrs) do
    path = data_path()

    :global.trans({{__MODULE__, path}, self()}, fn ->
      with {:ok, articles} <- read_articles(),
           {:ok, article} <- normalize(attrs, articles),
           updated <- upsert(articles, article),
           :ok <- write_articles(updated) do
        {:ok, article}
      end
    end)
  end

  def delete(id) do
    path = data_path()

    :global.trans({{__MODULE__, path}, self()}, fn ->
      with {:ok, articles} <- read_articles(),
           :ok <- write_articles(Enum.reject(articles, &(&1["id"] == id))) do
        :ok
      end
    end)
  end

  def slugify(title) do
    title
    |> String.normalize(:nfd)
    |> String.replace(~r/\p{Mn}/u, "")
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
  end

  def reading_time(body) do
    words = body |> String.split(~r/\s+/, trim: true) |> length()
    max(1, div(words + 199, 200))
  end

  def status(%{"published" => false}), do: "draft"
  def status(article) do
    if publication_due?(article["published_at"]), do: "published", else: "scheduled"
  end

  def media_dir, do: Path.join(Projects.data_dir(), "uploads/articles")

  defp normalize(attrs, articles) do
    title = attrs["title"] |> value() |> String.trim()
    body = attrs["body"] |> value() |> String.trim()
    id = attrs["id"] || UUID.uuid4()
    slug = attrs["slug"] |> value() |> String.trim() |> slugify_if_blank(title)

    cond do
      title == "" -> {:error, :title_required}
      body == "" -> {:error, :body_required}
      slug == "" -> {:error, :slug_required}
      Enum.any?(articles, &(&1["slug"] == slug and &1["id"] != id)) -> {:error, :slug_taken}
      true ->
        existing = Enum.find(articles, &(&1["id"] == id)) || %{}
        now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
        published = attrs["published"] == true

        article = %{
          "id" => id,
          "title" => title,
          "slug" => slug,
          "summary" => attrs["summary"] |> value() |> String.trim(),
          "body" => body,
          "tags" => attrs["tags"] || [],
          "cover_url" => blank_to_nil(attrs["cover_url"]),
          "published" => published,
          "published_at" => publication_time(attrs, existing, published, now),
          "created_at" => existing["created_at"] || now,
          "updated_at" => now
        }

        {:ok, article}
    end
  end

  defp slugify_if_blank("", title), do: slugify(title)
  defp slugify_if_blank(slug, _title), do: slug

  defp upsert(articles, article) do
    if Enum.any?(articles, &(&1["id"] == article["id"])) do
      Enum.map(articles, fn existing -> if existing["id"] == article["id"], do: article, else: existing end)
    else
      [article | articles]
    end
  end

  defp read_articles do
    path = data_path()
    seed = Path.join(:code.priv_dir(:portfolio_hermann), "articles.json")

    if not File.exists?(path) do
      with :ok <- File.mkdir_p(Path.dirname(path)),
           {:ok, contents} <- File.read(seed),
           :ok <- atomic_write(path, contents) do
        read_json(path)
      else
        {:error, reason} -> {:error, reason}
      end
    else
      read_json(path)
    end
  end

  defp read_json(path) do
    with {:ok, content} <- File.read(path),
         {:ok, articles} <- Jason.decode(content),
         true <- is_list(articles) do
      {:ok, articles}
    else
      _ -> {:error, :invalid_articles}
    end
  end

  defp write_articles(articles) do
    path = data_path()

    with :ok <- File.mkdir_p(Path.dirname(path)),
         :ok <- atomic_write(path, Jason.encode!(articles, pretty: true)) do
      :ok
    end
  end

  defp atomic_write(path, contents) do
    temp_path = path <> ".tmp.#{System.unique_integer([:positive])}"

    with :ok <- File.write(temp_path, contents, [:binary, :sync]),
         :ok <- File.rename(temp_path, path) do
      :ok
    end
  end

  defp data_path, do: Path.join(Projects.data_dir(), "articles.json")
  defp value(value) when is_binary(value), do: value
  defp value(_), do: ""
  defp blank_to_nil(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end
  defp blank_to_nil(_), do: nil

  defp publication_time(_attrs, _existing, false, _now), do: nil

  defp publication_time(attrs, existing, true, now) do
    case blank_to_nil(attrs["published_at"]) do
      nil -> existing["published_at"] || now
      value -> value
    end
  end

  defp publication_due?(nil), do: true

  defp publication_due?(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> DateTime.compare(datetime, DateTime.utc_now()) != :gt
      _ -> false
    end
  end
end
