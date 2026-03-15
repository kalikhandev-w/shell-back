defmodule LobbyWeb.AuthControllerTest do
  use LobbyWeb.ConnCase, async: true

  import Lobby.Fixtures

  setup %{conn: conn} do
    club = create_club()
    %{conn: put_req_header(conn, "content-type", "application/json"), club: club}
  end

  describe "POST /api/auth/register" do
    test "registers new user", %{conn: conn, club: club} do
      conn = post(conn, "/api/auth/register", %{
        email: "new@test.com", password: "secret123",
        username: "newuser", club_id: club.id
      })
      assert %{"token" => token, "user" => user} = json_response(conn, 201)
      assert token != nil
      assert user["email"] == "new@test.com"
    end

    test "fails with invalid data", %{conn: conn} do
      conn = post(conn, "/api/auth/register", %{email: "bad", password: "x"})
      assert json_response(conn, 422)
    end
  end

  describe "POST /api/auth/login" do
    test "returns token on valid login", %{conn: conn, club: club} do
      create_user(club, %{email: "login@test.com", password: "secret123"})
      conn = post(conn, "/api/auth/login", %{email: "login@test.com", password: "secret123"})
      assert %{"token" => token} = json_response(conn, 200)
      assert token != nil
    end

    test "returns 401 on invalid password", %{conn: conn, club: club} do
      create_user(club, %{email: "login2@test.com", password: "secret123"})
      conn = post(conn, "/api/auth/login", %{email: "login2@test.com", password: "wrong"})
      assert json_response(conn, 401)
    end
  end

  describe "GET /api/auth/profile" do
    test "returns profile when authenticated", %{conn: conn, club: club} do
      user = create_user(club)
      conn = conn |> auth_conn(user) |> get("/api/auth/profile")
      assert %{"user" => profile} = json_response(conn, 200)
      assert profile["id"] == user.id
    end

    test "returns 401 when unauthenticated", %{conn: conn} do
      conn = get(conn, "/api/auth/profile")
      assert json_response(conn, 401)
    end
  end

  describe "POST /api/auth/guest" do
    test "creates guest user", %{conn: conn, club: club} do
      conn = post(conn, "/api/auth/guest", %{club_id: club.id})
      assert %{"token" => token, "user" => user} = json_response(conn, 201)
      assert token != nil
      assert user["is_guest"] == true
    end
  end
end
