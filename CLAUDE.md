# CLAUDE.md

Guía para Claude Code trabajando en este repositorio.

## Project Overview

SDK Ruby con DSL en inglés para la API OpenFactura (Haulmer) de facturación electrónica chilena. Foco
principal: emisión de DTEs, consulta de documentos y datos de organización. Ruby >= 3.3.

Consumidor típico: una app Rails que emite facturas (tipo 33) y consulta su estado/PDF/XML —
`EmeralHQ/Emeral-next` lo usa en `Billings::`. **Es un gem público en RubyGems**: la API pública tiene
consumidores fuera de nuestro control y romperla cuesta un release.

## Comandos

- Tests unitarios: `bundle exec rspec` (WebMock bloquea red)
- Un archivo / un ejemplo: `bundle exec rspec spec/path/to/file_spec.rb` · `...:42`
- Tests de integración (sandbox real): `RUN_INTEGRATION=1 bundle exec rspec spec/integration` — fuera
  de la suite por defecto (`spec_helper` los excluye), requieren credenciales
- Lint: `bundle exec rubocop` (`-a` para autocorregir)
- Build del gem: `bundle exec rake build`
- Instalar local: `bundle exec rake install`
- Publicar: `bundle exec rake release` — **irreversible**, ver skill `release`

Los tres que corre la CI en cada PR son `rspec`, `rubocop` y `rake build`. Si pasan localmente, el PR
sale verde.

## Skills del proyecto (usarlos — son la fuente de verdad)

### Dominio

- **openfactura-gem-dev**: arquitectura, convenciones DSL, mapeo campos inglés↔API, matriz de cobertura y checklist para agregar endpoints. Cargar antes de tocar `lib/`.
- **openfactura-api**: referencia completa de la API (scraping de la doc oficial). Cargar antes de implementar/depurar cualquier llamada a la API.
- **sii-dte-formato**: normativa SII de formato DTE y boletas. Cargar al modelar campos de documentos.
- **api-sync**: procedimiento para re-scrapear la doc oficial y actualizar la base de conocimiento.

### Flujo de trabajo (compartidas con Emeral-next)

- **branch-strategy**: ramas, bases y PRs. **Única vía para abrir un PR.**
- **release**: bump de versión, cierre del changelog, tag, GitHub release y publicación a RubyGems.
- **commit**: Conventional Commits en español sobre lo que ya está en stage.

Ver [.claude/README.md](.claude/README.md) para los criterios de diseño de la configuración.

## Convenciones esenciales

- Código y API pública del gem en inglés; claves JSON de la API en español SII solo dentro de `to_api_hash` y specs.
- Clases DSL: patrón `REQUIRED_FIELDS` + `validate_required_fields!` (lanza `Openfactura::ValidationError` al convertir) + `to_api_hash` + auto-conversión de hashes a objetos.
- Zeitwerk con `resources/` colapsado: las clases de respuesta viven en `Openfactura::` directamente (no `Openfactura::Resources::`).
- Comillas dobles (`Style/StringLiterals`), `snake_case` para métodos y archivos, `CamelCase` para clases.
- Constantes en ALL_CAPS; sin números mágicos (los códigos SII van a una constante con nombre).
- Al agregar campos/endpoints: actualizar README (uso + glosario English↔Spanish), CHANGELOG.md y la referencia correspondiente en `.claude/skills/openfactura-api/references/`.

## Ramas y versionado

Trunk-based: **`main` es la única rama de larga vida** y la base de todo PR. No hay `develop` ni
`hotfix/*` — a diferencia de Emeral-next, este repo no tiene staging ni deploy. Detalle completo en
[docs/BRANCHING_STRATEGY.md](docs/BRANCHING_STRATEGY.md); ejecútalo con la skill `branch-strategy`.

El gem está en `0.x`: un breaking change es **minor**, no major. Desde `1.0.0`, SemVer estricto.

## Testing

- RSpec + WebMock (la red está bloqueada en los unitarios: toda llamada HTTP va mockeada).
- FactoryBot para datos de prueba; factories en `spec/factories/`.
- Todo campo o endpoint nuevo llega con specs: el happy path del `to_api_hash` **y** el
  `ValidationError` cuando falta un `REQUIRED_FIELDS`.
