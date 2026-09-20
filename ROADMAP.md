# Roadmap — stack-soberano

Principio rector: **soberanía primero, y solo lo necesario por fase**. Ningún servicio entra sin un caso de uso escrito en una frase. Cada fase deja el sistema funcionando; no hay big-bang.

Decisiones que rigen el recorte:

- **100% uso interno.** Fair-code (Carbone) es aceptable; sin reventa. La automatización usa **Activepieces (MIT)**, no n8n. Ver [`docs/02`](docs/02-stack-y-licencias.md).
- **Solo lectura por defecto.** La escritura se gana caso por caso mediante el gateway supervisor. Ver [`docs/adr/ADR-001`](docs/adr/ADR-001-gateway-supervisor.md).
- **El historial se conserva.** Es un activo y no sale de nosotros. Ver [`docs/06`](docs/06-datos.md).
- **Una sola base vectorial durable.** Open WebUI solo para documentos efímeros de chat; el corpus vive en Notebook.

Convenciones: `[ ]` pendiente · `[~]` en curso · `[x]` hecho · `[−]` congelado.

---

## Fase 0 — Fundamentos del repositorio

- [x] Estructura, documentación y decisión de licencias
- [x] Diseño de la modalidad Notebook
- [x] Sweet spot de datos y ADR del gateway supervisor
- [ ] Validar comando del worker de Open Notebook contra la imagen real
- [ ] Fijar versiones de imagen por digest en los compose
- [ ] `CONTRIBUTING.md`

## Fase 1 — Reemplazo soberano de Perplexity (3 servicios)

**Objetivo:** chat privado con búsqueda web citada. Nada más.

- [ ] Open WebUI tras el proxy
- [ ] Ollama como backend de modelos (vLLM solo si aparece concurrencia real)
- [ ] SearXNG con `format: json` habilitado
- [ ] Memoria nativa con reglas de `docs/06`
- [ ] Secretos fuera de Git

**Criterio de salida:** puedo preguntar, obtener respuesta con fuentes web citadas y conservar mi historial, todo self-hosted.

## Fase 1.5 — Investigación curada (solo si hay corpus que conservar)

Se añade **cuando existan fuentes que merezca la pena mantener**, no antes.

- [ ] Open Notebook + SurrealDB + worker
- [ ] Gateway supervisor en modo lectura delante de MCP
- [ ] Puente `open-notebook-mcp` vía gateway (mcpo/MCP)
- [ ] Regla de una sola base vectorial durable aplicada

**Criterio de salida:** guardo fuentes, las recupero con alcance por cuaderno y el agente solo puede leer.

## Fase 2 — Trabajo (cuando exista un flujo real)

- [ ] Plane CE + `plane-mcp-server` en **lectura** (stdio + PAT; CE no soporta OAuth)
- [ ] Activepieces **solo** cuando haya una automatización concreta que lo justifique
- [ ] Contrato cuaderno ↔ espacio de Plane

**Criterio de salida:** la investigación puede vincularse a un work item sin duplicar datos.

## Fase 3 — Entregables (bajo demanda, uno por uno)

- [ ] Carbone + Gotenberg al necesitar documentos con plantilla
- [ ] Metabase o Superset al necesitar KPIs
- [ ] ONLYOFFICE al necesitar edición posterior
- [ ] MinIO/Nextcloud al acumular artefactos
- [ ] Sandbox de código aislado al necesitar cómputo

## Congelado hasta necesidad real

- [−] ComfyUI (consume GPU)
- [−] Mem0 (memoria compartida entre agentes)
- [−] Dify / Langflow (orquestación visual)
- [−] LibreChat (se activa solo si Open WebUI se queda corto en MCP nativo)
- [−] vLLM (hasta tener concurrencia)

## Backlog / exploración

- [ ] SurrealDB v2 → v3 (seguir upstream de Open Notebook)
- [ ] Endurecer el gateway supervisor con reglas verificables
- [ ] Perplexica/Vane como UI de búsqueda-respuesta directa (opcional)
- [ ] Mapa de sustitución comercial si el proyecto deja de ser interno (`docs/02`)

## Riesgos transversales

| Riesgo | Mitigación |
| :-- | :-- |
| Fair-code restringe reventa/SaaS | Uso interno; mapa de sustitución en `docs/02` |
| Open Notebook es single-user hoy | No prometer multiusuario; seguir upstream [#712] |
| Auth básica y CORS abierto | No exponer directo; OAuth en el proxy |
| Inyección de prompt con acción | Gateway supervisor fail-closed + lectura por defecto (`ADR-001`) |
| Gotenberg con CVEs 2026 | Aislado, actualizado, sin exposición pública |
| SurrealDB operación propia | Backups y runbook (`docs/05`) |
| Divergencia de RAG | Una sola base vectorial durable (`docs/06`) |
| Complejidad operativa | Recorte por fase; sin servicio sin caso de uso |
