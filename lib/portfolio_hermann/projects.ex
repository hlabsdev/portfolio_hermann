defmodule PortfolioHermann.Projects do
  @path "priv/projects.json"

  def list_projects do
    case File.read(@path) do
      {:ok, content} -> Jason.decode!(content)
      _ -> []
    end
  end

  def increment_like(id) do
    projects = list_projects()
    updated_projects = Enum.map(projects, fn project ->
      if project["id"] == id do
        update_in(project, ["stats", "likes"], &(&1 + 1))
      else
        project
      end
    end)
    save_projects(updated_projects)
  end

  def increment_view(id) do
    projects = list_projects()
    updated_projects = Enum.map(projects, fn project ->
      if project["id"] == id do
        update_in(project, ["stats", "views"], &(&1 + 1))
      else
        project
      end
    end)
    save_projects(updated_projects)
  end

  def save_projects(projects) do
    File.write!(@path, Jason.encode!(projects, pretty: true))
  end

  def add_project(project) do
    projects = list_projects()
    updated = [project | projects]
    save_projects(updated)
  end

  def update_project(id, updates) do
    projects =
      list_projects()
      |> Enum.map(fn p -> if p["id"] == id, do: Map.merge(p, updates), else: p end)

    save_projects(projects)
  end

  def delete_project(id) do
    projects =
      list_projects()
      |> Enum.reject(fn p -> p["id"] == id end)

    save_projects(projects)
  end
end
