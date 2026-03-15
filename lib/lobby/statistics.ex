defmodule Lobby.Statistics do
  import Ecto.Query
  alias Lobby.Repo
  alias Lobby.Gaming.Session
  alias Lobby.Billing.Payment
  alias Lobby.Clubs.PC

  def dashboard(club_id) do
    %{
      active_sessions: count_active_sessions(club_id),
      total_pcs: count_pcs(club_id),
      online_pcs: count_online_pcs(club_id),
      today_revenue: today_revenue(club_id),
      today_sessions: today_sessions_count(club_id),
      pending_orders: pending_orders_count(club_id)
    }
  end

  def revenue_stats(club_id, days \\ 7) do
    since = DateTime.utc_now() |> DateTime.add(-days * 86400, :second) |> DateTime.truncate(:second)

    Payment
    |> where([p], p.club_id == ^club_id and p.status == "confirmed" and p.inserted_at >= ^since)
    |> group_by([p], fragment("date(?)", p.inserted_at))
    |> select([p], %{date: fragment("date(?)", p.inserted_at), total: sum(p.amount_tiyn), count: count(p.id)})
    |> order_by([p], fragment("date(?)", p.inserted_at))
    |> Repo.all()
  end

  def session_stats(club_id, days \\ 7) do
    since = DateTime.utc_now() |> DateTime.add(-days * 86400, :second) |> DateTime.truncate(:second)

    Session
    |> where([s], s.club_id == ^club_id and s.started_at >= ^since)
    |> group_by([s], fragment("date(?)", s.started_at))
    |> select([s], %{
      date: fragment("date(?)", s.started_at),
      count: count(s.id),
      total_minutes: sum(s.duration_minutes),
      total_revenue: sum(s.total_price_tiyn)
    })
    |> order_by([s], fragment("date(?)", s.started_at))
    |> Repo.all()
  end

  # Occupancy heatmap: hour × day_of_week → occupancy %
  def occupancy_stats(club_id, days \\ 30) do
    since = DateTime.utc_now() |> DateTime.add(-days * 86400, :second) |> DateTime.truncate(:second)
    total_pcs = count_pcs(club_id)

    if total_pcs == 0 do
      []
    else
      Session
      |> where([s], s.club_id == ^club_id and s.started_at >= ^since)
      |> group_by([s], [fragment("extract(dow from ?)", s.started_at), fragment("extract(hour from ?)", s.started_at)])
      |> select([s], %{
        day_of_week: fragment("extract(dow from ?)::int", s.started_at),
        hour: fragment("extract(hour from ?)::int", s.started_at),
        sessions: count(s.id),
        avg_duration: avg(s.duration_minutes)
      })
      |> Repo.all()
      |> Enum.map(fn row ->
        Map.put(row, :occupancy_percent, min(round(row.sessions / max(total_pcs, 1) * 100), 100))
      end)
    end
  end

  # Customer analytics
  def customer_stats(club_id, days \\ 30) do
    since = DateTime.utc_now() |> DateTime.add(-days * 86400, :second) |> DateTime.truncate(:second)

    total_customers =
      Session
      |> where([s], s.club_id == ^club_id and s.started_at >= ^since)
      |> select([s], count(s.user_id, :distinct))
      |> Repo.one()

    returning_customers =
      Session
      |> where([s], s.club_id == ^club_id and s.started_at >= ^since)
      |> group_by([s], s.user_id)
      |> having([s], count(s.id) >= 3)
      |> select([s], count(s.user_id))
      |> Repo.all()
      |> length()

    new_today =
      Lobby.Accounts.User
      |> where([u], u.club_id == ^club_id and u.inserted_at >= ^DateTime.new!(Date.utc_today(), ~T[00:00:00], "Etc/UTC"))
      |> where([u], u.is_guest == false)
      |> Repo.aggregate(:count)

    top_customers =
      Session
      |> where([s], s.club_id == ^club_id and s.started_at >= ^since)
      |> join(:inner, [s], u in Lobby.Accounts.User, on: s.user_id == u.id)
      |> group_by([s, u], [u.id, u.username, u.email])
      |> select([s, u], %{
        user_id: u.id,
        username: u.username,
        email: u.email,
        sessions_count: count(s.id),
        total_minutes: sum(s.duration_minutes),
        total_spent: sum(s.total_price_tiyn)
      })
      |> order_by([s, u], desc: sum(s.total_price_tiyn))
      |> limit(10)
      |> Repo.all()

    %{
      total_customers: total_customers,
      returning_customers: returning_customers,
      retention_percent: if(total_customers > 0, do: round(returning_customers / total_customers * 100), else: 0),
      new_today: new_today,
      top_customers: top_customers
    }
  end

  # Game library stats (grouped by category)
  def game_stats(club_id) do
    Lobby.Gaming.Game
    |> where([g], g.club_id == ^club_id and g.is_active == true)
    |> group_by([g], g.category)
    |> select([g], %{category: g.category, count: count(g.id)})
    |> order_by([g], desc: count(g.id))
    |> Repo.all()
  end

  # ── Private ──

  defp count_active_sessions(club_id) do
    Session
    |> where([s], s.club_id == ^club_id and s.status == "active")
    |> Repo.aggregate(:count)
  end

  defp count_pcs(club_id) do
    PC
    |> where([p], p.club_id == ^club_id)
    |> Repo.aggregate(:count)
  end

  defp count_online_pcs(club_id) do
    five_min_ago = DateTime.utc_now() |> DateTime.add(-300, :second) |> DateTime.truncate(:second)

    PC
    |> where([p], p.club_id == ^club_id and p.last_heartbeat_at >= ^five_min_ago)
    |> Repo.aggregate(:count)
  end

  defp today_revenue(club_id) do
    today = Date.utc_today()
    start_of_day = DateTime.new!(today, ~T[00:00:00], "Etc/UTC")

    Payment
    |> where([p], p.club_id == ^club_id and p.status == "confirmed" and p.inserted_at >= ^start_of_day)
    |> Repo.aggregate(:sum, :amount_tiyn) || 0
  end

  defp today_sessions_count(club_id) do
    today = Date.utc_today()
    start_of_day = DateTime.new!(today, ~T[00:00:00], "Etc/UTC")

    Session
    |> where([s], s.club_id == ^club_id and s.started_at >= ^start_of_day)
    |> Repo.aggregate(:count)
  end

  defp pending_orders_count(club_id) do
    Lobby.Pos.Order
    |> where([o], o.club_id == ^club_id and o.status in ["pending", "preparing"])
    |> Repo.aggregate(:count)
  end
end
