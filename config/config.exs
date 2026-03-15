# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :lobby,
  ecto_repos: [Lobby.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure the endpoint
config :lobby, LobbyWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: LobbyWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Lobby.PubSub,
  live_view: [signing_salt: "X0gU0C9/"]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Guardian JWT config
config :lobby, Lobby.Guardian,
  issuer: "lobby",
  secret_key: System.get_env("GUARDIAN_SECRET", "dev-secret-key-change-in-production"),
  ttl: {7, :days}

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure JOSE to use Jason
config :jose, json_module: Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
