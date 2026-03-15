defmodule Lobby.Pos.MenuCategory do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "menu_categories" do
    field :name, :string
    field :sort_order, :integer, default: 0

    belongs_to :club, Lobby.Clubs.Club
    has_many :items, Lobby.Pos.MenuItem, foreign_key: :category_id

    timestamps(type: :utc_datetime)
  end

  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :sort_order, :club_id])
    |> validate_required([:name, :club_id])
  end
end
