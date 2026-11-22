defmodule PortfolioHermannWeb.ArticleApiController do
  use PortfolioHermannWeb, :controller

  alias PortfolioHermann.Articles

  def upsert(conn, params) do
    with :ok <- authorize(conn),
         attrs when is_map(attrs) <- Map.get(params, "article", params),
         {:ok, attrs} <- prepare_article(attrs),
         {:ok, article} <- Articles.save(attrs) do
      json(conn, %{ok: true, article: article_response(article)})
    else
      {:error, :unauthorized} ->
        send_error(conn, 401, "unauthorized", "Invalid bearer token")

      {:error, :token_not_configured} ->
        send_error(conn, 503, "not_configured", "Publishing API is not configured")

      {:error, :invalid_status} ->
        send_error(conn, 422, "invalid_status", "status must be draft, scheduled, or published")

      {:error, :invalid_publish_at} ->
        send_error(
          conn,
          422,
          "invalid_publish_at",
          "published_at must be an ISO 8601 timestamp with timezone"
        )

      {:error, :scheduled_date_required} ->
        send_error(
          conn,
          422,
          "scheduled_date_required",
          "scheduled articles require published_at"
        )

      {:error, :scheduled_date_in_past} ->
        send_error(
          conn,
          422,
          "scheduled_date_in_past",
          "scheduled articles require a future published_at"
        )

      {:error, :published_at_required} ->
        send_error(
          conn,
          422,
          "scheduled_date_required",
          "scheduled articles require published_at"
        )

      {:error, :published_at_in_past} ->
        send_error(
          conn,
          422,
          "scheduled_date_in_past",
          "scheduled articles require a future published_at"
        )

      {:error, :published_at_invalid} ->
        send_error(
          conn,
          422,
          "invalid_publish_at",
          "published_at must be an ISO 8601 timestamp with timezone"
        )

      {:error, :title_required} ->
        send_error(conn, 422, "title_required", "title is required")

      {:error, :body_required} ->
        send_error(conn, 422, "body_required", "body_markdown is required")

      {:error, :slug_required} ->
        send_error(
          conn,
          422,
          "slug_required",
          "Provide a slug or a title that can be converted to a slug"
        )

      {:error, :slug_taken} ->
        send_error(conn, 409, "slug_taken", "That slug is already used by another article")

      _ ->
        send_error(conn, 400, "invalid_request", "Expected a JSON article object")
    end
  end

  def delete(conn, %{"slug" => slug}) do
    with :ok <- authorize(conn),
         %{"id" => id} <- Articles.get_by_slug(slug),
         :ok <- Articles.delete(id) do
      json(conn, %{ok: true, deleted: slug})
    else
      {:error, :unauthorized} ->
        send_error(conn, 401, "unauthorized", "Invalid bearer token")

      {:error, :token_not_configured} ->
        send_error(conn, 503, "not_configured", "Publishing API is not configured")

      nil ->
        send_error(conn, 404, "not_found", "Article not found")

      _ ->
        send_error(conn, 500, "delete_failed", "The article could not be deleted")
    end
  end

  defp prepare_article(attrs) do
    title = value(attrs["title"]) |> String.trim()
    body = value(attrs["body_markdown"] || attrs["body"]) |> String.trim()
    slug = value(attrs["slug"]) |> String.trim()
    slug = if slug == "", do: Articles.slugify(title), else: Articles.slugify(slug)
    status = attrs["status"] || if(attrs["published"] == true, do: "published", else: "draft")
    published_at = blank_to_nil(attrs["published_at"])

    cond do
      status not in ["draft", "scheduled", "published"] ->
        {:error, :invalid_status}

      not is_nil(published_at) and not valid_timestamp?(published_at) ->
        {:error, :invalid_publish_at}

      status == "scheduled" and is_nil(published_at) ->
        {:error, :scheduled_date_required}

      status == "scheduled" and not future_timestamp?(published_at) ->
        {:error, :scheduled_date_in_past}

      true ->
        existing = if slug == "", do: nil, else: Articles.get_by_slug(slug)

        {:ok,
         %{
           "id" => attrs["id"] || (existing && existing["id"]),
           "title" => title,
           "slug" => slug,
           "summary" => value(attrs["summary"]),
           "body" => body,
           "tags" => normalize_tags(attrs["tags"]),
           "cover_url" => value(attrs["cover_url"]),
           "status" => status,
           "published" => status in ["published", "scheduled"],
           # `published` sans date => Articles force la publication immédiate,
           # y compris pour un article auparavant programmé.
           "published_at" => if(status == "draft", do: nil, else: published_at)
         }}
    end
  end

  defp article_response(article) do
    Map.take(article, [
      "id",
      "title",
      "slug",
      "status",
      "summary",
      "tags",
      "cover_url",
      "published",
      "published_at",
      "updated_at"
    ])
    |> Map.put("status", Articles.status(article))
  end

  defp normalize_tags(tags) when is_list(tags),
    do:
      tags
      |> Enum.filter(&is_binary/1)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.uniq()

  defp normalize_tags(tags) when is_binary(tags),
    do: tags |> String.split(",") |> normalize_tags()

  defp normalize_tags(_), do: []

  defp authorize(conn) do
    case {System.fetch_env("BLOG_PUBLISH_TOKEN"), get_req_header(conn, "authorization")} do
      {{:ok, expected}, ["Bearer " <> token]} when expected != "" ->
        if Plug.Crypto.secure_compare(expected, token), do: :ok, else: {:error, :unauthorized}

      {{:ok, expected}, _headers} when expected != "" ->
        {:error, :unauthorized}

      _ ->
        {:error, :token_not_configured}
    end
  end

  defp valid_timestamp?(value), do: match?({:ok, _, _}, DateTime.from_iso8601(value))

  defp future_timestamp?(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> DateTime.compare(datetime, DateTime.utc_now()) == :gt
      _ -> false
    end
  end

  defp value(value) when is_binary(value), do: value
  defp value(_), do: ""

  defp blank_to_nil(raw) do
    case value(raw) |> String.trim() do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp send_error(conn, status, code, message) do
    conn
    |> put_status(status)
    |> json(%{ok: false, error: %{code: code, message: message}})
  end
end
