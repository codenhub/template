# The pre-commit checks for Node.js and pnpm, sourced by `.githooks/pre-commit`,
# which says what each name below provides.
#
# oxfmt formats code, JSON, and the web formats; Prettier formats Markdown and
# skips anything `.prettierignore` lists; oxlint lints code. A formatter for
# another language, such as `rustfmt` for `rs`, adds its extension to
# PROFILE_EXTENSIONS, its commands to profile_fix and profile_check, and the same
# commands to the `format:fix` and `format:check` scripts in `package.json`.

PROFILE_EXTENSIONS='astro|cjs|css|cts|html|js|json|jsx|md|mjs|mts|svelte|ts|tsx'
PROFILE_FIX_HINT='Run `pnpm format:fix` and `pnpm lint:fix`'

oxfmt_extensions='astro|cjs|css|cts|html|js|json|jsx|mjs|mts|svelte|ts|tsx'
code_extensions='cjs|cts|js|jsx|mjs|mts|ts|tsx'

# oxlint exits non-zero when every file it is handed matches its ignorePatterns,
# and oxfmt does the same with its own; `--no-error-on-unmatched-pattern` turns
# that back into a pass, since committing a file the config deliberately ignores
# is not a failure.
profile_fix() {
  on_ext "$1" "$oxfmt_extensions" pnpm exec oxfmt --no-error-on-unmatched-pattern --
  on_ext "$1" md pnpm exec prettier --write --log-level warn --
  on_ext "$1" "$code_extensions" pnpm exec oxlint --fix --no-error-on-unmatched-pattern --
}

profile_check() {
  on_ext "$1" "$oxfmt_extensions" pnpm exec oxfmt --check --no-error-on-unmatched-pattern --
  on_ext "$1" md pnpm exec prettier --check --log-level warn --
  on_ext "$1" "$code_extensions" pnpm exec oxlint --deny-warnings --no-error-on-unmatched-pattern --
}
