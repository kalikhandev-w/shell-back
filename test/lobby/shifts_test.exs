defmodule Lobby.ShiftsTest do
  use Lobby.DataCase, async: true

  alias Lobby.Shifts
  import Lobby.Fixtures

  setup do
    club = create_club()
    admin = create_admin(club)
    %{club: club, admin: admin}
  end

  describe "shifts" do
    test "open_shift creates open shift", %{club: club, admin: admin} do
      {:ok, shift} = Shifts.open_shift(%{club_id: club.id, staff_id: admin.id, opening_cash: 50000})
      assert shift.status == "open"
      assert shift.opening_cash == 50000
    end

    test "get_open_shift returns current shift", %{club: club, admin: admin} do
      {:ok, _} = Shifts.open_shift(%{club_id: club.id, staff_id: admin.id, opening_cash: 0})
      shift = Shifts.get_open_shift(club.id)
      assert shift != nil
      assert shift.status == "open"
    end

    test "close_shift marks closed", %{club: club, admin: admin} do
      {:ok, shift} = Shifts.open_shift(%{club_id: club.id, staff_id: admin.id, opening_cash: 50000})
      {:ok, closed} = Shifts.close_shift(shift, 45000)
      assert closed.status == "closed"
      assert closed.closing_cash == 45000
    end

    test "list_shifts returns shifts", %{club: club, admin: admin} do
      {:ok, _} = Shifts.open_shift(%{club_id: club.id, staff_id: admin.id, opening_cash: 0})
      shifts = Shifts.list_shifts(club.id)
      assert length(shifts) == 1
    end
  end

  describe "cash operations" do
    test "create and list cash operations", %{club: club, admin: admin} do
      {:ok, shift} = Shifts.open_shift(%{club_id: club.id, staff_id: admin.id, opening_cash: 0})

      {:ok, op} = Shifts.create_cash_operation(%{
        type: "encashment", amount: 100_000,
        shift_id: shift.id, club_id: club.id, created_by: admin.id
      })
      assert op.type == "encashment"

      ops = Shifts.list_cash_operations(shift.id)
      assert length(ops) == 1
    end
  end
end
