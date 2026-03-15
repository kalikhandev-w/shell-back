defmodule Lobby.Audit.AuditLog do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "audit_logs" do
    field :action, :string
    field :target_type, :string
    field :target_id, :binary_id
    field :details, :map, default: %{}

    belongs_to :club, Lobby.Clubs.Club
    belongs_to :user, Lobby.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(log, attrs) do
    log
    |> cast(attrs, [:action, :target_type, :target_id, :details, :club_id, :user_id])
    |> validate_required([:action, :club_id])
  end
end
