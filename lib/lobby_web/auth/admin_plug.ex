defmodule LobbyWeb.Auth.AdminPlug do
  @moduledoc """
  Plug that ensures the current user is an admin.
  Must be used after Guardian.Plug.EnsureAuthenticated.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    user = Lobby.Guardian.Plug.current_resource(conn)

    if user && user.is_admin do
      conn
    else
      conn
      |> put_status(403)
      |> Phoenix.Controller.json(%{error: "Admin access required"})
      |> halt()
    end
  end
end
