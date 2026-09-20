# stack-soberano

Plataforma de IA **self-hosted** y **source-available** que sustituye a Perplexity y a un stack SaaS de gestión de proyectos, cómputo, investigación y entregables. Todo corre en infraestructura propia; los datos, embeddings y credenciales no salen de ella.

> **Política de licencias:** el objetivo es *self-hosted y auditable*, no pureza OSI. Se aceptan componentes **fair-code / source-available** (n8n, Carbone, Dify) para uso interno. Reglas en [`docs/02-stack-y-licencias.md`](docs/02-stack-y-licencias.md).

## Capacidades objetivo

| Necesidad | Componente | Estado |
| :-- | :-- | :-- |
| Chat general con memoria y multi-proveedor | Open WebUI (+ LibreChat opcional) | Diseñado |
| Modelos locales | Ollama (1 usuario) / vLLM (multi-usuario) | Diseñado |
| Búsqueda web privada con fuentes | SearXNG | Diseñado |
| Gestión de proyectos e issues | Plane CE + `plane-mcp-server` | Diseñado |
| Automatización y orquestación | n8n (fair-code) | Diseñado |
| **Modalidad Notebook** (investigación curada, RAG, podcasts) | Open Notebook | Diseñado — [`docs/03`](docs/03-modalidad-notebook.md) |
| Imágenes e infografías | ComfyUI | Fase 2 |
| Gráficas, BI y tableros | Metabase / Apache Superset | Fase 2 |
| Documentos y PDF con plantilla | Carbone (fair-code) + Gotenberg | Fase 2 |
| Edición colaborativa | ONLYOFFICE Docs | Fase 3 |
| Almacenamiento de artefactos | MinIO / Nextcloud | Fase 3 |
| Memoria compartida entre agentes | Mem0 OSS (opcional) | Fase 3 |

## Arquitectura

```text
Proxy inverso (Caddy/Traefik)
├── Open WebUI / LibreChat      → chat, agentes, MCP
├── Plane CE + plane-mcp-server → proyectos, issues, ciclos
├── Open Notebook               → cuadernos, fuentes, notas, RAG, podcasts
└── Metabase / Superset         → KPIs y tableros

Servicios de soporte
├── Ollama / vLLM               → LLM + embeddings
├── SearXNG                     → búsqueda web privada
├── n8n                         → flujos, ingesta, artefactos
├── ComfyUI                     → imagen (GPU)
├── Carbone + Gotenberg         → documentos y PDF
├── SurrealDB                   → datos de Notebook (interno)
├── PostgreSQL + Redis          → datos de soporte
└── MinIO / Nextcloud           → artefactos y archivos
```

Detalle completo en [`docs/01-arquitectura.md`](docs/01-arquitectura.md).

## Estructura del repositorio

```text
stack-soberano/
├── README.md
├── ROADMAP.md
├── docs/
│   ├── 00-alternativas-perplexity.md   # investigación original (adaptada)
│   ├── 01-arquitectura.md
│   ├── 02-stack-y-licencias.md
│   ├── 03-modalidad-notebook.md
│   ├── 04-seguridad.md
│   ├── 05-operacion.md
│   ├── 06-datos.md
│   └── adr/
│       └── ADR-001-gateway-supervisor.md
├── deploy/
│   ├── docker-compose.core.yml
│   ├── docker-compose.assets.yml
│   ├── .env.example
│   └── Caddyfile
└── scripts/
    └── bootstrap.sh
```

## Inicio rápido (esqueleto)

```bash
git clone https://github.com/SebastianVernis/stack-soberano.git
cd stack-soberano/deploy
cp .env.example .env
# edita .env: claves de cifrado, contraseñas, tokens
docker compose -f docker-compose.core.yml --profile core up -d
```

> El compose es un **esqueleto de referencia**: los comandos del worker de Open Notebook y las versiones de imagen deben validarse contra el repo upstream antes de producción.

## Documentos

- [Alternativas self-hosted a Perplexity (investigación original)](docs/00-alternativas-perplexity.md)
- [Arquitectura](docs/01-arquitectura.md)
- [Stack y licencias (fair-code)](docs/02-stack-y-licencias.md)
- [Modalidad Notebook](docs/03-modalidad-notebook.md)
- [Seguridad](docs/04-seguridad.md)
- [Operación](docs/05-operacion.md)
- [Datos: deber ser y sweet spot](docs/06-datos.md)
- [ADR-001: gateway supervisor](docs/adr/ADR-001-gateway-supervisor.md)
- [Roadmap](ROADMAP.md)

## Licencia

Documentación y configuración de este repositorio: MIT (ver `LICENSE`). Los componentes de terceros conservan **sus propias licencias**; consulta [`docs/02-stack-y-licencias.md`](docs/02-stack-y-licencias.md).
