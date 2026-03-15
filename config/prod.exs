import Config

# Note: SSL/force_ssl will be enabled once a domain + cert is configured.
# For now, running on plain HTTP behind the VPS IP.

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
