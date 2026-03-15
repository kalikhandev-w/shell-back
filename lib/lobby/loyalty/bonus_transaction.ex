defmodule Lobby.Loyalty.BonusTransaction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "bonus_transactions" do
    field :amount, :integer
    field :reason, :string
    field :reference_id, :binary_id

    belongs_to :user, Lobby.Accounts.User
    belongs_to :club, Lobby.Clubs.Club

    timestamps(type: :utc_datetime)
  end

  def changeset(tx, attrs) do
    tx
    |> cast(attrs, [:amount, :reason, :reference_id, :user_id, :club_id])
    |> validate_required([:amount, :reason, :user_id, :club_id])
    |> validate_inclusion(:reason, ~w(cashback referral tournament achievement spend admin))
  end
end
