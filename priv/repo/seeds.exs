alias Lobby.Repo
alias Lobby.Clubs.{Club, PC, Tariff}
alias Lobby.Accounts.User
alias Lobby.Gaming.Game
alias Lobby.Pos.{MenuCategory, MenuItem}

# ── Demo Club ──

{:ok, club} =
  %Club{}
  |> Club.changeset(%{
    name: "Lobby Demo Club",
    slug: "demo",
    address: "ул. Абая 1, Алматы",
    timezone: "Asia/Almaty"
  })
  |> Repo.insert()

IO.puts("Created club: #{club.name} (#{club.id})")

# ── Tariffs ──

for data <- [
  %{name: "Стандарт", zone: "standard", price_per_hour_tiyn: 50000},
  %{name: "VIP", zone: "vip", price_per_hour_tiyn: 80000},
  %{name: "Турнирный", zone: "tournament", price_per_hour_tiyn: 100000}
] do
  {:ok, t} =
    %Tariff{}
    |> Tariff.changeset(Map.put(data, :club_id, club.id))
    |> Repo.insert()

  IO.puts("  Tariff: #{t.name}")
end

# ── PCs ──

for data <- [
  %{pc_token: "pc-demo-001", hostname: "PC-001", zone: "standard", mac_address: "AA:BB:CC:DD:EE:01"},
  %{pc_token: "pc-demo-002", hostname: "PC-002", zone: "standard", mac_address: "AA:BB:CC:DD:EE:02"},
  %{pc_token: "pc-demo-003", hostname: "PC-003", zone: "vip", mac_address: "AA:BB:CC:DD:EE:03"},
  %{pc_token: "pc-demo-004", hostname: "PC-004", zone: "vip", mac_address: "AA:BB:CC:DD:EE:04"},
  %{pc_token: "pc-demo-005", hostname: "PC-005", zone: "tournament", mac_address: "AA:BB:CC:DD:EE:05"}
] do
  {:ok, pc} =
    %PC{}
    |> PC.changeset(Map.put(data, :club_id, club.id))
    |> Repo.insert()

  IO.puts("  PC: #{pc.hostname} (#{pc.pc_token})")
end

# ── Admin User ──

{:ok, admin} =
  %User{}
  |> User.registration_changeset(%{
    email: "admin@lobby.gg",
    password: "admin123",
    username: "Admin",
    club_id: club.id
  })
  |> Ecto.Changeset.put_change(:is_admin, true)
  |> Ecto.Changeset.put_change(:balance_tiyn, 1_000_000)
  |> Repo.insert()

IO.puts("Created admin: #{admin.email}")

# ── Test User ──

{:ok, _user} =
  %User{}
  |> User.registration_changeset(%{
    email: "player@test.com",
    password: "player123",
    username: "TestPlayer",
    club_id: club.id
  })
  |> Ecto.Changeset.put_change(:balance_tiyn, 500_000)
  |> Repo.insert()

IO.puts("Created user: player@test.com")

# ── Games ──

for data <- [
  %{name: "Counter-Strike 2", exe_name: "cs2.exe", category: "fps"},
  %{name: "Dota 2", exe_name: "dota2.exe", category: "moba"},
  %{name: "Valorant", exe_name: "VALORANT.exe", category: "fps"},
  %{name: "League of Legends", exe_name: "LeagueClient.exe", category: "moba"},
  %{name: "Fortnite", exe_name: "FortniteClient.exe", category: "fps"},
  %{name: "Apex Legends", exe_name: "r5apex.exe", category: "fps"},
  %{name: "GTA V", exe_name: "GTA5.exe", category: "other"},
  %{name: "Minecraft", exe_name: "javaw.exe", category: "other"}
] do
  {:ok, g} =
    %Game{}
    |> Game.changeset(Map.put(data, :club_id, club.id))
    |> Repo.insert()

  IO.puts("  Game: #{g.name}")
end

# ── Menu ──

menu = [
  {"Напитки", 0, [
    %{name: "Coca-Cola 0.5л", price_tiyn: 50000},
    %{name: "Red Bull 0.25л", price_tiyn: 80000},
    %{name: "Вода 0.5л", price_tiyn: 20000},
    %{name: "Чай", price_tiyn: 30000},
    %{name: "Кофе", price_tiyn: 40000}
  ]},
  {"Снеки", 1, [
    %{name: "Чипсы Lay's", price_tiyn: 40000},
    %{name: "Сухарики", price_tiyn: 25000},
    %{name: "Snickers", price_tiyn: 35000}
  ]},
  {"Еда", 2, [
    %{name: "Пицца Маргарита", price_tiyn: 150000},
    %{name: "Хот-дог", price_tiyn: 80000},
    %{name: "Бургер", price_tiyn: 120000},
    %{name: "Наггетсы 6шт", price_tiyn: 90000},
    %{name: "Доширак", price_tiyn: 30000}
  ]}
]

for {cat_name, sort_order, items} <- menu do
  {:ok, cat} =
    %MenuCategory{}
    |> MenuCategory.changeset(%{name: cat_name, sort_order: sort_order, club_id: club.id})
    |> Repo.insert()

  for item <- items do
    {:ok, _} =
      %MenuItem{}
      |> MenuItem.changeset(Map.merge(item, %{category_id: cat.id, club_id: club.id}))
      |> Repo.insert()
  end

  IO.puts("  Menu: #{cat_name} (#{length(items)} items)")
end

# ── Zones ──

alias Lobby.Clubs.Zone

for data <- [
  %{name: "Standard", color: "#3B82F6", sort_order: 0},
  %{name: "VIP", color: "#F59E0B", sort_order: 1},
  %{name: "Tournament", color: "#EF4444", sort_order: 2}
] do
  {:ok, z} =
    %Zone{}
    |> Zone.changeset(Map.put(data, :club_id, club.id))
    |> Repo.insert()

  IO.puts("  Zone: #{z.name}")
end

# ── Packages ──

alias Lobby.Packages.Package

for data <- [
  %{name: "5 часов", type: "hours", hours: 5, price: 200_000, validity_days: 30, is_active: true},
  %{name: "10 часов", type: "hours", hours: 10, price: 350_000, validity_days: 30, is_active: true},
  %{name: "Безлимит день", type: "unlimited", hours: 24, price: 500_000, validity_days: 1, is_active: true}
] do
  {:ok, p} =
    %Package{}
    |> Package.changeset(Map.put(data, :club_id, club.id))
    |> Repo.insert()

  IO.puts("  Package: #{p.name}")
end

IO.puts("\nSeeds completed!")
