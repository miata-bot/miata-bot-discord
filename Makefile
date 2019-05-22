help:
	@echo "Make targets:"
	@echo
	@echo "server - start the server"
	@echo "iex-server - start the server with the interactive shell"
	@echo "reset-db - reinitialize the database"
	@echo "reset-test-db - reinitialize the test database"
	@echo "test - run the unit tests"

.env:
	@echo "Please create a '.env' file first. Copy 'dev.env' to '.env' for a start."
	@exit 1

server: .env
	. ./.env && \
	mix phx.server

iex:
	make iex-server

iex-server: .env
	. ./.env && \
	iex -S mix 

mix:
	iex -S mix

format:
	mix cmd mix format

check-format:
	mix cmd mix format --check-formatted

docker-compose:
	sudo docker-compose up

reset-db: .env
	. ./.env && \
	make rebuild-db

reset-test-db: .env
	DB=db_test \
	MIX_ENV=test \
	make reset-db

rebuild-db:
	mix ecto.drop && \
	mix ecto.create && \
	mix ecto.migrate

test: .env
	DB=db_test \
	. ./.env && \
	mix test

.PHONY: test rebuild-db reset-db reset-test-db mix iex-server server help
