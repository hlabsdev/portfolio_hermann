defmodule PortfolioHermann.AnalyticsTest do
  use ExUnit.Case, async: false

  alias PortfolioHermann.Analytics

  @today ~D[2026-11-22]

  defp state(views \\ 0, visits \\ %{}), do: %{views: views, visits: visits}

  defp analytics_path(dir), do: Path.join(dir, "analytics.json")

  defp read_persisted!(dir) do
    dir |> analytics_path() |> File.read!() |> Jason.decode!()
  end

  defp start_analytics!(dir, flush_interval, id) do
    spec =
      Supervisor.child_spec(
        {Analytics, name: nil, data_dir: dir, flush_interval: flush_interval},
        id: id
      )

    start_supervised!(spec)
  end

  defp wait_until(fun, timeout, interval \\ 10) do
    deadline = System.monotonic_time(:millisecond) + timeout
    do_wait_until(fun, deadline, interval)
  end

  defp do_wait_until(fun, deadline, interval) do
    cond do
      fun.() -> true
      System.monotonic_time(:millisecond) > deadline -> false
      true -> Process.sleep(interval) && do_wait_until(fun, deadline, interval)
    end
  end

  describe "apply_view/3" do
    test "incrémente le total et le compteur du jour" do
      state = state() |> Analytics.apply_view("/projects", @today)

      assert state.views == 1
      assert state.visits[@today] == %{total: 1, paths: %{"/projects" => 1}}

      state = Analytics.apply_view(state, "/projects", @today)
      state = Analytics.apply_view(state, "/about", @today)

      assert state.views == 3
      assert state.visits[@today].total == 3
      assert state.visits[@today].paths == %{"/projects" => 2, "/about" => 1}
    end

    test "classe les vues par jour" do
      yesterday = Date.add(@today, -1)

      state =
        state()
        |> Analytics.apply_view("/", yesterday)
        |> Analytics.apply_view("/", @today)
        |> Analytics.apply_view("/projects", @today)

      assert state.visits[yesterday].total == 1
      assert state.visits[@today].total == 2
    end

    test "normalise les chemins (atomes de live_action) en chaînes" do
      state = state() |> Analytics.apply_view(:index, @today)

      assert state.visits[@today].paths == %{"index" => 1}
    end

    test "préserve les champs internes du serveur (dirty, timer...)" do
      state = Map.merge(state(), %{dirty: true, flush_timer: nil})
      state = Analytics.apply_view(state, "/", @today)

      assert state.dirty == true
      assert state.flush_timer == nil
    end
  end

  describe "encode_state/1 et decode_state/1" do
    test "aller-retour JSON" do
      state =
        state(42)
        |> Analytics.apply_view("/projects", @today)
        |> Analytics.apply_view("/", Date.add(@today, -3))

      content = Analytics.encode_state(state)
      assert is_binary(content)
      assert {:ok, decoded} = Analytics.decode_state(content)
      assert decoded.views == 44
      assert decoded.visits == state.visits
    end

    test "decode_state/1 renvoie une erreur sur du JSON corrompu" do
      assert {:error, _reason} = Analytics.decode_state("{ pas du json")
      assert {:error, :invalid_shape} = Analytics.decode_state(Jason.encode!(%{"views" => "x"}))
    end

    test "decode_state/1 ignore les jours invalides sans perdre les autres" do
      content =
        Jason.encode!(%{
          "views" => 3,
          "visits" => %{
            "pas-une-date" => %{"total" => 5, "paths" => %{"/" => 5}},
            "2026-11-21" => %{"total" => 2, "paths" => %{"/projects" => 2}},
            "2026-11-20" => %{"total" => "invalide", "paths" => %{}}
          }
        })

      assert {:ok, decoded} = Analytics.decode_state(content)
      assert decoded.views == 3
      assert decoded.visits == %{~D[2026-11-21] => %{total: 2, paths: %{"/projects" => 2}}}
    end

    test "encode_state/1 gère des compteurs nil" do
      content =
        Analytics.encode_state(%{
          views: 1,
          visits: %{@today => %{total: 1, paths: %{"/" => nil}}}
        })

      assert {:ok, decoded} = Analytics.decode_state(content)
      assert decoded.visits[@today].paths == %{"/" => 0}
    end
  end

  describe "prune_visits/3" do
    test "conserve les max_days derniers jours et le total de vues" do
      visits =
        for offset <- 0..9, into: %{} do
          {Date.add(@today, -offset), %{total: offset + 1, paths: %{}}}
        end

      state = %{views: 100, visits: visits}
      pruned = Analytics.prune_visits(state.visits, @today, 5)

      assert map_size(pruned) == 5
      assert Map.has_key?(pruned, @today)
      assert Map.has_key?(pruned, Date.add(@today, -4))
      refute Map.has_key?(pruned, Date.add(@today, -5))
      # Le total de vues reste inchangé.
      pruned_state = %{state | visits: pruned}
      assert Analytics.decode_state(Analytics.encode_state(pruned_state)) == {:ok, pruned_state}
    end

    test "laisse les visites courtes intactes" do
      visits = %{@today => %{total: 1, paths: %{"/" => 1}}}
      assert Analytics.prune_visits(visits, @today, 365) == visits
    end

    test "max_days invalide => visites inchangées" do
      visits = %{@today => %{total: 1, paths: %{"/" => 1}}}
      assert Analytics.prune_visits(visits, @today, 0) == visits
      assert Analytics.prune_visits(visits, @today, -1) == visits
    end
  end

  describe "popular_pages/2" do
    test "trie par vues décroissantes" do
      assert Analytics.popular_pages(%{"/a" => 1, "/b" => 10, "/c" => 5}) == [
               {"/b", 10},
               {"/c", 5},
               {"/a", 1}
             ]
    end

    test "limite à 5 entrées par défaut" do
      paths = Map.new(1..10, fn i -> {"/page-#{i}", i} end)
      assert length(Analytics.popular_pages(paths)) == 5
      assert Analytics.popular_pages(paths, 2) == [{"/page-10", 10}, {"/page-9", 9}]
    end

    test "gère les nil et les clés atom" do
      assert Analytics.popular_pages(%{:index => 2, "/nil" => nil}) == [
               {"index", 2},
               {"/nil", 0}
             ]
    end

    test "gère l'absence de données" do
      assert Analytics.popular_pages(%{}) == []
      assert Analytics.popular_pages(nil) == []
    end
  end

  describe "persistance par lots" do
    setup do
      dir =
        Path.join(
          System.tmp_dir!(),
          "portfolio_hermann_analytics_#{System.unique_integer([:positive])}"
        )

      File.mkdir_p!(dir)
      on_exit(fn -> File.rm_rf!(dir) end)
      %{dir: dir}
    end

    test "n'écrit pas à chaque vue puis flush automatiquement", %{dir: dir} do
      pid = start_analytics!(dir, 300, :analytics_auto_flush)

      Analytics.increment_page_view("/projects", pid)
      Analytics.increment_page_view("/about", pid)

      # Le cast est asynchrone : on attend qu'il soit traité...
      assert wait_until(fn -> Analytics.get_stats(pid).views == 2 end, 1_000)
      # ...mais l'écriture disque est différée (batch), pas synchrone.
      refute File.exists?(analytics_path(dir))

      assert wait_until(fn -> File.exists?(analytics_path(dir)) end, 2_000)
      persisted = read_persisted!(dir)
      assert persisted["views"] == 2
      assert persisted["visits"][Date.to_iso8601(Date.utc_today())]["total"] == 2
    end

    test "flush/1 force l'écriture immédiate", %{dir: dir} do
      pid = start_analytics!(dir, 60_000, :analytics_manual_flush)

      Analytics.increment_page_view("/", pid)
      assert :ok = Analytics.flush(pid)

      assert File.exists?(analytics_path(dir))
      assert read_persisted!(dir)["views"] == 1
      assert Analytics.get_stats(pid).views == 1
    end

    test "l'arrêt propre (terminate/2) vide les vues en attente", %{dir: dir} do
      pid = start_analytics!(dir, 60_000, :analytics_terminate_flush)

      Analytics.increment_page_view("/projects", pid)
      Analytics.increment_page_view("/", pid)
      assert wait_until(fn -> Analytics.get_stats(pid).views == 2 end, 1_000)

      :ok = stop_supervised(:analytics_terminate_flush)

      assert File.exists?(analytics_path(dir))
      assert read_persisted!(dir)["views"] == 2
    end

    test "get_stats/1 reste cohérent avant écriture disque", %{dir: dir} do
      pid = start_analytics!(dir, 60_000, :analytics_stats_coherent)

      Analytics.increment_page_view("/", pid)
      stats = Analytics.get_stats(pid)

      assert stats.views == 1
      assert stats.visits[Date.utc_today()].paths == %{"/" => 1}
      refute File.exists?(analytics_path(dir))

      # Nettoyage déterministe (le terminate du test précédent écrirait le
      # fichier après le rm_rf du on_exit).
      :ok = stop_supervised(:analytics_stats_coherent)
    end
  end
end
