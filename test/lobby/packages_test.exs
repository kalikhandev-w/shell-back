defmodule Lobby.PackagesTest do
  use Lobby.DataCase, async: true

  alias Lobby.Packages
  import Lobby.Fixtures

  setup do
    club = create_club()
    user = create_user(club)
    admin = create_admin(club)
    %{club: club, user: user, admin: admin}
  end

  test "CRUD package template", %{club: club} do
    {:ok, pkg} = Packages.create_package(%{
      name: "5 hours", type: "hours", hours: 5,
      price: 200_000, validity_days: 30, club_id: club.id
    })
    assert pkg.name == "5 hours"

    {:ok, updated} = Packages.update_package(pkg, %{name: "10 hours", hours: 10})
    assert updated.name == "10 hours"

    {:ok, _} = Packages.delete_package(updated)
    assert Packages.get_package(pkg.id) == nil
  end

  test "sell_package creates gamer_package", %{club: club, user: user, admin: admin} do
    {:ok, pkg} = Packages.create_package(%{
      name: "5h", type: "hours", hours: 5,
      price: 200_000, validity_days: 30, club_id: club.id
    })

    {:ok, gp} = Packages.sell_package(user.id, pkg, admin.id)
    assert Decimal.equal?(gp.hours_remaining, Decimal.new(5))
    assert gp.status == "active"
  end

  test "list_active_packages", %{club: club, user: user, admin: admin} do
    {:ok, pkg} = Packages.create_package(%{
      name: "5h", type: "hours", hours: 5,
      price: 200_000, validity_days: 30, club_id: club.id
    })
    {:ok, _} = Packages.sell_package(user.id, pkg, admin.id)

    packages = Packages.list_active_packages(user.id, club.id)
    assert length(packages) == 1
  end
end
