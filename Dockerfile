# syntax=docker/dockerfile:1

FROM hexpm/elixir:1.15.7-erlang-26.1.2-alpine-3.18.4 AS build

RUN apk add --no-cache build-base git curl nodejs npm

WORKDIR /app

COPY mix.exs mix.lock ./
RUN mix local.hex --force && mix local.rebar --force
RUN MIX_ENV=prod mix deps.get

COPY config config
COPY lib lib
COPY priv priv
COPY assets assets


RUN mix assets.deploy
RUN MIX_ENV=prod mix compile
RUN MIX_ENV=prod mix release

FROM alpine:3.18.4 AS app

RUN apk add --no-cache libstdc++ openssl ncurses-libs

WORKDIR /app
COPY --from=build /app/_build/prod/rel/portfolio_hermann ./

ENV HOME=/app
ENV MIX_ENV=prod
ENV PORT=8080

CMD ["bin/portfolio_hermann", "start"]
