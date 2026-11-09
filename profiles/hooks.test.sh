#!/bin/sh
# Runs the git hooks of a project created from a profile, as `.github/workflows/template.yml` and the local check
# in `profiles/README.md` do. Template-only, like the rest of `profiles/`.
#
# Run it from the root of a disposable project, after setup: it commits the working tree as it is, then commits
# and resets on top of that. The formatting cases use files `node-pnpm` formats, the only profile so far.
set -eu

cd "$(git rev-parse --show-toplevel)"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

failures=0
pass() { printf 'ok    %s\n' "$1"; }
fail() {
  printf 'FAIL  %s\n' "$1"
  if [ -s "$work/out" ]; then sed 's/^/      /' "$work/out"; fi
  failures=$((failures + 1))
}

# A fixed identity, so a runner without one can commit.
commit() {
  git -c user.name=Hooks -c user.email=hooks@example.invalid commit -q "$@" >"$work/out" 2>&1
}

git add -A
commit --no-verify --allow-empty -m "chore: create the project"
base=$(git rev-parse HEAD)
reset() {
  git reset -q --hard "$base"
  git clean -qfd
}

# Setup

if [ "$(git config core.hooksPath)" = .githooks ]; then
  pass "setup points core.hooksPath at .githooks"
else
  : >"$work/out"
  fail "setup points core.hooksPath at .githooks"
fi

# pre-commit

printf 'export const a = {b:1}\n' >fixed.ts
printf '# Title\n\n\n\nText\n' >fixed.md
git add fixed.ts fixed.md
if commit -m "test: format" &&
  [ "$(git show HEAD:fixed.ts)" = 'export const a = { b: 1 };' ] &&
  [ "$(git show HEAD:fixed.md)" = "$(printf '# Title\n\nText')" ] &&
  [ -z "$(git status --porcelain)" ]; then
  pass "pre-commit formats staged code and Markdown, and re-stages them"
else
  fail "pre-commit formats staged code and Markdown, and re-stages them"
fi
reset

printf 'console.log("left in");\n' >lint.ts
git add lint.ts
if commit -m "test: lint"; then
  fail "pre-commit refuses a lint error it cannot fix"
else
  pass "pre-commit refuses a lint error it cannot fix"
fi
reset

printf 'export const a = 1;\n' >partial.ts
git add partial.ts
commit --no-verify -m "test: add partial"
printf 'export const a = 2;\n' >partial.ts
git add partial.ts
printf 'export const a = 2;\nexport const b = {c:1}\n' >partial.ts
if commit -m "test: partial"; then
  fail "pre-commit checks a partly staged file on disk, and refuses it"
elif [ "$(git show :partial.ts)" = 'export const a = 2;' ] &&
  [ "$(cat partial.ts)" = "$(printf 'export const a = 2;\nexport const b = {c:1}')" ]; then
  pass "pre-commit checks a partly staged file on disk, and refuses it"
else
  fail "pre-commit leaves a partly staged file as it was, in the index and on disk"
fi
reset

mkdir -p 'app/[id]' app/i
printf 'export const a = 1;\n' >'app/[id]/page.ts'
printf 'export const a = 1;\n' >app/i/page.ts
git add app
commit --no-verify -m "test: add pages"
printf 'export const a = {b:1}\n' >'app/[id]/page.ts'
git add 'app/[id]/page.ts'
printf 'export const a = 2;\n' >app/i/page.ts
if commit -m "test: brackets" &&
  [ "$(git show HEAD:app/i/page.ts)" = 'export const a = 1;' ] &&
  [ "$(git diff --name-only)" = app/i/page.ts ]; then
  pass "pre-commit re-stages a bracketed path literally"
else
  fail "pre-commit re-stages a bracketed path literally"
fi
reset

printf 'export const a = {b:1}\n' >café.ts
git add café.ts
if commit -m "test: non-ascii" && [ "$(git show HEAD:café.ts)" = 'export const a = { b: 1 };' ]; then
  pass "pre-commit formats a file with a non-ASCII name"
else
  fail "pre-commit formats a file with a non-ASCII name"
fi
reset

# commit-msg, run directly on a message file

message() {
  printf '%s\n' "$2" >"$work/message"
  if ./.githooks/commit-msg "$work/message" >"$work/out" 2>&1; then
    result=accepts
  else
    result=refuses
  fi
  if [ "$result" = "$1" ]; then
    pass "commit-msg $1 '$2'"
  else
    fail "commit-msg $1 '$2'"
  fi
}

message accepts 'feat(core): add the export command'
message accepts 'fix(plugins/vite)!: rename the session option'
message accepts "Merge branch 'feat/x'"
message accepts 'fixup! feat: add x'
message refuses ''
message refuses 'Add the export command'
message refuses 'feat: Add the export command'
message refuses 'feat: add the export command.'
message refuses "feat: $(printf '%067d' 0)"

# pre-push, run directly on the refs git would hand it

sha=$(git rev-parse HEAD)
zero=0000000000000000000000000000000000000000
push() {
  if printf '%s\n' "$3" | ./.githooks/pre-push origin https://example.invalid/repo.git >"$work/out" 2>&1; then
    result=accepts
  else
    result=refuses
  fi
  if [ "$result" = "$1" ]; then
    pass "pre-push $1 $2"
  else
    fail "pre-push $1 $2"
  fi
}

push accepts "a <type>/<slug> branch" "refs/heads/x $sha refs/heads/feat/export-command $zero"
push refuses "a push to main" "refs/heads/x $sha refs/heads/main $zero"
push refuses "deleting main" "(delete) $zero refs/heads/main $sha"
push refuses "a misnamed branch" "refs/heads/x $sha refs/heads/claude/agent-03bee5 $zero"
push accepts "deleting a misnamed branch" "(delete) $zero refs/heads/claude/agent-03bee5 $sha"
push accepts "a tag" "refs/tags/v1 $sha refs/tags/v1 $zero"

if [ "$failures" -ne 0 ]; then
  printf '\n%s hook check(s) failed.\n' "$failures"
  exit 1
fi
