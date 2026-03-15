defmodule Lobby.Clubs.PC do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "pcs" do
    field :pc_token, :string
    field :hostname, :string
    field :mac_address, :string
    field :ip_address, :string
    field :status, :string, default: "free"
    field :zone, :string, default: "standard"
    field :specs, :map, default: %{}
    field :last_heartbeat_at, :utc_datetime

    belongs_to :club, Lobby.Clubs.Club

    timestamps(type: :utc_datetime)
  end

  def changeset(pc, attrs) do
    pc
    |> cast(attrs, [:pc_token, :hostname, :mac_address, :ip_address, :status, :zone, :specs, :club_id])
    |> validate_required([:pc_token, :club_id])
    |> unique_constraint(:pc_token)
  end

  def heartbeat_changeset(pc, attrs) do
    pc
    |> cast(attrs, [:hostname, :mac_address, :ip_address, :specs, :status])
    |> put_change(:last_heartbeat_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end
end
