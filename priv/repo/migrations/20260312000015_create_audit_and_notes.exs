defmodule Lobby.Repo.Migrations.CreateAuditAndNotes do
  use Ecto.Migration

  def change do
    create table(:audit_logs, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :action, :string, null: false
      add :target_type, :string
      add :target_id, :uuid
      add :details, :map, default: %{}
      add :club_id, references(:clubs, type: :uuid, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :uuid, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:audit_logs, [:club_id])
    create index(:audit_logs, [:club_id, :action])

    create table(:gamer_notes, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :type, :string, null: false
      add :text, :string, null: false
      add :amount, :integer
      add :gamer_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :club_id, references(:clubs, type: :uuid, on_delete: :delete_all), null: false
      add :created_by, references(:users, type: :uuid, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:gamer_notes, [:gamer_id, :club_id])

    # Add ban fields and role to users
    alter table(:users) do
      add :role, :string, default: "gamer"
      add :is_banned, :boolean, default: false
      add :ban_reason, :string
      add :ban_until, :utc_datetime
      add :phone, :string
      add :avatar_url, :string
      add :reputation_score, :integer, default: 100
    end

    create unique_index(:users, [:phone], where: "phone IS NOT NULL")
  end
end
