defmodule Lobby.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :status, :string, default: "pending"
      add :total_price_tiyn, :integer, default: 0
      add :items, {:array, :map}, default: []
      add :user_id, references(:users, type: :uuid, on_delete: :nilify_all)
      add :session_id, references(:sessions, type: :uuid, on_delete: :nilify_all)
      add :club_id, references(:clubs, type: :uuid, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:orders, [:user_id])
    create index(:orders, [:session_id])
    create index(:orders, [:club_id])
    create index(:orders, [:status])
  end
end
