# prepare release image
FROM alpine:latest AS app_base
WORKDIR /app
RUN apk add --no-cache openssl ncurses-libs bash chromium-chromedriver chromium python3 py3-pip
RUN pip3 install -U selenium
RUN pip3 install -U erlang-py

FROM erlang:23.2.7-alpine as build
ENV ELIXIR_VERSION="v1.11.1-otp-23"

# # install elixir
RUN wget https://repo.hex.pm/builds/elixir/$ELIXIR_VERSION.zip && \
  mkdir -p /usr/local/elixir && \
  unzip -q -d /usr/local/elixir $ELIXIR_VERSION.zip
ENV PATH=/usr/local/elixir/bin:$PATH

RUN apk add bash npm make alpine-sdk

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

ENV MIX_ENV=prod
ENV SECRET_KEY_BASE=${SECRET_KEY_BASE}
ENV DATABASE_URL=${DATABASE_URL}
ENV DISCORD_TOKEN=${DISCORD_TOKEN}
ENV DISCORD_CLIENT_ID=${DISCORD_CLIENT_ID}
ENV DISCORD_CLIENT_SECRET=${DISCORD_CLIENT_SECRET}
ENV PORT=${PORT}
ENV COMMIT=${COMMIT}

COPY mix.exs mix.lock ./
RUN mix do deps.get, deps.compile

FROM deps as assets
# build assets
COPY assets/package.json assets/package-lock.json ./assets/
RUN npm --prefix ./assets install --progress=false --no-audit --loglevel=error

COPY assets assets
RUN npm run --prefix ./assets deploy

FROM deps as compile

# compile and build release
COPY lib lib
COPY rel rel
COPY priv priv
RUN mix compile

FROM compile as release

COPY --from=assets /app/priv/static ./priv/static
RUN mix phx.digest
RUN mix release --overwrite

FROM app_base as app
COPY --from=release --chown=nobody:nobody /app/_build/prod/rel/miata_bot ./
RUN chown nobody:nobody /app

USER nobody:nobody
ENV HOME=/app
ENTRYPOINT ["bin/miata_bot", "start"]
