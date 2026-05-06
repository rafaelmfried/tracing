#!/usr/bin/env bash
# scripts/reclone.sh — apaga o checkout local atual deste monorepo e re-clona
# corretamente com `--recurse-submodules`. Útil para quem clonou sem submodules
# ou quer ressincronizar tudo do zero.
#
# Uso:
#   scripts/reclone.sh [REPO_URL] [TARGET_DIR]
#
# Defaults:
#   REPO_URL = url do remote 'origin' deste repo (ou https://github.com/rafaelmfried/tracing.git)
#   TARGET_DIR = nome do diretório atual

set -euo pipefail

CYAN=$'\033[36m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
RESET=$'\033[0m'

repo_url="${1:-}"
target="${2:-}"

# Descobre URL e dir alvo a partir do repo atual quando o usuário não passou.
if [[ -z "$repo_url" ]]; then
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    repo_url="$(git remote get-url origin 2>/dev/null || true)"
  fi
  repo_url="${repo_url:-https://github.com/rafaelmfried/tracing.git}"
fi

if [[ -z "$target" ]]; then
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    target="$(basename "$(git rev-parse --show-toplevel)")"
  else
    target="tracing"
  fi
fi

# Detecta se estamos DENTRO do diretório que vamos apagar — saímos antes.
current_dir="$(pwd)"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  worktree_root="$(git rev-parse --show-toplevel)"
  parent_dir="$(dirname "$worktree_root")"
else
  worktree_root=""
  parent_dir="$(pwd)"
fi

printf "%s\n" "${CYAN}Plano de reclone:${RESET}"
printf "  remote     : %s\n" "$repo_url"
printf "  diretório  : %s/%s\n" "$parent_dir" "$target"
if [[ -n "$worktree_root" ]]; then
  printf "  apagando   : %s\n" "$worktree_root"
fi
printf "\n%sIsso vai APAGAR o diretório local e perder qualquer trabalho não pushado.%s\n" "$YELLOW" "$RESET"

# Sanity: alerta sobre trabalho não pushado.
if [[ -n "$worktree_root" ]]; then
  pushd "$worktree_root" >/dev/null
  if ! git diff --quiet HEAD -- 2>/dev/null; then
    printf "%saviso: há mudanças não commitadas no monorepo%s\n" "$RED" "$RESET"
  fi
  if [[ -n "$(git status --porcelain)" ]]; then
    printf "%saviso: working tree do monorepo não está limpo%s\n" "$RED" "$RESET"
  fi
  for sm in $(git submodule --quiet foreach 'echo $sm_path' 2>/dev/null); do
    if [[ -d "$sm" ]] && [[ -n "$(git -C "$sm" status --porcelain 2>/dev/null)" ]]; then
      printf "%saviso: submodule '%s' tem mudanças não commitadas%s\n" "$RED" "$sm" "$RESET"
    fi
  done
  popd >/dev/null
fi

read -r -p "Continuar? [y/N] " ans
case "$ans" in
  [Yy]*) ;;
  *) printf "%scancelado.%s\n" "$YELLOW" "$RESET"; exit 1 ;;
esac

cd "$parent_dir"

if [[ -n "$worktree_root" && -d "$worktree_root" ]]; then
  printf "%sApagando %s ...%s\n" "$RED" "$worktree_root" "$RESET"
  rm -rf -- "$worktree_root"
fi

printf "%sClonando com submodules ...%s\n" "$CYAN" "$RESET"
git clone --recurse-submodules "$repo_url" "$target"

printf "\n%sFeito.%s Próximos passos:\n" "$GREEN" "$RESET"
printf "  cd %s\n" "$target"
printf "  make init        # cria .env\n"
printf "  make up all      # sobe tudo\n"
