defmodule LobbyWeb.ShellLogController do
  use LobbyWeb, :controller

  require Logger

  def create(conn, %{"logs" => logs}) when is_list(logs) do
    pc_token = get_req_header(conn, "x-pc-token") |> List.first()

    for log <- logs do
      Logger.info("[ShellLog] pc=#{pc_token} level=#{log["level"]} msg=#{log["message"]}")
    end

    conn |> put_status(200) |> json(%{ok: true, received: length(logs)})
  end

  def create(conn, _params) do
    conn |> put_status(400) |> json(%{error: "Expected 'logs' array"})
  end
end
