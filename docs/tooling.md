---
status: IMPLEMENTED
last_updated: 2026-11-02
scope: Root scripts, the tool configurations, narrowing a run, and adding a package.
---

# Tooling

Every script runs from the repository root. There is no workspace CLI: the scripts call pnpm, Vitest, `tsc`, oxlint, oxfmt and Prettier directly, so each one is a command a contributor can read in `package.json` and run on its own. A workspace that outgrows plain scripts adds a CLI as a package of its own; until then a wrapper would be one more thing to learn and to keep in step.

## Root scripts

| Script               | Runs                                                                                                         |
| -------------------- | ------------------------------------------------------------------------------------------------------------ |
| `pnpm format:check`  | oxfmt over code, JSON and YAML, then Prettier over Markdown. Reports, writes nothing.                        |
| `pnpm format:fix`    | The same two formatters, rewriting files.                                                                    |
| `pnpm lint:check`    | oxlint over the repository, with warnings treated as errors (`--deny-warnings`).                             |
| `pnpm lint:fix`      | oxlint, applying its safe fixes.                                                                             |
| `pnpm typecheck`     | `tsc -b` over the solution in `tsconfig.json`: the root files and every referenced package.                  |
| `pnpm test`          | Every package's and app's Vitest suite, in one run.                                                          |
| `pnpm test:watch`    | The same, in watch mode.                                                                                     |
| `pnpm test:coverage` | The same, with a V8 coverage report in `coverage/`.                                                          |
| `pnpm build`         | Every workspace package's `build` script, in dependency order. A package without one is skipped.             |
| `pnpm verify`        | `format:check`, `lint:check`, `build`, `typecheck` and `test`, in that order, stopping at the first failure. |
| `pnpm prepare`       | Runs on install: points git at the committed hooks in `.githooks/`.                                          |

`pnpm verify` is what CI runs ([CI](ci.md)), so a green local `verify` predicts a green run. The order puts the cheapest checks first, so a formatting slip is reported in a second instead of after the tests. The build comes before type checking and tests because a package that imports another workspace package resolves it through that package's `exports`, which for a built package point at `dist/`: on a fresh clone, as in CI, `tsc -b` and Vitest run before the build cannot resolve the import and fail.

A script that only some projects need, such as `dev` or an end-to-end suite, is the project's to add. Keep the names above as they are: CI, the git hooks and the agent instructions call them by name.

## Configuration

| File                  | Configures                                                                                                                                                     |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `package.json`        | The root scripts, the tooling as `devDependencies`, and the pinned Node.js and pnpm (`engines`, `packageManager`).                                             |
| `pnpm-workspace.yaml` | The workspace globs, the catalog of every dependency version, and the supply-chain rules for installs ([CI](ci.md#dependency-installs)).                       |
| `.npmrc`              | `engine-strict`, so an install outside `engines` fails.                                                                                                        |
| `.nvmrc`              | The exact Node.js version, read by `nvm` and by CI.                                                                                                            |
| `.editorconfig`       | Indentation, final newline, LF line endings, and no hard wrap in Markdown.                                                                                     |
| `.gitattributes`      | LF line endings in the repository and the working tree on every platform, and the binary file types.                                                           |
| `.oxfmtrc.json`       | oxfmt: 120 columns, double quotes, semicolons, trailing commas, sorted imports and `package.json` keys. Markdown is excluded; Prettier owns it.                |
| `.prettierrc.json`    | Prettier, for Markdown only: `proseWrap: "never"`, so a paragraph is one line and a diff shows the sentence that changed.                                      |
| `.prettierignore`     | Paths inside the Markdown set Prettier leaves alone: build output and caches.                                                                                  |
| `.oxlintrc.json`      | oxlint's plugins and rules. `no-console` is an error except in `.githooks/`, `scripts/` and tests, where printing is the point.                                |
| `tsconfig.base.json`  | The compiler settings every project shares: strict, `noUncheckedIndexedAccess`, `verbatimModuleSyntax`, bundler resolution, and type-checking only (`noEmit`). |
| `tsconfig.json`       | The solution `tsc -b` builds. It lists projects and holds no files.                                                                                            |
| `tsconfig.root.json`  | The project for TypeScript outside the packages: root config files such as `vitest.config.ts`, and `scripts/`.                                                 |
| `vitest.config.ts`    | The Vitest projects: the root project for `scripts/`, and every package and app with a `vitest.config.ts`.                                                     |

### Two formatters

oxfmt formats everything it understands except Markdown; Prettier formats only Markdown. oxfmt is far faster and agrees with Prettier's output for code, but its Markdown support does not yet match Prettier's, and the documentation is where formatting churn costs the most review time. `.oxfmtrc.json` ignores `**/*.md`, and the scripts hand Prettier `**/*.md` explicitly, so neither formatter touches the other's files.

### Versions

Every dependency version is declared once, in the catalog in `pnpm-workspace.yaml`, and referred to as `catalog:` in each `package.json`. The workspace therefore cannot hold two versions of one dependency by accident, and an upgrade is a one-line change that Dependabot can propose ([CI](ci.md#dependency-updates)).

### The empty workspace

`apps/` and `packages/` hold only a `.gitkeep` until the first package arrives, so the workspace globs and the Vitest and coverage globs point at real directories. With no packages, every script still does real work: `typecheck` checks `vitest.config.ts` through `tsconfig.root.json`, `test` loads the Vitest configuration and runs the root project, and `build` runs pnpm across the workspace and finds nothing to build. Vitest refuses a configuration whose project list matches nothing, which is the other reason the root project exists; `passWithNoTests` keeps a workspace with no tests yet from failing. Delete a `.gitkeep` once its directory has a package.

<!-- project:start -->

<!-- Project-specific scripts and configuration, such as `dev`, an end-to-end suite, a Rust toolchain, or an extra tsconfig for one runtime, with what each runs. Leave empty when there are none. -->

<!-- project:end -->

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
