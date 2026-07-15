# Claude Code — openfactura-ruby (Emeral)

Configuración de Claude Code para este proyecto. Este archivo es **documentación**: vive fuera de
`skills/` justamente para no ser invocable.

Los criterios de diseño son los mismos que en
[Emeral-next](https://github.com/EmeralHQ/Emeral-next/blob/develop/.claude/README.md) — este repo es la
adaptación de esa configuración a un gem. Lo que difiere está marcado abajo con el motivo.

## Skills disponibles

Cada una se activa sola cuando su `description` calza con lo que pides. También puedes forzarla
escribiendo `/<nombre>`.

### Compartidas con Emeral-next (flujo de trabajo)

| Skill | Para qué | model | effort |
|-------|----------|-------|--------|
| `branch-strategy` | Enruta feature/fix/docs/release a la rama y base correctas. **Única vía para abrir PRs.** | `opus` | `high` |
| `release` | Publica una versión: bump, changelog, tag, GitHub release y `rake release` a RubyGems. | `opus` | `medium` |
| `commit` | Commitea lo que ya está en stage con Conventional Commits en español. | `haiku` | `low` |

### Propias de este gem (dominio)

| Skill | Para qué |
|-------|----------|
| `openfactura-gem-dev` | Arquitectura, convenciones DSL, matriz de cobertura API↔gem, checklist para agregar endpoints. |
| `openfactura-api` | Referencia completa de la API OpenFactura (scraping de la doc oficial). |
| `sii-dte-formato` | Normativa SII de formato DTE y boletas. |
| `api-sync` | Re-scrapea la doc oficial y actualiza la base de conocimiento. |

Las de dominio no declaran `model`/`effort`: son bases de conocimiento que se cargan como contexto del
trabajo en curso, no operaciones con un radio de daño propio. Fijarles un modelo sería peor —
el override aplica **al resto del turno** (ver abajo), y estas se cargan justo al empezar uno largo.

## Estructura

```
.claude/
├── README.md              # este archivo (no invocable)
├── skills/                # versionadas: compartidas con el equipo
│   ├── branch-strategy/SKILL.md
│   ├── commit/SKILL.md
│   ├── release/
│   │   ├── SKILL.md       # el flujo
│   │   └── template.md    # la plantilla, se carga solo al redactar
│   ├── openfactura-gem-dev/SKILL.md
│   ├── openfactura-api/
│   │   ├── SKILL.md
│   │   └── references/    # 4 refs, se cargan bajo demanda
│   ├── sii-dte-formato/
│   │   ├── SKILL.md
│   │   └── references/
│   └── api-sync/SKILL.md
├── settings.local.json    # permisos y overrides personales (ignorada)
└── worktrees/             # worktrees locales (ignorada)
```

## Diferencias con Emeral-next (y por qué)

**No hay skill `changelog`.** En Emeral-next el `CHANGELOG.md` se *deriva* de los GitHub Releases, y
`changelog` sincroniza en esa dirección. Acá el flujo va al revés: el changelog se escribe a mano
durante el desarrollo (Keep a Changelog, es regla de CLAUDE.md) y es la **fuente** de las notas del
release. Un skill que sincronizara al revés pelearía con esa regla, así que el cierre de la sección
`Unreleased` vive dentro de `release`. Un solo camino por operación.

**No hay skill `rollbar-issue`.** Es un gem: no hay producción, ni Rollbar, ni excepciones que
triagear. Los bugs llegan por issues de quien consume el gem.

**`branch-strategy` es trunk-based.** No hay `develop`, ni `release/*` de larga vida, ni back-merge:
`main` es la única rama de larga vida y es la base de todo PR. Un gem no tiene staging ni deploy — lo
que se "despliega" es una versión publicada en RubyGems, y eso lo marca un tag, no un merge. Un hotfix
es un `fix/*` normal + release de patch. Ver [docs/BRANCHING_STRATEGY.md](../docs/BRANCHING_STRATEGY.md).

**No hay `settings.json` versionado.** El de Emeral-next existe casi solo por el `deny` de `.cursor/`
(dos fuentes de verdad) y la config del MCP de Postgres. Este repo no tiene `.cursor/` ni servicios, así
que no hay nada que el equipo necesite compartir a la fuerza: `settings.local.json` sigue siendo personal.
Si algún día entra un `.cursor/` acá, hay que traerse el `deny` — debe aplicar a todos, y `deny` gana
sobre `allow` y no se puede sobrescribir desde la config personal.

**Una sola plantilla de PR.** Emeral-next tiene tres (`feature_fix_to_develop`, `release_to_main`,
`hotfix_to_main`) porque tiene tres destinos. Acá todo va a `main`, así que
`.github/PULL_REQUEST_TEMPLATE.md` es única y GitHub la carga sola.

## Criterios de diseño (compartidos)

**CLAUDE.md es la SSOT de las convenciones del proyecto.** Las skills la referencian, no la duplican.
Si una regla del DSL o del mapeo inglés↔SII aparece en una skill de flujo, está en el lugar equivocado.
El matiz de este repo: las skills de dominio (`openfactura-api`, `sii-dte-formato`) **sí** son fuente de
verdad de su material, porque son la doc externa scrapeada, no convenciones nuestras. CLAUDE.md apunta a
ellas; no las resume.

**El `description` es el contrato de activación.** El uso real es por prompt, no tecleando `/comando`:
el modelo elige según la descripción. Por eso cada una declara cuándo activarse *y cuándo no*
(`release` aclara que no corta la rama; `commit` que no crea PRs). Descripciones vagas → skill que nunca
se activa o que se activa de más.

**No duplicar los builtins.** `/code-review` y `/security-review` ya vienen con Claude Code y cubren la
revisión de diffs; las reglas del gem que necesitan ya están en CLAUDE.md, que se carga siempre. Por eso
no hay skill de review propia.

**Un solo camino por operación.** Abrir un PR es responsabilidad exclusiva de `branch-strategy`, porque
elegir la base correcta *es* la estrategia de ramas. Una skill de PR separada inevitablemente diverge del
doc y termina apuntando a la base equivocada.

**Progressive disclosure.** Los archivos de apoyo (`release/template.md`, los `references/` de las skills
de dominio) solo se cargan cuando la skill los referencia. Si un `SKILL.md` crece con material que no se
usa siempre, sepáralo.

**`model` y `effort` se asignan por radio de daño, no por dificultad.** No existe una tabla oficial de
Anthropic para esto; el criterio es nuestro. `commit` corre en casi todos los turnos y un mensaje mediocre
se arregla con `--amend`, así que va en `haiku`/`low` — ahí está el ahorro real. `branch-strategy` corre
poco y equivocarse manda un breaking change a un release de patch, así que va en `opus`/`high`. `release`
produce contenido público, corre pocas veces y termina en una publicación **irreversible** a RubyGems: el
costo es irrelevante frente a la calidad visible.

Dos detalles de la [doc oficial](https://code.claude.com/docs/en/skills) que conviene tener presentes al
editarlos:

- El override **aplica al resto del turno**, no solo a la ejecución de la skill, y se revierte en tu
  siguiente prompt. Por eso `commit` en `haiku` es seguro (suele ser el último paso de un turno) pero no
  pondríamos `haiku` en una skill que se invoca a mitad de un trabajo largo.
- `allowed-tools` **pre-aprueba, no restringe**: reduce prompts de permiso, pero toda herramienta sigue
  siendo invocable. Por eso solo pre-aprobamos lecturas y acciones locales reversibles (`git commit`).
  Nada que publique hacia afuera (`gh pr create`, `gh release create`, `git push`, `rake release`) está
  pre-aprobado a propósito: esas deben seguir pidiendo confirmación.

## Versionado

`.gitignore` versiona `skills/` y este `README.md`; deja fuera lo que es de tu máquina
(`settings.local.json`, `mcp.json`, `scheduled_tasks.lock`) y los `worktrees/`.

Agregar una skill nueva es un `git add` normal — y si no la agregas, nadie la tiene.
