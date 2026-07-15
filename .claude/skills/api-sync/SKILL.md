---
name: api-sync
description: Re-scrapear la documentación oficial de OpenFactura (Haulmer) y los PDFs del SII para detectar cambios de la API y actualizar la base de conocimiento local (.claude/skills/openfactura-api y sii-dte-formato) y los gaps del gem. Usar cuando se pida actualizar/verificar la doc de la API, revisar si hay endpoints o campos nuevos, o periódicamente antes de trabajo mayor sobre el gem.
---

# Sincronización de la base de conocimiento con la doc oficial

La documentación pública (https://docsapi-openfactura.haulmer.com/) es un **Postman Documenter**: la colección completa se obtiene como JSON, lo que permite un scraping 100% fiel sin parsear HTML renderizado.

## Fuentes de verdad

| Fuente | URL |
|---|---|
| Colección Postman (JSON completo) | `https://docsapi-openfactura.haulmer.com/api/collections/6074359/RztfvrGa?environment=6074359-63767e40-75d3-4c44-86e6-26660db9e9a0&segregateAuth=true&versionTag=latest` |
| Página pública (para verificar que los IDs no cambiaron) | `https://docsapi-openfactura.haulmer.com/` |
| SII — Formato DTE | `https://www.sii.cl/factura_electronica/factura_mercado/formato_dte.pdf` |
| SII — Formato boletas (versión antigua v2.22/2020; mismo documento que el siguiente) | `https://www.sii.cl/factura_electronica/factura_mercado/boletas_elec_020.pdf` |
| SII — Formato boleta electrónica (versión vigente; v4.2/2025 al último sync) | `https://www.sii.cl/factura_electronica/factura_mercado/formato_boleta_electronica.pdf` |

Si la URL de la colección devuelve 404, los IDs cambiaron: descargar `https://docsapi-openfactura.haulmer.com/` y extraer de los `<meta>` los valores `collectionId`, `ownerId`, `publishedId` y `environmentUID` para reconstruirla (`/api/collections/{ownerId-prefix de collectionId}/{publishedId}?environment={environmentUID}&segregateAuth=true&versionTag=latest`).

## Procedimiento

1. **Descargar** la colección JSON a un directorio temporal (`curl -sL <url> -o of-collection.json`). Es un Postman Collection v2: `info.description` (intro con changelog) + `item[]` plano (cada item = endpoint con `request.description` en HTML, `request.body`, `response[]` con ejemplos).

2. **Detectar cambios primero, no regenerar a ciegas:**
   - Comparar la tabla "Historial de cambios" de `info.description` contra la copia en `.claude/skills/openfactura-api/references/operacion-y-errores.md`. Filas nuevas = cambios a incorporar.
   - Listar los `item[].name` + método + URL y compararlos con la tabla de endpoints en `.claude/skills/openfactura-api/SKILL.md`. Items nuevos/eliminados = endpoints a documentar/retirar.
   - Si no hay filas ni endpoints nuevos, comparar longitudes de `request.description` por item para detectar ediciones silenciosas.

3. **Extraer a markdown** los items con cambios (convertir el HTML de descripciones a tablas markdown; truncar strings base64 largos de los ejemplos). Script de referencia: iterar `item[]`, volcar `name`, `request.method`, `request.url.raw`, `request.description`, `request.body.raw` y cada `response[]` (name, code, originalRequest.body, body).

4. **Actualizar las referencias** afectadas en `.claude/skills/openfactura-api/references/`:
   - `emision-dte.md` — POST /v2/dte/document (emisión + selfService/autoservicio)
   - `consulta-documentos.md` — issued, received, accuse, GET por rut/tipo/folio, GET por token, anularDTE52
   - `registros-y-organizacion.md` — registry sales/purchase, sync-rcv, organization, organization/document, taxpayer
   - `operacion-y-errores.md` — auth, rate limits, changelog, buenas prácticas, FAQ, códigos de error
   Editar quirúrgicamente lo que cambió; conservar la estructura. Actualizar la fecha de "Última sincronización" al final de cada archivo tocado.

5. **PDFs del SII**: comparar tamaño/fecha (`curl -sI` y `Last-Modified`) contra lo anotado en `.claude/skills/sii-dte-formato/references/`. Si cambiaron, re-destilar las secciones afectadas (los PDFs se leen con la herramienta Read por tramos de ≤20 páginas).

6. **Propagar al gem** (skill `openfactura-gem-dev`):
   - Actualizar la matriz de cobertura API↔gem si hay endpoints/campos nuevos.
   - Verificar que `DocumentError::ERROR_CODES` (lib/openfactura/resources/document_error.rb) siga completo vs los códigos OF-xx de la doc.
   - Abrir tareas/notas por cada campo que la doc anuncie como "WARNING hoy, obligatorio próximamente" (patrón que Haulmer usa, p. ej. Resolución 154/2025 en guías 52).

7. **Reportar** al usuario: qué cambió en la API, qué referencias se actualizaron y qué impacto tiene en el gem (roto / gap nuevo / sin impacto).

## Estado de la última sincronización

- Sincronizado por última vez: **2026-07-15** (colección con changelog hasta 28/05/2026: sync-rcv + Resolución 154/2025 para guías 52; MedioPago para boletas 10/02/2026; ivaExceptional 06/08/2025).
- formato_dte.pdf: 49 páginas, ~2.0 MB. boletas_elec_020.pdf: 15 páginas, ~376 KB.
