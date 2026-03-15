defmodule Lobby.Repo.Migrations.CreateBookings do
  use Ecto.Migration

  def change do
    create table(:bookings, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :booked_for, :utc_datetime, null: false
      add :gamer_name, :string
      add :status, :string, default: "active"
      add :club_id, references(:clubs, type: :uuid, on_delete: :delete_all), null: false
      add :pc_id, references(:pcs, type: :uuid, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :uuid, on_delete: :nilify_all)
      add :created_by, references(:users, type: :uuid, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:bookings, [:club_id])
    create index(:bookings, [:pc_id, :status])
    create index(:bookings, [:booked_for])
  end
end
