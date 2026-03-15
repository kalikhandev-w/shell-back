defmodule Lobby.BookingsTest do
  use Lobby.DataCase, async: true

  alias Lobby.Bookings
  import Lobby.Fixtures

  setup do
    club = create_club()
    user = create_user(club)
    pc = create_pc(club)
    %{club: club, user: user, pc: pc}
  end

  test "create and cancel booking", %{club: club, user: user, pc: pc} do
    {:ok, booking} = Bookings.create_booking(%{
      booked_for: DateTime.utc_now() |> DateTime.add(3600) |> DateTime.truncate(:second),
      gamer_name: "TestGamer",
      club_id: club.id,
      pc_id: pc.id,
      user_id: user.id,
      created_by: user.id
    })
    assert booking.status == "active"

    {:ok, cancelled} = Bookings.cancel_booking(booking)
    assert cancelled.status == "cancelled"
  end

  test "list_bookings returns bookings", %{club: club, user: user, pc: pc} do
    {:ok, _} = Bookings.create_booking(%{
      booked_for: DateTime.utc_now() |> DateTime.add(3600) |> DateTime.truncate(:second),
      gamer_name: "G1", club_id: club.id, pc_id: pc.id, created_by: user.id
    })
    bookings = Bookings.list_bookings(club.id)
    assert length(bookings) == 1
  end
end
