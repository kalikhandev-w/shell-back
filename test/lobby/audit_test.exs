defmodule Lobby.AuditTest do
  use Lobby.DataCase, async: true

  alias Lobby.Audit
  import Lobby.Fixtures

  setup do
    club = create_club()
    admin = create_admin(club)
    user = create_user(club)
    %{club: club, admin: admin, user: user}
  end

  test "log creates audit entry", %{club: club, admin: admin} do
    {:ok, log} = Audit.log(%{
      action: "session.start", club_id: club.id, user_id: admin.id,
      target_type: "Session", target_id: Ecto.UUID.generate()
    })
    assert log.action == "session.start"
  end

  test "list_audit_logs with filters", %{club: club, admin: admin} do
    Audit.log(%{action: "session.start", club_id: club.id, user_id: admin.id, target_type: "Session", target_id: Ecto.UUID.generate()})
    Audit.log(%{action: "shift.open", club_id: club.id, user_id: admin.id, target_type: "Shift", target_id: Ecto.UUID.generate()})

    all = Audit.list_audit_logs(club.id)
    assert length(all) == 2

    filtered = Audit.list_audit_logs(club.id, action: "shift.open")
    assert length(filtered) == 1
  end

  test "create and list notes", %{club: club, admin: admin, user: user} do
    {:ok, note} = Audit.create_note(%{
      type: "warning", text: "Late payment",
      gamer_id: user.id, club_id: club.id, created_by: admin.id
    })
    assert note.type == "warning"

    notes = Audit.list_notes(user.id, club.id)
    assert length(notes) == 1
  end
end
