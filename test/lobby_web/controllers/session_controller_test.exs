defmodule LobbyWeb.SessionControllerTest do
  use LobbyWeb.ConnCase, async: true

  import Lobby.Fixtures

  setup %{conn: conn} do
    club = create_club()
    user = create_user(club)
    pc = create_pc(club)
    tariff = create_tariff(club)
    conn = conn |> put_req_header("content-type", "application/json") |> auth_conn(user)
    %{conn: conn, club: club, user: user, pc: pc, tariff: tariff}
  end

  defp start_session(conn, pc, tariff) do
    post(conn, "/api/sessions", %{
      tariff_id: tariff.id,
      duration_minutes: 60,
      pc_token: pc.pc_token
    })
  end

  test "create session", %{conn: conn, pc: pc, tariff: tariff} do
    resp = start_session(conn, pc, tariff)
    assert %{"session" => session} = json_response(resp, 201)
    assert session["status"] == "active"
  end

  test "show session", %{conn: conn, pc: pc, tariff: tariff} do
    %{"session" => %{"id" => id}} = json_response(start_session(conn, pc, tariff), 201)
    conn = get(conn, "/api/sessions/#{id}")
    assert %{"session" => _, "remaining_seconds" => _} = json_response(conn, 200)
  end

  test "end session", %{conn: conn, pc: pc, tariff: tariff} do
    %{"session" => %{"id" => id}} = json_response(start_session(conn, pc, tariff), 201)
    conn = post(conn, "/api/sessions/#{id}/end")
    assert %{"session" => %{"status" => "ended"}} = json_response(conn, 200)
  end

  test "pause and resume session", %{conn: conn, pc: pc, tariff: tariff} do
    %{"session" => %{"id" => id}} = json_response(start_session(conn, pc, tariff), 201)

    conn_pause = post(conn, "/api/sessions/#{id}/pause")
    assert %{"session" => %{"status" => "paused"}} = json_response(conn_pause, 200)

    conn_resume = post(conn, "/api/sessions/#{id}/resume")
    assert %{"session" => %{"status" => "active"}} = json_response(conn_resume, 200)
  end

  test "move session to another PC", %{conn: conn, club: club, pc: pc, tariff: tariff} do
    %{"session" => %{"id" => id}} = json_response(start_session(conn, pc, tariff), 201)
    new_pc = create_pc(club)
    conn = post(conn, "/api/sessions/#{id}/move", %{pc_id: new_pc.id})
    assert %{"session" => %{"pc_id" => new_pc_id}} = json_response(conn, 200)
    assert new_pc_id == new_pc.id
  end

  test "add_time to session", %{conn: conn, pc: pc, tariff: tariff} do
    %{"session" => %{"id" => id}} = json_response(start_session(conn, pc, tariff), 201)
    conn = post(conn, "/api/sessions/#{id}/add_time", %{minutes: 30})
    assert %{"session" => %{"duration_minutes" => 90}} = json_response(conn, 200)
  end

  test "session history", %{conn: conn, pc: pc, tariff: tariff} do
    start_session(conn, pc, tariff)
    conn = get(conn, "/api/sessions/history")
    assert %{"sessions" => sessions} = json_response(conn, 200)
    assert length(sessions) == 1
  end

  test "404 for unknown session", %{conn: conn} do
    conn = get(conn, "/api/sessions/#{Ecto.UUID.generate()}")
    assert json_response(conn, 404)
  end
end
