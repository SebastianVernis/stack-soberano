# Operación

Runbook mínimo para operar el stack. No es exhaustivo; crece con cada incidente real.

## Orden de arranque

Cada capa depende de la inferior:

1. **Datos**: PostgreSQL, Redis, SurrealDB, MinIO.
2. **Modelos**: Ollama o vLLM (verificar endpoint OpenAI-compatible).
3. **Servicios base**: SearXNG, Open Notebook API + worker.
4. **Aplicaciones**: Open WebUI/LibreChat, Plane, Activepieces, Metabase.
5. **Borde**: proxy inverso.
6. **Pesados** (nodos GPU): ComfyUI, Carbone/Gotenberg, ONLYOFFICE.

> Si Open Notebook no arranca, verificar primero SurrealDB (el API falla sin él) y el worker (sin worker, fuentes/embeddings/podcasts se encolan para siempre).

## Health checks

| Servicio | Chequeo |
| :-- | :-- |
| Open Notebook API | `GET :5055/health` |
| Open Notebook UI | `:8502` responde |
| SurrealDB | conexión `ws://surrealdb:8000/rpc` |
| Open WebUI | `GET /health` interno |
| Plane | endpoint de salud del API |
| Activepieces | `GET :80/` |
| Ollama | `GET :11434/api/tags` |
| vLLM | `GET /health` |
| Gotenberg | `GET /health` o `:3000/docs` |

## Backups

| Dato | Método | Frecuencia |
| :-- | :-- | :-- |
| PostgreSQL | `pg_dump` + WAL | Diario |
| SurrealDB | export/backup del volumen + snapshots | Diario |
| Volúmenes de artefactos (MinIO/Nextcloud) | snapshot/versionado | Diario |
| Notebook `/app/data` (uploads) | snapshot | Diario |
| Plantillas y este repo | Git | Continuo |

- Respaldos **cifrados** y **restaurados de prueba** al menos una vez por trimestre.
- Guardar fuera del mismo host.

## Actualizaciones

1. Fijar versiones de imagen por digest (no `latest`) en producción.
2. Leer el changelog del upstream antes de actualizar.
3. Actualizar en ventana, con backup previo.
4. Verificar health checks y una operación de humo (chat, ingesta, búsqueda).

## Logs y observabilidad

- API de Notebook: logs estructurados (loguru); revisar errores de migración al arrancar.
- Activepieces: historial de ejecuciones.
- Proxy: logs de acceso y errores 4xx/5xx.
- SurrealDB: métricas del contenedor.
- Centralizar si es posible (Loki/Grafana o equivalente).

## Gestión de incidentes

1. **Contener**: aislar el servicio afectado (red o `stop`), sin borrar datos.
2. **Diagnosticar**: logs del proxy y del servicio; revisar cambios recientes.
3. **Corregir**: parche mínimo; evitar cambios amplios en caliente.
4. **Verificar**: health checks + operación de humo.
5. **Registrar**: post-mortem breve y actualización de este runbook.

## Tareas periódicas

- **Semanal**: revisar fallos de jobs/workers y espacio en disco.
- **Mensual**: rotar tokens con alcance de escritura; revisar usuarios y permisos.
- **Trimestral**: prueba de restauración de backups; revisar licencias upstream; actualizar dependencias con CVEs.
- **Semestral**: revisar retención y borrado; auditoría de accesos de agentes.

## Puntos a validar antes de producción

- [ ] Comando exacto del worker de Open Notebook (`make worker-start` → imagen)
- [ ] Variables de proveedor de modelos (usar el sistema de credenciales, no las env deprecadas)
- [ ] Configuración de `NO_PROXY` si hay proxy corporativo (`surrealdb`, `host.docker.internal`)
- [ ] Límites de subida (`OPEN_NOTEBOOK_MAX_UPLOAD_SIZE_MB`) vs límite del proxy
- [ ] `OPEN_NOTEBOOK_WORKER_MAX_TASKS=1` en GPU compartida o LLM local
- [ ] CVEs de Gotenberg y versión fijada
