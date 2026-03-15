defmodule Lobby.GamingTest do
  use Lobby.DataCase, async: true

  alias Lobby.Gaming
  import Lobby.Fixtures

  setup do
    club = create_club()
    user = create_user(club)
    pc = create_pc(club)
    tariff = create_tariff(club)
    %{club: club, user: user, pc: pc, tariff: tariff}
  end

  defp start(ctx, overrides \\ %{}) do
    attrs = Map.merge(%{
      duration_minutes: 60,
      total_price_tiyn: 50000,
      user_id: ctx.user.id,
      pc_id: ctx.pc.id,
      tariff_id: ctx.tariff.id,
      club_id: ctx.club.id
    }, overrides)
    {:ok, session} = Gaming.start_session(attrs)
    session
  end

  describe "sessions" do
    test "start_session creates active session", ctx do
      session = start(ctx)
      assert session.status == "active"
      assert session.duration_minutes == 60
    end

    test "end_session marks completed", ctx do
      session = start(ctx)
      {:ok, ended} = Gaming.end_session(session)
      assert ended.status == "ended"
      assert ended.ended_at != nil
    end

    test "extend_session adds minutes", ctx do
      session = start(ctx)
      {:ok, extended} = Gaming.extend_session(session, 30)
      assert extended.duration_minutes == 90
    end

    test "pause and resume session", ctx do
      session = start(ctx)
      {:ok, paused} = Gaming.pause_session(session)
      assert paused.status == "paused"
      assert paused.paused_at != nil

      {:ok, resumed} = Gaming.resume_session(paused)
      assert resumed.status == "active"
      assert resumed.paused_at == nil
    end

    test "move_session changes PC", ctx do
      session = start(ctx)
      new_pc = create_pc(ctx.club)
      {:ok, moved} = Gaming.move_session(session, new_pc.id)
      assert moved.pc_id == new_pc.id
    end

    test "add_free_time increases duration", ctx do
      session = start(ctx)
      {:ok, updated} = Gaming.add_free_time(session, 15)
      assert updated.duration_minutes == 75
    end

    test "remaining_seconds returns positive value", ctx do
      session = start(ctx)
      remaining = Gaming.remaining_seconds(session)
      assert remaining > 0
      assert remaining <= 3600
    end

    test "get_active_session_for_pc", ctx do
      session = start(ctx)
      found = Gaming.get_active_session_for_pc(ctx.pc.id)
      assert found.id == session.id
    end

    test "list_sessions with filters", ctx do
      start(ctx)
      sessions = Gaming.list_sessions(ctx.club.id, status: "active")
      assert length(sessions) == 1

      sessions = Gaming.list_sessions(ctx.club.id, status: "completed")
      assert length(sessions) == 0
    end

    test "list_user_sessions", ctx do
      start(ctx)
      sessions = Gaming.list_user_sessions(ctx.user.id)
      assert length(sessions) == 1
    end
  end

  describe "games" do
    test "CRUD game", ctx do
      game = create_game(ctx.club, %{name: "Test Game"})
      assert game.name == "Test Game"

      {:ok, updated} = Gaming.update_game(game, %{name: "Updated"})
      assert updated.name == "Updated"

      {:ok, _} = Gaming.delete_game(updated)
      assert Gaming.get_game(game.id) == nil
    end

    test "list_games returns active only", ctx do
      create_game(ctx.club, %{name: "Active", exe_name: "a.exe"})
      create_game(ctx.club, %{name: "Inactive", exe_name: "b.exe", is_active: false})
      games = Gaming.list_games(ctx.club.id)
      assert length(games) == 1
    end
  end
end
