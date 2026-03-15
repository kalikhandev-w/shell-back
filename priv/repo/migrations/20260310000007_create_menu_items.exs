defmodule Lobby.Repo.Migrations.CreateMenuItems do
  use Ecto.Migration

  def change do
    create table(:menu_categories, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :name, :string, null: false
      add :sort_order, :integer, default: 0
      add :club_id, references(:clubs, type: :uuid, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:menu_categories, [:club_id])

    create table(:menu_items, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :name, :string, null: false
      add :price_tiyn, :integer, null: false
      add :image_url, :string
      add :is_available, :boolean, default: true
      add :category_id, references(:menu_categories, type: :uuid, on_delete: :delete_all), null: false
      add :club_id, references(:clubs, type: :uuid, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:menu_items, [:category_id])
    create index(:menu_items, [:club_id])
  end
end
