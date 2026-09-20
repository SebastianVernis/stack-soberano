# Arquitectura

Diseño modular por capas. Cada capa se puede desplegar y escalar por separado; el proxy inverso es el único punto de entrada.

## Vista de capas

```text
Usuarios / equipo
        │
        ▼
┌───────────────────────────────────────────────────────────────────┐
│ Proxy inverso (Caddy / Traefik) — TLS, OAuth/OIDC, allowlist      │
└───────┬───────────────────┬──────────────────┬────────────────────┘
        │                   │                  │
        ▼                   ▼                  ▼
┌───────────────┐   ┌───────────────┐   ┌──────────────────────┐
│ Interfaz IA   │   │ Trabajo       │   │ Notebook             │
│ Open WebUI    │   │ Plane CE      │   │ Open Notebook        │
│ LibreChat     │   │ + Plane MCP   │   │ UI :8502 / API :5055 │
└───────┬───────┘   └───────┬───────┘   └──────────┬───────────┘
        │  MCP / OpenAPI    │                      │
        └─────────┬─────────┴──────────────────────┘
                  │
     ┌────────────┼───────────────────────────────┐
     ▼            ▼                               ▼
 Modelos      Automatización                 Persistencia
 Ollama/vLLM  n8n (fair-code)               PostgreSQL + Redis
 SearXNG      Sandbox de código              SurrealDB (Notebook)
 ComfyUI      (Open Terminal / efímero)      MinIO / Nextcloud
     │
     ▼
 Entregables
 Carbone + Gotenberg → DOCX/XLSX/PPTX/PDF
 Metabase / Superset → tableros y KPIs
 ONLYOFFICE Docs     → edición colaborativa
```

## Capas y responsabilidades

### 1. Borde (proxy inverso)
- Terminación TLS y enrutamiento por host/path.
- Autenticación fuerte (OAuth/OIDC) porque varias interfaces tienen auth débil por defecto.
- Rate limiting, allowlist de egress y logs de acceso.

### 2. Interfaz IA
- **Open WebUI**: cockpit principal. Chat, memoria nativa, RAG, herramientas OpenAPI/MCP, ejecución de código.
- **LibreChat** (opcional): agentes, MCP nativo, code interpreter. No montar dos interfaces para el mismo equipo al inicio (duplica usuarios y configuración).

### 3. Trabajo
- **Plane CE**: fuente de verdad de proyectos, work items, ciclos y roadmap.
- **`plane-mcp-server`**: expone Plane a los agentes. En CE usar transporte **stdio + personal access token** (CE no soporta apps OAuth).

### 4. Notebook (investigación curada)
- **Open Notebook**: cuadernos, fuentes, notas, RAG con SurrealDB, transformaciones, podcasts.
- Worker obligatorio para procesado asíncrono.
- Detalle en [`03-modalidad-notebook.md`](03-modalidad-notebook.md).

### 5. Modelos
- **Ollama**: arranque simple, un usuario. **vLLM**: producción multi-usuario (mucho mayor throughput y menor latencia bajo concurrencia).
- Endpoint OpenAI-compatible único para todos los consumidores.

### 6. Automatización y cómputo
- **n8n** (fair-code): webhooks, agendas, ingesta, generación y distribución de artefactos.
- **Sandbox**: contenedores efímeros sin privilegios para Python/Node/Bash. Aislamiento por usuario es capa Enterprise (Open WebUI Terminals) → alternativa: worker dedicado.

### 7. Entregables
- **Carbone** (fair-code) rellena plantillas con JSON → DOCX/XLSX/PPTX/PDF.
- **Gotenberg** convierte HTML/Markdown/Office → PDF (aislado por CVEs).
- **Metabase/Superset** para BI.
- **ONLYOFFICE Docs** para edición posterior.

### 8. Persistencia y artefactos
- **PostgreSQL + Redis**: datos de Open WebUI, Plane, n8n, Metabase.
- **SurrealDB**: exclusivo de Open Notebook (interno, `127.0.0.1`).
- **MinIO/Nextcloud**: podcasts, documentos, evidencias.

## Puertos de referencia

| Servicio | Puerto interno | Exposición |
| :-- | :-- | :-- |
| Proxy (Caddy) | 80/443 | Público (con auth) |
| Open WebUI | 8080 | Vía proxy |
| LibreChat | 3080 | Vía proxy |
| Plane (web/api) | 80 / 8000 | Vía proxy |
| Open Notebook UI | 8502 | Vía proxy (interno preferido) |
| Open Notebook API | 5055 | Solo red interna |
| SurrealDB | 8000 | Solo `127.0.0.1` |
| Ollama | 11434 | Solo red interna |
| vLLM | 8000 | Solo red interna |
| SearXNG | 8080 | Solo red interna |
| n8n | 5678 | Vía proxy (con auth) |
| Gotenberg | 3000 | Solo red interna |
| Carbone | 4000 | Solo red interna |
| Metabase | 3000 | Vía proxy |

## Flujo de datos (contrato)

1. **Ingesta**: n8n o el usuario crean `source` en un cuaderno (o issue/PR → fuente).
2. **Procesado**: el worker extrae texto, genera embeddings en SurrealDB y extrae temas.
3. **Consulta**: el agente usa `search`/`ask` con alcance por cuaderno (`notebook_ids`).
4. **Síntesis**: el LLM redacta citando fuentes; los hechos quedan en `note`.
5. **Entrega**: transformación → plantilla Carbone/Gotenberg → PDF/DOCX → MinIO → enlace en Plane.
6. **Auditoría**: se registran lecturas/escrituras de agentes y comandos ejecutados.

## Fronteras que no se cruzan

- Notebook **no** es editor de documentos ni storage ni chatbot general.
- Open WebUI **no** es la fuente de verdad de proyectos.
- Plane **no** almacena el corpus de investigación.
- No duplicar el mismo corpus con embeddings en SurrealDB y en el vector store de Open WebUI.
