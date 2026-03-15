defmodule Lobby.ClubsTest do
  use Lobby.DataCase, async: true

  alias Lobby.Clubs
  import Lobby.Fixtures

  setup do
    club = create_club()
    %{club: club}
  end

  describe "PCs" do
    test "list_pcs returns club PCs", %{club: club} do
      create_pc(club)
      create_pc(club)
      assert length(Clubs.list_pcs(club.id)) == 2
    end

    test "get_pc_by_token finds PC", %{club: club} do
      pc = create_pc(club, %{pc_token: "find-me"})
      found = Clubs.get_pc_by_token("find-me")
      assert found.id == pc.id
    end

    test "set_pc_status updates status", %{club: club} do
      pc = create_pc(club)
      {:ok, updated} = Clubs.set_pc_status(pc, "occupied")
      assert updated.status == "occupied"
    end

    test "update_pc changes fields", %{club: club} do
      pc = create_pc(club)
      {:ok, updated} = Clubs.update_pc(pc, %{hostname: "NEW-NAME"})
      assert updated.hostname == "NEW-NAME"
    end

    test "delete_pc removes PC", %{club: club} do
      pc = create_pc(club)
      {:ok, _} = Clubs.delete_pc(pc)
      assert Clubs.get_pc(pc.id) == nil
    end
  end

  describe "Tariffs" do
    test "create_tariff with valid data", %{club: club} do
      attrs = %{name: "VIP", zone: "vip", price_per_hour_tiyn: 80000, club_id: club.id}
      assert {:ok, tariff} = Clubs.create_tariff(attrs)
      assert tariff.name == "VIP"
    end

    test "list_tariffs returns active only", %{club: club} do
      create_tariff(club, %{name: "Active", is_active: true})
      create_tariff(club, %{name: "Inactive", is_active: false})
      tariffs = Clubs.list_tariffs(club.id)
      assert length(tariffs) == 1
    end

    test "list_all_tariffs returns all", %{club: club} do
      create_tariff(club, %{name: "A"})
      create_tariff(club, %{name: "B", is_active: false})
      tariffs = Clubs.list_all_tariffs(club.id)
      assert length(tariffs) == 2
    end
  end

  describe "Zones" do
    test "CRUD zone", %{club: club} do
      zone = create_zone(club, %{name: "VIP"})
      assert zone.name == "VIP"

      {:ok, updated} = Clubs.update_zone(zone, %{name: "VIP Gold"})
      assert updated.name == "VIP Gold"

      {:ok, _} = Clubs.delete_zone(updated)
      assert Clubs.get_zone(zone.id) == nil
    end

    test "list_zones returns all", %{club: club} do
      create_zone(club, %{name: "A", sort_order: 0})
      create_zone(club, %{name: "B", sort_order: 1})
      zones = Clubs.list_zones(club.id)
      assert length(zones) == 2
    end
  end

  describe "Club" do
    test "update_club changes settings", %{club: club} do
      {:ok, updated} = Clubs.update_club(club, %{name: "New Name"})
      assert updated.name == "New Name"
    end
  end
end
