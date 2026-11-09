# The template

This directory belongs to the template repository only, with two files outside it: `.github/workflows/template.yml`, the template's own check, and `.github/dependabot.yml`, its own dependency updates. Creating a project deletes all three, and the project keeps nothing else that ties it to the template: no manifest, no recorded sync, no markers. Every other file is the project's from the first commit.

This README is the source for creating a project and comparing one with the template. The `project-template` skill in codenhub/codenhub turns it into instructions for agents, and follows it where the two differ.

## What the template is

The template is a starting point and a reference, not a model a project has to follow. A new project copies it. From then on, the project and the template evolve apart, and either can end up with the better version of a file.

When someone wants to, they compare their project with the template's current version and, for each difference, ask which side is better:

- **The template's is better:** the project takes it.
- **The project's is better:** the project files an issue or a pull request on the template, or simply keeps its version.
- **The difference is the project's own,** such as its name, its packages, or a rule only it needs: the project keeps it.

Nothing records the outcome, so a difference the project keeps on purpose shows up again in the next comparison. That is accepted: a comparison is run by choice, rarely, and never blocks CI, so seeing the same intentional difference again costs a moment of reading, while recording it would need state in the project, which is the tie this design removes.

### Why

The earlier design kept `.template/manifest.json` in every project. The manifest assigned each template file a class, `canonical`, `blocks`, or `seed`; recorded the template commit the project last synced with; and listed exceptions. A checker, `.template/check.mjs`, ran in CI and failed on any difference from the template outside a `project:start`/`project:end` block, unless an exception was listed.

That design assumed projects would follow the template and send their improvements back to it. It did not weigh what happens when they do not:

- **A project that outgrows a file must do bookkeeping to keep its improvement.** Every local improvement to a `canonical` file, or to the template's text in a `blocks` file, failed CI until it was upstreamed or listed as an exception. Upstreaming is a choice the project gets to make, not a precondition for its own CI.
- **The ties are permanent.** The manifest, the markers in about twenty files, the CI step, and the agent instructions about them stayed in the project for good, and made no sense to anyone who never knew the template.
- **The answer it gave was not the one needed.** A recorded base commit answers "what changed in the template, and what did the project change, since the last sync". The question a comparison actually asks is "which version is better", and a two-way diff against the template's current version answers that directly.

Rejected alternatives:

- **Keep the manifest, but warn instead of failing.** The ties stay, and nobody acts on a warning that appears in every CI run.
- **Infer the base instead of recording it.** Matching the project's files against every historical template version finds the commit each one came from, without storing anything. It answers the same "since when" question as the recorded base, which is not the question being asked.
- **Record the base outside the tree:** in a commit trailer, which a squash merge can drop; in git notes, which are not pushed or fetched by default; or in a registry kept in the template repository, which the project's contributors cannot see. Each keeps a tie, only out of sight.
- **Record declined differences, so they stop reappearing.** That needs state in the project, the tie this design removes.
- **Automate the comparison,** with a script that assembles the core and a profile, or a branch per profile that the template's CI publishes. Both bring back machinery for a step that is meant to be a person's or an agent's judgment, run when they choose; two plain `git diff` commands, below, see the core and the profile without either.

## Core and profiles

The repository root is a stack-neutral core: the process, the agent instructions, the hooks, and the documentation that holds in any language. Each directory under `profiles/` holds one stack's files, at the paths they take in a project. Creating a project lays one profile over the core.

| Profile     | `{{setup}}`                        | `{{verify}}`  |
| ----------- | ---------------------------------- | ------------- |
| `node-pnpm` | `nvm install`, then `pnpm install` | `pnpm verify` |

Rejected: **one template repository per stack.** Each would be simpler alone, but every change to the process, the agent instructions, or the documentation guidelines would be repeated in each repository, and they would drift apart. Keeping the core in one place is the reason to split at all.

### Profile values fill the core

