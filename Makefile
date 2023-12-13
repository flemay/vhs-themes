COMPOSE_BUILD_VHS = docker compose build --no-cache vhs
COMPOSE_RUN_VHS_BASH = docker compose run --rm --entrypoint bash vhs
COMPOSE_RUN_VHS_MAKE = docker compose run --rm --entrypoint make vhs
ENVFILE ?= env.template

ciTest: envfile deps test prune
ciTestE2E: envfile deps testE2E prune
ciPublish: envfile deps testE2E checkMetadata record page publish prune

envfile:
	cp -f $(ENVFILE) .env

deps:
	ENVFILE=env.template $(COMPOSE_BUILD_VHS)

shell:
	$(COMPOSE_RUN_VHS_BASH)

test:
	$(COMPOSE_RUN_VHS_MAKE) _test
_test:
	ENV_INT_TEST_E2E=false ./scripts/run_test.sh

testE2E:
	$(COMPOSE_RUN_VHS_MAKE) _testE2E
_testE2E:
	ENV_INT_TEST_E2E=true ./scripts/run_test.sh

record:
	$(COMPOSE_RUN_VHS_BASH) ./scripts/run_record.sh

page:
	$(COMPOSE_RUN_VHS_BASH) ./scripts/run_page.sh

publish:
	$(COMPOSE_RUN_VHS_BASH) ./scripts/run_publish.sh

download:
	$(COMPOSE_RUN_VHS_BASH) ./scripts/run_download.sh

checkMetadata:
	$(COMPOSE_RUN_VHS_BASH) ./scripts/run_check_metadata.sh

prune:
	ENVFILE=env.template $(COMPOSE_RUN_VHS_MAKE) _prune
	ENVFILE=env.template docker compose down --remove-orphans --volumes
	docker image rm flemay/vhs-themes:local
_prune:
	rm -fr output* .env
