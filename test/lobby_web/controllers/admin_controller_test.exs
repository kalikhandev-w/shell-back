defmodule LobbyWeb.AdminControllerTest do
  use LobbyWeb.ConnCase, async: true

  import Lobby.Fixtures

  setup %{conn: conn} do
    club = create_club()
    admin = create_admin(club)
    user = create_user(club)
    conn = conn |> put_req_header("content-type", "application/json") |> auth_conn(admin)
    %{conn: conn, club: club, admin: admin, user: user}
  end

  describe "dashboard" do
    test "returns stats", %{conn: conn} do
      conn = get(conn, "/api/admin/dashboard")
      assert %{"dashboard" => dash} = json_response(conn, 200)
      assert Map.has_key?(dash, "active_sessions")
      assert Map.has_key?(dash, "total_pcs")
    end
  end

  describe "PCs" do
    test "list_pcs returns PCs", %{conn: conn, club: club} do
      create_pc(club)
      conn = get(conn, "/api/admin/pcs")
      assert %{"pcs" => pcs} = json_response(conn, 200)
      assert length(pcs) >= 1
    end

    test "update_pc changes hostname", %{conn: conn, club: club} do
      pc = create_pc(club)
      conn = put(conn, "/api/admin/pcs/#{pc.id}", %{hostname: "RENAMED"})
      assert %{"pc" => updated} = json_response(conn, 200)
      assert updated["hostname"] == "RENAMED"
    end

    test "delete_pc removes PC", %{conn: conn, club: club} do
      pc = create_pc(club)
      conn = delete(conn, "/api/admin/pcs/#{pc.id}")
      assert %{"ok" => true} = json_response(conn, 200)
    end
  end

  describe "tariffs" do
    test "CRUD tariff", %{conn: conn} do
      conn_create = post(conn, "/api/admin/tariffs", %{name: "Test", zone: "standard", price_per_hour_tiyn: 50000})
      assert %{"tariff" => tariff} = json_response(conn_create, 201)

      conn_update = put(conn, "/api/admin/tariffs/#{tariff["id"]}", %{name: "Updated"})
      assert %{"tariff" => updated} = json_response(conn_update, 200)
      assert updated["name"] == "Updated"

      conn_delete = delete(conn, "/api/admin/tariffs/#{tariff["id"]}")
      assert %{"ok" => true} = json_response(conn_delete, 200)
    end
  end

  describe "games" do
    test "CRUD game", %{conn: conn} do
      conn_create = post(conn, "/api/admin/games", %{name: "TestGame", exe_name: "test.exe", category: "fps"})
      assert %{"game" => game} = json_response(conn_create, 201)

      conn_update = put(conn, "/api/admin/games/#{game["id"]}", %{name: "Updated"})
      assert %{"game" => updated} = json_response(conn_update, 200)
      assert updated["name"] == "Updated"

      conn_delete = delete(conn, "/api/admin/games/#{game["id"]}")
      assert %{"ok" => true} = json_response(conn_delete, 200)
    end
  end

  describe "users" do
    test "list_users", %{conn: conn} do
      conn = get(conn, "/api/admin/users")
      assert %{"users" => users} = json_response(conn, 200)
      assert length(users) >= 2
    end

    test "add_balance", %{conn: conn, user: user} do
      conn = post(conn, "/api/admin/users/#{user.id}/balance", %{amount_tiyn: 100_000})
      assert %{"user" => updated} = json_response(conn, 200)
      assert updated["balance_tiyn"] == 100_000
    end
  end

  describe "stats" do
    test "revenue_stats returns data", %{conn: conn} do
      conn = get(conn, "/api/admin/stats/revenue")
      assert %{"revenue" => _} = json_response(conn, 200)
    end

    test "occupancy_stats returns data", %{conn: conn} do
      conn = get(conn, "/api/admin/stats/occupancy")
      assert %{"occupancy" => _} = json_response(conn, 200)
    end

    test "customer_stats returns data", %{conn: conn} do
      conn = get(conn, "/api/admin/stats/customers")
      assert %{"customers" => _} = json_response(conn, 200)
    end
  end

  describe "authorization" do
    test "non-admin gets 403", %{club: club} do
      user = create_user(club)
      conn = build_conn() |> put_req_header("content-type", "application/json") |> auth_conn(user)
      conn = get(conn, "/api/admin/dashboard")
      assert json_response(conn, 403)
    end
  end
end