The core never names a stack's command; it holds `{{setup}}`, the setup commands, and `{{verify}}`, the delivery gate, which creation fills from the table above as it fills `{{name}}`. `AGENTS.md`, `CONTRIBUTING.md`, the pull request template, and the README then show the real command in a created project. Anything about the stack beyond those values, such as where versions are pinned or how the hooks are set up by hand, is in the profile's documents.

Rejected: **pointers only,** where the core says "the gate `CONTRIBUTING.md` names" and never the command. Nothing is filled in, but every reader takes an extra hop to reach the command, and an agent reads a reference where it needs a command to run. The cost of the values is two more placeholders, which a comparison shows as differences on the lines that hold them, as it already shows `{{name}}`.

Rejected: **one runner command in every project,** such as `just verify` or `make verify`. Agents would get one command to call everywhere, but every project would need that runner installed, `make` is poor on Windows, and the command it ran would still differ per stack, so documents would still have to say what it does.

### Profile documents have fixed paths

Every profile provides the same four documents, at the same paths, so the core and its index link to them without knowing the stack:

| Path                        | Holds                                                                                    |
| --------------------------- | ---------------------------------------------------------------------------------------- |
| `docs/workspace.md`         | What each check guarantees, the configuration files, the pinned toolchain, and installs. |
| `docs/tooling.md`           | Setup, how the checks are implemented, narrowing a run, and adding a member.             |
| `docs/guidelines/stack.md`  | The conventions of the stack's languages, on top of `docs/guidelines/code.md`.           |
| `docs/specs/stack-tests.md` | How the categories in `docs/specs/tests.md` run: runners, file names, scripts, commands. |

A document's title names the stack, as "TypeScript guidelines" does; only its path is fixed. A core document says what holds in any language and links to the profile's document for the rest, and states a rule once, in whichever of the two owns it. In this repository those links point at files under `profiles/`, so they resolve only in a created project.

Rejected: **documents named after the stack,** such as `docs/guidelines/typescript.md`. The name says more, but the core's links and the index would then differ per profile, which would make them profile values too, or make the index the profile's.

### A file lives in one place

A file that holds both core content and stack content, such as `.gitignore`, `.editorconfig`, `.github/dependabot.yml`, and `.github/workflows/ci.yml`, belongs whole to the profile. Nothing merges two files, so what a project gets is a copy of a file, and what it compares with is that file. The template's own `.github/dependabot.yml` is the one path at both levels: it is template-only, deleted before the profile's takes its place.

Rejected: **merging a core part and a profile part,** such as a core `.gitignore` with the profile's lines appended. It saves repeating a core improvement in each profile, but it needs a merge rule per format, YAML for `ci.yml` and lines for `.gitignore`, and a comparison would have to repeat the merge to show what the project started from. With one profile, there is nothing to repeat yet.

### All hooks are `sh`, with commands the profile declares

`commit-msg` and `pre-push` are plain `sh` and stack-neutral. `pre-commit` is a stack-neutral `sh` dispatcher: it handles staged and partly staged files, and sources `.githooks/profile.sh`, which the profile provides. That file sets `PROFILE_EXTENSIONS`, a `grep -E` pattern for the extensions any of its checks reads, and `PROFILE_FIX_HINT`, the commands that fix what they report, and defines `profile_fix` and `profile_check`, which take a list of files and usually call `on_ext`, a helper the hook provides that runs a command over the files with matching extensions. Without `profile.sh`, as at this repository's root, the hook runs no checks and says so. Setup points git at the hooks with `git config core.hooksPath .githooks`, which `node-pnpm` runs from `pnpm prepare`.

Rejected: **hooks per profile,** keeping a Node `pre-commit` in `node-pnpm` and writing another for each stack. The staged-file handling is the hard part of the hook, with its own traps in `.githooks/AGENTS.md`, and it would be copied into every profile.

Rejected: **a plain data file** listing extension, fix command, and check command. It would look safer than shell code, but the hook is already shell code from the same repository, so it would add no protection, and the hook would need a parser for it whose quoting of arguments is where it would go wrong.

