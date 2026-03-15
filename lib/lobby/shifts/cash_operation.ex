defmodule Lobby.Shifts.CashOperation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "cash_operations" do
    field :type, :string
    field :amount, :integer
    field :description, :string

    belongs_to :shift, Lobby.Shifts.Shift
    belongs_to :club, Lobby.Clubs.Club
    belongs_to :created_by_user, Lobby.Accounts.User, foreign_key: :created_by

    timestamps(type: :utc_datetime)
  end

  def changeset(op, attrs) do
    op
    |> cast(attrs, [:type, :amount, :description, :shift_id, :club_id, :created_by])
    |> validate_required([:type, :amount, :shift_id, :club_id])
    |> validate_inclusion(:type, ~w(income encashment expense))
    |> validate_number(:amount, greater_than: 0)
  end
end
