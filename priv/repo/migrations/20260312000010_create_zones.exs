defmodule Lobby.Repo.Migrations.CreateZones do
  use Ecto.Migration

  def change do
    create table(:zones, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :name, :string, null: false
      add :color, :string, default: "#3B82F6"
      add :sort_order, :integer, default: 0
      add :club_id, references(:clubs, type: :uuid, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:zones, [:club_id])

    # Add zone_id FK to pcs and tariffs (replacing string zone field)
    alter table(:pcs) do
      add :zone_id, references(:zones, type: :uuid, on_delete: :nilify_all)
    end

    alter table(:tariffs) do
      add :zone_id, references(:zones, type: :uuid, on_delete: :nilify_all)
      add :type, :string, default: "hourly"
      add :fixed_price, :integer
      add :time_range, :map
      add :days_of_week, {:array, :integer}
      add :min_duration_minutes, :integer
      add :sort_order, :integer, default: 0
    end
  end
end
