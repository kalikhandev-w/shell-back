defmodule Lobby.Clubs.Club do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "clubs" do
    field :name, :string
    field :slug, :string
    field :logo_url, :string
    field :address, :string
    field :timezone, :string, default: "Asia/Almaty"
    field :settings, :map, default: %{}

    has_many :pcs, Lobby.Clubs.PC
    has_many :tariffs, Lobby.Clubs.Tariff
    has_many :games, Lobby.Gaming.Game

    timestamps(type: :utc_datetime)
  end

  def changeset(club, attrs) do
    club
    |> cast(attrs, [:name, :slug, :logo_url, :address, :timezone, :settings])
    |> validate_required([:name, :slug])
    |> unique_constraint(:slug)
  end
end
