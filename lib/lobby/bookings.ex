defmodule Lobby.Bookings do
  import Ecto.Query
  alias Lobby.Repo
  alias Lobby.Bookings.Booking

  def get_booking(id), do: Repo.get(Booking, id)

  def create_booking(attrs) do
    %Booking{}
    |> Booking.changeset(attrs)
    |> Repo.insert()
  end

  def cancel_booking(booking) do
    booking
    |> Ecto.Changeset.change(status: "cancelled")
    |> Repo.update()
  end

  def complete_booking(booking) do
    booking
    |> Ecto.Changeset.change(status: "completed")
    |> Repo.update()
  end

  def expire_booking(booking) do
    booking
    |> Ecto.Changeset.change(status: "expired")
    |> Repo.update()
  end

  def list_bookings(club_id, opts \\ []) do
    query =
      Booking
      |> where([b], b.club_id == ^club_id)

    query =
      case Keyword.get(opts, :status) do
        nil -> query
        status -> where(query, [b], b.status == ^status)
      end

    query
    |> order_by(desc: :booked_for)
    |> limit(^Keyword.get(opts, :limit, 50))
    |> Repo.all()
  end

  def get_active_booking_for_pc(pc_id) do
    Booking
    |> where([b], b.pc_id == ^pc_id and b.status == "active")
    |> order_by(desc: :booked_for)
    |> limit(1)
    |> Repo.one()
  end

  def expire_stale_bookings(minutes_threshold \\ 15) do
    threshold = DateTime.utc_now() |> DateTime.add(-minutes_threshold * 60, :second)

    Booking
    |> where([b], b.status == "active" and b.booked_for < ^threshold)
    |> Repo.update_all(set: [status: "expired"])
  end
end
