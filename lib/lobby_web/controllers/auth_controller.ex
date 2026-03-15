defmodule LobbyWeb.AuthController do
  use LobbyWeb, :controller

  alias Lobby.Accounts
  alias Lobby.Guardian

  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate(email, password) do
      {:ok, user} ->
        {:ok, token, _claims} = Guardian.encode_and_sign(user, %{}, ttl: {7, :day})

        conn
        |> put_status(200)
        |> json(%{token: token, user: user_json(user)})

      {:error, _reason} ->
        conn
        |> put_status(401)
        |> json(%{error: "Invalid email or password"})
    end
  end

  def register(conn, %{"email" => email, "password" => password} = params) do
    attrs = %{
      email: email,
      password: password,
      username: params["username"],
      club_id: params["club_id"]
    }

    case Accounts.register(attrs) do
      {:ok, user} ->
        {:ok, token, _claims} = Guardian.encode_and_sign(user, %{}, ttl: {7, :day})

        conn
        |> put_status(201)
        |> json(%{token: token, user: user_json(user)})

      {:error, changeset} ->
        conn
        |> put_status(422)
        |> json(%{error: "Registration failed", details: changeset_errors(changeset)})
    end
  end

  def guest(conn, params) do
    attrs = %{
      username: params["username"],
      club_id: params["club_id"]
    }

    case Accounts.create_guest(attrs) do
      {:ok, user} ->
        {:ok, token, _claims} = Guardian.encode_and_sign(user, %{}, ttl: {1, :day})

        conn
        |> put_status(201)
        |> json(%{token: token, user: user_json(user)})

      {:error, changeset} ->
        conn
        |> put_status(422)
        |> json(%{error: "Guest creation failed", details: changeset_errors(changeset)})
    end
  end

  def refresh(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    {:ok, token, _claims} = Guardian.encode_and_sign(user, %{}, ttl: {7, :day})

    conn
    |> put_status(200)
    |> json(%{token: token, user: user_json(user)})
  end

  def profile(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    conn
    |> put_status(200)
    |> json(%{user: user_json(user)})
  end

  defp user_json(user) do
    %{
      id: user.id,
      email: user.email,
      username: user.username,
      steam_id: user.steam_id,
      is_guest: user.is_guest,
      balance_tiyn: user.balance_tiyn,
      total_sessions: user.total_sessions,
      total_minutes: user.total_minutes
    }
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
