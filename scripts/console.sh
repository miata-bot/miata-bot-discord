#!/bin/bash
set -e
source .env
iex --name console@127.0.0.1 \
    --cookie 'aHR0cHM6Ly9kaXNjb3JkLmdnL25tOENFVDJNc1A=' \
    --remsh miata_bot@miata-bot.sixtyeightplus.one
