COMPOSE_FILE_PATH=./docker/compose.yaml
ENV_FILE=.env
REPO_URL=https://github.com/rafaelmfried/tracing.git

# Terminal colors
RESET=\033[0m
CYAN=\033[36m
GREEN=\033[32m
YELLOW=\033[33m
RED=\033[31m

# Targets que viram "argumentos" para up/down/logs/restart/build (filter MAKECMDGOALS)
PROFILE_TARGETS=go node infra obs all
PROFILE_SELECTED=$(filter $(PROFILE_TARGETS),$(MAKECMDGOALS))

# Default profile = all
ifeq ($(words $(PROFILE_SELECTED)),0)
PROFILE=all
else ifeq ($(words $(PROFILE_SELECTED)),1)
PROFILE=$(PROFILE_SELECTED)
else
$(error Use só um profile por vez: $(PROFILE_TARGETS))
endif

DC=docker compose -f $(COMPOSE_FILE_PATH) --env-file $(ENV_FILE) --profile $(PROFILE)

.DEFAULT_GOAL := help

.PHONY: help up down restart logs build ps clean reclone init status test test-go test-node $(PROFILE_TARGETS)

help: ## Mostra esta tela de ajuda com todos os targets documentados
	@./scripts/make-help.sh $(firstword $(MAKEFILE_LIST))

##@ Setup do monorepo

init: ## Inicializa o monorepo após clone (puxa submodules + cria .env)
	@printf "$(CYAN)Inicializando submodules...$(RESET)\n"
	@git submodule update --init --recursive
	@if [ ! -f .env ]; then cp .env.example .env; printf "$(GREEN)Criado .env a partir do exemplo.$(RESET)\n"; fi
	@printf "$(GREEN)Pronto. Tente: make up all$(RESET)\n"

reclone: ## Apaga este checkout local e re-clona com --recurse-submodules (interativo)
	@./scripts/reclone.sh "$(REPO_URL)"

##@ Ambiente Docker (use: make up [go|node|infra|obs|all])

up: ## Sobe containers do profile escolhido (default: all)
	@printf "$(YELLOW)Subindo profile: $(PROFILE)$(RESET)\n"
	@$(DC) up -d --build
	@printf "$(GREEN)Containers up. Status:$(RESET)\n"
	@$(DC) ps

down: ## Para containers do profile escolhido (default: all)
	@printf "$(RED)Parando profile: $(PROFILE)$(RESET)\n"
	@$(DC) down
	@printf "$(GREEN)Containers parados.$(RESET)\n"

restart: ## down + up no profile escolhido
	@$(MAKE) down $(PROFILE_SELECTED)
	@$(MAKE) up $(PROFILE_SELECTED)

logs: ## Tail dos logs do profile escolhido
	@$(DC) logs -f --tail=100

ps: ## Lista containers do profile escolhido
	@$(DC) ps

build: ## Apenas build das imagens do profile escolhido (sem subir)
	@printf "$(CYAN)Building profile: $(PROFILE)$(RESET)\n"
	@$(DC) build

clean: ## down -v (apaga volumes do Postgres e Grafana)
	@printf "$(RED)Removendo containers + volumes...$(RESET)\n"
	@docker compose -f $(COMPOSE_FILE_PATH) --env-file $(ENV_FILE) --profile all down -v
	@printf "$(GREEN)Limpo.$(RESET)\n"

status: ## Estado de todos os containers do compose (qualquer profile)
	@docker compose -f $(COMPOSE_FILE_PATH) --env-file $(ENV_FILE) --profile all ps

##@ Testes (delegam para os submodules)

test: ## Roda a suíte completa de Go E Node (requer Docker)
	@$(MAKE) test-go
	@$(MAKE) test-node

test-go: ## Roda só a suíte Go (cd go && make test)
	@printf "$(CYAN)Running Go tests...$(RESET)\n"
	@$(MAKE) -C go test

test-node: ## Roda só a suíte Node (cd node && make test)
	@printf "$(CYAN)Running Node tests...$(RESET)\n"
	@$(MAKE) -C node test

# Permite que `make up go` funcione: 'go', 'node', 'infra', 'obs', 'all' são
# alvos no-op consumidos pelo $(filter ...) acima.
$(PROFILE_TARGETS):
	@:
