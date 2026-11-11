defmodule PortfolioHermannWeb.ArticleMediaController do
  use PortfolioHermannWeb, :controller

  alias PortfolioHermann.Articles

  @max_bytes 8_000_000

  def create(conn, %{"file" => %Plug.Upload{} = upload} = params) do
    with :ok <- authorize(conn),
         {:ok, extension, mime} <- image_type(upload),
         {:ok, %{size: size}} when size <= @max_bytes <- File.stat(upload.path),
         :ok <- validate_image(upload.path, extension),
         :ok <- File.mkdir_p(Articles.media_dir()) do
      filename = "#{UUID.uuid4()}#{extension}"
      destination = Path.join(Articles.media_dir(), filename)

      case File.cp(upload.path, destination) do
        :ok ->
          url = "/article-media/#{filename}"
          alt = params["alt"] || ""
          json(conn, %{ok: true, url: url, markdown: "![#{alt}](#{url})", content_type: mime, size: size})

        {:error, _reason} ->
          send_error(conn, 500, "upload_failed", "The image could not be stored")
      end
    else
      {:error, :token_not_configured} -> send_error(conn, 503, "not_configured", "Publishing API is not configured")
      {:error, :unauthorized} -> send_error(conn, 401, "unauthorized", "Invalid bearer token")
      {:error, :unsupported_image} -> send_error(conn, 415, "unsupported_image", "Use JPEG, PNG, GIF, or WebP")
      {:error, :invalid_image} -> send_error(conn, 415, "invalid_image", "The file content does not match an accepted image")
      {:ok, %{size: size}} when size > @max_bytes -> send_error(conn, 413, "file_too_large", "Image files must be 8 MB or smaller")
      _ -> send_error(conn, 400, "invalid_upload", "Provide an image in the multipart file field")
    end
  end

  def create(conn, _params), do: send_error(conn, 400, "missing_file", "Provide an image in the multipart file field")

  def show(conn, %{"filename" => filename}) do
    if Regex.match?(~r/\A[a-f0-9-]+\.(jpg|jpeg|png|gif|webp)\z/i, filename) do
      path = Path.join(Articles.media_dir(), filename)

      if File.regular?(path) do
        conn
        |> put_resp_content_type(MIME.from_path(path))
        |> put_resp_header("cache-control", "public, max-age=31536000, immutable")
        |> put_resp_header("x-content-type-options", "nosniff")
        |> send_file(200, path)
      else
        send_resp(conn, 404, "Not found")
      end
    else
      send_resp(conn, 404, "Not found")
    end
  end

  defp image_type(%Plug.Upload{filename: filename}) do
    extension = filename |> Path.extname() |> String.downcase()

    case extension do
      ".jpg" -> {:ok, extension, "image/jpeg"}
      ".jpeg" -> {:ok, extension, "image/jpeg"}
      ".png" -> {:ok, extension, "image/png"}
      ".gif" -> {:ok, extension, "image/gif"}
      ".webp" -> {:ok, extension, "image/webp"}
      _ -> {:error, :unsupported_image}
    end
  end

  defp validate_image(path, extension) do
    case File.read(path) do
      {:ok, bytes} ->
        valid? =
          case extension do
            ext when ext in [".jpg", ".jpeg"] -> has_prefix?(bytes, <<255, 216, 255>>)
            ".png" -> has_prefix?(bytes, <<137, 80, 78, 71, 13, 10, 26, 10>>)
            ".gif" -> Enum.any?(["GIF87a", "GIF89a"], &has_prefix?(bytes, &1))
            ".webp" -> byte_size(bytes) >= 12 and binary_part(bytes, 0, 4) == "RIFF" and binary_part(bytes, 8, 4) == "WEBP"
          end

        if valid?, do: :ok, else: {:error, :invalid_image}

      _ ->
        {:error, :invalid_image}
    end
  end

  defp has_prefix?(bytes, prefix) when byte_size(bytes) >= byte_size(prefix) do
    binary_part(bytes, 0, byte_size(prefix)) == prefix
  end

  defp has_prefix?(_bytes, _prefix), do: false

  defp authorize(conn) do
    case {System.fetch_env("BLOG_PUBLISH_TOKEN"), get_req_header(conn, "authorization")} do
      {{:ok, expected}, ["Bearer " <> token]} when expected != "" ->
        if Plug.Crypto.secure_compare(expected, token), do: :ok, else: {:error, :unauthorized}

      {{:ok, expected}, _headers} when expected != "" -> {:error, :unauthorized}
      _ -> {:error, :token_not_configured}
    end
  end

  defp send_error(conn, status, code, message) do
    conn |> put_status(status) |> json(%{ok: false, error: %{code: code, message: message}})
  end
end
