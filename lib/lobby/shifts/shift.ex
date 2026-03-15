defmodule Lobby.Shifts.Shift do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "shifts" do
    field :opened_at, :utc_datetime
    field :closed_at, :utc_datetime
    field :opening_cash, :integer, default: 0
    field :closing_cash, :integer
    field :total_revenue, :integer, default: 0
    field :total_cash, :integer, default: 0
    field :total_balance, :integer, default: 0
    field :total_package, :integer, default: 0
    field :sessions_count, :integer, default: 0
    field :orders_count, :integer, default: 0
    field :discrepancy, :integer
    field :status, :string, default: "open"

    belongs_to :club, Lobby.Clubs.Club
    belongs_to :staff, Lobby.Accounts.User

    has_many :cash_operations, Lobby.Shifts.CashOperation

    timestamps(type: :utc_datetime)
  end

  def open_changeset(shift, attrs) do
    shift
    |> cast(attrs, [:opening_cash, :club_id, :staff_id])
    |> validate_required([:club_id, :staff_id])
    |> put_change(:opened_at, DateTime.utc_now() |> DateTime.truncate(:second))
    |> put_change(:status, "open")
  end

  def close_changeset(shift, attrs) do
    shift
    |> cast(attrs, [:closing_cash, :total_revenue, :total_cash, :total_balance,
                     :total_package, :sessions_count, :orders_count, :discrepancy])
    |> put_change(:closed_at, DateTime.utc_now() |> DateTime.truncate(:second))
    |> put_change(:status, "closed")
  end
end
