defmodule LobbyWeb.AdminController do
  use LobbyWeb, :controller

  alias Lobby.{Clubs, Gaming, Pos, Accounts, Billing, Statistics}
  alias Lobby.Guardian

  # ── Dashboard ──

  def dashboard(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    stats = Statistics.dashboard(user.club_id)
    conn |> put_status(200) |> json(%{dashboard: stats})
  end

  def revenue_stats(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    days = parse_int(params["days"], 7)
    stats = Statistics.revenue_stats(user.club_id, days)
    conn |> put_status(200) |> json(%{revenue: stats})
  end

  def session_stats(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    days = parse_int(params["days"], 7)
    stats = Statistics.session_stats(user.club_id, days)
    conn |> put_status(200) |> json(%{sessions: stats})
  end

  def occupancy_stats(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    days = parse_int(params["days"], 30)
    stats = Statistics.occupancy_stats(user.club_id, days)
    conn |> put_status(200) |> json(%{occupancy: stats})
  end

  def customer_stats(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    days = parse_int(params["days"], 30)
    stats = Statistics.customer_stats(user.club_id, days)
    conn |> put_status(200) |> json(%{customers: stats})
  end

  def game_stats(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    stats = Statistics.game_stats(user.club_id)
    conn |> put_status(200) |> json(%{games: stats})
  end

  # ── Club ──

  def update_club(conn, params) do
    user = Guardian.Plug.current_resource(conn)

    case Clubs.get_club(user.club_id) do
      nil -> conn |> put_status(404) |> json(%{error: "Club not found"})
      club ->
        case Clubs.update_club(club, params) do
          {:ok, club} -> conn |> put_status(200) |> json(%{club: club_json(club)})
          {:error, cs} -> conn |> put_status(422) |> json(%{error: "Failed", details: changeset_errors(cs)})
        end
    end
  end

  # ── PCs ──

  def list_pcs(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    pcs = Clubs.list_pcs(user.club_id)
    conn |> put_status(200) |> json(%{pcs: Enum.map(pcs, &pc_json/1)})
  end

  def update_pc(conn, %{"id" => id} = params) do
    case Clubs.get_pc(id) do
      nil -> conn |> put_status(404) |> json(%{error: "PC not found"})
      pc ->
        case Clubs.update_pc(pc, params) do
          {:ok, pc} -> conn |> put_status(200) |> json(%{pc: pc_json(pc)})
          {:error, cs} -> conn |> put_status(422) |> json(%{error: "Failed", details: changeset_errors(cs)})
        end
    end
  end

  def delete_pc(conn, %{"id" => id}) do
    case Clubs.get_pc(id) do
      nil -> conn |> put_status(404) |> json(%{error: "PC not found"})
      pc ->
        case Clubs.delete_pc(pc) do
          {:ok, _} -> conn |> put_status(200) |> json(%{ok: true})
          {:error, _} -> conn |> put_status(422) |> json(%{error: "Failed to delete PC"})
        end
    end
  end

  def send_command(conn, %{"pc_id" => pc_id, "action" => action} = params) do
    case Clubs.get_pc(pc_id) do
      nil ->
        conn |> put_status(404) |> json(%{error: "PC not found"})

      _pc ->
        payload = %{
          action: action,
          message: params["message"],
          minutes: params["minutes"]
        }

        Phoenix.PubSub.broadcast(
          Lobby.PubSub,
          "pc:#{pc_id}",
          {:admin_command, payload}
        )

        conn |> put_status(200) |> json(%{ok: true, action: action, pc_id: pc_id})
    end
  end

  def broadcast_command(conn, %{"action" => action} = params) do
    user = Guardian.Plug.current_resource(conn)
    pcs = Clubs.list_pcs(user.club_id)

    payload = %{
      action: action,
      message: params["message"],
      minutes: params["minutes"]
    }

    for pc <- pcs do
      Phoenix.PubSub.broadcast(
        Lobby.PubSub,
        "pc:#{pc.id}",
        {:admin_command, payload}
      )
    end

    conn |> put_status(200) |> json(%{ok: true, action: action, pc_count: length(pcs)})
  end

  # ── Tariffs ──

  def list_tariffs(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    tariffs = Clubs.list_all_tariffs(user.club_id)
    conn |> put_status(200) |> json(%{tariffs: Enum.map(tariffs, &tariff_json/1)})
  end

  def create_tariff(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    attrs = Map.put(params, "club_id", user.club_id)

    case Clubs.create_tariff(attrs) do
      {:ok, tariff} ->
        conn |> put_status(201) |> json(%{tariff: tariff_json(tariff)})
      {:error, changeset} ->
        conn |> put_status(422) |> json(%{error: "Validation failed", details: changeset_errors(changeset)})
    end
  end

  def update_tariff(conn, %{"id" => id} = params) do
    case Clubs.get_tariff(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Tariff not found"})
      tariff ->
        case Clubs.update_tariff(tariff, params) do
          {:ok, tariff} -> conn |> put_status(200) |> json(%{tariff: tariff_json(tariff)})
          {:error, cs} -> conn |> put_status(422) |> json(%{error: "Failed", details: changeset_errors(cs)})
        end
    end
  end

  def delete_tariff(conn, %{"id" => id}) do
    case Clubs.get_tariff(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Tariff not found"})
      tariff ->
        case Clubs.delete_tariff(tariff) do
          {:ok, _} -> conn |> put_status(200) |> json(%{ok: true})
          {:error, _} -> conn |> put_status(422) |> json(%{error: "Failed to delete tariff"})
        end
    end
  end

  # ── Sessions ──

  def list_sessions(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    opts = [status: params["status"], limit: parse_int(params["limit"], 50)]
    sessions = Gaming.list_sessions(user.club_id, opts)
    conn |> put_status(200) |> json(%{sessions: Enum.map(sessions, &session_json/1)})
  end

  def end_session(conn, %{"id" => id}) do
    case Gaming.get_session(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Session not found"})
      session ->
        case Gaming.end_session(session) do
          {:ok, session} ->
            if session.pc_id do
              pc = Clubs.get_pc(session.pc_id)
              if pc, do: Clubs.set_pc_status(pc, "free")
            end
            conn |> put_status(200) |> json(%{session: session_json(session)})
          {:error, _} ->
            conn |> put_status(422) |> json(%{error: "Failed to end session"})
        end
    end
  end

  # ── Games ──

  def list_games(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    games = Gaming.list_all_games(user.club_id)
    conn |> put_status(200) |> json(%{games: Enum.map(games, &game_json/1)})
  end

  def create_game(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    attrs = Map.put(params, "club_id", user.club_id)

    case Gaming.create_game(attrs) do
      {:ok, game} ->
        conn |> put_status(201) |> json(%{game: game_json(game)})
      {:error, changeset} ->
        conn |> put_status(422) |> json(%{error: "Validation failed", details: changeset_errors(changeset)})
    end
  end

  def update_game(conn, %{"id" => id} = params) do
    case Gaming.get_game(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Game not found"})
      game ->
        case Gaming.update_game(game, params) do
          {:ok, game} -> conn |> put_status(200) |> json(%{game: game_json(game)})
          {:error, cs} -> conn |> put_status(422) |> json(%{error: "Failed", details: changeset_errors(cs)})
        end
    end
  end

  def delete_game(conn, %{"id" => id}) do
    case Gaming.get_game(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Game not found"})
      game ->
        case Gaming.delete_game(game) do
          {:ok, _} -> conn |> put_status(200) |> json(%{ok: true})
          {:error, _} -> conn |> put_status(422) |> json(%{error: "Failed to delete game"})
        end
    end
  end

  # ── Menu ──

  def list_categories(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    categories = Pos.list_categories(user.club_id)
    conn |> put_status(200) |> json(%{categories: Enum.map(categories, &category_json/1)})
  end

  def create_category(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    attrs = Map.put(params, "club_id", user.club_id)

    case Pos.create_category(attrs) do
      {:ok, cat} ->
        conn |> put_status(201) |> json(%{category: category_json(cat)})
      {:error, changeset} ->
        conn |> put_status(422) |> json(%{error: "Validation failed", details: changeset_errors(changeset)})
    end
  end

  def update_category(conn, %{"id" => id} = params) do
    case Pos.get_category(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Category not found"})
      cat ->
        case Pos.update_category(cat, params) do
          {:ok, cat} -> conn |> put_status(200) |> json(%{category: category_json(cat)})
          {:error, cs} -> conn |> put_status(422) |> json(%{error: "Failed", details: changeset_errors(cs)})
        end
    end
  end

  def delete_category(conn, %{"id" => id}) do
    case Pos.get_category(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Category not found"})
      cat ->
        case Pos.delete_category(cat) do
          {:ok, _} -> conn |> put_status(200) |> json(%{ok: true})
          {:error, _} -> conn |> put_status(422) |> json(%{error: "Failed to delete category"})
        end
    end
  end

  def create_menu_item(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    attrs = Map.put(params, "club_id", user.club_id)

    case Pos.create_menu_item(attrs) do
      {:ok, item} ->
        conn |> put_status(201) |> json(%{item: item_json(item)})
      {:error, changeset} ->
        conn |> put_status(422) |> json(%{error: "Validation failed", details: changeset_errors(changeset)})
    end
  end

  def update_menu_item(conn, %{"id" => id} = params) do
    case Pos.get_menu_item(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Menu item not found"})
      item ->
        case Pos.update_menu_item(item, params) do
          {:ok, item} -> conn |> put_status(200) |> json(%{item: item_json(item)})
          {:error, cs} -> conn |> put_status(422) |> json(%{error: "Failed", details: changeset_errors(cs)})
        end
    end
  end

  def delete_menu_item(conn, %{"id" => id}) do
    case Pos.get_menu_item(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Menu item not found"})
      item ->
        case Pos.delete_menu_item(item) do
          {:ok, _} -> conn |> put_status(200) |> json(%{ok: true})
          {:error, _} -> conn |> put_status(422) |> json(%{error: "Failed to delete menu item"})
        end
    end
  end

  # ── Orders ──

  def list_orders(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    opts = [status: params["status"], limit: parse_int(params["limit"], 50)]
    orders = Pos.list_orders(user.club_id, opts)
    conn |> put_status(200) |> json(%{orders: Enum.map(orders, &order_json/1)})
  end

  # ── Users ──

  def list_users(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    users = Accounts.list_users(user.club_id)
    conn |> put_status(200) |> json(%{users: Enum.map(users, &user_json/1)})
  end

  def update_user(conn, %{"id" => id} = params) do
    case Accounts.get_user(id) do
      nil -> conn |> put_status(404) |> json(%{error: "User not found"})
      target_user ->
        attrs = %{}
        attrs = if params["balance_tiyn"], do: Map.put(attrs, :balance_tiyn, params["balance_tiyn"]), else: attrs
        attrs = if params["is_admin"] != nil, do: Map.put(attrs, :is_admin, params["is_admin"]), else: attrs
        attrs = if params["username"], do: Map.put(attrs, :username, params["username"]), else: attrs

        case Accounts.update_user(target_user, attrs) do
          {:ok, updated} -> conn |> put_status(200) |> json(%{user: user_json(updated)})
          {:error, _} -> conn |> put_status(422) |> json(%{error: "Failed to update user"})
        end
    end
  end

  def add_balance(conn, %{"id" => id, "amount_tiyn" => amount}) do
    case Accounts.get_user(id) do
      nil -> conn |> put_status(404) |> json(%{error: "User not found"})
      target_user ->
        case Accounts.add_balance(target_user, amount) do
          {:ok, updated} -> conn |> put_status(200) |> json(%{user: user_json(updated)})
          {:error, _} -> conn |> put_status(422) |> json(%{error: "Failed to add balance"})
        end
    end
  end

  # ── Payments ──

  def list_payments(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    opts = [status: params["status"], limit: parse_int(params["limit"], 50)]
    payments = Billing.list_payments(user.club_id, opts)
    conn |> put_status(200) |> json(%{payments: Enum.map(payments, &payment_json/1)})
  end

  def confirm_payment(conn, %{"id" => id}) do
    case Billing.get_payment(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Payment not found"})
      payment ->
        case Billing.confirm_payment(payment) do
          {:ok, payment} -> conn |> put_status(200) |> json(%{payment: payment_json(payment)})
          {:error, _} -> conn |> put_status(422) |> json(%{error: "Failed to confirm payment"})
        end
    end
  end

  def cancel_payment(conn, %{"id" => id}) do
    case Billing.get_payment(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Payment not found"})
      payment ->
        case Billing.cancel_payment(payment) do
          {:ok, payment} -> conn |> put_status(200) |> json(%{payment: payment_json(payment)})
          {:error, _} -> conn |> put_status(422) |> json(%{error: "Failed to cancel payment"})
        end
    end
  end

  # ── JSON helpers ──

  defp club_json(club) do
    %{id: club.id, name: club.name, slug: club.slug, logo_url: club.logo_url,
      address: club.address, timezone: club.timezone, settings: club.settings}
  end

  defp pc_json(pc) do
    %{id: pc.id, pc_token: pc.pc_token, hostname: pc.hostname,
      mac_address: pc.mac_address, ip_address: pc.ip_address,
      status: pc.status, zone: pc.zone, specs: pc.specs,
      last_heartbeat_at: pc.last_heartbeat_at}
  end

  defp tariff_json(t) do
    %{id: t.id, name: t.name, zone: t.zone,
      price_per_hour_tiyn: t.price_per_hour_tiyn, is_active: t.is_active}
  end

  defp session_json(s) do
    %{id: s.id, status: s.status, duration_minutes: s.duration_minutes,
      total_price_tiyn: s.total_price_tiyn, started_at: s.started_at,
      ended_at: s.ended_at, user_id: s.user_id, pc_id: s.pc_id}
  end

  defp game_json(g) do
    %{id: g.id, name: g.name, exe_name: g.exe_name, exe_path: g.exe_path,
      category: g.category, cover_url: g.cover_url, is_active: g.is_active}
  end

  defp category_json(c) do
    %{id: c.id, name: c.name, sort_order: c.sort_order}
  end

  defp item_json(i) do
    %{id: i.id, name: i.name, price_tiyn: i.price_tiyn,
      image_url: i.image_url, is_available: i.is_available, category_id: i.category_id}
  end

  defp order_json(o) do
    %{id: o.id, status: o.status, items: o.items,
      total_price_tiyn: o.total_price_tiyn, user_id: o.user_id,
      inserted_at: o.inserted_at}
  end

  defp user_json(u) do
    %{id: u.id, email: u.email, username: u.username,
      is_guest: u.is_guest, is_admin: u.is_admin, role: u.role,
      balance_tiyn: u.balance_tiyn, bonus_balance: u.bonus_balance,
      total_sessions: u.total_sessions, total_minutes: u.total_minutes,
      is_banned: u.is_banned, phone: u.phone,
      club_id: u.club_id, inserted_at: u.inserted_at}
  end

  defp payment_json(p) do
    %{id: p.id, method: p.method, amount_tiyn: p.amount_tiyn,
      status: p.status, user_id: p.user_id, session_id: p.session_id,
      inserted_at: p.inserted_at}
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  defp parse_int(nil, default), do: default
  defp parse_int(val, _default) when is_integer(val), do: val
  defp parse_int(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {n, _} -> n
      :error -> default
    end
  end
end
