defmodule Lobby.Repo.Migrations.CreateTariffs do
  use Ecto.Migration

  def change do
    create table(:tariffs, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :name, :string, null: false
      add :zone, :string, default: "standard"
      add :price_per_hour_tiyn, :integer, null: false
      add :is_active, :boolean, default: true
      add :club_id, references(:clubs, type: :uuid, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:tariffs, [:club_id])
  end
end
