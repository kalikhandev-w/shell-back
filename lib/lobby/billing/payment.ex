defmodule Lobby.Billing.Payment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "payments" do
    field :method, :string
    field :amount_tiyn, :integer
    field :status, :string, default: "pending"

    belongs_to :user, Lobby.Accounts.User
    belongs_to :session, Lobby.Gaming.Session
    belongs_to :club, Lobby.Clubs.Club

    timestamps(type: :utc_datetime)
  end

  def changeset(payment, attrs) do
    payment
    |> cast(attrs, [:method, :amount_tiyn, :status, :user_id, :session_id, :club_id])
    |> validate_required([:method, :amount_tiyn])
    |> validate_inclusion(:method, ~w(balance cash kaspi_qr))
    |> validate_number(:amount_tiyn, greater_than: 0)
  end
end
