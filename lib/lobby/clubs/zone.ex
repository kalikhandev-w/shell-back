defmodule Lobby.Clubs.Zone do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "zones" do
    field :name, :string
    field :color, :string, default: "#3B82F6"
    field :sort_order, :integer, default: 0

    belongs_to :club, Lobby.Clubs.Club

    timestamps(type: :utc_datetime)
  end

  def changeset(zone, attrs) do
    zone
    |> cast(attrs, [:name, :color, :sort_order, :club_id])
    |> validate_required([:name, :club_id])
  end
end
