name = PostgreSQL Backuper

NO_COLOR=\033[0m		# Color Reset
COLOR_OFF='\e[0m'       # Color Off
OK_COLOR=\033[32;01m	# Green Ok
ERROR_COLOR=\033[31;01m	# Error red
WARN_COLOR=\033[33;01m	# Warning yellow
RED='\e[1;31m'          # Red
GREEN='\e[1;32m'        # Green
YELLOW='\e[1;33m'       # Yellow
BLUE='\e[1;34m'         # Blue
PURPLE='\e[1;35m'       # Purple
CYAN='\e[1;36m'         # Cyan
WHITE='\e[1;37m'        # White
UCYAN='\e[4;36m'        # Cyan
USER_ID = $(shell id -u)
ifneq (,$(wildcard .env))
    include .env
    export $(shell sed 's/=.*//' .env)
endif

all:
	@printf "Launch configuration ${name}...\n"
	@docker-compose -f ./docker-compose.yml up -d

help:
	@echo -e "$(OK_COLOR)==== All commands of ${name} configuration ====$(NO_COLOR)"
	@echo -e "$(WARN_COLOR)- make				: Launch configuration"
	@echo -e "$(WARN_COLOR)- make build			: Building configuration"
	@echo -e "$(WARN_COLOR)- make config			: Show configuration"
	@echo -e "$(WARN_COLOR)- make condb			: Connect to database"
	@echo -e "$(WARN_COLOR)- make conn			: Connect to container"
	@echo -e "$(WARN_COLOR)- make down			: Stopping configuration"
	@echo -e "$(WARN_COLOR)- make env			: Create environment"
	@echo -e "$(WARN_COLOR)- make full			: Create full backup"
	@echo -e "$(WARN_COLOR)- make git			: Set user and mail for git"
	@echo -e "$(WARN_COLOR)- make incr			: Create incremental backup"
	@echo -e "$(WARN_COLOR)- make latest			: Restore latest backup"
	@echo -e "$(WARN_COLOR)- make list			: Show list of backup dates"
	@echo -e "$(WARN_COLOR)- make log			: Show backup container logs"
	@echo -e "$(WARN_COLOR)- make ps			: View configuration"
	@echo -e "$(WARN_COLOR)- make re			: Rebuild configuration"
	@echo -e "$(WARN_COLOR)- make rest <backup>		: Rebuild configuration"
	@echo -e "$(WARN_COLOR)- make test			: Start test container"
	@echo -e "$(WARN_COLOR)- make push			: Push changes to the github"
	@echo -e "$(WARN_COLOR)- make clean			: Cleaning configuration$(NO_COLOR)"

build:
	@printf "$(OK_COLOR)==== Building configuration ${name}... ====$(NO_COLOR)\n"
	@docker-compose -f ./docker-compose.yml up -d --build

config:
	@printf "$(OK_COLOR)==== Wiew container configuration... ====$(NO_COLOR)\n"
	@docker-compose config

conf:
	@printf "$(WARN_COLOR)==== Change postgres config file... ====$(NO_COLOR)\n"
	@docker-compose -f ./docker-compose.yml up -d wal-g-conf

con:
	@printf "$(OK_COLOR)==== Connect to database ${name}... ====$(NO_COLOR)\n"
	@docker exec -it wal-g-test bash

conn:
	@printf "$(OK_COLOR)==== Connect to database ${name}... ====$(NO_COLOR)\n"
	@docker exec -it wal-g-test bash

down:
	@printf "$(ERROR_COLOR)==== Stopping configuration ${name}... ====$(NO_COLOR)\n"
	@docker-compose -f ./docker-compose.yml down

env:
	@printf "$(WARN_COLOR)==== Create environment file for ${name}... ====$(NO_COLOR)\n"
	@if [ -f .env ]; then \
		echo "$(ERROR_COLOR).env file already exists!$(NO_COLOR)"; \
	else \
		cp .env.example .env; \
		echo "USER_ID=${USER_ID}" >> .env && \
		echo "$(OK_COLOR).env file successfully created!$(NO_COLOR)"; \
	fi

full:
	@printf "$(WARN_COLOR)==== Create full backup... ====$(NO_COLOR)\n"
	BACKUP_TYPE=full docker compose run --rm wal-g-backup

git:
	@printf "$(YELLOW)==== Set user name and email to git for ${name} repo... ====$(NO_COLOR)\n"
	@bash scripts/gituser.sh

incr:
	@printf "$(WARN_COLOR)==== Create incremental backup... ====$(NO_COLOR)\n"
	BACKUP_TYPE=incr docker compose run --rm wal-g-backup

latest:
	@printf "$(WARN_COLOR)==== Restore latest backup... ====$(NO_COLOR)\n"
	docker compose run --rm wal-g-restore

list:
	@printf "$(WARN_COLOR)==== Show backup dates list... ====$(NO_COLOR)\n"
	@docker compose run --rm wal-g-list > backups/list.txt
	@cat ./backups/list.txt

log:
	@printf "$(WARN_COLOR)==== Restore latest backup... ====$(NO_COLOR)\n"
	@docker logs wal-g-backup

logs:
	@printf "$(WARN_COLOR)==== Restore latest backup... ====$(NO_COLOR)\n"
	@docker logs wal-g-backup

ps:
	@printf "$(BLUE)==== View configuration ${name}... ====$(NO_COLOR)\n"
	@docker-compose -f ./docker-compose.yml ps

push:
	@bash scripts/push.sh

re:	down
	@printf "$(OK_COLOR)==== Rebuild configuration ${name}... ====$(NO_COLOR)\n"
	@docker-compose -f ./docker-compose.yml up -d --build

rest:
	@printf "$(WARN_COLOR)==== Restore backup from ${name}... ====$(NO_COLOR)\n"
	@$(eval args := $(words $(filter-out --,$(MAKECMDGOALS))))
	@if [ "$(args)" -eq 3 ]; then \
		echo "$(OK_COLOR)Restore backup $(word 2,$(MAKECMDGOALS))$(NO_COLOR)"; \
		bash scripts/restore.sh $(word 2,$(MAKECMDGOALS)) $(word 3,$(MAKECMDGOALS)); \
	else \
		echo "$(ERROR_COLOR)Enter the name of the backup and backup date from make list command!$(NO_COLOR)"; \
	fi

show:
	@printf "$(BLUE)==== Current environment variables... ====$(NO_COLOR)\n"
	@env | grep -E 'POSTGRES_|PG_DATA|RESTORE_BACKUP_NAME' || true

test:
	@printf "$(WARN_COLOR)==== Create full backup... ====$(NO_COLOR)\n"
	@docker-compose -f ./docker-compose.yml up -d wal-g-test

clean: down
	@printf "$(ERROR_COLOR)==== Cleaning configuration ${name}... ====$(NO_COLOR)\n"
	@yes | docker system prune -a

fclean:
	@printf "$(ERROR_COLOR)==== Total clean of all configurations docker ====$(NO_COLOR)\n"
	# Uncommit if necessary:
	# @docker stop $$(docker ps -qa)
	# @docker system prune --all --force --volumes
	# @docker network prune --force
	# @docker volume prune --force

.PHONY	: all help build conn down re rest ps test clean fclean
