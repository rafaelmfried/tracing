#!/usr/bin/env bash
# scripts/make-help.sh — imprime os targets do Makefile que possuem
# documentação inline no padrão `target: ## descrição` ou `target: deps ## descrição`.
#
# Uso:
#   scripts/make-help.sh [Makefile]
#
# Saída: lista colorida agrupada, com o target à esquerda e a descrição à direita.
set -euo pipefail

MAKEFILE="${1:-Makefile}"

if [[ ! -f "$MAKEFILE" ]]; then
  echo "make-help: não encontrei '$MAKEFILE'" >&2
  exit 1
fi

CYAN=$'\033[36m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
DIM=$'\033[2m'
RESET=$'\033[0m'

printf "%s\n" "${GREEN}tracing — monorepo de aula (Rafael Friederick / Unnamed-Lab)${RESET}"
printf "%s\n" "${DIM}Targets disponíveis no Makefile (\`make <target>\`):${RESET}"
printf "%s\n\n" "${DIM}Profiles para up/down/restart/logs/build: go, node, infra, obs, all (ex: 'make up go').${RESET}"

awk -v cyan="$CYAN" -v yellow="$YELLOW" -v reset="$RESET" -v dim="$DIM" '
  BEGIN { FS = ":.*?## " }
  /^##@/ {
    section = substr($0, 5)
    printf "\n%s%s%s\n", yellow, section, reset
    next
  }
  /^[a-zA-Z0-9_.-]+:.*?## / {
    target = $1
    desc = $2
    printf "  %s%-22s%s %s\n", cyan, target, reset, desc
  }
' "$MAKEFILE"

printf "\n%s\n" "${DIM}Dica: 'make <target>' executa. 'make help' mostra esta tela.${RESET}"
