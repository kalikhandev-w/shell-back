defmodule Lobby.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :name, :string, null: false
      add :exe_name, :string, null: false
      add :exe_path, :string
      add :category, :string, default: "other"
      add :cover_url, :string
      add :is_active, :boolean, default: true
      add :club_id, references(:clubs, type: :uuid, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:games, [:club_id])
    create index(:games, [:category])
  end
end
