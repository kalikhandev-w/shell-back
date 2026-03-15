defmodule Lobby.Clubs.Tariff do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "tariffs" do
    field :name, :string
    field :zone, :string, default: "standard"
    field :price_per_hour_tiyn, :integer
    field :is_active, :boolean, default: true

    belongs_to :club, Lobby.Clubs.Club

    timestamps(type: :utc_datetime)
  end

  def changeset(tariff, attrs) do
    tariff
    |> cast(attrs, [:name, :zone, :price_per_hour_tiyn, :is_active, :club_id])
    |> validate_required([:name, :price_per_hour_tiyn, :club_id])
    |> validate_number(:price_per_hour_tiyn, greater_than: 0)
  end
end
