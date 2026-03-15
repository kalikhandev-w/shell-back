defmodule Lobby.Repo.Migrations.CreateLoyalty do
  use Ecto.Migration

  def change do
    create table(:bonus_transactions, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :amount, :integer, null: false
      add :reason, :string, null: false
      add :reference_id, :uuid
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :club_id, references(:clubs, type: :uuid, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:bonus_transactions, [:user_id, :club_id])

    create table(:promo_rules, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :name, :string, null: false
      add :type, :string, null: false
      add :conditions, :map, default: %{}
      add :discount_percent, :integer
      add :is_active, :boolean, default: true
      add :club_id, references(:clubs, type: :uuid, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:promo_rules, [:club_id])

    # Add bonus_balance to users
    alter table(:users) do
      add :bonus_balance, :integer, default: 0
    end
  end
end
