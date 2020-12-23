FROM erlang:23.0.3-alpine as build
ENV ELIXIR_VERSION="v1.10.4-otp-23"

# # install elixir
RUN wget https://repo.hex.pm/builds/elixir/$ELIXIR_VERSION.zip && \
  mkdir -p /usr/local/elixir && \
  unzip -d /usr/local/elixir $ELIXIR_VERSION.zip
ENV PATH=/usr/local/elixir/bin:$PATH

RUN apk add bash npm make alpine-sdk

RUN mix do local.hex --force, local.rebar --force

FROM build AS compile

WORKDIR /app

ARG SECRET_KEY_BASE
ARG DATABASE_URL
ARG DISCORD_TOKEN
ARG DISCORD_CLIENT_ID
ARG DISCORD_CLIENT_SECRET
ARG PORT=4000
ARG COMMIT

ENV MIX_ENV=prod
ENV SECRET_KEY_BASE=${SECRET_KEY_BASE}
ENV DATABASE_URL=${DATABASE_URL}
ENV DISCORD_TOKEN=${DISCORD_TOKEN}
ENV DISCORD_CLIENT_ID=${DISCORD_CLIENT_ID}
ENV DISCORD_CLIENT_SECRET=${DISCORD_CLIENT_SECRET}
ENV PORT=${PORT}
ENV MIATA_BOT_COMMIT=${COMMIT}

COPY mix.exs mix.lock ./
COPY config config

RUN mix do deps.get, deps.compile

# build assets
COPY assets/package.json assets/package-lock.json ./assets/
RUN npm --prefix ./assets install --progress=false --no-audit --loglevel=error

COPY rel rel
COPY priv priv
COPY assets assets
RUN npm run --prefix ./assets deploy; mix phx.digest

# compile and build release
COPY lib lib
RUN mix do compile, release

# prepare release image
FROM alpine:latest AS app

WORKDIR /app

RUN apk add --no-cache openssl ncurses-libs bash

COPY --from=compile --chown=nobody:nobody /app/_build/prod/rel/miata_bot ./
RUN chown nobody:nobody /app

USER nobody:nobody
ENV HOME=/app

ENTRYPOINT ["bin/miata_bot", "start"]
