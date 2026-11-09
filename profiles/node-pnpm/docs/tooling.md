---
status: IMPLEMENTED
last_updated: 2026-11-09
scope: Setup, how the root scripts are implemented, the TypeScript and Vitest configuration, narrowing a run, and adding a package.
---

# Tooling

[Workspace](workspace.md) names the root scripts and what each one guarantees. This document is how this project implements them.

Every script runs from the repository root. There is no workspace CLI: the scripts call pnpm, Vitest, `tsc`, oxlint, oxfmt and Prettier directly, so each one is a command a contributor can read in `package.json` and run on its own. A workspace that outgrows plain scripts adds a CLI as a package of its own; until then a wrapper would be one more thing to learn and to keep in step.

Markdown is formatted by Prettier with `proseWrap: "never"`, set in `.prettierrc.json5`, and the files it leaves alone are listed in `.prettierignore`; [Workspace](workspace.md#two-formatters) says why Prettier, not oxfmt, owns Markdown.

## Setup

```sh
nvm install
pnpm install
```

Setup needs pnpm 10 or later on the `PATH`, installed apart from Node.js, with the standalone script in [pnpm's installation guide](https://pnpm.io/installation): a pnpm installed through `npm` belongs to the Node.js version it was installed under, and `nvm install` switching versions takes it off the `PATH`. Any such version switches itself to the one the `packageManager` field in `package.json` pins before it runs, unless its `manage-package-manager-versions` setting has been turned off; with it off, install the pinned version itself. Node.js does not bring pnpm with it: Node.js 24 ships Corepack switched off, and later versions do not ship it at all.

`.nvmrc` pins Node.js. `nvm install` reads it, downloads that version when it is missing, and switches to it; with another version manager, install and use the version `.nvmrc` names. nvm for Windows does not read `.nvmrc`, and `nvm install` and `nvm use` without a version fail, so name it; in PowerShell, `nvm install (Get-Content .nvmrc)`, then `nvm use (Get-Content .nvmrc)`. Checked with nvm for Windows 1.2.2, and in the source of 2.0.1, whose `install` requires the version. [Workspace](workspace.md#toolchain) covers why the versions are pinned where they are.

`pnpm install` runs the root `prepare` script, which points git at `.githooks/` through `core.hooksPath`. If lifecycle scripts were disabled during the install, run `git config core.hooksPath .githooks`.

## Scripts

| Script               | Runs                                                                                        |
| -------------------- | ------------------------------------------------------------------------------------------- |
| `pnpm format:check`  | `oxfmt --check`, then `prettier --check` over `**/*.md`.                                    |
| `pnpm format:fix`    | The same two formatters, rewriting files.                                                   |
| `pnpm lint:check`    | `oxlint --deny-warnings`.                                                                   |
| `pnpm lint:fix`      | `oxlint --fix`.                                                                             |
| `pnpm typecheck`     | `tsc -b` over the solution in `tsconfig.json`: the root files and every referenced package. |
| `pnpm test`          | `vitest run`: every package's and app's Vitest project, in one run.                         |
| `pnpm test:watch`    | `vitest`, in watch mode.                                                                    |
| `pnpm test:coverage` | `vitest run --coverage`, with a V8 coverage report in `coverage/`.                          |
| `pnpm build`         | `pnpm -r --if-present run build`. A package without a `build` script is skipped.            |
| `pnpm verify`        | The checks above in the order [Workspace](workspace.md#root-scripts) gives.                 |
| `pnpm prepare`       | `git config core.hooksPath .githooks`, reporting rather than failing when git cannot.       |

## TypeScript and Vitest

| File                 | Configures                                                                                                                                                                                                                                                                                            |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `tsconfig.base.json` | The compiler settings every project shares: strict, `noUncheckedIndexedAccess`, `verbatimModuleSyntax`, bundler resolution, and type-checking only (`noEmit`).                                                                                                                                        |
| `tsconfig.json`      | The solution `tsc -b` builds. It lists projects and holds no files.                                                                                                                                                                                                                                   |
| `tsconfig.root.json` | The project for code outside the packages: root config files such as `vitest.config.ts`, and `scripts/`, in `.ts` or `.mjs`. Node.js runs these directly, so it checks them by Node's rules: Node.js types, NodeNext resolution, and relative imports with the file's own extension, `.ts` or `.mjs`. |
| `vitest.config.ts`   | The Vitest projects: the root project for the `.ts` and `.mjs` tests in `scripts/`, and every package and app with a `vitest.config.ts`.                                                                                                                                                              |

### The empty workspace

`apps/` and `packages/` hold only a `.gitkeep` until the first package arrives, so the workspace globs and the Vitest and coverage globs point at real directories. With no packages, every script still does real work: `typecheck` checks `vitest.config.ts` through `tsconfig.root.json`, `test` loads the Vitest configuration and runs the root project, and `build` runs pnpm across the workspace and finds nothing to build. Vitest refuses a configuration whose project list matches nothing, which is the other reason the root project exists; `passWithNoTests` keeps a workspace with no tests yet from failing. Delete a `.gitkeep` once its directory has a package.

## Narrowing a run

Vitest names each project in its own `vitest.config.ts`, so one package runs on its own, and a path runs one file:

```sh
pnpm test --project <name>
pnpm test packages/<directory>/src/<file>.test.ts
pnpm test:watch --project <name>
```

pnpm's `--filter` narrows `build`, or runs any script of one package:

```sh
pnpm --filter @<scope>/<name> run build
```

oxlint and oxfmt take paths: `pnpm exec oxlint packages/<directory>` and `pnpm exec oxfmt --check packages/<directory>`.

## Adding a package

1. Create it under `packages/` (a library) or `apps/` (something deployed or run), with a `package.json` named `@<scope>/<directory>` (the scope every package in the repository shares), `"private": true` unless it is published, `"type": "module"`, and its dependencies as `catalog:` or `workspace:*`. A new third-party version goes in the catalog.
2. Give it a `tsconfig.json` that extends `../../tsconfig.base.json`, sets `tsBuildInfoFile` to `./node_modules/.cache/tsconfig.tsbuildinfo`, adds the `lib` and `types` its runtime needs (`"types": ["node"]` and `@types/node` for Node.js code), and includes its `src/`, tests and `vitest.config.ts`.
3. Add its path to `references` in the root `tsconfig.json`.
4. Give it a `vitest.config.ts` that names its project (`test: { name: "<directory>" }`). The root configuration picks it up through its glob.
5. Give it a `build` script if it produces output; `pnpm build` runs it.
6. Delete the directory's `.gitkeep` if this is its first package, and list the package where the project lists its layout.
