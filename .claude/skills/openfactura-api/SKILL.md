---
name: openfactura-api
description: Referencia completa de la API OpenFactura de Haulmer (facturación electrónica chilena) — endpoints, campos, validaciones, errores OF-xx, rate limits y changelog. Usar SIEMPRE antes de implementar, revisar o depurar cualquier interacción del gem con la API - emisión de DTE, consulta de documentos, registros de compra/venta, organización o contribuyentes.
---

# API OpenFactura (Haulmer) — Base de conocimiento

Fuente: scraping completo de https://docsapi-openfactura.haulmer.com/ (colección Postman oficial). Última sincronización: 2026-07-15 (para actualizar, usar el skill `api-sync`).

## Esencial

- API RESTful, JSON. Autenticación: header `apikey: <API_KEY>` en toda petición (una key por contribuyente/empresa).
- URLs: producción `https://api.haulmer.com` — desarrollo/sandbox `https://dev-api.haulmer.com` (operativo sin cuenta; usa CAF simulado, timbre no validable).
- Rate limits: **3 req/s y 100 req/min** → HTTP 429 `{"statusCode": 429, "message": "Rate limit is exceeded. Try again in X seconds."}`.
- API keys sandbox públicas: HAULMER SPA `928e15a2d14d4a6292345f04960f4bd3` (RUT 76795561-8) y HOSTY SPA `41eb78998d444dbaa4922c410ef14057` (RUT 76430498-5).
- La API de emisión sigue la convención de nombres y jerarquía del SII en JSON (ver skill `sii-dte-formato` para la normativa de campos).

## Mapa de endpoints → referencia a cargar

| Endpoint | Función | Referencia |
|---|---|---|
| `POST /v2/dte/document` | Emisión de DTE (y enlace de autoservicio vía `selfService`) | [references/emision-dte.md](references/emision-dte.md) |
| `POST /v2/dte/document/issued` | Listar/filtrar documentos emitidos | [references/consulta-documentos.md](references/consulta-documentos.md) |
| `POST /v2/dte/document/received` | Documentos recibidos | idem |
| `POST /v2/dte/document/received/accuse` | Acuse de recibo | idem |
| `GET /v2/dte/document/{rut}/{type}/{folio}/{value}` | Consulta por RUT+tipo+folio | idem |
| `GET /v2/dte/document/{token}/{value}` | Consulta por token (json/status/pdf/xml/cedible) | idem |
| `POST /v2/dte/anularDTE52` | Anular guía de despacho | idem |
| `GET /v2/dte/registry/sales/{y}/{m}[/{d}]` | Registro de ventas | [references/registros-y-organizacion.md](references/registros-y-organizacion.md) |
| `GET /v2/dte/registry/purchase/{y}/{m}[/{d}]` | Registro de compras (status=pending,exclude,…) | idem |
| `POST /v2/dte/registry/sync-rcv` | Sincronizar RCV desde el SII (nuevo 2026) | idem |
| `GET /v2/dte/organization` | Datos de la organización (extra_fields=logo) | idem |
| `GET /v2/dte/organization/document` | DTEs autorizados y folios disponibles | idem |
| `GET /v2/dte/taxpayer/{rut}` | Consulta de contribuyente | idem |

Operación transversal (auth, rate limits, changelog de la API, buenas prácticas de producción, FAQ, códigos de error consolidados): [references/operacion-y-errores.md](references/operacion-y-errores.md).

## Reglas de uso

- Cargar solo la referencia del endpoint en cuestión; son largas.
- Los nombres de campos JSON de la API van verbatim (español SII: `RznSocRecep`, `MntTotal`…). El mapeo a la DSL en inglés del gem está en el skill `openfactura-gem-dev`.
- El changelog en `operacion-y-errores.md` es la primera parada para saber si algo cambió: Haulmer introduce campos como opcionales con WARNING y luego los vuelve obligatorios (p. ej. Resolución 154/2025 en guías 52).
- Las referencias anotan inconsistencias detectadas en la doc oficial (campos mal descritos, ejemplos que contradicen tablas). Ante una discrepancia, confiar en los **ejemplos reales** de la doc y verificar contra el sandbox.
