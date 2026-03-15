defmodule Lobby.Repo.Migrations.CreatePcs do
  use Ecto.Migration

  def change do
    create table(:pcs, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :pc_token, :string, null: false
      add :hostname, :string
      add :mac_address, :string
      add :ip_address, :string
      add :status, :string, default: "free"
      add :zone, :string, default: "standard"
      add :specs, :map, default: %{}
      add :last_heartbeat_at, :utc_datetime
      add :club_id, references(:clubs, type: :uuid, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:pcs, [:pc_token])
    create index(:pcs, [:club_id])
  end
end
