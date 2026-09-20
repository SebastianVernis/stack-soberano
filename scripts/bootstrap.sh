#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY="$ROOT/deploy"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

need() { command -v "$1" >/dev/null 2>&1 || die "Falta '$1' en PATH"; }

info "Comprobando dependencias"
need docker
docker compose version >/dev/null 2>&1 || die "Falta 'docker compose' (v2)"
command -v gh >/dev/null 2>&1 || warn "gh no está instalado (solo necesario para publicar el repo)"

cd "$DEPLOY"

if [[ ! -f .env ]]; then
  info "Creando deploy/.env desde .env.example"
  cp .env.example .env
  warn "Edita deploy/.env y cambia TODOS los 'change-me' antes de arrancar"
  ${EDITOR:-nano} .env
else
  info "deploy/.env ya existe; no se sobreescribe"
fi

if grep -q "change-me" .env; then
  die "deploy/.env todavía contiene valores 'change-me'. Edítalo antes de continuar."
fi

info "Validando configuración de Compose"
docker compose -f docker-compose.core.yml config >/dev/null
docker compose -f docker-compose.assets.yml config >/dev/null

info "Arrancando servicios del núcleo"
docker compose -f docker-compose.core.yml up -d

info "Estado"
docker compose -f docker-compose.core.yml ps

cat <<'EOF'

Siguiente:
  1. Configura un modelo en Ollama:  docker exec -it $(docker ps -qf name=ollama) ollama pull qwen3
  2. Open WebUI:      http://localhost:8080
  3. Open Notebook:   http://localhost:8502  (API: http://localhost:5055/docs)
  4. Habilita JSON en SearXNG (deploy/searxng/settings.yml: formats -> json)
  5. Registra el Tool Server de mcpo en Open WebUI (http://mcpo-notebook:8000)

Artefactos (opcional):
  docker network create stack-soberano 2>/dev/null || true
  docker compose -f docker-compose.assets.yml up -d
EOF
