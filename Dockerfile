# prepare release image
FROM alpine:3.14 AS app_base
WORKDIR /app
RUN apk add --no-cache libstdc++ openssl ncurses-libs bash 

FROM erlang:24.0.3-alpine as build
ENV ELIXIR_VERSION="v1.12.2-otp-24"

# # install elixir
RUN wget https://repo.hex.pm/builds/elixir/$ELIXIR_VERSION.zip && \
  mkdir -p /usr/local/elixir && \
  unzip -q -d /usr/local/elixir $ELIXIR_VERSION.zip
ENV PATH=/usr/local/elixir/bin:$PATH

RUN apk add libstdc++ bash make alpine-sdk

RUN mix do local.hex --force, local.rebar --force

FROM build AS deps

WORKDIR /app

ARG SECRET_KEY_BASE
ARG DATABASE_URL
ARG DISCORD_TOKEN
ARG DISCORD_CLIENT_ID
ARG DISCORD_CLIENT_SECRET
ARG PORT=4000
ARG COMMIT
ARG PARTPICKER_API_TOKEN
ARG FREENODE_PASSWORD

ENV MIX_ENV=prod
ENV SECRET_KEY_BASE=${SECRET_KEY_BASE}
ENV DATABASE_URL=${DATABASE_URL}
ENV DISCORD_TOKEN=${DISCORD_TOKEN}
ENV DISCORD_CLIENT_ID=${DISCORD_CLIENT_ID}
ENV DISCORD_CLIENT_SECRET=${DISCORD_CLIENT_SECRET}
ENV PARTPICKER_API_TOKEN=${PARTPICKER_API_TOKEN}
ENV PORT=${PORT}
ENV COMMIT=${COMMIT}

COPY mix.exs mix.lock ./
COPY config config
RUN mix do deps.get, deps.compile

FROM deps as compile

# compile and build release
COPY lib lib
COPY config config
COPY rel rel
COPY priv priv
RUN mix compile

FROM compile as release

RUN mix release --overwrite

FROM app_base as app
COPY --from=release --chown=nobody:nobody /app/_build/prod/rel/miata_bot ./
RUN chown nobody:nobody /app

USER nobody:nobody
ENV HOME=/app
ENTRYPOINT ["bin/miata_bot", "start"]
