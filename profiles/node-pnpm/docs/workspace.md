---
status: IMPLEMENTED
last_updated: 2026-11-12
scope: The root script names and what each guarantees, the shared tool configurations, the pinned toolchain, install rules, and how dependency versions are declared.
---

# Workspace

This document is the workspace's contract: the names of the root scripts and what each one guarantees, the configuration files every project shares, and how versions are declared. CI, the git hooks, and the agent instructions rely on it. How this project implements the scripts, narrows a run, and adds a package is in [Tooling](tooling.md).

## Root scripts

| Script               | Guarantees                                                                                                                                    |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `pnpm format:check`  | Every file is formatted: code, JSON and YAML by oxfmt, Markdown by Prettier. Reports, writes nothing.                                         |
| `pnpm format:fix`    | The same two formatters, rewriting files.                                                                                                     |
| `pnpm lint:check`    | oxlint passes over the repository, with warnings treated as errors.                                                                           |
| `pnpm lint:fix`      | oxlint, applying its safe fixes.                                                                                                              |
| `pnpm typecheck`     | Every package and the repository's own TypeScript type-check.                                                                                 |
| `pnpm test`          | Every package's and app's unit and integration suites pass.                                                                                   |
| `pnpm test:watch`    | The same, in watch mode.                                                                                                                      |
| `pnpm test:coverage` | The same, with a coverage report in `coverage/`.                                                                                              |
| `pnpm build`         | Every package that produces output builds, in dependency order.                                                                               |
| `pnpm verify`        | `format:check`, `lint:check`, `build`, `typecheck` and `test`, in that order, then any check the project adds, stopping at the first failure. |
| `pnpm prepare`       | Runs on install: points git at the committed hooks in `.githooks/`.                                                                           |

`pnpm verify` is what CI runs ([CI](ci.md)), so a green local `verify` predicts a green run. The order puts the cheapest checks first, so a formatting slip is reported in a second instead of after the tests. The build comes before type checking and tests because a package that imports another workspace package resolves it through that package's `exports`, which for a built package point at `dist/`: on a fresh clone, as in CI, a type check or a test run before the build cannot resolve the import and fails.

Keep these names as they are: CI, the git hooks and the agent instructions call them by name. A script that only some projects need, such as `dev` or an end-to-end suite, is the project's to add.

<!-- The project's own root scripts, as a table with the same columns, such as `dev`, `test:browser`, or a generator, and the checks `pnpm verify` runs after `test`. -->

## Configuration

