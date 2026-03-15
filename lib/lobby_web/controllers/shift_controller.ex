defmodule LobbyWeb.ShiftController do
  use LobbyWeb, :controller

  alias Lobby.{Shifts, Audit}
  alias Lobby.Guardian

  def open(conn, params) do
    user = Guardian.Plug.current_resource(conn)

    case Shifts.get_open_shift(user.club_id) do
      nil ->
        attrs = %{
          club_id: user.club_id,
          staff_id: user.id,
          opening_cash: params["opening_cash"] || 0
        }

        case Shifts.open_shift(attrs) do
          {:ok, shift} ->
            Audit.log(%{action: "shift.open", club_id: user.club_id, user_id: user.id,
                        target_type: "Shift", target_id: shift.id})
            conn |> put_status(201) |> json(%{shift: shift_json(shift)})
          {:error, _} ->
            conn |> put_status(422) |> json(%{error: "Failed to open shift"})
        end

      _shift ->
        conn |> put_status(409) |> json(%{error: "A shift is already open"})
    end
  end

  def close(conn, %{"id" => id} = params) do
    user = Guardian.Plug.current_resource(conn)

    case Shifts.get_shift(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Shift not found"})
      shift ->
        case Shifts.close_shift(shift, params["closing_cash"]) do
          {:ok, shift} ->
            Audit.log(%{action: "shift.close", club_id: user.club_id, user_id: user.id,
                        target_type: "Shift", target_id: shift.id})
            conn |> put_status(200) |> json(%{shift: shift_json(shift)})
          {:error, _} ->
            conn |> put_status(422) |> json(%{error: "Failed to close shift"})
        end
    end
  end

  def show(conn, %{"id" => id}) do
    case Shifts.get_shift(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Shift not found"})
      shift ->
        operations = Shifts.list_cash_operations(shift.id)
        conn |> put_status(200) |> json(%{
          shift: shift_json(shift),
          operations: Enum.map(operations, &operation_json/1)
        })
    end
  end

  def index(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    opts = [status: params["status"], limit: parse_int(params["limit"], 50)]
    shifts = Shifts.list_shifts(user.club_id, opts)
    conn |> put_status(200) |> json(%{shifts: Enum.map(shifts, &shift_json/1)})
  end

  def current(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    case Shifts.get_open_shift(user.club_id) do
      nil -> conn |> put_status(200) |> json(%{shift: nil})
      shift -> conn |> put_status(200) |> json(%{shift: shift_json(shift)})
    end
  end

  def encashment(conn, %{"id" => id, "amount" => amount} = params) do
    user = Guardian.Plug.current_resource(conn)

    case Shifts.get_shift(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Shift not found"})
      shift ->
        attrs = %{
          type: "encashment",
          amount: amount,
          description: params["description"],
          shift_id: shift.id,
          club_id: shift.club_id,
          created_by: user.id
        }

        case Shifts.create_cash_operation(attrs) do
          {:ok, op} -> conn |> put_status(201) |> json(%{operation: operation_json(op)})
          {:error, _} -> conn |> put_status(422) |> json(%{error: "Failed to create operation"})
        end
    end
  end

  defp shift_json(s) do
    %{id: s.id, status: s.status, opened_at: s.opened_at, closed_at: s.closed_at,
      opening_cash: s.opening_cash, closing_cash: s.closing_cash,
      total_revenue: s.total_revenue, total_cash: s.total_cash,
      total_balance: s.total_balance, sessions_count: s.sessions_count,
      orders_count: s.orders_count, discrepancy: s.discrepancy,
      staff_id: s.staff_id}
  end

  defp operation_json(o) do
    %{id: o.id, type: o.type, amount: o.amount, description: o.description,
      created_by: o.created_by, inserted_at: o.inserted_at}
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
