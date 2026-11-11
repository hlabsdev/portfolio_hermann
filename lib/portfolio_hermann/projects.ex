defmodule PortfolioHermann.Projects do
  @moduledoc """
  Gestion des projets avec persistance dans des fichiers JSON.
  Version optimisée pour le déploiement en production.
  """

  # Fly.io's root filesystem is replaced during deploys. Point PORTFOLIO_DATA_DIR
  # at a mounted volume in production; local development keeps using priv/.
  def data_dir do
    case System.get_env("PORTFOLIO_DATA_DIR") do
      nil -> to_string(:code.priv_dir(:portfolio_hermann))
      "" -> to_string(:code.priv_dir(:portfolio_hermann))
      path -> Path.expand(path)
    end
  end

  def uploads_dir, do: Path.join(data_dir(), "uploads")

  defp data_path(filename), do: Path.join(data_dir(), filename)

  @doc """
  Récupère la liste des projets avec gestion d'erreur améliorée.
  """
  def list_projects do
    case read_json_file(data_path("projects.json"), Path.join(:code.priv_dir(:portfolio_hermann), "projects.json")) do
      {:ok, data} when is_list(data) -> data
      _ -> []
    end
  end

  @doc """
  Récupère la liste des technologies.
  """
  def list_techs do
    case read_json_file(data_path("techs.json"), Path.join(:code.priv_dir(:portfolio_hermann), "techs.json")) do
      {:ok, %{"techs" => techs}} -> techs
      _ -> []
    end
  end

  @doc """
  Récupère la liste des tags.
  """
  def list_tags do
    case read_json_file(data_path("techs.json"), Path.join(:code.priv_dir(:portfolio_hermann), "techs.json")) do
      {:ok, %{"tags" => tags}} -> tags
      _ -> []
    end
  end

  def list_experiences do
    seed = Path.join(:code.priv_dir(:portfolio_hermann), "experiences.json")

    case read_json_file(data_path("experiences.json"), seed) do
      {:ok, data} when is_map(data) -> data
      _ -> %{}
    end
  end

  def save_experiences(experiences) when is_map(experiences) do
    path = data_path("experiences.json")

    :global.trans({{__MODULE__, path}, self()}, fn ->
      write_json_file_unlocked(path, experiences)
    end)
  end

  @doc """
  Incrémente le compteur de likes d'un projet.
  """
  def increment_like(id) do
    update_projects(&update_project_stats(&1, id, "likes"), :update_failed)
  end

  @doc """
  Incrémente le compteur de vues d'un projet.
  """
  def increment_view(id) do
    update_projects(&update_project_stats(&1, id, "views"), :update_failed)
  end

  @doc """
  Ajoute un nouveau projet.
  """
  def add_project(project) do
    update_projects(&[project | &1], :add_failed)
  end

  @doc """
  Met à jour un projet existant.
  """
  def update_project(id, updates) do
    update_projects(&Enum.map(&1, fn project -> maybe_update_project(project, id, updates) end), :update_failed)
  end

  @doc """
  Supprime un projet.
  """
  def delete_project(id) do
    update_projects(&Enum.reject(&1, fn project -> project["id"] == id end), :delete_failed)
  end

  # Fonctions privées

  defp read_json_file(path, seed_path) do
    path = ensure_seed_file(path, seed_path)
    case File.read(path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, data} ->
            {:ok, data}

          error ->
            IO.warn("Failed to decode JSON from #{path}: #{inspect(error)}")
            error
        end

      {:error, reason} ->
        IO.warn("Could not read file #{path}: #{reason}")
        {:error, reason}
    end
  end

  defp update_projects(update_fun, failure) do
    path = data_path("projects.json")
    :global.trans({{__MODULE__, path}, self()}, fn ->
      with {:ok, projects} <- read_json_file(path, Path.join(:code.priv_dir(:portfolio_hermann), "projects.json")),
           true <- is_list(projects) do
        write_json_file_unlocked(path, update_fun.(projects))
      else
        _ -> {:error, failure}
      end
    end)
  end

  defp write_json_file_unlocked(path, data) do
    with :ok <- File.mkdir_p(Path.dirname(path)),
         :ok <- atomic_write(path, Jason.encode!(data, pretty: true)) do
      :ok
    else
      {:error, reason} ->
        IO.warn("Failed to write to #{path}: #{reason}")
        {:error, reason}
    end
  end

  defp atomic_write(path, content) do
    temp_path = path <> ".tmp.#{System.unique_integer([:positive])}"
    with :ok <- File.write(temp_path, content, [:binary, :sync]),
         :ok <- File.rename(temp_path, path),
         do: :ok
  end

  defp ensure_seed_file(path, seed_path) do
    if File.exists?(path) do
      path
    else
      with :ok <- File.mkdir_p(Path.dirname(path)),
           {:ok, contents} <- File.read(seed_path),
           :ok <- atomic_write(path, contents) do
        path
      else
        _ -> seed_path
      end
    end
  end

  defp update_project_stats(projects, id, field) do
    Enum.map(projects, fn project ->
      if project["id"] == id do
        stats = Map.get(project, "stats", %{})
        Map.put(project, "stats", Map.put(stats, field, Map.get(stats, field, 0) + 1))
      else
        project
      end
    end)
  end

  defp maybe_update_project(project, id, updates) do
    if project["id"] == id do
      Map.merge(project, updates)
    else
      project
    end
  end
end