| File                  | Configures                                                                                                                                                                                                                                                                |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `package.json`        | The root scripts, the tooling as `devDependencies`, and the pinned Node.js and pnpm (`engines`, `packageManager`).                                                                                                                                                        |
| `pnpm-workspace.yaml` | The workspace globs, the catalog of every dependency version, the supply-chain rules for installs ([below](#dependency-installs)), and `engineStrict`, so an install outside `engines` fails.                                                                             |
| `.nvmrc`              | The exact Node.js version, read by `nvm` and by CI.                                                                                                                                                                                                                       |
| `.editorconfig`       | Indentation, final newline, LF line endings, and no hard wrap in Markdown.                                                                                                                                                                                                |
| `.gitattributes`      | LF line endings in the repository and the working tree on every platform, and the binary file types.                                                                                                                                                                      |
| `.oxfmtrc.json`       | oxfmt: 120 columns, double quotes, semicolons, trailing commas, sorted imports and `package.json` keys. Markdown is excluded; Prettier owns it. Nothing else is listed: oxfmt already skips what `.gitignore` and `.prettierignore` list, and the lockfile.               |
| `.prettierrc.json5`   | Prettier, for Markdown only: `proseWrap: "never"`, so a paragraph is one line and a diff shows the sentence that changed.                                                                                                                                                 |
| `.prettierignore`     | Paths inside the Markdown set Prettier leaves alone: build output and caches.                                                                                                                                                                                             |
| `.oxlintrc.json`      | oxlint's plugins and rules. `no-console` allows `console.warn` and `console.error`, a library's deliberate diagnostics, and refuses the rest, such as a forgotten `console.log`, except in `.githooks/`, any `scripts/` directory and tests, where printing is the point. |

The TypeScript and Vitest configurations depend on how the project runs its checks; [Tooling](tooling.md) describes them.

<!-- The project's own configuration files, as a table with the same columns, such as an extra tsconfig for one runtime, a Rust toolchain, or a deployment config. -->

### Two formatters

oxfmt formats everything it understands except Markdown; Prettier formats only Markdown. oxfmt is far faster and agrees with Prettier's output for code, but its Markdown support does not yet match Prettier's, and the documentation is where formatting churn costs the most review time. `.oxfmtrc.json` ignores `**/*.md`, and the scripts hand Prettier `**/*.md` explicitly, so neither formatter touches the other's files.

### Versions

Every third-party dependency version is declared once, in the catalog in `pnpm-workspace.yaml`, and referred to as `catalog:` in each `package.json`. The workspace therefore cannot hold two versions of one dependency by accident, and an upgrade is a one-line change that Dependabot can propose ([CI](ci.md#dependency-updates)). A workspace package depends on another as `workspace:*`, and a `peerDependencies` range says what a consumer may install, so neither is a catalog entry.

`@types/node` never takes a major update from Dependabot. Node's types follow the Node.js release in `engines` and `.nvmrc`, and types for a newer Node accept APIs the pinned runtime does not have; they move by hand, with `.nvmrc`.

<!-- Version rules only this project has, such as installing a published workspace package from its release through the catalog. -->

## Toolchain

Local and CI runs resolve the same versions, each declared once:

| Where                                | Declares                                        |
| ------------------------------------ | ----------------------------------------------- |
| `package.json` `engines`             | The Node.js and pnpm range every run must meet  |
| `package.json` `packageManager`      | The exact pnpm version pnpm installs itself     |
| `.nvmrc`                             | The exact Node.js version, read by `nvm` and CI |
| `pnpm-workspace.yaml` `engineStrict` | Makes an install outside `engines` fail         |

CI reads those same files rather than repeating a version: `pnpm/action-setup` takes pnpm from `packageManager`, and `actions/setup-node` takes Node.js from `.nvmrc`, both in the [setup action](ci.md#toolchain), which then installs with `--frozen-lockfile`.

`engineStrict` is deliberate friction. A patch-level difference rarely matters, and the one time it does, the failure looks like a bug in the change under review rather than a difference in the runtime.

### Dependency installs

`pnpm-workspace.yaml` holds the pnpm settings that govern installs, locally and in CI alike:

- `blockExoticSubdeps: true` refuses a transitive dependency that resolves to a git repository or a tarball URL instead of the registry. A direct dependency's source is written in `package.json`, where a reviewer sees it; a transitive one would arrive through another package's manifest unseen.
- `trustPolicy: no-downgrade` refuses a version whose publish-time trust evidence, such as provenance or trusted publishing, is weaker than that of an earlier version of the same package. A release that drops its provenance is a common sign of a compromised publish.
- `trustPolicyIgnoreAfter: 10080` is an age in minutes, seven days, after which a version is no longer held to the trust policy. It stops a long-published version that predates provenance from being refused as a downgrade, while a fresh release, the one a compromise would be, is still checked. When one recent version must be let through, `trustPolicyExclude` names that exact version, with the reason in a comment and the condition for removing it.
- `allowBuilds` lists the only dependencies whose install scripts run. It starts empty: the workspace's own tools ship their native binaries as optional dependencies and need none. A dependency that needs one, such as `esbuild`, gets an entry in the same change, with the reason.
- pnpm's default `minimumReleaseAge` prefers a version published at least a day ago, so a compromised release is usually caught and pulled before it is chosen here. It is not a hard gate: the workspace does not set `minimumReleaseAge`, so pnpm's default non-strict mode applies, and when the only version that matches a range or an exact pin is younger than a day, pnpm installs it anyway. Setting `minimumReleaseAge` explicitly, in `pnpm-workspace.yaml` or in a contributor's own pnpm configuration, makes it strict, so such an install fails instead; a version needed sooner then goes in `minimumReleaseAgeExclude`, by exact version, and leaves it once it is old enough.

## Git hooks

[Contributing](../CONTRIBUTING.md#hooks) lists what each hook checks and why each does that much and no more. This section records what is particular to this stack.

`pre-commit` itself knows nothing of the stack: it finds the staged files, keeps partly staged ones out of the rewrite, and calls `profile_fix` and `profile_check` from `.githooks/profile.sh`, which run oxfmt, Prettier, and oxlint. oxfmt is handed every staged file and formats those it understands, so the hook covers the same files as `pnpm format:check`, YAML and the formats oxfmt gains later included, with no list of extensions to fall behind. A project with code in another language, such as Rust or Go, adds its formatter to both functions and to the `format:fix` and `format:check` scripts, so the hook and the gate run the same formatter. When oxfmt also understands those files, the project lists them in `ignorePatterns` in `.oxfmtrc.json`. Its linter, like the type checker, belongs to `pnpm verify`.

The hooks are wired by `core.hooksPath`, which the root `prepare` script sets on every install with `git config`. That is a local git setting rather than a tracked one, so a fresh clone runs no hooks until something sets it; doing it from `prepare` keeps a hook manager out of the dependency list. The setup step never fails an install: a tree without git, or without permission to write its config, reports and carries on.
