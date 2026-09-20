# Roadmap — stack-soberano

Principio rector: **primero soberanía y trazabilidad, luego comodidad**. Cada fase deja el sistema funcionando y auditable, sin big-bang.

Convenciones de estado: `[ ]` pendiente · `[~]` en curso · `[x]` hecho.

---

## Fase 0 — Fundamentos del repositorio

Objetivo: repo, documentación y decisiones de licencia cerradas.

- [x] Estructura de directorios y documentos base
- [x] Política de licencias (fair-code aceptado para uso interno) — `docs/02`
- [x] Diseño de la modalidad Notebook
- [ ] Validar comando del worker de Open Notebook contra la imagen real
- [ ] Fijar versiones de imagen (pin por digest) en los compose
- [ ] `LICENSE` (MIT para el repo) y `CONTRIBUTING.md`

## Fase 1 — Núcleo de chat y conocimiento

Objetivo: chat general privado con memoria y búsqueda web con fuentes.

- [ ] Open WebUI operativo detrás del proxy
- [ ] Ollama (single-user) o vLLM (multi-usuario) como backend de modelos
- [ ] SearXNG con `format: json` habilitado e integrado en Open WebUI
- [ ] Memoria nativa de Open WebUI con política de retención (`docs/04`)
- [ ] Open Notebook + SurrealDB + worker para la modalidad notebook
- [ ] Puente MCP (`open-notebook-mcp`) vía `mcpo` o MCP nativo
- [ ] `OPEN_NOTEBOOK_ENCRYPTION_KEY` y secretos fuera de Git

**Criterio de salida:** un usuario puede chatear, buscar en web con citas y guardar/recuperar investigación en un cuaderno, todo self-hosted.

## Fase 2 — Trabajo, cómputo y entregables

Objetivo: conectar la operación y producir artefactos reproducibles.

- [ ] Plane CE + `plane-mcp-server` (stdio + PAT; CE no soporta OAuth)
- [ ] Mapeo cuaderno ↔ espacio de Plane y contrato de datos (`docs/01`)
- [ ] n8n (fair-code) para ingesta y flujos recurrentes
- [ ] Sandbox de código aislado (Open Terminal MIT / contenedor efímero)
- [ ] ComfyUI en nodo GPU separado
- [ ] Carbone (fair-code) + Gotenberg para documentos y PDF
- [ ] Metabase o Superset para KPIs
- [ ] Plantillas versionadas en Git (5–8 plantillas corporativas)

**Criterio de salida:** un issue cerrado se convierte en borrador de reporte y un paquete de entrega, sin intervención manual.

## Fase 3 — Operación, gobierno y escala

Objetivo: endurecer, automatizar y auditar.

- [ ] OAuth/OIDC en el proxy para todas las interfaces (hoy: auth básica de Notebook)
- [ ] ONLYOFFICE Docs para edición posterior de DOCX/XLSX/PPTX
- [ ] MinIO o Nextcloud para artefactos, versionado y retención
- [ ] Mem0 OSS si se necesita memoria compartida entre agentes
- [ ] Auditoría: registrar qué agente leyó/escribió (MCP, comandos, cambios)
- [ ] Backups probados de PostgreSQL, SurrealDB y volúmenes de artefactos
- [ ] SSO, roles y segmentación de red; egress restringido en sandboxes

**Criterio de salida:** operación con aprobación humana para acciones mutables y auditoría completa.

## Backlog / exploración

- [ ] Migración SurrealDB v2 → v3 (seguir plataforma upstream de Open Notebook)
- [ ] Evaluar Superset vs Metabase según perfil de usuarios
- [ ] Endurecer `mcpo` con API key y red interna
- [ ] Evaluar alternativas fair-code de n8n (Activepieces MIT, Kestra Apache-2.0) si cambian las condiciones
- [ ] Perplexica/Vane como UI de búsqueda-respuesta directa (opcional)

## Riesgos transversales

| Riesgo | Mitigación |
| :-- | :-- |
| Fair-code restringe reventa/SaaS | Uso interno únicamente; no white-label; documentado en `docs/02` |
| Open Notebook es single-user hoy | No prometer multiusuario; seguir upstream [#712] |
| Auth básica y CORS abierto | No exponer directo; OAuth en proxy (Fase 3) |
| Gotenberg con CVEs 2026 (SSRF/path traversal) | Aislado, actualizado, sin exposición pública |
| SurrealDB operación propia | Backups y runbook (`docs/05`) |
| Duplicar RAG (Notebook vs Open WebUI) | Asignar dominios de conocimiento distintos |
