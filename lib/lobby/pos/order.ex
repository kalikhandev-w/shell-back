defmodule Lobby.Pos.Order do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "orders" do
    field :status, :string, default: "pending"
    field :total_price_tiyn, :integer, default: 0
    field :items, {:array, :map}, default: []
    field :payment_method, :string
    field :pc_id, :binary_id

    belongs_to :user, Lobby.Accounts.User
    belongs_to :session, Lobby.Gaming.Session
    belongs_to :club, Lobby.Clubs.Club
    belongs_to :shift, Lobby.Shifts.Shift

    timestamps(type: :utc_datetime)
  end

  def changeset(order, attrs) do
    order
    |> cast(attrs, [:items, :total_price_tiyn, :status, :user_id, :session_id, :club_id, :shift_id, :pc_id, :payment_method])
    |> validate_required([:items, :user_id, :club_id])
    |> validate_inclusion(:status, ~w(pending preparing ready delivered cancelled))
  end
end
