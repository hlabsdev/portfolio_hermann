# syntax=docker/dockerfile:1

# Build stage: latest stable Elixir/OTP, Debian bookworm (glibc) for reliable
# precompiled NIFs (mdex_native, etc.).
FROM hexpm/elixir:1.20.5-erlang-29.1.2-debian-bookworm-20261104-slim AS build

RUN apt-get update -y \
  && apt-get install -y --no-install-recommends git ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV MIX_ENV=prod

# Pre-fetch prod dependencies in their own layer for faster rebuilds.
COPY mix.exs mix.lock ./
RUN mix local.hex --force \
  && mix local.rebar --force \
  && mix deps.get --only prod

# Compile dependencies (needs the prod config to be present).
COPY config/config.exs config/prod.exs config/
RUN mix deps.compile

# Application sources and assets. Tailwind scans lib/**, so lib comes first.
COPY priv priv
COPY assets assets
COPY lib lib
RUN mix assets.deploy \
  && mix compile

COPY config/runtime.exs config/
RUN mix release

# Runtime stage: minimal Debian image, only the libraries the release needs.
FROM debian:bookworm-slim AS app

RUN apt-get update -y \
  && apt-get install -y --no-install-recommends \
    libstdc++6 \
    openssl \
    libncurses6 \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/_build/prod/rel/portfolio_hermann ./

ENV HOME=/app
ENV MIX_ENV=prod
ENV PORT=8080

EXPOSE 8080

CMD ["bin/portfolio_hermann", "start"]
