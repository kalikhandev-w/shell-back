defmodule Lobby.Gaming.Game do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "games" do
    field :name, :string
    field :exe_name, :string
    field :exe_path, :string
    field :category, :string, default: "other"
    field :cover_url, :string
    field :is_active, :boolean, default: true

    belongs_to :club, Lobby.Clubs.Club

    timestamps(type: :utc_datetime)
  end

  def changeset(game, attrs) do
    game
    |> cast(attrs, [:name, :exe_name, :exe_path, :category, :cover_url, :is_active, :club_id])
    |> validate_required([:name, :exe_name, :club_id])
    |> validate_inclusion(:category, ~w(fps moba rpg racing strategy other))
  end
end
