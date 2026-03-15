defmodule Lobby.Gaming do
  import Ecto.Query
  alias Lobby.Repo
  alias Lobby.Gaming.{Session, Game}

  # ── Sessions ──

  def get_session(id), do: Repo.get(Session, id)

  def start_session(attrs) do
    %Session{}
    |> Session.create_changeset(attrs)
    |> Repo.insert()
  end

  def end_session(session) do
    session
    |> Session.end_changeset()
    |> Repo.update()
  end

  def extend_session(session, extra_minutes) do
    session
    |> Session.extend_changeset(extra_minutes)
    |> Repo.update()
  end

  def pause_session(session) do
    session
    |> Session.pause_changeset()
    |> Repo.update()
  end

  def resume_session(session) do
    session
    |> Session.resume_changeset()
    |> Repo.update()
  end

  def move_session(session, new_pc_id) do
    session
    |> Session.move_changeset(new_pc_id)
    |> Repo.update()
  end

  def add_free_time(session, minutes, note \\ nil) do
    session
    |> Session.add_time_changeset(minutes, note)
    |> Repo.update()
  end

  def get_active_session_for_pc(pc_id) do
    Session
    |> where([s], s.pc_id == ^pc_id and s.status == "active")
    |> order_by(desc: :started_at)
    |> limit(1)
    |> Repo.one()
  end

  def remaining_seconds(%Session{} = session) do
    if session.status == "paused" do
      # While paused, calculate based on time before pause
      elapsed = DateTime.diff(session.paused_at, session.started_at, :second)
      total = session.duration_minutes * 60
      pause_secs = session.total_pause_seconds || 0
      max(total - elapsed + pause_secs, 0)
    else
      elapsed = DateTime.diff(DateTime.utc_now(), session.started_at, :second)
      total = session.duration_minutes * 60
      pause_secs = session.total_pause_seconds || 0
      max(total - elapsed + pause_secs, 0)
    end
  end

  # ── Games ──

  def list_games(club_id) do
    Game
    |> where([g], g.club_id == ^club_id and g.is_active == true)
    |> order_by(:name)
    |> Repo.all()
  end

  def get_popular_games(club_id, limit \\ 5) do
    # For now return first N games; later integrate with play-time stats
    Game
    |> where([g], g.club_id == ^club_id and g.is_active == true)
    |> limit(^limit)
    |> Repo.all()
  end

  def get_game(id), do: Repo.get(Game, id)

  def create_game(attrs) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  def update_game(game, attrs) do
    game
    |> Game.changeset(attrs)
    |> Repo.update()
  end

  def delete_game(game) do
    Repo.delete(game)
  end

  # ── Admin queries ──

  def list_sessions(club_id, opts \\ []) do
    query =
      Session
      |> where([s], s.club_id == ^club_id)

    query =
      case Keyword.get(opts, :status) do
        nil -> query
        status -> where(query, [s], s.status == ^status)
      end

    query
    |> order_by(desc: :started_at)
    |> limit(^Keyword.get(opts, :limit, 50))
    |> Repo.all()
  end

  def list_user_sessions(user_id, opts \\ []) do
    query =
      Session
      |> where([s], s.user_id == ^user_id)

    query =
      case Keyword.get(opts, :status) do
        nil -> query
        status -> where(query, [s], s.status == ^status)
      end

    query
    |> order_by(desc: :started_at)
    |> limit(^Keyword.get(opts, :limit, 50))
    |> Repo.all()
  end

  def list_active_sessions(club_id) do
    Session
    |> where([s], s.club_id == ^club_id and s.status == "active")
    |> order_by(desc: :started_at)
    |> Repo.all()
  end

  def list_all_games(club_id) do
    Game
    |> where([g], g.club_id == ^club_id)
    |> order_by(:name)
    |> Repo.all()
  end
end
