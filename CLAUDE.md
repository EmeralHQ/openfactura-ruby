# openfactura-ruby

SDK Ruby con DSL en inglés para la API OpenFactura (Haulmer) de facturación electrónica chilena. Foco principal: emisión de DTEs, consulta de documentos y datos de organización. Ruby >= 3.1.

## Comandos

- Tests unitarios: `bundle exec rspec` (WebMock bloquea red)
- Tests de integración (sandbox real): specs con tag `:integration` en `spec/integration/`
- Lint: `bundle exec rubocop`
- Instalar local: `bundle exec rake install`

## Skills del proyecto (usarlos — son la fuente de verdad)

- **openfactura-gem-dev**: arquitectura, convenciones DSL, mapeo campos inglés↔API, matriz de cobertura y checklist para agregar endpoints. Cargar antes de tocar `lib/`.
- **openfactura-api**: referencia completa de la API (scraping de la doc oficial). Cargar antes de implementar/depurar cualquier llamada a la API.
- **sii-dte-formato**: normativa SII de formato DTE y boletas. Cargar al modelar campos de documentos.
- **api-sync**: procedimiento para re-scrapear la doc oficial y actualizar la base de conocimiento.

## Convenciones esenciales

- Código y API pública del gem en inglés; claves JSON de la API en español SII solo dentro de `to_api_hash` y specs.
- Clases DSL: patrón `REQUIRED_FIELDS` + `validate_required_fields!` (lanza `Openfactura::ValidationError` al convertir) + `to_api_hash` + auto-conversión de hashes a objetos.
- Zeitwerk con `resources/` colapsado: las clases de respuesta viven en `Openfactura::` directamente (no `Openfactura::Resources::`).
- Al agregar campos/endpoints: actualizar README (uso + glosario English↔Spanish), CHANGELOG.md y la referencia correspondiente en `.claude/skills/openfactura-api/references/`.
