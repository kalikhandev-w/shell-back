defmodule Lobby.Packages.GamerPackage do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "gamer_packages" do
    field :hours_remaining, :decimal
    field :purchased_at, :utc_datetime
    field :expires_at, :utc_datetime
    field :status, :string, default: "active"

    belongs_to :user, Lobby.Accounts.User
    belongs_to :club, Lobby.Clubs.Club
    belongs_to :package, Lobby.Packages.Package
    belongs_to :sold_by_user, Lobby.Accounts.User, foreign_key: :sold_by

    timestamps(type: :utc_datetime)
  end

  def changeset(gp, attrs) do
    gp
    |> cast(attrs, [:hours_remaining, :purchased_at, :expires_at, :status,
                     :user_id, :club_id, :package_id, :sold_by])
    |> validate_required([:purchased_at, :expires_at, :user_id, :club_id, :package_id])
    |> validate_inclusion(:status, ~w(active expired exhausted))
  end

  def deduct_changeset(gp, hours) do
    new_remaining = Decimal.sub(gp.hours_remaining, Decimal.new(hours))

    status =
      if Decimal.compare(new_remaining, Decimal.new(0)) in [:lt, :eq],
        do: "exhausted",
        else: gp.status

    gp
    |> Ecto.Changeset.change(hours_remaining: new_remaining, status: status)
  end
end
