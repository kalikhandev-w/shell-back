defmodule LobbyWeb.HeartbeatController do
  use LobbyWeb, :controller

  alias Lobby.Clubs

  def create(conn, params) do
    pc_token = get_req_header(conn, "x-pc-token") |> List.first()

    case Clubs.get_pc_by_token(pc_token) do
      nil ->
        conn |> put_status(401) |> json(%{error: "Invalid PC token"})

      pc ->
        attrs = %{
          hostname: params["hostname"],
          mac_address: params["mac_address"],
          ip_address: params["ip_address"],
          specs: params["specs"],
          status: params["status"] || pc.status
        }

        {:ok, _pc} = Clubs.update_heartbeat(pc, attrs)

        conn
        |> put_status(200)
        |> json(%{ok: true})
    end
  end
end
