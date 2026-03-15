defmodule Lobby.Audit.GamerNote do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "gamer_notes" do
    field :type, :string
    field :text, :string
    field :amount, :integer

    belongs_to :gamer, Lobby.Accounts.User
    belongs_to :club, Lobby.Clubs.Club
    belongs_to :created_by_user, Lobby.Accounts.User, foreign_key: :created_by

    timestamps(type: :utc_datetime)
  end

  def changeset(note, attrs) do
    note
    |> cast(attrs, [:type, :text, :amount, :gamer_id, :club_id, :created_by])
    |> validate_required([:type, :text, :gamer_id, :club_id])
    |> validate_inclusion(:type, ~w(note fine warning))
  end
end
