defmodule Lobby.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :email, :string
    field :username, :string
    field :password_hash, :string
    field :steam_id, :string
    field :is_guest, :boolean, default: false
    field :is_admin, :boolean, default: false
    field :balance_tiyn, :integer, default: 0
    field :total_sessions, :integer, default: 0
    field :total_minutes, :integer, default: 0
    field :role, :string, default: "gamer"
    field :is_banned, :boolean, default: false
    field :ban_reason, :string
    field :ban_until, :utc_datetime
    field :phone, :string
    field :avatar_url, :string
    field :reputation_score, :integer, default: 100
    field :bonus_balance, :integer, default: 0

    field :password, :string, virtual: true

    belongs_to :club, Lobby.Clubs.Club
    has_many :sessions, Lobby.Gaming.Session
    has_many :orders, Lobby.Pos.Order

    timestamps(type: :utc_datetime)
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :password, :club_id])
    |> validate_required([:email, :password])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:password, min: 6)
    |> unique_constraint(:email)
    |> hash_password()
  end

  def guest_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :club_id])
    |> put_change(:is_guest, true)
    |> put_change(:username, attrs[:username] || "Guest-#{:rand.uniform(9999)}")
  end

  def steam_changeset(user, attrs) do
    user
    |> cast(attrs, [:steam_id, :username, :club_id])
    |> validate_required([:steam_id])
    |> unique_constraint(:steam_id)
  end

  def balance_changeset(user, amount_tiyn) do
    user
    |> change(balance_tiyn: user.balance_tiyn + amount_tiyn)
    |> validate_number(:balance_tiyn, greater_than_or_equal_to: 0)
  end

  defp hash_password(%{valid?: true, changes: %{password: password}} = changeset) do
    put_change(changeset, :password_hash, Pbkdf2.hash_pwd_salt(password))
  end

  defp hash_password(changeset), do: changeset
end