- **Cobertura (SimpleCov):** `bundle exec rspec` genera el reporte en `coverage/` (ignorado por git).
  El piso es **97% de líneas** y la CI lo hace fallar si baja (gate solo en CI: una corrida de un
  archivo suelto no bloquea localmente). Código nuevo llega con los tests que mantengan el piso; se
  sube cuando la cobertura mejora, no se baja. El único código sin cubrir es glue de Rails (Railtie) y
  ramas defensivas inalcanzables.
- Los specs son el único lugar (junto a `to_api_hash`) donde aparecen claves en español SII —
  ahí es correcto y esperado: verifican el contrato real con la API.
- Los `:integration` pegan al sandbox real y necesitan credenciales: `spec_helper` los excluye de la
  suite por defecto (opt-in con `RUN_INTEGRATION=1` o `--tag integration`). No los uses para verificar
  un cambio a menos que el usuario lo pida.
- La suite corre en Ruby 3.3–3.5 en CI: el gemspec promete `>= 3.3.0`. Por eso `Gemfile.lock` **no** se
  versiona — fijarlo arrastra a todos los Ruby a una resolución que solo sirve en el más nuevo.

## AI Behavior Rules

### Calidad de código

- **Match existing style** — sigue los patrones que ya están en el repo; una clase DSL nueva se parece a las que existen.
- **No over-engineering** — solo lo que se pide; nada de validaciones o abstracciones extra.
- **La doc oficial manda** — nombres de campos, largos y obligatoriedad salen de las skills
  `openfactura-api` / `sii-dte-formato`, no de la intuición. Si la doc no lo dice, dilo en vez de asumir.

### RuboCop (style gate)

- Corre `bundle exec rubocop <path>` una vez al final de la tarea. Arregla todas las ofensas antes de terminar.
- `bundle exec rubocop -a <path>` para las autocorregibles de Layout/Style. **No uses `-A`** sin mirar
  qué toca: las unsafe cambian comportamiento (ver el `disable` de `Style/MapJoin` en `error.rb`).
- Guía de estilos de Ruby de Shopify (`rubocop-shopify`), cargada con `inherit_gem`. Su `rubocop.yml`
  ya declara el `plugins:`, así que acá no va ni `require:` ni `plugins:`.
- Shopify pide **sin** espacio dentro de los brackets de array (`["TOKEN"]`) y `class << self` en vez de
  `def self.x`. Desactiva todo `Metrics/*` y `Style/Documentation`: no los reconfigures acá.
- `NewCops` queda en `disable` (lo hereda de Shopify, que triajea los cops nuevos). No lo actives.
- Única desviación deliberada de la guía: `Style/StringLiterals` va reactivado en `double_quotes`,
  porque las comillas dobles son convención del proyecto y Shopify deja el cop apagado.
- El piso del gem (`>= 3.3`) coincide con el que exige `rubocop-shopify` 3.0, así que el `Gemfile`
  instala el linter sin guardas de versión. Si algún día se sube el piso, el linter lo acompaña solo.
- Las dev dependencies viven en el `Gemfile`, no en el gemspec (`Gemspec/DevelopmentDependencies`).

### Compatibilidad (lo crítico acá)

Un gem no se puede rollbackear: una versión publicada en RubyGems no se borra. Antes de cambiar algo ya
publicado, asume que alguien lo llama.

- **Breaking** es renombrar o quitar un método público, clase DSL, campo o clase de error; cambiar un
  default; o cambiar el JSON que produce `to_api_hash` (aunque el cambio sea interno, el receptor es el SII).
- Prefiere **agregar** sobre cambiar: campo nuevo opcional > renombrar el existente.
- Si un cambio rompe la API pública, dilo explícitamente y refléjalo en el CHANGELOG y en el PR
  (bloque "Impacto en la API pública" de la plantilla) — no lo dejes pasar en silencio.

### Datos sensibles

- La API key es un secreto por contribuyente: nunca la loguees, ni la pongas en un spec, un fixture o
  un mensaje de error. En specs va un valor dummy.
- Los DTEs llevan RUTs y montos reales: no pegues respuestas reales del sandbox en el repo ni en un issue.