A gap found in review of codenhub/template#18, where a project's other formatter was run by the hook but not by `pnpm format:check`, is narrowed, not closed: the formatter's commands sit side by side in the profile, in `profile.sh` and in the `format:*` scripts, and the profile's [Workspace](node-pnpm/docs/workspace.md#git-hooks) says to add them to both. Having the gate read `profile.sh` would close it, but `pnpm` runs scripts through `cmd` on Windows, where `sh` is not always on the path.

### The layout is the project's

The core does not fix `apps/` + `packages/`. A project is a single package or a workspace whose members it declares, and the core defines commit scopes and the `pkg:` and `app:` labels in terms of those declared members. `node-pnpm` keeps `apps/*` and `packages/*` as its default member globs.

### `node-pnpm` is the only profile at first

The first profile was extracted from what the template was before the split, so the split is proven on a stack real projects use. A Rust, Python, or Ruby profile is added when a project needs one, and is written from that project, with a row in the table above and a job in `.github/workflows/template.yml`.

Rejected: **a second profile now,** to prove the core is neutral. A profile nobody uses is a profile nobody verifies; it would look supported and be wrong in ways only its first user finds.

### The label list is a `sh` script

`.github/labels.sh` lists the labels, one `label` line each, and creates or updates them through `gh` when run. It needs only `gh` and the `sh` that git ships on every platform, which on Windows is reachable from PowerShell or `cmd` through a git alias, as `CONTRIBUTING.md` shows; the hooks rely on the same `sh`.

Rejected: **a JSON list read by `node -e`,** the earlier design. A project without Node.js could not run it.

Rejected: **a JSON list read by a `sh` loop through `jq`.** `jq` is not installed by default on Windows or on many Linux systems.

Rejected: **the command as a profile value.** Each profile would carry its own command for a list that holds the same labels in every stack.

## Creating a project

1. Create the repository from the template, such as with `gh repo create <owner>/<slug> --template codenhub/template --clone`, or copy the template's files into it.
2. Delete the template-only files and lay the chosen profile over the core:

   ```sh
   rm .github/workflows/template.yml .github/dependabot.yml
   cp -R profiles/node-pnpm/. .
   rm -r profiles
   ```

3. Replace every placeholder:

   | Placeholder       | Replaced with                               | Example              |
   | ----------------- | ------------------------------------------- | -------------------- |
   | `{{name}}`        | The project's display name.                 | `Acme Notes`         |
   | `{{slug}}`        | The repository and root package name.       | `acme-notes`         |
   | `{{description}}` | One sentence saying what the project is.    | `A note-taking app.` |
   | `{{owner}}`       | The GitHub owner, a user or organization.   | `acme`               |
   | `{{holder}}`      | The copyright holder.                       | `Acme`               |
   | `{{year}}`        | The year the project was created.           | `2026`               |
   | `{{setup}}`       | The profile's setup commands, one per line. | From the table above |
   | `{{verify}}`      | The profile's delivery gate.                | From the table above |

4. Check that no placeholder is left; this prints nothing when none is, and searches files not yet added to git too:

   ```sh
   git grep --untracked -nE '(^|[^$])\{\{[a-z0-9_]+\}\}'
   ```

   It matches any placeholder, including one a document uses that the table above misses, and not a GitHub Actions expression, which starts with `$`, such as `${{ github.ref }}` or `${{true}}`.

5. Run the setup commands and the gate.

