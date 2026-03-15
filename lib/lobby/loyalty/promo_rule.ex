defmodule Lobby.Loyalty.PromoRule do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "promo_rules" do
    field :name, :string
    field :type, :string
    field :conditions, :map, default: %{}
    field :discount_percent, :integer
    field :is_active, :boolean, default: true

    belongs_to :club, Lobby.Clubs.Club

    timestamps(type: :utc_datetime)
  end

  def changeset(rule, attrs) do
    rule
    |> cast(attrs, [:name, :type, :conditions, :discount_percent, :is_active, :club_id])
    |> validate_required([:name, :type, :club_id])
    |> validate_inclusion(:type, ~w(time_based occupancy_based))
  end
end
