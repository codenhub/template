---
status: DRAFT
last_updated: 2026-11-08
scope: How the template splits into a stack-neutral core and stack profiles, and the plan for getting there.
---

# Core and profiles

The template today is a Node.js and pnpm workspace throughout: the delivery gate is `pnpm verify` in every document, the pre-commit hook calls `pnpm exec`, the hooks are installed by a Node script, and the coding and testing guidelines are written for TypeScript and Vitest. A Rust, Python, or Ruby project starting from it would rewrite most files before its first commit, and a single-package project inherits a fixed `apps/` + `packages/` layout it does not have. This document records how the template is split so the process, which is general, stops being tied to one stack.

Like [the rest of this directory](README.md), it belongs to the template repository only.

## Decisions

### A core and `profiles/<stack>/` in this repository

The template repository holds a stack-neutral core at its root and one directory per stack under `profiles/`, such as `profiles/node-pnpm/`. Creating a project copies the core, lays one profile over it, and deletes `profiles/` and `.template/`. A project compares itself with the core and the profile it started from.

Rejected: **one template repository per stack.** Each would be simpler alone, but every change to the process, the agent instructions, or the documentation guidelines would be repeated in each repository, and they would drift apart. Keeping the core in one place is the reason to split at all.

### Profile values fill the core

The core never names a stack's command; it holds a placeholder that creation fills, as it fills `{{name}}`. A profile declares a value for each: `{{setup}}`, the setup commands, and `{{verify}}`, the delivery gate. `AGENTS.md`, `CONTRIBUTING.md`, the pull request template, and the README then show the real command in a created project. Anything about the stack beyond those values, such as where versions are pinned or how the hooks are set up by hand, is in the profile's `docs/tooling.md`, a document every profile provides and the core links to.

