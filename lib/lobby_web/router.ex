defmodule LobbyWeb.Router do
  use LobbyWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :rate_limited do
    plug LobbyWeb.Auth.RateLimiter
  end

  pipeline :auth do
    plug LobbyWeb.Auth.Pipeline
  end

  pipeline :admin do
    plug LobbyWeb.Auth.Pipeline
    plug LobbyWeb.Auth.AdminPlug
  end

  # ── Public auth routes (rate limited) ──
  scope "/api", LobbyWeb do
    pipe_through [:api, :rate_limited]

    post "/auth/login", AuthController, :login
    post "/auth/register", AuthController, :register
    post "/auth/guest", AuthController, :guest
  end

  # ── Public non-auth routes ──
  scope "/api", LobbyWeb do
    pipe_through :api

    post "/clubs/register", ClubController, :register_pc
    post "/shell/heartbeat", HeartbeatController, :create
    post "/shell/logs", ShellLogController, :create
    get "/shell/update", UpdateController, :check
  end

  # ── Authenticated routes ──
  scope "/api", LobbyWeb do
    pipe_through [:api, :auth]

    # Auth
    post "/auth/refresh", AuthController, :refresh
    get "/auth/profile", AuthController, :profile

    # Clubs
    get "/clubs/:id", ClubController, :show

    # Tariffs
    get "/tariffs", SessionController, :tariffs

    # Sessions
    post "/sessions", SessionController, :create
    get "/sessions/history", SessionController, :history
    get "/sessions/:id", SessionController, :show
    post "/sessions/:id/end", SessionController, :end_session
    post "/sessions/:id/extend", SessionController, :extend
    post "/sessions/:id/pause", SessionController, :pause
    post "/sessions/:id/resume", SessionController, :resume
    post "/sessions/:id/move", SessionController, :move
    post "/sessions/:id/add_time", SessionController, :add_time

    # Payments
    post "/payments", PaymentController, :create
    get "/payments/:id", PaymentController, :show
    post "/payments/:id/confirm", PaymentController, :confirm

    # POS
    get "/menu", PosController, :menu
    post "/orders", PosController, :create_order
    get "/orders/:id", PosController, :show_order
    put "/orders/:id", PosController, :update_order

    # Games
    get "/games", GameController, :index
    get "/games/popular", GameController, :popular
  end

  # ── Admin routes (requires admin role) ──
  scope "/api/admin", LobbyWeb do
    pipe_through [:api, :admin]

    # Dashboard & Stats
    get "/dashboard", AdminController, :dashboard
    get "/stats/revenue", AdminController, :revenue_stats
    get "/stats/sessions", AdminController, :session_stats
    get "/stats/occupancy", AdminController, :occupancy_stats
    get "/stats/customers", AdminController, :customer_stats
    get "/stats/games", AdminController, :game_stats

    # Club settings
    put "/club", AdminController, :update_club

    # PCs management
    get "/pcs", AdminController, :list_pcs
    put "/pcs/:id", AdminController, :update_pc
    delete "/pcs/:id", AdminController, :delete_pc
    post "/pcs/:pc_id/command", AdminController, :send_command
    post "/pcs/broadcast", AdminController, :broadcast_command

    # Tariffs
    get "/tariffs", AdminController, :list_tariffs
    post "/tariffs", AdminController, :create_tariff
    put "/tariffs/:id", AdminController, :update_tariff
    delete "/tariffs/:id", AdminController, :delete_tariff

    # Sessions
    get "/sessions", AdminController, :list_sessions
    post "/sessions/:id/end", AdminController, :end_session

    # Games
    get "/games", AdminController, :list_games
    post "/games", AdminController, :create_game
    put "/games/:id", AdminController, :update_game
    delete "/games/:id", AdminController, :delete_game

    # Menu categories
    get "/menu/categories", AdminController, :list_categories
    post "/menu/categories", AdminController, :create_category
    put "/menu/categories/:id", AdminController, :update_category
    delete "/menu/categories/:id", AdminController, :delete_category

    # Menu items
    post "/menu/items", AdminController, :create_menu_item
    put "/menu/items/:id", AdminController, :update_menu_item
    delete "/menu/items/:id", AdminController, :delete_menu_item

    # Orders
    get "/orders", AdminController, :list_orders

    # Users
    get "/users", AdminController, :list_users
    put "/users/:id", AdminController, :update_user
    post "/users/:id/balance", AdminController, :add_balance

    # Payments
    get "/payments", AdminController, :list_payments
    post "/payments/:id/confirm", AdminController, :confirm_payment
    post "/payments/:id/cancel", AdminController, :cancel_payment

    # Zones
    get "/zones", ZoneController, :index
    post "/zones", ZoneController, :create
    put "/zones/:id", ZoneController, :update
    delete "/zones/:id", ZoneController, :delete

    # Shifts
    post "/shifts/open", ShiftController, :open
    post "/shifts/:id/close", ShiftController, :close
    get "/shifts/current", ShiftController, :current
    get "/shifts", ShiftController, :index
    get "/shifts/:id", ShiftController, :show
    post "/shifts/:id/encashment", ShiftController, :encashment

    # Bookings
    get "/bookings", BookingController, :index
    post "/bookings", BookingController, :create
    post "/bookings/:id/cancel", BookingController, :cancel

    # Packages
    get "/packages", PackageController, :index
    post "/packages", PackageController, :create
    put "/packages/:id", PackageController, :update
    delete "/packages/:id", PackageController, :delete
    post "/packages/sell", PackageController, :sell
    get "/packages/gamer/:user_id", PackageController, :gamer_packages

    # Loyalty
    post "/loyalty/bonus", LoyaltyController, :award_bonus
    get "/loyalty/bonus/:user_id", LoyaltyController, :bonus_history
    get "/loyalty/promos", LoyaltyController, :list_promos
    post "/loyalty/promos", LoyaltyController, :create_promo
    put "/loyalty/promos/:id", LoyaltyController, :update_promo
    delete "/loyalty/promos/:id", LoyaltyController, :delete_promo

    # Audit & Notes
    get "/audit", AuditController, :index
    post "/gamers/:gamer_id/notes", AuditController, :create_note
    get "/gamers/:gamer_id/notes", AuditController, :list_notes
    post "/users/:id/ban", AuditController, :ban_user
    post "/users/:id/unban", AuditController, :unban_user
  end
end
