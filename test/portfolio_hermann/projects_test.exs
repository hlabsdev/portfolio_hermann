defmodule PortfolioHermann.ProjectsTest do
  # Tests fichiers : on ne peut pas partager un PORTFOLIO_DATA_DIR temporaire
  # entre plusieurs tests exécutés en parallèle.
  use ExUnit.Case, async: false

  alias PortfolioHermann.Projects

  setup do
    previous = System.get_env("PORTFOLIO_DATA_DIR")

    dir =
      Path.join(
        System.tmp_dir!(),
        "portfolio_hermann_projects_#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(dir)
    System.put_env("PORTFOLIO_DATA_DIR", dir)
    Projects.clear_cache()

    on_exit(fn ->
      Projects.clear_cache()
      restore_data_dir_env(previous)
      File.rm_rf!(dir)
    end)

    %{dir: dir}
  end

  defp restore_data_dir_env(nil), do: System.delete_env("PORTFOLIO_DATA_DIR")
  defp restore_data_dir_env(value), do: System.put_env("PORTFOLIO_DATA_DIR", value)

  defp projects_path(dir), do: Path.join(dir, "projects.json")

  defp sample_project(id, overrides \\ %{}) do
    Map.merge(
      %{
        "id" => id,
        "title" => "Projet #{id}",
        "tags" => ["tag"],
        "techs" => ["Elixir"],
        "year" => 2024,
        "stats" => %{"views" => 0, "likes" => 0}
      },
      overrides
    )
  end

  defp write_projects!(dir, projects) do
    File.write!(projects_path(dir), Jason.encode!(projects, pretty: true))
  end

  describe "data_dir/0" do
    test "respecte PORTFOLIO_DATA_DIR", %{dir: dir} do
      assert Projects.data_dir() == Path.expand(dir)
      assert Projects.uploads_dir() == Path.join(Path.expand(dir), "uploads")
    end
  end

  describe "cache de lecture JSON" do
    test "seed projects.json depuis priv/ puis met la lecture en cache", %{dir: dir} do
      refute File.exists?(projects_path(dir))

      projects = Projects.list_projects()

      assert is_list(projects)
      assert projects != []
      assert File.exists?(projects_path(dir))

      assert %{signature: {mtime, size, _inode}, data: ^projects} =
               Projects.cache_entry("projects.json")

      assert is_integer(mtime)
      assert is_integer(size)
    end

    test "une écriture via l'API met le cache à jour (write-through)", %{dir: dir} do
      projects = Projects.list_projects()
      project = sample_project("nouveau")
      assert :ok = Projects.add_project(project)

      updated = Projects.list_projects()
      assert length(updated) == length(projects) + 1
      assert Enum.any?(updated, &(&1["id"] == "nouveau"))
      assert %{data: ^updated} = Projects.cache_entry("projects.json")

      # Le fichier sur disque est bien à jour et lisible.
      on_disk = projects_path(dir) |> File.read!() |> Jason.decode!()
      assert on_disk == updated
    end

    test "invalide le cache quand le fichier change sur disque", %{dir: dir} do
      assert [_ | _] = Projects.list_projects()

      new_projects = [sample_project("externe-1"), sample_project("externe-2")]
      write_projects!(dir, new_projects)

      assert Projects.list_projects() == new_projects
    end

    test "clear_cache/0 vide les entrées du module", _context do
      assert [_ | _] = Projects.list_projects()
      assert Projects.cache_entry("projects.json") != nil
      assert :ok = Projects.clear_cache()
      assert Projects.cache_entry("projects.json") == nil
      # La lecture suivante repeuple le cache.
      assert [_ | _] = Projects.list_projects()
      assert Projects.cache_entry("projects.json") != nil
    end

    test "les écritures restent atomiques (pas de fichier temporaire résiduel)", %{dir: dir} do
      assert [_ | _] = Projects.list_projects()
      assert :ok = Projects.add_project(sample_project("atomique"))

      assert Path.wildcard(Path.join(dir, "*.tmp*")) == []
      assert {:ok, [_ | _]} = projects_path(dir) |> File.read!() |> Jason.decode()
    end
  end

  describe "list_techs/0 et list_tags/0" do
    test "partagent une seule lecture de techs.json", %{dir: dir} do
      techs = Projects.list_techs()
      tags = Projects.list_tags()

      assert is_list(techs) and techs != []
      assert is_list(tags) and tags != []
      assert File.exists?(Path.join(dir, "techs.json"))

      assert %{data: %{"techs" => ^techs, "tags" => ^tags}} = Projects.cache_entry("techs.json")
    end
  end

  describe "list_experiences/0 et save_experiences/1" do
    test "seed puis lecture des expériences", %{dir: dir} do
      experiences = Projects.list_experiences()

      assert is_map(experiences)
      assert is_map(experiences["profile"])
      assert File.exists?(Path.join(dir, "experiences.json"))
      assert %{data: ^experiences} = Projects.cache_entry("experiences.json")
    end

    test "save_experiences/1 écrit et invalide le cache", %{dir: dir} do
      experiences = Projects.list_experiences()
      updated = Map.put(experiences, "certifications", [])

      assert :ok = Projects.save_experiences(updated)
      assert Projects.list_experiences() == updated

      on_disk = Path.join(dir, "experiences.json") |> File.read!() |> Jason.decode!()
      assert on_disk == updated
    end
  end

  describe "mutations projets" do
    test "update_project/2 et delete_project/1 sont visibles immédiatement", _context do
      [first | _] = projects = Projects.list_projects()
      id = first["id"]

      assert :ok = Projects.update_project(id, %{"title" => "Titre modifié"})
      assert Enum.find(Projects.list_projects(), &(&1["id"] == id))["title"] == "Titre modifié"

      assert :ok = Projects.delete_project(id)
      refute Enum.any?(Projects.list_projects(), &(&1["id"] == id))
      assert length(Projects.list_projects()) == length(projects) - 1
    end

    test "increment_like/1 et increment_view/1 mettent à jour les stats", _context do
      [first | _] = Projects.list_projects()
      id = first["id"]
      likes = get_in(first, ["stats", "likes"]) || 0
      views = get_in(first, ["stats", "views"]) || 0

      assert :ok = Projects.increment_like(id)
      assert :ok = Projects.increment_view(id)

      updated = Enum.find(Projects.list_projects(), &(&1["id"] == id))
      assert updated["stats"]["likes"] == likes + 1
      assert updated["stats"]["views"] == views + 1
    end
  end

  describe "robustesse" do
    @tag :capture_log
    test "un JSON corrompu ne crashe pas et n'est pas mis en cache", %{dir: dir} do
      File.write!(projects_path(dir), "{ ceci n'est pas du json")

      assert Projects.list_projects() == []
      assert Projects.cache_entry("projects.json") == nil

      # Une correction externe est bien prise en compte ensuite.
      write_projects!(dir, [sample_project("reparé")])
      assert [%{"id" => "reparé"}] = Projects.list_projects()
    end

    test "un JSON valide mais de mauvaise forme renvoie une liste vide", %{dir: dir} do
      File.write!(projects_path(dir), Jason.encode!(%{"pas" => "une liste"}))
      assert Projects.list_projects() == []
    end
  end
end
