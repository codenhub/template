# The template

This directory belongs to the template repository only. A project created from the template deletes it, and keeps nothing else that ties it to the template: no manifest, no recorded sync, no markers. Every other file is the project's from the first commit.

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

## Creating a project

1. Copy the template's files into the new repository.
2. Replace every placeholder:

   | Placeholder       | Replaced with                                         | Example              |
   | ----------------- | ----------------------------------------------------- | -------------------- |
   | `{{name}}`        | The project's display name.                           | `Acme Notes`         |
   | `{{slug}}`        | The repository and root package name.                 | `acme-notes`         |
   | `{{scope}}`       | The npm scope of workspace packages, without the `@`. | `acme-notes`         |
   | `{{description}}` | One sentence saying what the project is.              | `A note-taking app.` |
   | `{{owner}}`       | The GitHub owner, a user or organization.             | `acme`               |
   | `{{holder}}`      | The copyright holder.                                 | `Acme`               |
   | `{{year}}`        | The year the project was created.                     | `2026`               |

3. Delete `.template/`.
4. Check that no placeholder is left; this prints nothing when none is, and searches files not yet added to git too:

   ```sh
   git grep --untracked -nE '\{\{(name|slug|scope|description|owner|holder|year)\}\}'
   ```

5. Run `pnpm install` and `pnpm verify`.

The HTML comments in the documents are prompts for what the project writes in each section; the [documentation guidelines](../docs/guidelines/documentation.md#prompts) say what to do with them, and stay in the project once this directory is gone.

## Comparing a project with the template

From the project's repository, fetch the template without adding a remote, then compare the template with the project's working tree, leaving out the files that only ever held a starting point:

```sh
git fetch --no-tags https://github.com/codenhub/template HEAD
git diff --stat -M --diff-filter=a FETCH_HEAD -- \
  ':(exclude).template' ':(exclude)README.md' ':(exclude)LICENSE' \
  ':(exclude)docs/guidelines/brand.md' ':(exclude)pnpm-lock.yaml' ':(exclude)*.gitkeep'
```

Drop `--stat` to see the changes. Lines starting with `-` are the template's, and lines starting with `+` are the project's. `--diff-filter=a` leaves out files only the project has, which would otherwise show as added. A file the template has and the project deleted shows as removed, and `-M` pairs a file the project moved with its template original, as `docs/{ci.md => pipeline.md}`. A file both moved and mostly rewritten is too different to pair, so it shows as removed; compare it by hand, with `git diff FETCH_HEAD:<template path> HEAD:<project path>`. The fetch adds no remote or ref beyond `FETCH_HEAD`, and changes no tracked file. The commands are POSIX shell; on Windows, run them from Git Bash.

Judge each change on its own rather than each file: one file can hold a better section from each side. The project's placeholder values show up as differences on the lines that hold them, and are not changes to judge.

To take the template's version of a whole file, run `git checkout FETCH_HEAD -- <path>` and restore the project's own values in it. `pnpm-lock.yaml` is never copied: after taking a change to `package.json` or `pnpm-workspace.yaml`, `pnpm install` regenerates it.

## Projects from the manifest design

A project created before this design still has its ties. Removing them changes no behavior:

1. Delete `.template/`, including `manifest.json` and `check.mjs`.
2. Delete each `project:start` and `project:end` marker line, keeping the text between them: it is the project's.
3. In `.github/workflows/ci.yml`, delete the `Template conformance` step, which runs the deleted checker and would fail.
4. In `AGENTS.md`, delete the rule about files listed in `.template/manifest.json`; in `tsconfig.root.json` and `vitest.config.ts`, delete the `.template/*.mjs` entries.
5. Run `pnpm verify`.

This prints nothing once no marker or reference is left:

```sh
git grep -nE 'project:(start|end)|\.template/'
```
