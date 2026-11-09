.PHONY: help network update pull up down restart ps logs migrate shell dbshell createsuperuser

ENV_FILE ?= .env
DC = ENV_FILE=$(ENV_FILE) docker compose -f docker-compose.dist.yml --env-file $(ENV_FILE)
S ?=

help:
	@echo "  make update            git pull + pull immagini + up (aggiornamento completo)"
	@echo "  make pull              Scarica le immagini aggiornate"
	@echo "  make up                Avvia/ricrea i container (crea la rete shared_edge)"
	@echo "  make down              Ferma i container"
	@echo "  make restart [S=svc]   Riavvia tutti i servizi o solo S"
	@echo "  make ps                Stato container"
	@echo "  make logs [S=svc]      Segue i log (tutti o solo S)"
	@echo "  make migrate           Migrazioni + seed (servizio migrate)"
	@echo "  make shell             Shell Django nel backend"
	@echo "  make dbshell           Shell DB nel backend"
	@echo "  make createsuperuser   Crea un superuser"
	@echo "  Variabile: ENV_FILE=<file> (default .env)"

# Rete esterna usata per collegarsi al reverse proxy; senza, `up` fallisce.
network:
	@docker network inspect shared_edge >/dev/null 2>&1 || docker network create shared_edge

update:
	git pull
	$(MAKE) pull
	$(MAKE) up

pull:
	$(DC) pull

up: network
	$(DC) up -d --remove-orphans

down:
	$(DC) down

restart:
	$(DC) restart $(S)

ps:
	$(DC) ps

logs:
	$(DC) logs -f --tail 200 $(S)

migrate:
	$(DC) run --rm migrate

shell:
	docker exec -it rioaction_backend python manage.py shell

dbshell:
	docker exec -it rioaction_backend python manage.py dbshell

createsuperuser:
	docker exec -it rioaction_backend python manage.py createsuperuser
