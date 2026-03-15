defmodule LobbyWeb.BookingController do
  use LobbyWeb, :controller

  alias Lobby.{Bookings, Clubs, Audit}
  alias Lobby.Guardian

  def index(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    opts = [status: params["status"], limit: parse_int(params["limit"], 50)]
    bookings = Bookings.list_bookings(user.club_id, opts)
    conn |> put_status(200) |> json(%{bookings: Enum.map(bookings, &booking_json/1)})
  end

  def create(conn, params) do
    user = Guardian.Plug.current_resource(conn)

    attrs = %{
      booked_for: params["booked_for"],
      gamer_name: params["gamer_name"],
      club_id: user.club_id,
      pc_id: params["pc_id"],
      user_id: params["user_id"],
      created_by: user.id
    }

    case Bookings.create_booking(attrs) do
      {:ok, booking} ->
        # Set PC status to reserved
        if pc = Clubs.get_pc(booking.pc_id), do: Clubs.set_pc_status(pc, "reserved")
        Audit.log(%{action: "booking.create", club_id: user.club_id, user_id: user.id,
                    target_type: "Booking", target_id: booking.id})
        conn |> put_status(201) |> json(%{booking: booking_json(booking)})
      {:error, changeset} ->
        conn |> put_status(422) |> json(%{error: "Failed", details: changeset_errors(changeset)})
    end
  end

  def cancel(conn, %{"id" => id}) do
    user = Guardian.Plug.current_resource(conn)

    case Bookings.get_booking(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Booking not found"})
      booking ->
        {:ok, booking} = Bookings.cancel_booking(booking)
        if booking.pc_id, do: (if pc = Clubs.get_pc(booking.pc_id), do: Clubs.set_pc_status(pc, "free"))
        Audit.log(%{action: "booking.cancel", club_id: user.club_id, user_id: user.id,
                    target_type: "Booking", target_id: booking.id})
        conn |> put_status(200) |> json(%{booking: booking_json(booking)})
    end
  end

  defp booking_json(b) do
    %{id: b.id, booked_for: b.booked_for, gamer_name: b.gamer_name,
      status: b.status, pc_id: b.pc_id, user_id: b.user_id,
      created_by: b.created_by, inserted_at: b.inserted_at}
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  defp parse_int(nil, default), do: default
  defp parse_int(val, _) when is_integer(val), do: val
  defp parse_int(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {n, _} -> n
      :error -> default
    end
  end
end
