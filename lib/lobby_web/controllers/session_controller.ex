defmodule LobbyWeb.SessionController do
  use LobbyWeb, :controller

  alias Lobby.Gaming
  alias Lobby.Clubs
  alias Lobby.Guardian

  def create(conn, %{"tariff_id" => tariff_id, "duration_minutes" => duration, "pc_token" => pc_token}) do
    user = Guardian.Plug.current_resource(conn)
    pc = Clubs.get_pc_by_token(pc_token)
    tariff = Clubs.get_tariff(tariff_id)

    cond do
      is_nil(pc) ->
        conn |> put_status(404) |> json(%{error: "PC not found"})

      is_nil(tariff) ->
        conn |> put_status(404) |> json(%{error: "Tariff not found"})

      true ->
        total_price = round(tariff.price_per_hour_tiyn / 60 * duration)

        attrs = %{
          duration_minutes: duration,
          total_price_tiyn: total_price,
          user_id: user.id,
          pc_id: pc.id,
          tariff_id: tariff.id,
          club_id: pc.club_id
        }

        case Gaming.start_session(attrs) do
          {:ok, session} ->
            Clubs.set_pc_status(pc, "occupied")

            conn
            |> put_status(201)
            |> json(%{session: session_json(session, tariff)})

          {:error, _changeset} ->
            conn
            |> put_status(422)
            |> json(%{error: "Failed to start session"})
        end
    end
  end

  def show(conn, %{"id" => id}) do
    case Gaming.get_session(id) do
      nil ->
        conn |> put_status(404) |> json(%{error: "Session not found"})

      session ->
        tariff = Clubs.get_tariff(session.tariff_id)
        remaining = Gaming.remaining_seconds(session)

        conn
        |> put_status(200)
        |> json(%{session: session_json(session, tariff), remaining_seconds: remaining})
    end
  end

  def end_session(conn, %{"id" => id}) do
    case Gaming.get_session(id) do
      nil ->
        conn |> put_status(404) |> json(%{error: "Session not found"})

      session ->
        {:ok, session} = Gaming.end_session(session)

        if session.pc_id do
          pc = Clubs.get_pc(session.pc_id)
          if pc, do: Clubs.set_pc_status(pc, "free")
        end

        conn
        |> put_status(200)
        |> json(%{session: %{id: session.id, status: session.status}})
    end
  end

  def extend(conn, %{"id" => id, "minutes" => minutes}) do
    case Gaming.get_session(id) do
      nil ->
        conn |> put_status(404) |> json(%{error: "Session not found"})

      session ->
        {:ok, session} = Gaming.extend_session(session, minutes)

        conn
        |> put_status(200)
        |> json(%{session: %{id: session.id, duration_minutes: session.duration_minutes}})
    end
  end

  def pause(conn, %{"id" => id}) do
    case Gaming.get_session(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Session not found"})
      session ->
        case Gaming.pause_session(session) do
          {:ok, session} -> conn |> put_status(200) |> json(%{session: %{id: session.id, status: session.status, paused_at: session.paused_at}})
          {:error, _} -> conn |> put_status(422) |> json(%{error: "Cannot pause session"})
        end
    end
  end

  def resume(conn, %{"id" => id}) do
    case Gaming.get_session(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Session not found"})
      session ->
        case Gaming.resume_session(session) do
          {:ok, session} -> conn |> put_status(200) |> json(%{session: %{id: session.id, status: session.status}})
          {:error, _} -> conn |> put_status(422) |> json(%{error: "Cannot resume session"})
        end
    end
  end

  def move(conn, %{"id" => id, "pc_id" => new_pc_id}) do
    case Gaming.get_session(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Session not found"})
      session ->
        old_pc_id = session.pc_id
        case Gaming.move_session(session, new_pc_id) do
          {:ok, session} ->
            if old_pc = Clubs.get_pc(old_pc_id), do: Clubs.set_pc_status(old_pc, "free")
            if new_pc = Clubs.get_pc(new_pc_id), do: Clubs.set_pc_status(new_pc, "occupied")
            conn |> put_status(200) |> json(%{session: %{id: session.id, pc_id: session.pc_id}})
          {:error, _} -> conn |> put_status(422) |> json(%{error: "Cannot move session"})
        end
    end
  end

  def add_time(conn, %{"id" => id, "minutes" => minutes}) do
    case Gaming.get_session(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Session not found"})
      session ->
        case Gaming.add_free_time(session, minutes) do
          {:ok, session} -> conn |> put_status(200) |> json(%{session: %{id: session.id, duration_minutes: session.duration_minutes}})
          {:error, _} -> conn |> put_status(422) |> json(%{error: "Cannot add time"})
        end
    end
  end

  def history(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    opts = [status: params["status"], limit: parse_int(params["limit"], 50)]
    sessions = Gaming.list_user_sessions(user.id, opts)
    conn |> put_status(200) |> json(%{sessions: Enum.map(sessions, &history_json/1)})
  end

  def tariffs(conn, %{"club_id" => club_id}) do
    tariffs = Clubs.list_tariffs(club_id)

    conn
    |> put_status(200)
    |> json(%{tariffs: Enum.map(tariffs, &tariff_json/1)})
  end

  defp session_json(session, tariff) do
    %{
      id: session.id,
      status: session.status,
      duration_minutes: session.duration_minutes,
      total_price_tiyn: session.total_price_tiyn,
      started_at: session.started_at,
      ended_at: session.ended_at,
      tariff_name: tariff && tariff.name
    }
  end

  defp history_json(session) do
    %{
      id: session.id,
      status: session.status,
      duration_minutes: session.duration_minutes,
      total_price_tiyn: session.total_price_tiyn,
      started_at: session.started_at,
      ended_at: session.ended_at,
      pc_id: session.pc_id,
      payment_method: session.payment_method
    }
  end

  defp tariff_json(tariff) do
    %{
      id: tariff.id,
      name: tariff.name,
      zone: tariff.zone,
      price_per_hour_tiyn: tariff.price_per_hour_tiyn
    }
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