Until the profiles exist, the values are listed with the other placeholders in [the README](README.md#creating-a-project), and this repository is filled with `node-pnpm`'s wherever it is not a placeholder.

Rejected: **pointers only,** where the core says "the gate [`CONTRIBUTING.md`](../CONTRIBUTING.md#validation) names" and never the command. Nothing is filled in, but every reader takes an extra hop to reach the command, and an agent reads a reference where it needs a command to run. The cost of the values is two more placeholders, which a comparison shows as differences on the lines that hold them, as it already shows `{{name}}`.

Rejected: **one runner command in every project,** such as `just verify` or `make verify`. Agents would get one command to call everywhere, but every project would need that runner installed, `make` is poor on Windows, and the command it ran would still differ per stack, so documents would still have to say what it does.

### All hooks are `sh`, with commands the profile declares

`commit-msg` and `pre-push` are already plain `sh` and stack-neutral. `pre-commit` becomes a stack-neutral `sh` dispatcher: it keeps its current handling of staged and partly staged files, and calls the fix and check commands a profile declares per file extension. `.githooks/install.mjs` goes away; setup documents `git config core.hooksPath .githooks`, and a profile MAY run it from its install step, as `node-pnpm` does from `pnpm prepare`.

The profile's commands are in `.githooks/profile.sh`, which `pre-commit` sources. It sets `PROFILE_EXTENSIONS`, the extensions any of its checks reads, and `PROFILE_FIX_HINT`, the commands that fix what they report, and defines `profile_fix` and `profile_check`, which take a list of files and usually call `on_ext`, a helper the hook provides that runs a command over the files with matching extensions.

Rejected: **a plain data file** listing extension, fix command, and check command. It would look safer than shell code, but the hook is already shell code from the same repository, so it would add no protection, and the hook would need a parser for it whose quoting of arguments is where it would go wrong.

This narrows a gap found in review of codenhub/template#18, where a project's other formatter was run by the hook but not by `pnpm format:check`, without closing it: the formatter's commands now sit side by side in the profile, in `profile.sh` and in the `format:*` scripts, and [Workspace](../docs/workspace.md#git-hooks) says to add them to both. Having the gate read `profile.sh` would close it, but `pnpm` runs scripts through `cmd` on Windows, where `sh` is not always on the path.

Rejected: **hooks per profile,** keeping `install.mjs` and the Node `pre-commit` in `node-pnpm` and writing another `pre-commit` for each stack. The staged-file handling is the hard part of the hook, with its own traps in `.githooks/AGENTS.md`, and it would be copied into every profile.

### `node-pnpm` is the only profile at first

The first version ships one profile, extracted from what the template is today, so the split is proven on a stack that real projects use. A Rust, Python, or Ruby profile is added when a project needs one, and is written from that project.

Rejected: **a second profile now,** to prove the core is neutral. A profile nobody uses is a profile nobody verifies; it would look supported and be wrong in ways only its first user finds.

### The layout is the project's, in the core

The core does not fix `apps/` + `packages/`. A project is a single package or a workspace whose members it declares, and the core defines commit scopes and the `pkg:` and `app:` labels in terms of those declared members. `node-pnpm` keeps `apps/*` and `packages/*` as its default member globs.

### A file lives in one place

A file that holds both core content and stack content, such as `.gitignore`, `.editorconfig`, `.github/dependabot.yml`, and `.github/workflows/ci.yml`, belongs whole to the profile. Nothing merges two files, so what a project gets is a copy of a file, and what it compares with is that file.

Rejected: **merging a core part and a profile part,** such as a core `.gitignore` with the profile's lines appended. It saves repeating a core improvement in each profile, but it needs a merge rule per format, YAML for `ci.yml` and lines for `.gitignore`, and a comparison would have to repeat the merge to show what the project started from. With one profile, there is nothing to repeat yet.

## Open questions

These are answered while implementing, each recorded here before the change that depends on it:

- **How a comparison sees the overlay.** A project compares with the core plus one profile, not with the repository as it is. Candidates: a script in `.template/` that assembles core and profile into a temporary directory, compared with `git diff --no-index`; or an assembled branch per profile, published by the template's CI, which keeps the comparison a plain `git diff FETCH_HEAD`.
- **The label sync command.** `CONTRIBUTING.md` creates the labels with `node -e`, which a project without Node.js cannot run. Candidates: a `sh` loop over `gh label create` that needs `jq`, or the command as a profile value.
- **How the template verifies itself.** Once the Node files move into `profiles/node-pnpm/`, the repository root is no longer a pnpm workspace, and `pnpm verify` cannot run there. The template's CI assembles each profile into a project and runs that project's gate, and the same assembly creates a project.

## Inventory

Where each file goes. "Split" means the file's general part stays in the core and its stack part moves to a profile document.

| File                                                                                                                                         | Goes to          |
| -------------------------------------------------------------------------------------------------------------------------------------------- | ---------------- |
| `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `SECURITY.md`, `LICENSE`, `README.md`                                                           | Core, values     |
| `.gitattributes`, `.github/ISSUE_TEMPLATE/`, `.github/labels.json`, `.github/pull_request_template.md`                                       | Core             |
| `.githooks/commit-msg`, `.githooks/pre-push`, `.githooks/AGENTS.md`                                                                          | Core             |
| `.githooks/pre-commit`                                                                                                                       | Core, dispatcher |
| `.githooks/install.mjs`                                                                                                                      | Removed          |
| `.githooks/profile.sh`                                                                                                                       | `node-pnpm`      |
| `docs/README.md`, `docs/guidelines/documentation.md`, `docs/guidelines/security.md`, `docs/guidelines/brand.md`                              | Core             |
| `docs/guidelines/code.md`                                                                                                                    | Split            |
| `docs/specs/tests.md`, `docs/ci.md`                                                                                                          | Split            |
| `docs/workspace.md`, `docs/tooling.md`                                                                                                       | `node-pnpm`      |
| `.gitignore`, `.editorconfig`, `.github/dependabot.yml`, `.github/workflows/ci.yml`, `.github/actions/setup/`                                | `node-pnpm`      |
| `package.json`, `pnpm-workspace.yaml`, `pnpm-lock.yaml`, `.nvmrc`, `.oxfmtrc.json`, `.oxlintrc.json`, `.prettierrc.json5`, `.prettierignore` | `node-pnpm`      |
| `tsconfig.base.json`, `tsconfig.json`, `tsconfig.root.json`, `vitest.config.ts`, `apps/`, `packages/`                                        | `node-pnpm`      |

## Plan

Each step is its own pull request, and each leaves the template working:

1. **Neutral wording in place.** The core's documents hold `{{setup}}` and `{{verify}}` where they named pnpm commands, and describe the layout through declared members, with no file moved yet. `pnpm verify` still runs at the root.
2. **Hooks.** `pre-commit` becomes the dispatcher, reading the Node commands from `.githooks/profile.sh`; `install.mjs` is replaced by `git config core.hooksPath .githooks`, run from `pnpm prepare`.
3. **Split the documents.** The general parts of `code.md`, `tests.md`, and `ci.md` stay; their TypeScript, Vitest, and pnpm parts move to profile documents, still at the root.
4. **Assembly and self-verification.** The script that assembles core and profile, used by the template's CI, by creation, and by comparison.
5. **Move `node-pnpm` into `profiles/node-pnpm/`,** update `.template/README.md` for creation and comparison with a profile, and the `project-template` skill with it.
