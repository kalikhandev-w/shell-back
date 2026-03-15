defmodule Lobby.Shifts do
  import Ecto.Query
  alias Lobby.Repo
  alias Lobby.Shifts.{Shift, CashOperation}

  def get_shift(id), do: Repo.get(Shift, id)

  def get_open_shift(club_id) do
    Shift
    |> where([s], s.club_id == ^club_id and s.status == "open")
    |> order_by(desc: :opened_at)
    |> limit(1)
    |> Repo.one()
  end

  def open_shift(attrs) do
    %Shift{}
    |> Shift.open_changeset(attrs)
    |> Repo.insert()
  end

  def close_shift(shift, closing_cash) do
    # Calculate totals from payments/orders during this shift
    stats = calculate_shift_stats(shift)

    discrepancy =
      if closing_cash do
        expected = shift.opening_cash + stats.total_cash
        closing_cash - expected
      end

    shift
    |> Shift.close_changeset(Map.merge(stats, %{closing_cash: closing_cash, discrepancy: discrepancy}))
    |> Repo.update()
  end

  def list_shifts(club_id, opts \\ []) do
    query =
      Shift
      |> where([s], s.club_id == ^club_id)

    query =
      case Keyword.get(opts, :status) do
        nil -> query
        status -> where(query, [s], s.status == ^status)
      end

    query
    |> order_by(desc: :opened_at)
    |> limit(^Keyword.get(opts, :limit, 50))
    |> Repo.all()
  end

  # Cash operations
  def create_cash_operation(attrs) do
    %CashOperation{}
    |> CashOperation.changeset(attrs)
    |> Repo.insert()
  end

  def list_cash_operations(shift_id) do
    CashOperation
    |> where([c], c.shift_id == ^shift_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  defp calculate_shift_stats(shift) do
    # Sessions during shift
    sessions =
      Lobby.Gaming.Session
      |> where([s], s.shift_id == ^shift.id)
      |> Repo.all()

    sessions_count = length(sessions)
    total_revenue = Enum.sum(Enum.map(sessions, & &1.total_price_tiyn))

    total_cash =
      sessions
      |> Enum.filter(&(&1.payment_method == "cash"))
      |> Enum.map(& &1.total_price_tiyn)
      |> Enum.sum()

    total_balance =
      sessions
      |> Enum.filter(&(&1.payment_method == "balance"))
      |> Enum.map(& &1.total_price_tiyn)
      |> Enum.sum()

    # Orders during shift
    orders =
      Lobby.Pos.Order
      |> where([o], o.shift_id == ^shift.id and o.status != "cancelled")
      |> Repo.all()

    orders_count = length(orders)
    orders_revenue = Enum.sum(Enum.map(orders, & &1.total_price_tiyn))

    %{
      sessions_count: sessions_count,
      orders_count: orders_count,
      total_revenue: total_revenue + orders_revenue,
      total_cash: total_cash,
      total_balance: total_balance,
      total_package: 0
    }
  end
end
