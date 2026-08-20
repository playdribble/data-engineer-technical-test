.PHONY: build up down shell reset-db set-permissions shell postgres-shell check-port show-tables

POSTGRES_PORT := 5432
DB := analytics

# HOME := /opt/src/

reset-db: down set-permissions
	rm -rfv db-data

build: reset-db
	docker-compose down
	docker-compose build --no-cache

set-permissions:
	mkdir -p db-data
	chmod -R 777 db-data

check-port:
	@if docker-compose ps --status running postgres 2>/dev/null | grep -q postgres; then \
		exit 0; \
	elif lsof -nP -iTCP:$(POSTGRES_PORT) -sTCP:LISTEN >/dev/null 2>&1; then \
		echo "ERROR: port $(POSTGRES_PORT) is already in use by:"; \
		lsof -nP -iTCP:$(POSTGRES_PORT) -sTCP:LISTEN; \
		exit 1; \
	fi

up: check-port set-permissions
	docker-compose up -d

down:
	docker-compose down

shell:
	docker-compose exec core bash -c "cd /opt/src; exec bash"

postgres-shell:
	docker-compose exec postgres bash

show-tables:
	@docker-compose exec -T postgres psql -U postgres -d $(DB) -P pager=off -c "SELECT current_database() AS database, schemaname AS schema, relname AS \"table\", (xpath('/row/c/text()', query_to_xml(format('SELECT count(*) AS c FROM %I.%I', schemaname, relname), false, true, '')))[1]::text::bigint AS row_count FROM pg_stat_user_tables ORDER BY schemaname, relname;"