.PHONY: up down logs

up: # start all services
	docker compose up -d

down: # stop all services
	docker compose down

logs: # tail service logs
	docker compose logs -f

migrate: # run database migrations
	npm run db:migrate

seed: # seed the database
	npm run db:seed
