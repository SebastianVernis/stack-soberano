# Stack y licencias (fair-code)

Este proyecto es **self-hosted y source-available**. No exige que cada pieza sea OSI-open-source: acepta componentes **fair-code / source-available** para uso interno. Lo que sí exige es que la licencia **permita operarlos self-hosted** y que se cumplan sus condiciones.

> **Regla única que resume todo:** uso **interno**. No revender, no white-label y no ofrecer el software como servicio hospedado a terceros. Si eso cambia, cada licencia se revisa antes, no después.

## Inventario de licencias

| Componente | Licencia | Modelo | ¿Uso interno self-hosted? | Condición clave |
| :-- | :-- | :-- | :-- | :-- |
| Open WebUI | Open WebUI License (BSD-3 + branding) | Source-available | Sí | Mantener branding salvo ≤50 usuarios o licencia enterprise |
| LibreChat | MIT | OSI | Sí | Sin restricciones |
| Ollama | MIT | OSI | Sí | Sin restricciones |
| vLLM | Apache-2.0 | OSI | Sí | Sin restricciones |
| SearXNG | AGPL-3.0 | OSI (copyleft) | Sí | Si se modifica y se sirve por red, publicar cambios |
| Plane CE | AGPL-3.0 | OSI (copyleft) | Sí | Modificaciones bajo la misma licencia |
| plane-mcp-server | MIT | OSI | Sí | Sin restricciones |
| **n8n** | Sustainable Use License ("fair-code") | Source-available | **Sí** | Solo uso interno; **prohibido revender/hospedar como servicio** |
| Open Notebook | MIT | OSI | Sí | Sin restricciones |
| open-notebook-mcp | (tercero, PyPI) | — | Sí | Dependencia externa; revisar antes de producción |
| **Carbone CE** | Carbone Community License (CCL) | Open core | **Sí** | No ofrecer como "Document-Generator-as-a-Service"; CE va una major por detrás |
| Gotenberg | MIT | OSI | Sí | Sin restricciones (aislar por CVEs) |
| **Dify CE** | Apache-2.0 + condiciones | Source-available | **Sí** (si se usa) | Prohibido multi-tenant y quitar el logo |
| Langflow | MIT | OSI | Sí | Sin restricciones |
| ComfyUI | GPL-3.0 | OSI (copyleft) | Sí | Copyleft fuerte |
| Metabase | AGPL-3.0 | Open core | Sí | Funciones de gobernanza son de pago |
| Apache Superset | Apache-2.0 | OSI | Sí | Sin restricciones |
| ONLYOFFICE Docs CE | AGPL-3.0 | OSI (copyleft) | Sí | CE recomendada ≤20 usuarios; no quitar logo |
| MinIO | AGPL-3.0 | OSI (copyleft) | Sí | Modificaciones/servicio por red → publicar |
| Nextcloud | AGPL-3.0 | OSI | Sí | Apps enterprise son propietarias |
| Mem0 OSS | Apache-2.0 | OSI | Sí | La plataforma gestionada tiene optimizaciones propietarias |
| Open Terminal | MIT | OSI | Sí | **Terminals** (orquestación por usuario) es Enterprise License |

## Reglas de cumplimiento

1. **Sin reventa ni SaaS.** n8n y Carbone CE no pueden ofrecerse como servicio hospedado a terceros. Uso interno, sí.
2. **Atribución.** No quitar branding de Open WebUI, Dify ni ONLYOFFICE.
3. **Copyleft.** Si se modifica SearXNG, Plane CE, Metabase, ONLYOFFICE o MinIO y se sirve por red, liberar las modificaciones.
4. **Sin multi-tenant en Dify CE** salvo licencia comercial.
5. **Fair-code ≠ OSI.** En la documentación del proyecto se etiqueta correctamente como *source-available / fair-code*, nunca como "open source" a secas.
6. **Licencias de terceros.** Este repo se licencia MIT, pero cada servicio arrastra su propia licencia; ante duda, revisar el `LICENSE` del componente antes de desplegar.

## Mapa de sustitución comercial (si deja de ser 100% interno)

Hoy el proyecto es de uso interno y **no se cambia nada**. Si algún día se incorporan terceros o clientes, este es el plan de sustitución, por carril:

| Carril | Componentes | Si se comercializa |
| :-- | :-- | :-- |
| **Verde** (OSI, seguro para embeber/distribuir) | Ollama, vLLM, LibreChat (MIT), Open Notebook (MIT), Gotenberg (MIT), Langflow (MIT), Superset (Apache-2.0) | Sin cambios |
| **Amarillo** (fair-code, solo interno) | n8n, Carbone CE | **n8n → Activepieces (MIT) o Kestra (Apache-2.0)**; **Carbone → docxtemplater (MIT) + Gotenberg** |
| **Rojo** (branding / open-core) | Open WebUI (cláusula de marca), Dify (prohibido multi-tenant), Metabase (gobernanza de pago) | Open WebUI → mantener marca o comprar licencia; Metabase → Superset; Dify → no usar |
| **AGPL embebido** | Plane CE, MinIO, ONLYOFFICE, SearXNG | **Consumir por API sin modificar el código** (el AGPL no se dispara por usar la API); si se modifica y se distribuye/expone por red, liberar cambios |

**Regla de oro del carril AGPL:** no forkear AGPL y meterlo dentro de un producto. Usarlo por su API no contagia; embeber una versión modificada, sí.

La mitigación estructural ya está: al hablar todo por **MCP / OpenAI-compatible / REST**, sustituir una pieza es barato. El único eslabón rígido es Notebook↔SurrealDB, que es MIT.

## Cuándo revisar una licencia

- Antes de **exponer cualquier servicio a usuarios externos** o clientes.
- Antes de **empaquetar el stack para terceros**.
- Cuando un upstream cambie de licencia (revisar releases periódicamente).
- Si se plantea un modelo freemium o de reventa → volver a evaluar n8n y Carbone primero.

## Referencias upstream

- n8n — Sustainable Use License: https://docs.n8n.io/privacy-and-security/sustainable-use-license/
- Carbone CCL: https://github.com/carboneio/carbone/blob/master/LICENSE.md
- Dify License: https://github.com/langgenius/dify/blob/main/LICENSE
- Open WebUI License: https://docs.openwebui.com/license
- Plane editions: https://github.com/makeplane/developer-docs
- ONLYOFFICE License FAQ: https://www.onlyoffice.com/license-faq
