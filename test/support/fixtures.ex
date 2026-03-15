defmodule Lobby.Fixtures do
  alias Lobby.Repo
  alias Lobby.Clubs.{Club, PC, Tariff, Zone}
  alias Lobby.Accounts.User
  alias Lobby.Gaming.Game

  def create_club(attrs \\ %{}) do
    {:ok, club} =
      %Club{}
      |> Club.changeset(
        Map.merge(
          %{name: "Test Club", slug: "test-#{System.unique_integer([:positive])}", address: "Test St", timezone: "UTC"},
          attrs
        )
      )
      |> Repo.insert()

    club
  end

  def create_user(club, attrs \\ %{}) do
    uniq = System.unique_integer([:positive])

    {:ok, user} =
      %User{}
      |> User.registration_changeset(
        Map.merge(
          %{email: "user#{uniq}@test.com", password: "password123", username: "user#{uniq}", club_id: club.id},
          attrs
        )
      )
      |> Repo.insert()

    user
  end

  def create_admin(club, attrs \\ %{}) do
    user = create_user(club, attrs)
    {:ok, admin} = Ecto.Changeset.change(user, %{is_admin: true}) |> Repo.update()
    admin
  end

  def create_pc(club, attrs \\ %{}) do
    uniq = System.unique_integer([:positive])

    {:ok, pc} =
      %PC{}
      |> PC.changeset(
        Map.merge(
          %{pc_token: "pc-test-#{uniq}", hostname: "PC-#{uniq}", zone: "standard", mac_address: "AA:BB:CC:DD:EE:#{String.pad_leading("#{rem(uniq, 100)}", 2, "0")}", club_id: club.id},
          attrs
        )
      )
      |> Repo.insert()

    pc
  end

  def create_tariff(club, attrs \\ %{}) do
    {:ok, tariff} =
      %Tariff{}
      |> Tariff.changeset(
        Map.merge(
          %{name: "Standard", zone: "standard", price_per_hour_tiyn: 50000, club_id: club.id},
          attrs
        )
      )
      |> Repo.insert()

    tariff
  end

  def create_zone(club, attrs \\ %{}) do
    {:ok, zone} =
      %Zone{}
      |> Zone.changeset(
        Map.merge(
          %{name: "Standard", color: "#3B82F6", sort_order: 0, club_id: club.id},
          attrs
        )
      )
      |> Repo.insert()

    zone
  end

  def create_game(club, attrs \\ %{}) do
    {:ok, game} =
      %Game{}
      |> Game.changeset(
        Map.merge(
          %{name: "CS2", exe_name: "cs2.exe", category: "fps", club_id: club.id},
          attrs
        )
      )
      |> Repo.insert()

    game
  end

  def auth_conn(conn, user) do
    {:ok, token, _claims} = Lobby.Guardian.encode_and_sign(user)
    Plug.Conn.put_req_header(conn, "authorization", "Bearer #{token}")
  end
end
