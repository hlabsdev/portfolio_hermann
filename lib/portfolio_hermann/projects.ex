defmodule PortfolioHermann.Projects do
  @moduledoc """
  Gestion des projets avec persistance dans des fichiers JSON.
  Version optimisée pour le déploiement en production.
  """

  # Chemins des fichiers avec fallback pour la prod
  @priv_dir :code.priv_dir(:portfolio_hermann) || "priv"
  @projects_path Path.join(@priv_dir, "projects.json")
  @techs_path Path.join(@priv_dir, "techs.json")

  @doc """
  Récupère la liste des projets avec gestion d'erreur améliorée.
  """
  def list_projects do
    case read_json_file(@projects_path) do
      {:ok, data} when is_list(data) -> data
      _ -> []
    end
  end

  @doc """
  Récupère la liste des technologies.
  """
  def list_techs do
    case read_json_file(@techs_path) do
      {:ok, %{"techs" => techs}} -> techs
      _ -> []
    end
  end

  @doc """
  Récupère la liste des tags.
  """
  def list_tags do
    case read_json_file(@techs_path) do
      {:ok, %{"tags" => tags}} -> tags
      _ -> []
    end
  end

  @doc """
  Incrémente le compteur de likes d'un projet.
  """
  def increment_like(id) do
    with {:ok, projects} <- read_json_file(@projects_path),
         true <- is_list(projects) do
      updated = update_project_stats(projects, id, "likes")
      write_json_file(@projects_path, updated)
    else
      _ -> {:error, :update_failed}
    end
  end

  @doc """
  Incrémente le compteur de vues d'un projet.
  """
  def increment_view(id) do
    with {:ok, projects} <- read_json_file(@projects_path),
         true <- is_list(projects) do
      updated = update_project_stats(projects, id, "views")
      write_json_file(@projects_path, updated)
    else
      _ -> {:error, :update_failed}
    end
  end

  @doc """
  Ajoute un nouveau projet.
  """
  def add_project(project) do
    with {:ok, projects} <- read_json_file(@projects_path),
         true <- is_list(projects) do
      write_json_file(@projects_path, [project | projects])
    else
      _ -> {:error, :add_failed}
    end
  end

  @doc """
  Met à jour un projet existant.
  """
  def update_project(id, updates) do
    with {:ok, projects} <- read_json_file(@projects_path),
         true <- is_list(projects) do
      updated = Enum.map(projects, &maybe_update_project(&1, id, updates))
      write_json_file(@projects_path, updated)
    else
      _ -> {:error, :update_failed}
    end
  end

  @doc """
  Supprime un projet.
  """
  def delete_project(id) do
    with {:ok, projects} <- read_json_file(@projects_path),
         true <- is_list(projects) do
      updated = Enum.reject(projects, &(&1["id"] == id))
      write_json_file(@projects_path, updated)
    else
      _ -> {:error, :delete_failed}
    end
  end

  # Fonctions privées

  defp read_json_file(path) do
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

  defp write_json_file(path, data) do
    case File.write(path, Jason.encode!(data, pretty: true)) do
      :ok ->
        :ok

      {:error, reason} ->
        IO.warn("Failed to write to #{path}: #{reason}")
        {:error, reason}
    end
  end

  defp update_project_stats(projects, id, field) do
    Enum.map(projects, fn project ->
      if project["id"] == id do
        update_in(project, ["stats", field], &(&1 + 1))
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
