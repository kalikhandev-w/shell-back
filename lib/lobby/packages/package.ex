defmodule Lobby.Packages.Package do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "packages" do
    field :name, :string
    field :type, :string
    field :hours, :integer
    field :price, :integer
    field :validity_days, :integer, default: 30
    field :is_active, :boolean, default: true

    belongs_to :club, Lobby.Clubs.Club

    timestamps(type: :utc_datetime)
  end

  def changeset(pkg, attrs) do
    pkg
    |> cast(attrs, [:name, :type, :hours, :price, :validity_days, :is_active, :club_id])
    |> validate_required([:name, :type, :price, :club_id])
    |> validate_inclusion(:type, ~w(hours unlimited))
    |> validate_number(:price, greater_than: 0)
  end
end
