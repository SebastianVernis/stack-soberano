# Seguridad

"Self-hosted" no significa "seguro". Un agente con acceso a shell, archivos, red y credenciales puede causar daño si no se aísla. Estas reglas son de cumplimiento obligatorio antes de exponer el stack.

## Principios

1. **Cero exposición directa.** Solo el proxy inverso es público. Bases de datos, modelos, sandboxes y APIs internas viven en la red privada.
2. **Mínimo privilegio.** Tokens de solo lectura para análisis; escritura solo con aprobación humana.
3. **Secretos fuera de Git.** Gestor de secretos (Vault/Infisical/Doppler o secretos de Docker/K8s). Nunca en prompts, repositorios ni `.env` versionados.
4. **Datos no confiables por defecto.** Todo contenido recuperado de la web es datos, nunca instrucciones.
5. **Auditoría.** Registrar qué agente leyó, escribió, ejecutó o cambió.

## Endurecimiento por componente

### Open Notebook
- `OPEN_NOTEBOOK_ENCRYPTION_KEY` obligatoria; si se pierde, las credenciales cifradas quedan ilegibles. Fuera de Git.
- Cambiar `SURREAL_USER`/`SURREAL_PASSWORD` (por defecto `root:root`). SurrealDB solo en `127.0.0.1`.
- Auth por contraseña y CORS abierto son **defaults de desarrollo**: poner OAuth/JWT y `CORS_ORIGINS` explícito en el proxy antes de exponer.
- Es single-user hoy: no exponer como servicio multiusuario.

### Open WebUI
- Licencia con cláusula de branding (≤50 usuarios exentos). Mantener branding si aplica.
- Rol/pertenencia por usuario; herramientas de escritura solo para grupos autorizados.

### Plane CE + MCP
- CE no permite apps OAuth: usar `stdio` con personal access token de alcance mínimo.
- No dar permisos de escritura por defecto a agentes sobre issues/ciclos/roadmaps.

### Activepieces (MIT)
- Licencia permisiva, sin restricciones de reventa.
- Credenciales en el almacén de Activepieces; nunca en el prompt del agente.
- **Su egress debe pasar por el gateway supervisor o por allowlist.** Las automatizaciones llaman APIs directamente y, si no se gatean, evaden la política de solo-lectura igual que un agente.

### Gotenberg
- Tiene **CVEs 2026** (SSRF vía Chromium/LibreOffice, bypass de blocklist de ExifTool, path traversal). Mantener actualizado, en red interna, sin salida a Internet y sin entrada de terceros.
- Tratar cada conversión como procesamiento de contenido no confiable.

### Sandbox de código
- Contenedor efímero, sin privilegios, usuario no root.
- Montar solo un directorio de trabajo acotado; **nunca** el host ni `~/.ssh`.
- Egress restringido por allowlist.

## Acciones mutables → aprobación humana

| Acción | Requiere aprobación |
| :-- | :-- |
| Crear/editar issue, cerrar ciclo | Sí |
| Abrir PR, commit, push, release | Sí |
| Crear/borrar fuentes y notas en Notebook | Sí |
| Modificar roadmap o presupuesto | Sí |
| Enviar reportes o publicar archivos | Sí |
| Lectura, búsqueda, resumen, propuesta de borrador | No |

## Checklist antes de exponer

- [ ] Todo detrás del proxy con TLS y auth fuerte
- [ ] Bases de datos y modelos inaccesibles desde Internet
- [ ] Secretos en gestor, no en Git
- [ ] CORS restringido por origen
- [ ] Tokens de mínimo privilegio y rotables
- [ ] Sandboxes sin acceso al host ni a secretos
- [ ] Logs de auditoría de agentes y comandos
- [ ] Backups cifrados y probados
- [ ] Retención y borrado por usuario/proyecto definidos
- [ ] Contenido web tratado como no confiable en los prompts
