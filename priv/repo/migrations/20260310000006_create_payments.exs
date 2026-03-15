defmodule Lobby.Repo.Migrations.CreatePayments do
  use Ecto.Migration

  def change do
    create table(:payments, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :method, :string, null: false
      add :amount_tiyn, :integer, null: false
      add :status, :string, default: "pending"
      add :user_id, references(:users, type: :uuid, on_delete: :nilify_all)
      add :session_id, references(:sessions, type: :uuid, on_delete: :nilify_all)
      add :club_id, references(:clubs, type: :uuid, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:payments, [:user_id])
    create index(:payments, [:session_id])
    create index(:payments, [:status])
  end
end
