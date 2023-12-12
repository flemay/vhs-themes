COMPOSE_GO_RUN = docker compose run --rm golang

# run executes main.go in a container
run:
	$(COMPOSE_GO_RUN) go run main.go

prune:
	docker compose down --remove-orphans --volumes
