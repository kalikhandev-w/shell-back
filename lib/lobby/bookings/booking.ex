defmodule Lobby.Bookings.Booking do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "bookings" do
    field :booked_for, :utc_datetime
    field :gamer_name, :string
    field :status, :string, default: "active"

    belongs_to :club, Lobby.Clubs.Club
    belongs_to :pc, Lobby.Clubs.PC
    belongs_to :user, Lobby.Accounts.User
    belongs_to :created_by_user, Lobby.Accounts.User, foreign_key: :created_by

    timestamps(type: :utc_datetime)
  end

  def changeset(booking, attrs) do
    booking
    |> cast(attrs, [:booked_for, :gamer_name, :status, :club_id, :pc_id, :user_id, :created_by])
    |> validate_required([:booked_for, :club_id, :pc_id])
    |> validate_inclusion(:status, ~w(active completed cancelled expired))
  end
end
