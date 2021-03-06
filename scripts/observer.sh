#!/bin/bash
set -e
source .env
erl \
  -name console@127.0.0.1 \
  -connect_all \
  -setcookie 'aHR0cHM6Ly9kaXNjb3JkLmdnL25tOENFVDJNc1A=' \
  -run observer -noshell
