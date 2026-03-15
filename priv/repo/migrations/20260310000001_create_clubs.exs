defmodule Lobby.Repo.Migrations.CreateClubs do
  use Ecto.Migration

  def change do
    create table(:clubs, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :name, :string, null: false
      add :slug, :string, null: false
      add :logo_url, :string
      add :address, :string
      add :timezone, :string, default: "Asia/Almaty"
      add :settings, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:clubs, [:slug])
  end
end
