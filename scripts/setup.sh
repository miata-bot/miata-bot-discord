#!/bin/bash
set -e

mkdir work
cd work
git clone https://github.com/miata-bot/miatapartpicker.git
git clone https://github.com/miata-bot/miata-bot-discord.git

# open a new terminal
cd work/miatapartpicker
npm install --prefix=assets
mix deps.get && mix deps.compile
export DISCORD_CLIENT_ID="topsecret"
export DISCORD_CLIENT_SECRET="topsecret"
# this step seeds the database, watch the output, it should print out a token you'll need
mix ecto.setup
iex -S mix phx.server
# you should be able to login w/ your discord account at http://localhost:4000

# open another new terminal
cd work/miata-bot-discord
export DISCORD_TOKEN="topsecret"
export PARTPICKER_API_TOKEN="that thing i said you'd need earlier"
export PARTPICKER_BASE_URL="http://localhost:4000/api"
mix deps.get && mix deps.compile
mix ecto.setup
iex -S mix phx.server