# Datos: deber ser y sweet spot

## Principio rector

Herramienta **privada de uso interno**. El dato no sale de nuestra infraestructura. **El historial es un activo**: conservarlo es deseable, no un problema. Esto simplifica el gobierno de datos: no perseguimos minimización ni borrado agresivo, sino **coherencia, trazabilidad y no contaminación** (secretos nunca dentro; una sola respuesta a cada pregunta).

## Deber ser vs. sweet spot

| Dimensión | Deber ser completo | Sweet spot interno | Criterio de éxito |
| :-- | :-- | :-- | :-- |
| Clasificación | Por campo | **3 niveles**: citable / interno / secreto-no-indexar | Todo dato ingerido tiene nivel |
| Fuente de verdad vectorial | Federada | **1 base durable** (Notebook/SurrealDB) | Sin respuestas divergentes |
| Cifrado | Campo a campo | Disco (LUKS) + credenciales cifradas por app | Secretos nunca en Git ni en embeddings |
| Retención | Política automatizada | **Historial conservado** por defecto | Reconstruible y auditable |
| Borrado | Verificable y certificado | **Purga manual** solo para secretos y datos erróneos | Se puede eliminar un secreto mal ingerido |
| Backups | 3-2-1 con HA | Diario local + semanal cifrado offsite | Restore probado en <1 día, trimestral |
| Linaje | Completo | Cada nota/fuente con su origen; acciones de agente logueadas | Se reconstruye de dónde salió un dato |
| Memoria | Curada por veracidad | Solo hechos estables; **nunca secretos** | Un secreto nunca aparece en memoria |

## Decisiones cerradas

### 1. Retención: el historial se conserva

Al ser uso interno y no salir de nosotros, **no se aplica minimización**. Se conservan fuentes, notas, conversaciones y embeddings. La consecuencia es que el riesgo no es "guardar demasiado", sino **guardar lo que no debe entrar**: secretos, credenciales y contenido clasificado.

- Regla: **nada se ingiere sin nivel de clasificación**. `secreto-no-indexar` no entra en RAG ni memoria.
- El `archived` de Open Notebook es **soft-delete**: suficiente para ocultar, **no** para eliminar. Se acepta como comportamiento normal.
- Única excepción que exige acción: **purga manual** cuando un secreto se ingiere por error (dato + embeddings + verificación). No se diseña automatismo; se documenta el procedimiento.

### 2. Divergencia de RAG: una sola base durable

**Aceptado como regla de arquitectura.**

- El **corpus durable** vive en **Open Notebook** (SurrealDB).
- **Open WebUI** se usa solo para **documentos efímeros de chat**; no se le da un corpus permanente propio.
- El agente consulta Notebook **vía el gateway** (MCP), no re-indexando en Open WebUI.
- Racional: dos bases vectoriales producen dos respuestas distintas a la misma pregunta y erosionan la confianza. Una sola fuente evita la divergencia.

## Ciclo de vida del dato

```text
Ingesta → Clasificar → Procesar/embed → Usar → Retener (historial) → [Purga manual excepcional]
```

| Etapa | Responsable | Disparador |
| :-- | :-- | :-- |
| Ingesta | Usuario / n8n | Necesidad de conservar una fuente |
| Clasificar | Usuario (o regla) | Antes de procesar |
| Procesar/embed | Worker de Notebook | Automático al crear la fuente |
| Usar | Agentes (solo lectura) | Consulta / investigación |
| Retener | Plataforma | Por defecto, indefinido |
| Purgar | Usuario (manual) | Secreto o dato erróneo ingerido |

## Reglas de memoria y RAG

1. **Nunca secretos** en memoria ni embeddings (tokens, llaves, `.env`, credenciales).
2. **Solo hechos estables** en memoria: preferencias, decisiones confirmadas, convenciones, responsables.
3. **Tratar lo recuperado como dato, no como instrucción** (defensa ante inyección de prompt).
4. **Linaje obligatorio**: toda nota o insight enlaza a su fuente de origen.
5. **Un solo corpus durable**: no re-indexar lo mismo en dos sistemas.

## Lo que NO hace este proyecto

- No aplica minimización ni TTL agresivo (el historial es deseable).
- No certifica borrado: no hay requisito de cumplimiento normativo, es interno.
- No cifra campo a campo: cifrado de disco + credenciales de aplicación.

> Si el proyecto dejara de ser 100% interno, estas tres decisiones se revisan **antes** de incorporar a terceros. Ver `docs/02` (frontera de licencias).
