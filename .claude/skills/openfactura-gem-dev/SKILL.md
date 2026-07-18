---
name: openfactura-gem-dev
description: Arquitectura, convenciones y guía de extensión del gem openfactura-ruby (SDK/DSL Ruby para la API OpenFactura de Haulmer). Usar al desarrollar, revisar o extender el gem — agregar endpoints, clases DSL, campos, manejo de errores o tests. Incluye la matriz de cobertura API↔gem y el checklist para agregar funcionalidades.
---

# Desarrollo del gem openfactura-ruby

## Objetivo del gem

SDK Ruby con DSL en inglés para consumir la API OpenFactura (Haulmer) de facturación electrónica chilena. El foco principal es la **emisión de DTEs** (facturas, notas, guías), la **consulta de documentos emitidos** y los **datos de la organización**. El gem traduce una interfaz Ruby idiomática (claves en inglés, snake_case) al formato JSON de la API (claves en español, convención SII).

Consumidor típico: una app Rails que emite facturas (tipo 33) y consulta su estado/PDF/XML.

## Skills relacionados

- `openfactura-api`: referencia completa de la API (endpoints, campos, errores, changelog). Consultar SIEMPRE antes de implementar contra un endpoint.
- `sii-dte-formato`: normativa SII (formato DTE y boletas) para validaciones de campos a nivel de documento.

## Arquitectura

```
lib/openfactura.rb              # Entrypoint: Zeitwerk loader + módulo con accessors singleton
├── config.rb                   # Config de clase (api_key, environment, timeout, logger, api_base_url)
├── client.rb                   # Cliente HTTP (HTTParty): get/post/put/delete + manejo de errores HTTP
├── error.rb                    # Jerarquía de errores + Openfactura.parse_error_body
├── sandbox_companies.rb        # Datos de las 2 empresas sandbox públicas (haulmer, hosty)
├── railtie.rb                  # Integración Rails
├── dsl.rb                      # Namespace DSL
├── dsl/
│   ├── documents.rb            # Openfactura.documents → emit, find_by_token
│   ├── organizations.rb        # Openfactura.organizations → current, current_as_issuer, documents
│   ├── dte.rb                  # Clase Dte (valida type, emission_date; ensambla Encabezado/Detalle)
│   ├── receiver.rb             # Receptor
│   ├── dte_item.rb             # Línea de detalle
│   ├── totals.rb               # Totales
│   └── issuer.rb               # Emisor
├── resources/                  # (Zeitwerk: collapse — clases viven en Openfactura::, no ::Resources)
│   ├── organization.rb         # Organization (respuesta de /organization)
│   ├── document.rb             # Document (datos de un DTE consultado)
│   ├── document_response.rb    # DocumentResponse (respuesta de emisión)
│   ├── document_query_response.rb  # DocumentQueryResponse (respuesta de consulta por token)
│   └── document_error.rb       # DocumentError (errores OF-xx con details por campo)
└── generators/openfactura/install_generator.rb  # rails g openfactura:install (ignorado por Zeitwerk)
```

Detalles del loader ([lib/openfactura.rb](lib/openfactura.rb)): Zeitwerk con `collapse` sobre `resources/` (las clases son `Openfactura::Document`, NO `Openfactura::Resources::Document`), `inflect "dsl" => "DSL"`, e `ignore` sobre `generators/`. `error.rb` se requiere explícitamente además del loader.

## Superficie pública actual

| Método Ruby | Endpoint API | Retorna |
|---|---|---|
| `Openfactura.configure { \|c\| ... }` | — | configura `Config` (validación lazy en `Client#initialize`) |
| `Openfactura.documents.emit(dte:, issuer:, response:, custom:, iva_exceptional:, send_email:, idempotency_key:)` | `POST /v2/dte/document` (header `Idempotency-Key`, auto-UUID si no se pasa) | `DocumentResponse` |
| `Openfactura.documents.find_by_token(token:, value:)` — value: json/status/pdf/xml/cedible | `GET /v2/dte/document/{token}/{value}` | `DocumentQueryResponse` |
| `Openfactura.organizations.current(extra_fields:)` | `GET /v2/dte/organization` | `Organization` |
| `Openfactura.organizations.current_as_issuer` | idem + mapeo | `DSL::Issuer` |
| `Openfactura.organizations.documents` | `GET /v2/dte/organization/document` | Hash crudo |
| `Openfactura.reset!` | — | limpia client/documents/organizations memoizados (tests) |

## Matriz de cobertura API ↔ gem (oportunidades de mejora)

Endpoints de la API **aún no cubiertos** por el gem (ver referencias del skill `openfactura-api` para su contrato):

