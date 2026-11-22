defmodule PortfolioHermann.Articles do
  @moduledoc """
  Gestion des articles Markdown, persistés sur le volume de données du site.

  Un article possède trois états, dérivés de `published` et `published_at` :

    * `"draft"` : `published` à `false`, jamais visible publiquement ;
    * `"scheduled"` : `published` à `true` et `published_at` dans le futur ;
    * `"published"` : `published` à `true` et `published_at` absent ou passé.

  `save/1` accepte un statut explicite (`"status"`), ou à défaut les champs
  historiques `"published"` / `"published_at"`. Enregistrer un article en
  `"published"` sans nouvelle date force la publication immédiate, même si
  l'article était auparavant programmé dans le futur.
  """

  alias PortfolioHermann.Projects

  @statuses ~w(draft scheduled published)

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

  @doc """
  Publie immédiatement l'article `id` : `published` à `true`, `published_at` à
  maintenant et `updated_at` rafraîchi.
  """
  def publish_now(id) do
    update_article(id, fn article, now ->
      Map.merge(article, %{"published" => true, "published_at" => now, "updated_at" => now})
    end)
  end

  @doc """
  Repasse l'article `id` en brouillon : `published` à `false`, `published_at`
  effacé et `updated_at` rafraîchi.
  """
  def unpublish(id) do
    update_article(id, fn article, now ->
      Map.merge(article, %{"published" => false, "published_at" => nil, "updated_at" => now})
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
      title == "" ->
        {:error, :title_required}

      body == "" ->
        {:error, :body_required}

      slug == "" ->
        {:error, :slug_required}

      Enum.any?(articles, &(&1["slug"] == slug and &1["id"] != id)) ->
        {:error, :slug_taken}

      true ->
        existing = Enum.find(articles, &(&1["id"] == id)) || %{}
        now = DateTime.utc_now() |> DateTime.truncate(:second)
        now_iso = DateTime.to_iso8601(now)

        with {:ok, status} <- resolve_status(attrs),
             {:ok, published, published_at} <- resolve_publication(status, attrs, existing, now) do
          article = %{
            "id" => id,
            "title" => title,
            "slug" => slug,
            "summary" => attrs["summary"] |> value() |> String.trim(),
            "body" => body,
            "tags" => attrs["tags"] || [],
            "cover_url" => blank_to_nil(attrs["cover_url"]),
            "published" => published,
            "published_at" => published_at,
            "created_at" => existing["created_at"] || now_iso,
            "updated_at" => now_iso
          }

          {:ok, article}
        end
    end
  end

  # Statut explicite (`"status"`) prioritaire, sinon compatibilité avec les
  # appels historiques qui passaient uniquement `"published"`.
  defp resolve_status(attrs) do
    case attrs["status"] do
      nil -> {:ok, if(attrs["published"] == true, do: "published", else: "draft")}
      status when status in @statuses -> {:ok, status}
      _ -> {:error, :invalid_status}
    end
  end

  # draft : jamais publié.
  defp resolve_publication("draft", _attrs, _existing, _now), do: {:ok, false, nil}

  # scheduled : une date future est obligatoire.
  defp resolve_publication("scheduled", attrs, _existing, now) do
    case parse_timestamp(attrs["published_at"]) do
      :none ->
        {:error, :published_at_required}

      {:error, _reason} ->
        {:error, :published_at_invalid}

      {:ok, datetime} ->
        if DateTime.compare(datetime, now) == :gt do
          {:ok, true, iso8601(datetime)}
        else
          {:error, :published_at_in_past}
        end
    end
  end

  # published : publication immédiate par défaut. Une date future explicitement
  # fournie reste une programmation (cohérence avec la règle "scheduled"), mais
  # une date absente ou passée publie maintenant : c'est ce qui publie
  # immédiatement un article auparavant programmé. En revanche, éditer un
  # article déjà publié conserve sa date de publication d'origine.
  defp resolve_publication("published", attrs, existing, now) do
    case parse_timestamp(attrs["published_at"]) do
      :none ->
        {:ok, true, existing_publication_date(existing, now)}

      {:error, _reason} ->
        {:error, :published_at_invalid}

      {:ok, datetime} ->
        if DateTime.compare(datetime, now) == :gt do
          {:ok, true, iso8601(datetime)}
        else
          {:ok, true, existing_publication_date(existing, now)}
        end
    end
  end

  # Conserve la date de publication d'un article déjà publié lors d'une simple
  # édition ; un brouillon ou un article programmé est publié "maintenant".
  defp existing_publication_date(%{"published" => true, "published_at" => published_at}, now) do
    if is_nil(published_at) or publication_due?(published_at),
      do: published_at,
      else: iso8601(now)
  end

  defp existing_publication_date(_existing, now), do: iso8601(now)

  defp update_article(id, update_fun) do
    path = data_path()

    :global.trans({{__MODULE__, path}, self()}, fn ->
      with {:ok, articles} <- read_articles(),
           {:ok, article} <- find_article(articles, id) do
        now = now_iso8601()
        updated = update_fun.(article, now)

        with :ok <- write_articles(upsert(articles, updated)) do
          {:ok, updated}
        end
      end
    end)
  end

  defp find_article(articles, id) do
    case Enum.find(articles, &(&1["id"] == id)) do
      nil -> {:error, :not_found}
      article -> {:ok, article}
    end
  end

  defp slugify_if_blank("", title), do: slugify(title)
  defp slugify_if_blank(slug, _title), do: slug

  defp upsert(articles, article) do
    if Enum.any?(articles, &(&1["id"] == article["id"])) do
      Enum.map(articles, fn existing ->
        if existing["id"] == article["id"], do: article, else: existing
      end)
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

  defp parse_timestamp(value) when is_binary(value) do
    case String.trim(value) do
      "" ->
        :none

      trimmed ->
        with {:error, _} <- DateTime.from_iso8601(trimmed) do
          case NaiveDateTime.from_iso8601(trimmed) do
            {:ok, naive} -> {:ok, DateTime.from_naive!(naive, "Etc/UTC")}
            _ -> {:error, :invalid}
          end
        else
          {:ok, datetime, _offset} -> {:ok, DateTime.truncate(datetime, :second)}
        end
    end
  end

  defp parse_timestamp(_value), do: :none

  defp now_iso8601, do: iso8601(DateTime.utc_now())
  defp iso8601(datetime), do: datetime |> DateTime.truncate(:second) |> DateTime.to_iso8601()

  @doc """
  Indique si un article publie est visible : `true` quand la date de publication est
  absente ou passee, `false` pour un article programme dans le futur.
  """
  def publication_due?(nil), do: true

  def publication_due?(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> DateTime.compare(datetime, DateTime.utc_now()) != :gt
      _ -> false
    end
  end
end
