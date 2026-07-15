# Plantilla oficial de release notes (Emeral · openfactura-ruby)

Estructura exacta del body. Omite las secciones que queden vacías.

```markdown
## Release Notes vX.Y.Z

### Resumen
<Párrafo corto en español. Destaca en **negrita** los 3-5 temas principales de la versión. Menciona áreas afectadas, no listes items individuales.>

### Compatibilidad
<Solo si hay breaking changes. Qué rompe y cómo migrar, con el antes/después mínimo en un bloque de código. Si es compatible hacia atrás, omite la sección entera.>

---

## 1) Features y mejoras funcionales

- **<Título conciso del cambio>**
  <Una o dos frases sobre el valor para quien consume el gem. Empieza con verbo en tercera persona: "Agrega…", "Permite…", "Soporta…".>
  PR: [#NNN](url) <!-- o PRs: [#NNN](url), [#NNN](url) si son varios -->

---

## 2) Fixes

- <Descripción del fix, sin negrita en el título.>
  PR: [#NNN](url)

---

## 3) Refactors y performance

- **<Título del refactor>**
  <Descripción del cambio técnico y su motivación.>
  PR: [#NNN](url)

---

## 4) Documentación y base de conocimiento

- **<Título>**
  <Descripción. Incluye README, CHANGELOG y los skills de .claude/skills/ (openfactura-api, sii-dte-formato).>
  PR: [#NNN](url)

---

## 5) Dependencias y mantenimiento (chore)

### Dependencias runtime
- `<gem>` X.Y.Z → A.B.C ([#NNN](url))

### Dependencias dev
- `<gem>` X.Y.Z → A.B.C ([#NNN](url))

---

## Instalación

```ruby
gem "openfactura", "~> X.Y.Z"
```

## Changelog completo
- [Compare vPrev...vX.Y.Z](https://github.com/EmeralHQ/openfactura-ruby/compare/vPrev...vX.Y.Z)
```

## Reglas de formato

- Todo en **español**. Sin emojis en ninguna parte del body.
- Features/refactors: título en **negrita**, descripción en la línea siguiente con 2 espacios de indentación.
- Fixes menores (sin impacto significativo): sin negrita, solo texto directo.
- Dependencias: formato inline `` `gem` vOld → vNew ([#NNN](url)) ``.
- Omite secciones vacías por completo (si no hay deps dev, elimina esa sub-sección).
- Siempre incluye el compare link en el footer. En el primer release no hay `vPrev`: enlaza a
  `/releases/tag/vX.Y.Z` y omite el compare.
- El `### Resumen` va redactado, no en lista — máximo 3-4 líneas.
- PRs sin link disponible: lístalos como `#NNN` sin hipervínculo.
- **Nombres en inglés**: los identificadores públicos del gem (`Dte`, `Totals`, `total_amount`) van en
  inglés como en el código, aunque el texto sea español. No los traduzcas ni uses la clave SII de la API
  (`MntTotal`) salvo que el item sea justamente sobre el mapeo.

## Clasificación de cambios

| Sección | Tipos de PR/commit | Origen en CHANGELOG.md |
|---------|-------------------|------------------------|
| **1) Features y mejoras funcionales** | `feat`, `feature`, `add` | `### Added` |
| **2) Fixes** | `fix` | `### Fixed` |
| **3) Refactors y performance** | `refactor`, `perf` | `### Changed` |
| **4) Documentación y base de conocimiento** | `docs` | `### Changed` / `### Added` |
| **5) Dependencias y mantenimiento** | `chore(deps)`, `chore` no-deps | `### Changed` |

Un `### Removed` o `### Deprecated` del changelog es siempre **Compatibilidad** en el resumen, además de
su sección por tipo.

Omite cambios triviales (typos, whitespace) que no aportan valor al lector. Ante ambigüedad, prefiere la
sección más visible (Features > Fixes > Refactors).
