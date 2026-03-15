defmodule LobbyWeb.UpdateController do
  use LobbyWeb, :controller

  @doc """
  Tauri updater endpoint. Returns update info if a newer version exists.
  The actual update files should be hosted on a CDN or static server.

  Configure via env vars:
    SHELL_VERSION - current latest version (e.g. "0.2.0")
    SHELL_UPDATE_URL - URL to the update bundle
    SHELL_SIGNATURE - signature of the update bundle
  """
  def check(conn, %{"current_version" => current_version, "target" => _target}) do
    latest = System.get_env("SHELL_VERSION", "0.1.0")

    if Version.compare(current_version, latest) == :lt do
      update_url = System.get_env("SHELL_UPDATE_URL", "")
      signature = System.get_env("SHELL_SIGNATURE", "")

      conn
      |> put_status(200)
      |> json(%{
        version: latest,
        url: update_url,
        signature: signature,
        notes: "Update to #{latest}"
      })
    else
      conn |> put_status(204) |> send_resp(204, "")
    end
  end

  def check(conn, _params) do
    conn |> put_status(400) |> json(%{error: "Missing current_version and target"})
  end
end
