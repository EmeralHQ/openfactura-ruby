---
name: branch-strategy
description: Aplica la estrategia de ramas del proyecto (docs/BRANCHING_STRATEGY.md) y es la única vía para abrir PRs. Enruta feature/fix/docs/chore/release hacia la rama, base y plantilla de PR correctas.
when_to_use: Al abrir cualquier PR. También cuando el usuario dice "crea una rama", "empiezo una feature/fix", "corta el release vX.Y.Z", "hay que arreglar esto en producción", o pregunta desde qué base ramificar o hacia dónde apunta un PR.
argument-hint: "[operación, ej. 'feature boletas-39-41' | 'fix tasa-iva' | 'release v0.2.0']"
model: opus
effort: high
allowed-tools: Bash(git fetch *) Bash(git log *) Bash(git status *) Bash(git branch *) Bash(git diff *) Bash(gh pr view *) Bash(gh pr list *) Bash(gh --version)
---

# Branch Strategy (Emeral · openfactura-ruby)

Operacionaliza la estrategia de ramas del gem **y es la única vía para abrir PRs**: elegir la base y
rellenar la plantilla es parte de la estrategia, no un paso aparte.

**Fuente de verdad:** [docs/BRANCHING_STRATEGY.md](../../../docs/BRANCHING_STRATEGY.md) — ante cualquier
duda de flujo o rationale, reléela; esta skill no la reemplaza, la ejecuta.

**Repo:** `EmeralHQ/openfactura-ruby`

**Arguments:** `$ARGUMENTS` — describe la operación. Ejemplos: `feature boletas-39-41`, `fix tasa-iva`,
`release v0.2.0`, o vacío (infiere desde la rama/estado actual).

## 0. Prerequisitos

Verificar `gh`: `gh --version`. Si falta, sugerir instalar (`sudo apt install gh` / `brew install gh`) y parar.

```bash
git fetch origin main 2>&1 | tail -1
```

## Reglas núcleo (siempre)

- **`main` es la única rama de larga vida** y la base de **todo** PR. Este gem **no** tiene `develop`,
  ni `release/*` de larga vida, ni back-merge — no los inventes por analogía con Emeral-next.
- Toda rama de trabajo nace de `origin/main`, nunca de otra rama de trabajo.
- PRs pequeños, con tests, título `type(scope): descripción en español`, **squash merge**.
- **No** usar `cherry-pick` como proceso por defecto.
- Mergear a `main` **no publica nada**. Publicar es un tag + `rake release` — eso es la skill `release`.

## 1. Identificar la operación y enrutar

| Intención | Rama nueva desde | Base del PR | Sección |
|-----------|------------------|-------------|---------|
| Feature (endpoint, clase DSL, campo) | `origin/main` → `feature/<user>/<slug>` | `main` | §2 |
| Fix de bug (incluye "hotfix") | `origin/main` → `fix/<user>/<slug>` | `main` | §2 |
| Docs / skills / tooling | `origin/main` → `docs/<slug>` o `chore/<slug>` | `main` | §2 |
| Release | `origin/main` → `release/vX.Y.Z` | `main` | §3 |

`<user>` = handle git del autor (`git config user.name` / `gh api user --jq .login`).

**Un "hotfix" aquí es un `fix/*` normal.** No hay rama `hotfix/*` ni back-merge: `main` es la única rama
de larga vida, así que no existe la divergencia que el back-merge de Emeral-next resuelve. Lo que sí
cambia es la urgencia del release de patch posterior — dilo, no cambies la rama.

## 2. Feature / fix / docs → main

```bash
git checkout -b feature/<user>/<slug> origin/main   # o fix/<user>/<slug>, docs/<slug>, chore/<slug>
# ...trabajo, commits...
git push -u origin <rama>
```

Antes de abrir el PR, corre localmente lo mismo que exige la CI (no las pre-apruebo, pídelas si hace
falta): `bundle exec rspec`, `bundle exec rubocop` y `bundle exec rake build`. Si algo falla, arréglalo
o dilo — no abras el PR en rojo.

`main` está protegida: sin los checks verdes el PR no se puede mergear, y el merge es squash-only. No
intentes saltarte la protección (`--admin`, push directo) ni desactivarla; si un check está roto o
sobra, eso se discute, no se rodea.

Crear PR con base `main` → §4.

## 3. Release → main

Esta skill **solo corta la rama y abre el PR**. El contenido (bump de versión, cierre del changelog,
notas, tag, publicación) es de la skill `release` — invócala para eso.

```bash
git checkout -b release/vX.Y.Z origin/main
```

1. La rama lleva **solo** el bump de `lib/openfactura/version.rb` y el cierre de `## [Unreleased]` en
   `CHANGELOG.md`. Sin scope creep: un bug que aparezca va en su propio `fix/*` a `main` **antes** del release.
2. PR con base `main`, título `chore(release): vX.Y.Z` → §4.
3. Tras el squash merge: tag `vX.Y.Z`, GitHub release y `rake release` → skill `release`.

Confirma el número de versión contra SemVer (ver la tabla de docs/BRANCHING_STRATEGY.md). El gem está
en `0.x`: un breaking change es **minor**, no major. Si el rango de commits contiene un breaking change
y el usuario pidió un patch, dilo antes de cortar la rama.

## 4. Crear el PR (helper común)

1. Verifica que la rama tenga commits por delante de `origin/main`; si no, avisa y para.
   ```bash
   git log origin/main..HEAD --oneline --no-merges
   git diff origin/main...HEAD --stat
   ```
2. `git push -u origin <head>` si falta.
3. Lee `.github/PULL_REQUEST_TEMPLATE.md` y rellena **cada** sección con datos reales del diff. No inventes
   ni omitas secciones. Marca el "Tipo de cambio" correcto y resuelve honestamente el bloque
   **Impacto en la API pública** — si el diff toca firmas de métodos públicos, nombres de campos DSL,
   clases de error o el JSON que produce `to_api_hash`, es breaking (ver docs/BRANCHING_STRATEGY.md).
4. Crear (body inline por heredoc, nunca a archivo):
   ```bash
   gh pr create \
     --repo EmeralHQ/openfactura-ruby \
     --base main \
     --head <head> \
     --title "type(scope): descripción en español" \
     --body "$(cat <<'EOBODY'
   <body rellenado desde la plantilla>
   EOBODY
   )"
   ```
5. Imprime la URL del PR.

## Notas

- No dupliques la estrategia en el body; ante dudas de flujo relee `docs/BRANCHING_STRATEGY.md`.
- El checklist de la plantilla incluye README, `CHANGELOG.md` (`## [Unreleased]`) y las referencias de
  `.claude/skills/openfactura-api/references/` — es la regla de CLAUDE.md. Verifica el diff antes de
  marcarlos; si falta alguno, dilo en vez de marcar la casilla.
