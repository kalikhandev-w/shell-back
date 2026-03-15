defmodule Lobby.Pos.MenuItem do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "menu_items" do
    field :name, :string
    field :price_tiyn, :integer
    field :image_url, :string
    field :is_available, :boolean, default: true

    belongs_to :category, Lobby.Pos.MenuCategory
    belongs_to :club, Lobby.Clubs.Club

    timestamps(type: :utc_datetime)
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:name, :price_tiyn, :image_url, :is_available, :category_id, :club_id])
    |> validate_required([:name, :price_tiyn, :category_id, :club_id])
    |> validate_number(:price_tiyn, greater_than: 0)
  end
end