The HTML comments in the documents are prompts for what the project writes in each section; the [documentation guidelines](../docs/guidelines/documentation.md#prompts) say what to do with them, and stay in the project once this directory is gone.

## Comparing a project with the template

From the project's repository, fetch the template without adding a remote, then compare the project's working tree with the core, and with the profile it started from, leaving out the files that only ever held a starting point:

```sh
git fetch --no-tags https://github.com/codenhub/template HEAD
git diff --stat -M --diff-filter=a FETCH_HEAD -- ':(exclude)profiles' \
  ':(exclude).github/workflows/template.yml' ':(exclude).github/dependabot.yml' \
  ':(exclude)README.md' ':(exclude)LICENSE' ':(exclude)docs/guidelines/brand.md'
git diff --stat -M --diff-filter=a FETCH_HEAD:profiles/node-pnpm -- \
  ':(exclude)pnpm-lock.yaml' ':(exclude)*.gitkeep'
```

The first command compares the core, and the second the profile: `FETCH_HEAD:profiles/node-pnpm` is that directory of the template, compared as if it were the repository root. Drop `--stat` to see the changes. Lines starting with `-` are the template's, and lines starting with `+` are the project's. `--diff-filter=a` leaves out files the other side does not have, so the profile's files do not show in the first command, the core's do not show in the second, and neither shows files only the project has. A file the template has and the project deleted shows as removed, and `-M` pairs a file the project moved with its template original, as `docs/{ci.md => pipeline.md}`. A file both moved and mostly rewritten is too different to pair, so it shows as removed; compare it by hand, with `git diff FETCH_HEAD:<template path> HEAD:<project path>`. The fetch adds no remote or ref beyond `FETCH_HEAD`, and changes no tracked file. The commands are POSIX shell; on Windows, run them from Git Bash.

Judge each change on its own rather than each file: one file can hold a better section from each side. The project's placeholder values show up as differences on the lines that hold them, and are not changes to judge.

To take the template's version of a whole file, run `git checkout FETCH_HEAD -- <path>` for a core file, or `git show FETCH_HEAD:profiles/node-pnpm/<path> > <path>.new && mv <path>.new <path>` for a profile file, so a mistyped path leaves the project's file as it was, and restore the project's own values in it. `pnpm-lock.yaml` is never copied: after taking a change to `package.json` or `pnpm-workspace.yaml`, `pnpm install` regenerates it.

A project created before the split into profiles compares the same way: its stack files are the `node-pnpm` profile's.

## Projects from the manifest design

A project created before this design still has its ties. Removing them changes nothing the project's code does; CI stops checking for drift from the template, which is the point:

1. Delete `.template/`, including `manifest.json` and `check.mjs`.
2. Delete each `project:start` and `project:end` marker line, keeping the text between them: it is the project's.
3. In `.github/workflows/ci.yml`, delete the `Template conformance` step, which runs the deleted checker and would fail.
4. In `AGENTS.md`, delete the rule about files listed in `.template/manifest.json`; in `tsconfig.root.json` and `vitest.config.ts`, delete the `.template/*.mjs` entries.
5. Update or remove text that describes the old design, such as the paragraph in `docs/ci.md` about the conformance step and the hint comments that say to leave a block empty.
6. Run the gate.

This prints nothing once no marker or reference is left:

```sh
git grep -nE 'project:(start|end)|\.template/'
```

## Changing the template

`.github/workflows/template.yml` creates a project from each profile, with the steps above on its own checkout, runs that profile's gate, and then runs `profiles/hooks.test.sh`, which commits through the created project's hooks and checks what each one accepts, refuses, and rewrites; it is the check branch protection requires. The gate checks files, not hooks, so without that script a broken hook would reach every new project with nothing failing. To run the same locally, create a project in a scratch clone:

```sh
template="$(pwd)" && dir="$(mktemp -d)/check" && git clone --quiet . "$dir" && cd "$dir"
rm .github/workflows/template.yml .github/dependabot.yml
cp -R profiles/node-pnpm/. . && rm -r profiles
nvm install && pnpm install && pnpm verify
sh "$template/profiles/hooks.test.sh"
```

The clone holds what is committed, so commit first, on a branch; the hook check runs from the working tree. It commits and resets in the clone, which is why it runs there and never in a checkout you work in. On Windows, run these from Git Bash, and give nvm for Windows the version, as the profile's [Tooling](node-pnpm/docs/tooling.md#setup) says.
