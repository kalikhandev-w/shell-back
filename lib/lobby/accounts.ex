defmodule Lobby.Accounts do
  alias Lobby.Repo
  alias Lobby.Accounts.User

  def get_user(id), do: Repo.get(User, id)

  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  def get_user_by_steam_id(steam_id) do
    Repo.get_by(User, steam_id: steam_id)
  end

  def register(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def create_guest(attrs \\ %{}) do
    %User{}
    |> User.guest_changeset(attrs)
    |> Repo.insert()
  end

  def find_or_create_steam_user(steam_id, attrs) do
    case get_user_by_steam_id(steam_id) do
      nil ->
        %User{}
        |> User.steam_changeset(Map.put(attrs, :steam_id, steam_id))
        |> Repo.insert()

      user ->
        {:ok, user}
    end
  end

  def authenticate(email, password) do
    user = get_user_by_email(email)

    cond do
      user && Pbkdf2.verify_pass(password, user.password_hash) ->
        {:ok, user}

      user ->
        {:error, :invalid_password}

      true ->
        Pbkdf2.no_user_verify()
        {:error, :not_found}
    end
  end

  def get_profile(user_id) do
    Repo.get(User, user_id)
  end

  def deduct_balance(user, amount_tiyn) do
    user
    |> User.balance_changeset(-amount_tiyn)
    |> Repo.update()
  end

  def add_balance(user, amount_tiyn) do
    user
    |> User.balance_changeset(amount_tiyn)
    |> Repo.update()
  end

  def increment_stats(user, minutes) do
    user
    |> Ecto.Changeset.change(
      total_sessions: user.total_sessions + 1,
      total_minutes: user.total_minutes + minutes
    )
    |> Repo.update()
  end

  # ── Admin queries ──

  def list_users(club_id) do
    import Ecto.Query
    Lobby.Accounts.User
    |> where([u], u.club_id == ^club_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def update_user(user, attrs) do
    user
    |> Ecto.Changeset.change(attrs)
    |> Repo.update()
  end

  def set_admin(user, is_admin) do
    user
    |> Ecto.Changeset.change(is_admin: is_admin)
    |> Repo.update()
  end
end