| Endpoint | Función | Estado en gem |
|---|---|---|
| `POST /v2/dte/document` con `selfService` | Emisión de enlace de autoservicio | ❌ no expuesto (emit no acepta selfService) |
| `POST /v2/dte/document/issued` | Listar/filtrar documentos emitidos | ❌ |
| `POST /v2/dte/document/received` | Documentos recibidos | ❌ |
| `POST /v2/dte/document/received/accuse` | Acuse de recibo | ❌ |
| `GET /v2/dte/document/{rut}/{type}/{folio}/{value}` | Consulta por RUT+tipo+folio | ❌ (solo por token) |
| `GET /v2/dte/registry/sales/{y}/{m}[/{d}]` | Registro de ventas | ❌ |
| `GET /v2/dte/registry/purchase/{y}/{m}[/{d}]` | Registro de compras | ❌ |
| `POST /v2/dte/registry/sync-rcv` | Sincronizar RCV desde SII (nuevo 2026) | ❌ |
| `GET /v2/dte/taxpayer/{rut}` | Consulta de contribuyente | ❌ |
| `POST /v2/dte/anularDTE52` | Anular guía de despacho | ❌ |

Gaps funcionales dentro de lo ya cubierto:

- **Boletas (39/41)**: la doc de emisión de la API las cubre explícitamente, pero `Dte::VALID_DTE_TYPES` no incluye 39 ni 41. Implica además soportar `IndServicio`, `MedioPago` (cambio API 10/02/2026) y montos con IVA incluido (ver skill `sii-dte-formato`).
- **Tipos 46/110/111/112**: el gem los lista en `VALID_DTE_TYPES`, pero la doc de emisión de OpenFactura NO los documenta (solo 33/34/39/41/43/52/56/61). Verificar contra sandbox antes de prometer soporte; considerar alinearlos o marcar como no verificados.
- **Guías de despacho (52)**: campos de la Resolución 154/2025 son WARNING hoy y serán obligatorios (cambio API 28/05/2026); el DSL no los modela (`IndTraslado`, transporte).
- **Referencias entre documentos** (`Referencia`, obligatoria para NC/ND 56/61): el DSL `Dte` no modela referencias — hoy no se puede emitir una nota de crédito correcta.
- **Descuentos/recargos globales** (`DscRcgGlobal`): no modelado.
- `organizations.documents` retorna Hash crudo, sin objeto tipado.

## Convenciones del DSL

Patrón uniforme de las clases DSL (`Receiver`, `DteItem`, `Totals`, `Issuer`):

1. `REQUIRED_FIELDS = %i[...].freeze` + `validate_required_fields!` que lanza `Openfactura::ValidationError` al convertir (no al construir).
2. `initialize(attributes = {})` acepta claves símbolo o string (`attributes[:x] || attributes["x"]`).
3. `to_api_hash` traduce a claves API (español/CamelCase del SII), aplica truncados y tipos; `to_h` es alias.
4. Los contenedores (`Dte`) auto-convierten hashes a objetos (`receiver.is_a?(Receiver) ? receiver : Receiver.new(receiver)`).
5. Campos opcionales se agregan condicionalmente y se hace `.compact` cuando aplica.

### Mapeo de campos DSL → API (estado actual)

| Clase | Ruby | API | Transformación |
|---|---|---|---|
| Receiver | rut | `RUTRecep` | — |
| | business_name | `RznSocRecep` | trunca a 100 |
| | business_activity | `GiroRecep` | trunca a 40 |
| | contact | `Contacto` | — |
| | address | `DirRecep` | — |
| | commune | `CmnaRecep` | — |
| DteItem | line_number | `NroLinDet` | `to_i` |
| | name | `NmbItem` | trunca a 80 |
| | quantity | `QtyItem` | `to_f.round(2)` |
| | price | `PrcItem` | `to_f.round(2)` |
| | amount | `MontoItem` | `to_i` |
| | description | `DscItem` | opcional, trunca a 1000 |
| | exempt | `IndExe` | opcional, `true` → `1` |
| Totals | total_amount (requerido) | `MntTotal` | `to_i` |
| | net_amount | `MntNeto` | opcional, `to_i` |
| | tax_amount | `IVA` | opcional, `to_i` |
| | exempt_amount | `MntExe` | opcional, `to_i` |
| | tax_rate | `TasaIVA` | opcional, `to_s` |
| | period_amount | `MontoPeriodo` | opcional, `to_i` |
| | amount_to_pay | `VlrPagar` | opcional, `to_i` |
| Issuer | rut | `RUTEmisor` | — |
| | business_name | `RznSoc` | trunca a 100 |
| | business_activity | `GiroEmis` | trunca a 80 |
| | economic_activity_code | `Acteco` | `to_s` |
| | address | `DirOrigen` | — |
| | commune | `CmnaOrigen` | — |
| | sii_branch_code | `CdgSIISucur` | opcional (compact) |
| | phone | `Telefono` | opcional |
| Dte | type | `TipoDTE` | valida contra VALID_DTE_TYPES |
| | folio | `Folio` | default 0 (auto-asignado) |
| | emission_date | `FchEmis` | default hoy; valida YYYY-MM-DD, rango 2003-04-01..2050-12-31 |
| | purchase_transaction_type | `TpoTranCompra` | opcional |
| | sale_transaction_type | `TpoTranVenta` | opcional |
| | payment_form | `FmaPago` | opcional |

