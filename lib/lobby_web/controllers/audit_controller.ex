defmodule LobbyWeb.AuditController do
  use LobbyWeb, :controller

  alias Lobby.Audit
  alias Lobby.Guardian

  def index(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    opts = [action: params["action"], limit: parse_int(params["limit"], 100)]
    logs = Audit.list_audit_logs(user.club_id, opts)
    conn |> put_status(200) |> json(%{audit_logs: Enum.map(logs, &log_json/1)})
  end

  # Gamer notes
  def create_note(conn, %{"gamer_id" => gamer_id} = params) do
    user = Guardian.Plug.current_resource(conn)

    attrs = %{
      type: params["type"] || "note",
      text: params["text"],
      amount: params["amount"],
      gamer_id: gamer_id,
      club_id: user.club_id,
      created_by: user.id
    }

    case Audit.create_note(attrs) do
      {:ok, note} -> conn |> put_status(201) |> json(%{note: note_json(note)})
      {:error, _} -> conn |> put_status(422) |> json(%{error: "Failed"})
    end
  end

  def list_notes(conn, %{"gamer_id" => gamer_id}) do
    user = Guardian.Plug.current_resource(conn)
    notes = Audit.list_notes(gamer_id, user.club_id)
    conn |> put_status(200) |> json(%{notes: Enum.map(notes, &note_json/1)})
  end

  # Ban/unban
  def ban_user(conn, %{"id" => id} = params) do
    admin = Guardian.Plug.current_resource(conn)

    case Lobby.Accounts.get_user(id) do
      nil -> conn |> put_status(404) |> json(%{error: "User not found"})
      target ->
        ban_until = params["ban_until"]
        attrs = %{is_banned: true, ban_reason: params["reason"], ban_until: ban_until}
        case Lobby.Accounts.update_user(target, attrs) do
          {:ok, updated} ->
            Audit.log(%{action: "gamer.ban", club_id: admin.club_id, user_id: admin.id,
                        target_type: "User", target_id: id, details: %{reason: params["reason"]}})
            conn |> put_status(200) |> json(%{user: %{id: updated.id, is_banned: true}})
          {:error, _} ->
            conn |> put_status(422) |> json(%{error: "Failed to ban user"})
        end
    end
  end

  def unban_user(conn, %{"id" => id}) do
    admin = Guardian.Plug.current_resource(conn)

    case Lobby.Accounts.get_user(id) do
      nil -> conn |> put_status(404) |> json(%{error: "User not found"})
      target ->
        case Lobby.Accounts.update_user(target, %{is_banned: false, ban_reason: nil, ban_until: nil}) do
          {:ok, updated} ->
            Audit.log(%{action: "gamer.unban", club_id: admin.club_id, user_id: admin.id,
                        target_type: "User", target_id: id})
            conn |> put_status(200) |> json(%{user: %{id: updated.id, is_banned: false}})
          {:error, _} ->
            conn |> put_status(422) |> json(%{error: "Failed to unban user"})
        end
    end
  end

  defp log_json(l) do
    %{id: l.id, action: l.action, target_type: l.target_type,
      target_id: l.target_id, details: l.details,
      user_id: l.user_id, inserted_at: l.inserted_at}
  end

  defp note_json(n) do
    %{id: n.id, type: n.type, text: n.text, amount: n.amount,
      gamer_id: n.gamer_id, created_by: n.created_by, inserted_at: n.inserted_at}
  end

  defp parse_int(nil, default), do: default
  defp parse_int(val, _) when is_integer(val), do: val
  defp parse_int(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {n, _} -> n
      :error -> default
    end
  end
end
