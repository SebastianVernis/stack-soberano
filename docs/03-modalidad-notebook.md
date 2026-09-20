# Modalidad Notebook: Open Notebook como capa de investigación curada

> Extraído de la investigación original y endurecido como documento de diseño. Repo base: `open-notebook` (MIT). Ver también [`02-stack-y-licencias.md`](02-stack-y-licencias.md).

> Documento de diseño de integración. Repo base: `open-notebook` (copia local en `~/open-notebook`, upstream `lfnovo/open-notebook`, **licencia MIT**). Verificado contra la documentación del propio repo (arquitectura, API, MCP, variables de entorno, ADRs y `VISION.md`).

## 1. Qué aporta Open Notebook y qué no

Open Notebook es una alternativa self-hosted a Google NotebookLM. Técnicamente es un stack de tres capas:

```text
Navegador
   │
   ▼  :8502 (Docker) / :3000 (dev)
Next.js 15 + React 19  (UI; proxy interno de /api/*)
   │
   ▼  :5055
FastAPI (Python 3.11+, async)  — 20+ routers, migraciones automáticas al arrancar
   │
   ▼  :8000
SurrealDB  — grafo + full-text + embeddings vectoriales nativos
```

Piezas distintivas:

- **Cuadernos como unidad**: `Notebook → Sources (PDF/URL/texto/audio) → Notes`, con transformaciones y chat con contexto acotado por cuaderno.
- **RAG nativo**: embeddings vectoriales dentro de SurrealDB (no requiere Qdrant/pgvector aparte) y búsqueda con alcance opcional por cuaderno (`notebook_ids`), ver [ADR-008].
- **Multi-proveedor** vía la librería `Esperanto` (18+ proveedores, incluye Ollama y cualquier endpoint OpenAI-compatible).
- **Trabajos asíncronos**: cola `Surreal-Commands` con **worker obligatorio** (procesado de fuentes, embeddings y podcasts se encolan en silencio si falta).
- **API REST completa** (`:5055/docs`) y **servidor MCP de terceros** (`open-notebook-mcp`, del equipo Epochal) que expone cuadernos, fuentes, notas, chat, búsqueda y modelos.

Límites declarados por el propio proyecto (`VISION.md`) — importante para no asignarle el rol equivocado:

