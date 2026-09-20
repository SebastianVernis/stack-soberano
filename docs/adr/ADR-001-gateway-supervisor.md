# ADR-001: Gateway supervisor con lectura por defecto

- **Estado:** Aceptada
- **Fecha:** 2026-09
- **Relacionado:** `docs/04-seguridad.md`, `docs/06-datos.md`, `ROADMAP.md`

## Contexto

El valor del stack es que los agentes **actúan** sobre herramientas (MCP, archivos, shell, Plane, PRs). Ese mismo hecho es el mayor riesgo: una inyección de prompt —vía web, PDF o fuente de terceros— puede intentar que el agente exfiltre datos o ejecute una acción no deseada. Además, varias piezas de autenticación son débiles por defecto y los servidores MCP en `stdio` corren con privilegios del host.

Se decide que la plataforma sea **solo-lectura por defecto**, ganando capacidad de escritura caso por caso, con un **modelo supervisor** que únicamente adjudica el acceso a herramientas.

## Decisión

Introducir un **gateway de herramientas** entre el agente y los servidores MCP (o APIs), que aplica políticas y decide `allow | deny | needs_human` antes de reenviar cualquier llamada.

Dos responsabilidades separadas, nunca mezcladas:

1. **Reglas deterministas (código).** Invariantes que el LLM no decide jamás.
2. **Supervisor LLM (zona gris).** Solo juzga los casos que las reglas no cubren.

## Diseño

```text
Modelo actor ──propone tool call──► GATEWAY (PEP)
                                      │
                       ┌──────────────┴───────────────┐
                       ▼                              ▼
             Reglas deterministas            Supervisor LLM (PDP)
             (código, sin LLM)               (solo zona gris)
                       │                              │
                       └──────────────┬───────────────┘
                                      ▼
                           allow | deny | needs_human
                                      │
                             log de auditoría (siempre)
                                      │
                                      ▼
                              servidor MCP / API
```

### Reglas deterministas (nunca el LLM)

- **Lectura permitida por defecto; escritura denegada por defecto.**
- Borrado, `push`, release, acceso a secretos y egress de red: **denegados** salvo concesión explícita.
- Allowlist de recursos (a qué cuaderno, proyecto y rutas puede tocar).
- Límites de coste/tokens y de concurrencia.
- **Fail-closed**: sin veredicto válido → `deny`.

### Supervisor LLM (solo zona gris)

- Recibe: herramienta propuesta, argumentos, **objetivo declarado del paso** y clasificación del dato tocado.
- **No ve secretos.** Trata argumentos y contenido recuperado como **datos, no instrucciones**.
- Modelo **pequeño, local y distinto del actor**; temperatura 0; salida estructurada.
- **Fast-path**: las lecturas conocidas no invocan al LLM (latencia y GPU). El supervisor entra en escrituras y casos ambiguos.

### Contrato de decisión

```json
{
  "decision": "allow | deny | needs_human",
  "scope": "source:abc | notebook:xyz | project:prj",
  "ttl": "task",
  "risk": "bajo | medio | alto",
  "policy_rule": "read-only-default | scope-allowlist | ...",
  "reason": "explicación breve"
}
```

### Escritura ganada, no permanente

- La escritura se concede con **token de capacidad acotado** (recurso + tarea + caducidad), no de forma global.
- `needs_human` escala a aprobación humana en la interfaz (Open WebUI/LibreChat) o vía Activepieces.
- Toda decisión —`allow`, `deny`, `needs_human`— queda **auditada**.

## Consecuencias

- El modo lectura es el **default del transporte**, aplicable a Open WebUI, LibreChat y Activepieces por igual. Las automatizaciones también deben pasar por el gateway o por allowlist de egress.
- Se añade latencia y consumo de GPU en las escrituras; mitigado con el fast-path y un modelo pequeño.
- El supervisor es un nuevo punto de fallo: puede denegar de más. Se mitiga con reglas deterministas por encima y revisión de denegaciones.
- Si el supervisor es el mismo modelo que el actor, comparten punto ciego; de ahí la separación.

## Alternativas consideradas

- **Confiar en el prompt del agente** ("no hagas daño"): rechazada; no es un control.
- **Solo reglas deterministas sin supervisor**: rechazada; no cubre el matiz del caso gris.
- **Solo supervisor LLM para todo**: rechazada; los invariantes duros deben ser código.
- **Permisos por agente en cada interfaz**: rechazada; fragmenta la política y no es transporte-agnóstico.

## Cuestiones abiertas

- Criterio de aceptación del supervisor en Fase 1.5 (qué escrituras se habilitan primero).
- Umbral de riesgo que fuerza `needs_human` frente a `deny` automático.
- Revisión periódica de las denegaciones para evitar falso negativo sistémico.
