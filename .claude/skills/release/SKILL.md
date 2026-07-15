---
name: release
description: Publica una versión del gem openfactura - bump de version.rb, cierre de la sección Unreleased del CHANGELOG, tag, GitHub release y publicación a RubyGems. No corta la rama release/* (eso es branch-strategy).
when_to_use: Cuando el usuario dice "release vX.Y.Z", "publica la versión", "saca una versión nueva", "release notes", "notas de la versión", o pide bumpear la versión del gem.
argument-hint: "[tag, ej. 'v0.2.0' — existente para mejorar sus notas, nuevo o vacío para preparar el release]"
model: opus
effort: medium
allowed-tools: Bash(git describe *) Bash(git log *) Bash(git status *) Bash(git diff *) Bash(gh pr list *) Bash(gh release view *) Bash(gh release list *) Bash(gh --version)
---

# Release (Emeral · openfactura-ruby)

Publica una versión del gem. En Emeral-next esto son dos skills (`release` redacta las notas en GitHub,
`changelog` sincroniza `CHANGELOG.md` desde ellas). **Acá es una sola, y el flujo va al revés**: el
`CHANGELOG.md` de este gem se escribe a mano durante el desarrollo (Keep a Changelog, regla de CLAUDE.md),
así que es la **fuente** de las notas, no su derivado. Un skill que sincronizara el changelog desde los
releases pelearía con esa regla — un solo camino por operación.

**Repo:** `EmeralHQ/openfactura-ruby` · **RubyGems:** `openfactura`

La estructura de las notas vive en [template.md](template.md) — **léelo antes de redactar**.

## Prerequisitos

`gh --version`. Si falta, sugiere instalarlo y detente.

## Modo

Según `$ARGUMENTS`:

- **Tag existente** (`gh release view <tag>` responde) → flujo *Mejorar notas*.
- **Tag nuevo o vacío** → flujo *Nuevo release*.

---

## Flujo: nuevo release

### 1. Determinar versión y rango

```bash
git describe --tags --abbrev=0 2>/dev/null || echo "sin tags — primer release"
git log <last_tag>..origin/main --oneline --no-merges    # o todo el historial si no hay tags
gh pr list --state merged --base main --limit 50 --json number,title,url,mergedAt
```

Lee la sección `## [Unreleased]` del `CHANGELOG.md` — es el inventario real de lo que va en el release.
Si el `git log` tiene cambios de usuario que **no** están en `Unreleased`, dilo: falta changelog, y es
más probable que el hueco esté ahí a que el commit no importe.

Propón el número de versión según SemVer y **pregunta antes de continuar** si el usuario no lo indicó.
El gem está en `0.x`: un breaking change es **minor** (`0.1.0` → `0.2.0`), no major. Ver la tabla de
[docs/BRANCHING_STRATEGY.md](../../../docs/BRANCHING_STRATEGY.md).

### 2. Preparar la rama

La rama `release/vX.Y.Z` la corta la skill `branch-strategy` (desde `origin/main`). En ella van **solo**:

1. `lib/openfactura/version.rb` → `VERSION = "X.Y.Z"`
2. `CHANGELOG.md` → renombrar `## [Unreleased]` a `## [X.Y.Z] - YYYY-MM-DD` (fecha real, UTC) y dejar
   una `## [Unreleased]` nueva y vacía arriba. Conserva el header de Keep a Changelog tal cual.

`Gemfile.lock` fija la versión del propio gem: si `bundle exec rspec` o `bundle install` lo actualiza,
inclúyelo en el mismo commit. Es esperado, no ruido.

PR con base `main`, título `chore(release): vX.Y.Z`, y squash merge → skill `branch-strategy`.

### 3. Redactar las notas

Lee [template.md](template.md) y clasifica según su tabla, tomando los items de la sección del
`CHANGELOG.md` que acabas de cerrar y enriqueciéndolos con los PRs del rango. Muestra el markdown
generado en la respuesta antes de publicar.

### 4. Publicar

Solo **después** de que el PR del release esté mergeado en `main`. Por defecto crea **draft** y entrega
la URL para que el usuario revise:

```bash
gh release create vX.Y.Z \
  --title "vX.Y.Z" \
  --draft \
  --target main \
  --notes "$(cat <<'EONOTES'
<body generado>
EONOTES
)"
```

Quita `--draft` solo si el usuario pide publicar directo. El tag lo crea `gh release create` sobre `main`.

### 5. Publicar a RubyGems

**Esto no lo corres tú.** Entrégalo como el paso final para el usuario:

```bash
git checkout main && git pull
bundle exec rake release
```

`rake release` construye el gem, crea/pushea el tag y publica a RubyGems. Requiere credenciales y
**MFA** (`rubygems_mfa_required` está activo en el gemspec), así que es interactivo por diseño.

Adviértelo explícitamente: **publicar a RubyGems es irreversible**. Una versión publicada no se borra;
`gem yank` la esconde pero rompe los `Gemfile.lock` que ya la fijaron. El rollback real es publicar un
patch nuevo. Verifica el número de versión antes de correrlo.

Si `rake release` ya creó el tag, `gh release create` sobre un tag existente falla — en ese caso usa
`gh release create vX.Y.Z --verify-tag` o publica el release primero, como arriba.

---

## Flujo: mejorar notas de un release existente

1. Descarga el actual: `gh release view <tag> --json body,tagName,publishedAt,isDraft`
2. Compáralo contra [template.md](template.md) y corrige: reformatea al estilo oficial, agrega PR links
   faltantes (búscalos en `git log` / `gh pr list`), enriquece descripciones vagas con contexto técnico
   real, reagrupa items mal clasificados, completa el `### Resumen` si falta.
3. Muestra un diff resumido de lo que cambia. **Si el release ya está publicado (no draft), pide confirmación.**

```bash
gh release edit <tag> --notes "$(cat <<'EONOTES'
<body mejorado>
EONOTES
)"
```

Mejorar las notas **no** toca `CHANGELOG.md`: el changelog es la fuente. Si las notas quedaron mejor que
el changelog, propón el cambio al `CHANGELOG.md` como un PR `docs/*` aparte.
