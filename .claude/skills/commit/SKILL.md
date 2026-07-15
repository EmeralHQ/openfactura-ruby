---
name: commit
description: Commitea los cambios que ya están en stage con formato Conventional Commits en español y los scopes de este gem. Nunca hace `git add` ni crea ramas ni PRs (para eso, branch-strategy).
when_to_use: Cuando el usuario dice "commitea", "haz commit", "guarda los cambios", "registra esto", o pide redactar un mensaje de commit para lo que ya está en stage.
argument-hint: "[pista para el mensaje, ej. 'closes #42']"
model: haiku
effort: low
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git commit *) Bash(bundle exec rubocop *)
---

# Commit (Emeral · openfactura-ruby)

Commitea **solo** lo que ya está en stage. **No** ejecutes `git add`.

Si no hay nada en stage, dilo y detente.

`$ARGUMENTS` es una pista opcional para el mensaje — úsala como contexto, no literal.

## Flujo

1. `git status` y `git diff --staged` (en paralelo).
2. `bundle exec rubocop --format simple <archivos_ruby_staged>` — reporta ofensas, no bloquea el commit.
3. Redacta el mensaje (formato abajo).
4. Commitea con heredoc para preservar el formato:

```bash
git commit -m "$(cat <<'EOF'
<subject>

<body>
EOF
)"
```

## Formato

- **Idioma:** español, modo imperativo.
- **Subject:** `<type>[scope]: <descripción>` — máx. 72 chars.
- **Types:** `feat` `fix` `docs` `style` `refactor` `test` `chore` `perf` `ci` `revert`
- **Scopes:** `dte` `client` `resources` `errors` `config` `rails` `docs` `spec` `skills`

  Los scopes siguen la estructura de `lib/openfactura/`: `dte` para las clases DSL del documento
  (`Dte`, `Receiver`, `DteItem`, `Totals`, `Issuer`), `client` para el HTTP client y los endpoints,
  `resources` para las clases de respuesta, `rails` para Railtie y generadores, `skills` para
  `.claude/skills/`.
- **Body:** 1–6 bullets `- <acción>: <qué cambió>`, derivados del diff. Omítelo si el cambio es trivial (1–2 archivos, propósito único).

```
feat(dte): agrega soporte para boletas electrónicas 39 y 41

- agrega los tipos 39 y 41 a DTE_TYPES con su validación
- mapea el bloque Totals específico de boleta en to_api_hash
```

## Notas

- Si hay cambios no relacionados en el mismo stage, sugiere separarlos en commits distintos.
- Issues: `closes #123` como footer cuando aplique.
- Breaking changes: `BREAKING CHANGE: <descripción>` como footer. En un gem público esto **obliga** a un bump minor
  mientras la versión sea 0.x, o major desde 1.0 (SemVer) — dilo en el body si el commit rompe la API pública.
- Recordatorio del proyecto (CLAUDE.md): si el cambio agrega campos o endpoints, el commit debería incluir
  también README, `CHANGELOG.md` (sección `## [Unreleased]`) y la referencia en `.claude/skills/openfactura-api/references/`.
  Si falta alguno, avísalo — no lo agregues tú (no haces `git add`).
