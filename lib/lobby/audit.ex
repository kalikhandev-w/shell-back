defmodule Lobby.Audit do
  import Ecto.Query
  alias Lobby.Repo
  alias Lobby.Audit.{AuditLog, GamerNote}

  # Audit log
  def log(attrs) do
    %AuditLog{}
    |> AuditLog.changeset(attrs)
    |> Repo.insert()
  end

  def list_audit_logs(club_id, opts \\ []) do
    query =
      AuditLog
      |> where([a], a.club_id == ^club_id)

    query =
      case Keyword.get(opts, :action) do
        nil -> query
        action -> where(query, [a], a.action == ^action)
      end

    query
    |> order_by(desc: :inserted_at)
    |> limit(^Keyword.get(opts, :limit, 100))
    |> Repo.all()
  end

  # Gamer notes
  def create_note(attrs) do
    %GamerNote{}
    |> GamerNote.changeset(attrs)
    |> Repo.insert()
  end

  def list_notes(gamer_id, club_id) do
    GamerNote
    |> where([n], n.gamer_id == ^gamer_id and n.club_id == ^club_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end
end
