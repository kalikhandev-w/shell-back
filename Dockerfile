# Build stage
FROM elixir:1.18-otp-27-slim AS build

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV MIX_ENV=prod

# Install hex + rebar
RUN mix local.hex --force && mix local.rebar --force

# Install deps
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config
COPY config/config.exs config/prod.exs config/runtime.exs config/
RUN mix deps.compile

# Compile app
COPY lib lib
COPY priv priv
RUN mix compile

# Build release
RUN mix release

# Runtime stage
FROM debian:bookworm-slim AS app

RUN apt-get update && apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
  && rm -rf /var/lib/apt/lists/*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR /app
RUN useradd --create-home app
USER app

COPY --from=build --chown=app:app /app/_build/prod/rel/lobby ./

ENV PHX_SERVER=true

EXPOSE 4000

CMD ["bin/lobby", "start"]