`Dte#to_api_hash` ensambla `{ Encabezado: { IdDoc, Receptor, Totales, Emisor? }, Detalle: [...] }`.

### Jerarquía de errores

```
Openfactura::Error < StandardError
├── ValidationError (errores de config/DSL locales; attr errors)
└── ApiError (attr status_code, response_body)
    ├── AuthenticationError (401)
    ├── NotFoundError (404)
    ├── RateLimitError (429; la API limita 3 req/s y 100 req/min)
    └── ServerError (5xx)
Openfactura::DocumentError < StandardError   # errores de emisión OF-xx; ERROR_CODES, #details, #details_for_field
```

`Documents#emit` convierte `ApiError` con body formato `{ "error": { code, message, details } }` en `DocumentError`. El mapeo OF-01..OF-23 vive en [document_error.rb](lib/openfactura/resources/document_error.rb) y debe mantenerse sincronizado con la referencia `openfactura-api/references/operacion-y-errores.md`.

### Glosario y bilingüismo

El código, nombres de métodos y docs del gem van en **inglés**; las claves de la API son en **español SII** y solo aparecen dentro de `to_api_hash` y specs. El README mantiene un glosario English↔Spanish — al agregar un campo o clase nueva, actualizarlo.

## Testing

- Correr: `bundle exec rspec` (unit) — WebMock bloquea red salvo tests con tag `:integration`.
- Integración real contra sandbox: specs tagged `:integration` (`spec/integration/`), usan `Openfactura::SandboxCompanies.configure_with(:haulmer, environment: :sandbox)` y hacen skip si la API no responde. Las API keys sandbox son públicas (están en el README y en `sandbox_companies.rb`).
- Cada clase nueva lleva spec unitario espejo en `spec/openfactura/...` (mismo path). FactoryBot está configurado; fixtures en `spec/fixtures/`.
- Para stubs HTTP usar WebMock contra `https://dev-api.haulmer.com`.
- Lint: RuboCop (rubocop-shopify). Ruby >= 3.3. Dependencias runtime: httparty, dry-configurable, zeitwerk.

## Checklist: agregar un endpoint nuevo

1. **Leer el contrato** en `openfactura-api/references/` (y la normativa en `sii-dte-formato` si toca campos de documento).
2. Decidir el módulo DSL: documentos → `dsl/documents.rb`; organización → `dsl/organizations.rb`; si es un dominio nuevo (p. ej. registros RCV), crear `dsl/<dominio>.rb` + accessor memoizado en `lib/openfactura.rb` (`def registries; @registries ||= DSL::Registries.new(client); end`) y limpiarlo en `reset!`.
3. Firma del método: keyword args en inglés, validación temprana con `ArgumentError` para argumentos y `ValidationError` para datos.
4. Si la respuesta es estructurada, crear clase en `resources/` (recuerda: namespace colapsado → `Openfactura::MiClase`) con `attr_accessor`, constructor tolerante a claves string/símbolo y `to_h`.
5. Si el request lleva estructura de documento nueva, crear clase DSL siguiendo el patrón (REQUIRED_FIELDS / to_api_hash / auto-conversión de hashes).
6. Manejo de errores: apoyarse en `Client#handle_response`; solo agregar rescate específico si el endpoint tiene formato de error propio (como OF-xx en emisión).
7. Specs: unitario con WebMock (casos éxito + errores API) y, si aplica, escenario en `spec/integration/` contra sandbox.
8. Documentar: README (sección de uso + glosario) y CHANGELOG.md.
9. Si la API cambió (campo/endpoint nuevo), actualizar también la referencia correspondiente en `.claude/skills/openfactura-api/references/` — es la fuente de verdad local (ver skill `api-sync` para regenerarla desde la doc oficial).
