defmodule Lobby.Repo.Migrations.CreateShifts do
  use Ecto.Migration

  def change do
    create table(:shifts, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :opened_at, :utc_datetime, null: false
      add :closed_at, :utc_datetime
      add :opening_cash, :integer, default: 0
      add :closing_cash, :integer
      add :total_revenue, :integer, default: 0
      add :total_cash, :integer, default: 0
      add :total_balance, :integer, default: 0
      add :total_package, :integer, default: 0
      add :sessions_count, :integer, default: 0
      add :orders_count, :integer, default: 0
      add :discrepancy, :integer
      add :status, :string, default: "open"
      add :club_id, references(:clubs, type: :uuid, on_delete: :delete_all), null: false
      add :staff_id, references(:users, type: :uuid, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:shifts, [:club_id])
    create index(:shifts, [:club_id, :status])

    create table(:cash_operations, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :type, :string, null: false
      add :amount, :integer, null: false
      add :description, :string
      add :shift_id, references(:shifts, type: :uuid, on_delete: :delete_all), null: false
      add :club_id, references(:clubs, type: :uuid, on_delete: :delete_all), null: false
      add :created_by, references(:users, type: :uuid, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:cash_operations, [:shift_id])

    # Link sessions to shifts
    alter table(:sessions) do
      add :shift_id, references(:shifts, type: :uuid, on_delete: :nilify_all)
      add :paused_at, :utc_datetime
      add :total_pause_seconds, :integer, default: 0
      add :payment_method, :string, default: "balance"
      add :payment_source, :string, default: "self_service"
      add :notes, :string
    end

    # Link orders to shifts
    alter table(:orders) do
      add :shift_id, references(:shifts, type: :uuid, on_delete: :nilify_all)
      add :pc_id, references(:pcs, type: :uuid, on_delete: :nilify_all)
      add :payment_method, :string, default: "balance"
    end
  end
end