- **No** es un editor de documentos (eso es ONLYOFFICE/Carbone).
- **No** es almacenamiento de archivos (eso es MinIO/Nextcloud).
- **No** es un chatbot general (eso es Open WebUI/LibreChat).
- **Hoy es single-user**; multi-usuario está en consideración ([#712]). La autenticación es **solo contraseña** y CORS por defecto abierto: son *defaults de desarrollo*, no endurecimiento de producción.

**Rol en el stack**: Open Notebook es la **memoria de conocimiento curado por proyecto** (evidencia, fuentes, resúmenes, notas con trazabilidad). Es un complemento de Open WebUI (conversación general) y de Plane (fuente de verdad del trabajo), no un reemplazo de ninguno.

## 2. Dónde encaja en la arquitectura objetivo

```text
                         ┌────────────────────────────────────────────┐
                         │        Proxy inverso (Caddy/Traefik)       │
                         │  chat.*   proyectos.*   notebook.*         │
                         └───────┬───────────────┬───────────────┬────┘
                                 │               │               │
              ┌──────────────────▼──┐   ┌────────▼────────┐  ┌───▼──────────────────┐
              │    Open WebUI /     │   │   Plane CE      │  │  Open Notebook       │
              │    LibreChat        │   │  (proyectos)    │  │  UI :8502            │
              │  (chat general)     │   │  + Plane MCP    │  │  API :5055           │
              └───────┬─────────────┘   └────────┬────────┘  └───┬──────────────────┘
                      │  MCP / mcpo              │               │
                      │  (herramientas notebook) │               │
                      └──────────────┬───────────┴───────────────┘
                                     │
                 ┌───────────────────┼───────────────────────┐
                 ▼                   ▼                       ▼
         Ollama / vLLM        n8n (flujos)           SurrealDB :8000
        (LLM + embeddings)    ingesta/artefactos      (solo interno 127.0.0.1)
                                     │
                                     ▼
                             MinIO / Nextcloud
                        (podcasts, notas exportadas)
```

Principios de la integración:

1. **Una sola fuente de verdad por dominio**: conocimiento curado → Open Notebook; conversación → Open WebUI/LibreChat; trabajo → Plane. No se duplican embeddings ni se re-indexa el mismo corpus en dos bases vectoriales.
2. **Open Notebook se consume por herramientas (MCP/OpenAPI), no por scraping de UI.**
3. **Modelos compartidos**: Open Notebook apunta al mismo `Ollama`/`vLLM` que el resto del stack.
4. **El worker es un servicio de primera clase**, no un detalle: sin él no hay procesado de fuentes ni embeddings.

## 3. Contrato de datos y trazabilidad

| Open Notebook | Equivalente en el stack | Regla |
| :-- | :-- | :-- |
| `notebook` | Espacio/proyecto de Plane | 1 espacio de Plane ↔ 1 cuaderno (o varios por fase) |
| `source` | Documento/issue/PR/transcripción | Guardar el id de SurrealDB (`source:xxx`) en el issue/enlace de Plane |
| `note` | Decisiones, ADRs, minutas | Las notas confirmadas se enlazan al work item; el agente solo propone |
| `chat_session` | — (vive en Notebook) | La conversación de investigación NO reemplaza a Open WebUI |
| `transformation` | Plantillas de resumen/análisis | Versionar en Git, no editar a mano en producción |
| `source_insight` | Borrador de reporte | Salida intermedia; el PDF final lo hace Carbone/Gotenberg |
| Podcast / audio | Artefacto entregable | Se archiva en MinIO/Nextcloud, no en Notebook |

Contrato mínimo de intercambio (JSON) entre el agente y Notebook:

```json
{
  "notebook_id": "notebook:abc123",
  "plane_workspace": "Chispart-App",
  "source_ref": "source:src001",
  "kind": "source|note|insight",
  "external_link": "https://github.com/org/repo/issues/42",
  "classification": "citable|internal|secret-never-index",
  "created": "2026-09-19T00:00:00Z"
}
```

Regla de oro: los **enlaces de trazabilidad viven fuera** de Notebook (en Plane/Git), porque Notebook no es un gestor de proyectos.

## 4. Puente de herramientas (cómo el agente usa el cuaderno)

Hay dos rutas; conviene elegir una como primaria y dejar la otra de respaldo.

### Ruta A — MCP nativo (recomendada para LibreChat y Open WebUI Computer)

El paquete `open-notebook-mcp` (PyPI, mantenido por terceros) se ejecuta por `uvx` y habla con la API vía `OPEN_NOTEBOOK_URL`.

```json
{
  "mcpServers": {
    "open-notebook": {
      "command": "uvx",
      "args": ["open-notebook-mcp"],
      "env": {
        "OPEN_NOTEBOOK_URL": "http://open-notebook:5055",
        "OPEN_NOTEBOOK_PASSWORD": "${OPEN_NOTEBOOK_PASSWORD}"
      }
    }
  }
}
```

- **LibreChat** soporta MCP de forma nativa (stdio/HTTP) vía `librechat.yaml`.
- **Open WebUI** puede consumir MCP; su ruta estable y documentada es el puente OpenAPI de la Ruta B.

### Ruta B — Puente MCP→OpenAPI (`mcpo` de open-webui)

`mcpo` toma un servidor MCP (stdio) y lo expone como OpenAPI, que Open WebUI consume como Tool Server sin cambios.

```bash
uvx mcpo --host 0.0.0.0 --port 8000 --api-key "$MCPO_KEY" \
  -- uvx open-notebook-mcp
```

Luego se registra en **Open WebUI → Admin → Tool Servers** como servidor OpenAPI (`spec URL` = `http://mcpo:8000`). En Docker, `mcpo` debe conocer `OPEN_NOTEBOOK_URL` y `OPEN_NOTEBOOK_PASSWORD`.

> Alternativa sin MCP: al ser `open-notebook` una API REST completa, n8n puede llamarla directamente (`POST /sources`, `POST /search/ask`, `POST /chat/execute`) sin depender del paquete MCP de terceros. Útil si se quiere evitar una dependencia externa.

### Política de permisos del agente

| Acción | Permiso | Regla |
| :-- | :-- | :-- |
| Listar/buscar cuadernos, fuentes, notas | Lectura | Permitido por defecto |
| `search` / `ask` con alcance por cuaderno | Lectura | Permitido; citar fuente |
| Crear nota o `source` | Escritura | Requiere confirmación; marcar como `human` vs `ai` |
| Borrar fuente/nota/cuaderno | Escritura destructiva | Nunca automático; aprobación explícita |
| Generar podcast / transformación costosa | Cómputo | Aprobación y límite de concurrencia |

## 5. Modelos, embeddings y cómputo

- **Proveedor**: configurar Open Notebook contra `Ollama` (nativo) o `OpenAI-Compatible` apuntando a `vLLM`. Los proveedores se gestionan en **Manage → Models** y se cifran en BD con `OPEN_NOTEBOOK_ENCRYPTION_KEY` (variables de entorno de proveedor están **deprecadas**).
- **Embeddings**: viven en SurrealDB. Escoger un modelo de embeddings y mantenerlo estable; cambiarlo obliga a re-indexar.
- **Concurrencia**: en GPU compartida o LLM local, fijar `OPEN_NOTEBOOK_WORKER_MAX_TASKS=1` (procesado secuencial) para no saturar el modelo; subirlo solo con capacidad dedicada.
- **Aislamiento de carga**: el worker (embeddings/podcasts) es intensivo; en hardware compartido, separarlo del nodo de chat para que una ingesta no bloquee Open WebUI/Plane.
- **TTS/STT** (podcasts) usan proveedores propios; si se quiere 100% local, verificar que el proveedor elegido tenga TTS (Ollama no lo tiene).

## 6. Seguridad (no negociable)

- `OPEN_NOTEBOOK_ENCRYPTION_KEY` **obligatoria** y fuera de Git; si se pierde, las credenciales cifradas quedan ilegibles.
- Cambiar `SURREAL_USER`/`SURREAL_PASSWORD` (por defecto `root:root`) y **no exponer SurrealDB**: el puerto 8000 solo en `127.0.0.1`.
- La auth por contraseña y el CORS abierto son de desarrollo: poner **OAuth/JWT y restricción de `CORS_ORIGINS`** en el proxy inverso antes de exponer. Idealmente, publicar Notebook solo en la red interna.
- **Contenido web no confiable**: las fuentes que entran por URLs (Crawl4AI/Firecrawl/Jina) se tratan como datos, nunca como instrucciones; no deben disparar comandos ni cambios en Plane.
- **Nunca indexar secretos** (`.env`, llaves, volcados). Regla de clasificación explícita por fuente.
- Podcasts y archivos subidos viven en el volumen de datos (`/app/data/uploads`); incluirlos en la política de retención y respaldo.

## 7. Despliegue (compose conceptual, integrado al stack)

```yaml
services:
  open-notebook:
    image: lfnovo/open_notebook:v1-latest
    ports:
      - "127.0.0.1:8502:8502"   # UI  (detrás del proxy)
      - "127.0.0.1:5055:5055"   # API (solo red interna)
    environment:
      OPEN_NOTEBOOK_ENCRYPTION_KEY: ${OPEN_NOTEBOOK_ENCRYPTION_KEY}
      OPEN_NOTEBOOK_PASSWORD: ${OPEN_NOTEBOOK_PASSWORD}
      SURREAL_URL: ws://surrealdb:8000/rpc
      SURREAL_USER: ${SURREAL_USER}
      SURREAL_PASSWORD: ${SURREAL_PASSWORD}
      SURREAL_NAMESPACE: open_notebook
      SURREAL_DATABASE: open_notebook
      OLLAMA_API_BASE: http://ollama:11434      # o endpoint vLLM OpenAI-compatible
      OPEN_NOTEBOOK_WORKER_MAX_TASKS: 1
      CORS_ORIGINS: https://notebook.example.internal
    volumes:
      - ./notebook_data:/app/data
    depends_on: [surrealdb, ollama]
    restart: always

  # Worker obligatorio: procesado de fuentes, embeddings y podcasts
  open-notebook-worker:
    image: lfnovo/open_notebook:v1-latest
    command: ["python", "-m", "open_notebook.worker"]
    environment:
      SURREAL_URL: ws://surrealdb:8000/rpc
      SURREAL_USER: ${SURREAL_USER}
      SURREAL_PASSWORD: ${SURREAL_PASSWORD}
      OPEN_NOTEBOOK_ENCRYPTION_KEY: ${OPEN_NOTEBOOK_ENCRYPTION_KEY}
      OPEN_NOTEBOOK_WORKER_MAX_TASKS: 1
    volumes:
      - ./notebook_data:/app/data
    depends_on: [surrealdb]
    restart: always

  surrealdb:
    image: surrealdb/surrealdb:v2
    command: ["start", "--user", "${SURREAL_USER}", "--pass", "${SURREAL_PASSWORD}", "rocksdb:/mydata/mydatabase.db"]
    ports:
      - "127.0.0.1:8000:8000"   # solo depuración local
    volumes:
      - ./surreal_data:/mydata
    restart: always

  # Puente MCP -> OpenAPI para Open WebUI (Ruta B)
  mcpo-notebook:
    image: ghcr.io/open-webui/mcpo:main
    command: ["--host", "0.0.0.0", "--port", "8000", "--api-key", "${MCPO_KEY}", "--", "uvx", "open-notebook-mcp"]
    environment:
      OPEN_NOTEBOOK_URL: http://open-notebook:5055
      OPEN_NOTEBOOK_PASSWORD: ${OPEN_NOTEBOOK_PASSWORD}
    ports:
      - "127.0.0.1:8100:8000"
    restart: always
```

Notas de despliegue:
- El comando del worker exacto debe confirmarse contra la imagen/`Makefile` del repo antes de fijarlo (el backend expone `make worker-start`); trátalo como punto a validar, no como copia literal.
- Con Reverse Proxy, v1.1+ solo exige enrutar `:8502` (la UI proxya `/api/*` internamente); aun así conviene fijar `API_URL`.
- Perfiles de Compose separados: `core` (Notebook surrealdb) vs `integrations` (mcpo) vs `artifacts` (MinIO) para no levantar todo de golpe.

## 8. Automatizaciones (n8n)

- **Ingesta desde trabajo**: issue/PR/comentario cerrado en Plane o GitHub → `POST /sources` (texto o URL) en el cuaderno del proyecto.
- **Cierre de sprint**: `POST /sources/{id}/insights` con transformación de resumen → `note` → dispara Carbone/Gotenberg para el reporte.
- **Podcast/entregable**: generar episodio → archivar audio en MinIO/Nextcloud → registrar enlace en Plane.
- **Sincronización ligera**: exportar notas confirmadas a Markdown y versionarlas en Git (la edición fina no vive en Notebook).

## 9. Fases de adopción

1. **Fase 1 — levantar y aislar**: Open Notebook + SurrealDB + proveedor local (Ollama/vLLM), sin exponer; validar worker, cifrado e ingesta de una fuente.
2. **Fase 2 — integrar herramientas**: puente MCP/mcpo hacia Open WebUI/LibreChat; mapear cuadernos ↔ espacios de Plane; definir el contrato de datos.
3. **Fase 3 — operar y gobernar**: automatizaciones n8n, artefactos a MinIO/Nextcloud, OAuth en el proxy, retención, auditoría de qué agente leyó/escribió.

## 10. Riesgos y puntos abiertos

- **Single-user** hoy: no asumir multiusuario real hasta [#712].
- **Auth básica + CORS abierto**: endurecer en el proxy o no exponer.
- **Dependencia externa**: `open-notebook-mcp` lo mantiene un tercero (Epochal); si preocupa, usar la API REST directa.
- **Contrato de retrieval en evolución**: el diseño de "evidence bundle" y citas validación está en deliberación ([#1315], ~oct-2026); el filtrado por cuaderno ([ADR-008]) ya está disponible y es estable.
- **SurrealDB**: base de datos menos común que Postgres; requiere respaldos y operación propias.
- **Solapamiento de RAG**: evitar tener el mismo corpus indexado a la vez en Open Notebook (SurrealDB) y en Open WebUI (vector store); asignar dominios distintos.

[[#712]]: https://github.com/lfnovo/open-notebook/issues/712
[[ADR-008]]: docs/7-DEVELOPMENT/decisions/ADR-008-notebook-scoped-search.md
[[#1315]]: https://github.com/lfnovo/open-notebook/discussions/1315
