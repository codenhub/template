---
status: IMPLEMENTED
last_updated: 2026-11-09
scope: The CI workflow, the shared setup action, action pinning, dependency updates, and branch protection.
---

# Continuous integration

`.github/workflows/ci.yml` verifies every pull request, every merge-queue check, and, unless the project requires a merge queue, every push to `main`. It runs the same gate a contributor runs locally, `{{verify}}`, so a green run means the gate passed rather than that some CI-only approximation of it did. [Workspace](workspace.md) says what each check guarantees.

## Toolchain

Local and CI runs resolve the same versions, each declared once, and CI reads those same declarations rather than repeating a version. A version is raised in one place, and a machine that cannot satisfy it is told at install time instead of failing later in a way nobody can reproduce. [Workspace](workspace.md#toolchain) lists where each version is declared.

Setup, the toolchain and an install from the lockfile, lives in the composite action `.github/actions/setup`, so every job that needs the project sets it up the same way. A lockfile that disagrees with the manifests fails the install rather than being rewritten in CI.

## The workflow

<!-- The workflow's jobs. A project that adds jobs or changes what `Verify` runs updates the table. -->

| Job      | Runner          | Runs                                                |
| -------- | --------------- | --------------------------------------------------- |
| `Verify` | `ubuntu-latest` | `{{verify}}`, then the `Working tree is clean` step |

By default there is no change-based selection: every run checks the whole workspace. A check that skips part of the workspace on a pull request lets that part reach `main` unverified, and a selection has to be maintained and can be wrong in ways a green run hides. A project whose full run grows too slow to wait for adds selection then, under three rules:

- **The whole workspace is checked before the merge lands.** A merge queue does that: it runs the full check on the merge result and drops a pull request that fails it. A push run on `main` only reports afterwards, once the failure is already there. Without a queue, the pull requests of codenhub/codenhub, the monorepo this rule comes from, went green on their own packages while 3 of 30 merges on 2026-11-03 failed on `main`, in packages those pull requests never touched ([codenhub/codenhub@702af904](https://github.com/codenhub/codenhub/commit/702af904)).
- **A change to `.github/` runs everything.** A workflow or the setup action belongs to no package, so a selection by changed package selects nothing, and the run passes without exercising the change it was opened for ([codenhub/codenhub@3d9bfe8a](https://github.com/codenhub/codenhub/commit/3d9bfe8a)).
- **The run asserts the ref it compares against.** A selection that compares against the base branch needs that ref in the checkout (`fetch-depth: 0`), and the job checks the ref exists before selecting: a tool that falls back to working-tree changes when the ref is missing would, in CI, check nothing and report success.

`Working tree is clean` fails when a check has left a tracked or untracked file changed. A check that writes has changed what it was checking, so it is reported rather than passing.

Runs for the same pull request cancel each other, because only the newest push is worth a verdict. A merge-queue run or a push to `main` is never cancelled to make way for a newer one: each is the authoritative check of a commit, so each is grouped by its commit rather than its branch. Grouping by branch would not hold that: a concurrency group holds one running and one pending run, and GitHub cancels the pending one when a third arrives, whatever `cancel-in-progress` says, so three quick pushes to `main` would leave the second without a verdict. The cost is that runs on `main` can run in parallel. The `merge_group` trigger never fires in a repository without a merge queue. A project that requires one removes the `push` trigger: the queue lands the exact commit it checked, so a push run would only repeat a passed check. The workflow's token is read-only (`permissions: contents: read`); a job that needs more asks for it on that job alone.

<!-- Project-specific jobs, such as browser suites, a native build, a container image, or a database service, with what each runs and why it is a job of its own. -->

## Changing the workflow

Prefer adding a check to the gate over adding a step to the workflow. A step only CI can run is a step nobody can reproduce before pushing, and that is how CI turns into a second build system.

### Pinning third-party actions

Every action from another repository is referenced by full commit SHA, with the release it corresponds to in a trailing comment:

```yaml
uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
```

A tag is a mutable pointer. `@v7` resolves to whatever its owner last pointed it at, so a compromised or simply retagged release changes what runs here without any change landing in this repository. A SHA cannot move, which turns an action upgrade into a reviewable diff. The comment carries the human-readable version, because a bare SHA says nothing about how far behind it is.

The rule is all or nothing on purpose. Pinning some actions and not others is worse than pinning none: a reader cannot tell a reference that was reviewed from one that was missed. Adding an action means resolving its SHA in the same change. The repository's Actions settings can enforce the rule, refusing any workflow that references another repository's action by anything but a full SHA; that setting is dashboard state, so turn it on when the repository is created.

`./.github/actions/setup` is deliberately not pinned. It is a path in this repository, already versioned by the commit under test.

For a hand upgrade, resolve the new SHA with `gh` and update the comment alongside it:

```sh
gh api repos/actions/checkout/commits/v7.0.1 --jq .sha
```

## Dependency updates

`.github/dependabot.yml` proposes weekly updates for the GitHub Actions, including the composite actions under `.github/actions/`, and for the stack's dependencies, as [Workspace](workspace.md#versions) describes. It moves an action's SHA and its version comment together, so a pin and its label cannot drift apart. Every update pull request is labelled `type:chore`.

The groups take minor and patch updates only, so a week is one grouped pull request per ecosystem and directory. Dependabot groups each listed directory on its own, so the workflows and `.github/actions/*` can each get one: two pull requests for the actions in one week is the configuration working, not a duplicate. A major update arrives as a pull request of its own: it is a decision that may need code changes, and inside a group it would hold the routine updates back until it is dealt with.

A dependency held back for a known breakage gets an `ignore` entry with the reason and the condition for removing it.

Renovate does the same job, and was rejected: it runs as a GitHub App with a configuration of its own, while Dependabot is built into GitHub and already raises the repository's security updates.

## Branch protection

The workflow reports; it does not block on its own. What blocks is a branch protection rule or a ruleset on `main`, repository settings no file here can enforce. A ruleset does the same job with more control, and either works if nobody can bypass it. The recommended configuration:

| Setting                | Value                                 |
| ---------------------- | ------------------------------------- |
| Required status checks | `Verify`, from the GitHub Actions app |
| Pull request required  | Yes                                   |
| Enforced for admins    | Yes, with no bypass actors            |
| Force pushes, deletion | Refused                               |

Binding the checks to the GitHub Actions app stops any other integration from reporting a passing check under the same name. Admin enforcement is what makes the rest hold: without it, a maintainer's direct push to `main` is stopped only by the `pre-push` hook, which `--no-verify` skips.

Turn on "Automatically delete head branches" in the repository's general settings too; it is available on every plan. Deleting a merged branch is what makes GitHub retarget a pull request built on it to that branch's own base. With the branch left behind, the next pull request merges into it and never reaches `main`.

<!-- The project's actual branch protection, if it differs from the recommendation above, and why: required reviews, extra required checks, up-to-date branches. -->

## Other workflows

The workflow above verifies; it does not deploy, release or publish. A project that does adds a workflow of its own and documents it here.

<!-- Release, publish, and deployment workflows, with their triggers and credentials, and what CI still does not cover. -->
