---
status: APPROVED
last_updated: 2026-11-08
scope: Coding conventions for every part of the project, in any language.
---

# Coding guidelines

This document outlines the patterns, conventions, and guidelines to follow when working on this codebase. The [testing specification](../specs/tests.md) owns how tests are organized and run, and the [security guidelines](security.md) own how code keeps the project's security commitments. The [stack guidelines](stack.md) add the conventions of the project's languages and the tools that check them, such as casing and the format of API documentation.

## Naming

- Casing: each language's convention, which the [stack guidelines](stack.md#naming) name.
- Booleans: prefixed with is, has, can, or should (`isLoading`, `hasPermission`).
- Arrays: plural nouns (`users`, `items`).
- Functions: verb phrases (`calculateTotal`, `fetchUser`).

Name by domain intent. Avoid names that say only the type or the mechanism, such as `data`, `item`, `manager`, or `helper`, unless the scope makes the meaning obvious.

## Architecture and design

- Single responsibility: each function, class, and module does one thing well.
- High cohesion: logic that belongs together stays together.
- Loose coupling: minimize dependencies between modules.
- Prefer dependency injection to hard-coding. Whatever makes code hard to test or tied to one environment, such as the clock, randomness, the network, and storage, arrives as a dependency.
- Keep each package's public surface small and intentional.
- Keep dependency direction clear: shared code does not import app-specific code.
- Do not add compatibility layers unless there is a real consumer, persisted data, shipped behavior, or explicit requirement that needs one.
- Do not add a dependency unless simple in-house code is clearly worse.

<!-- Where the project's architecture is recorded (for example `docs/architecture.md`), its layout and dependency direction, runtime boundaries, and what code must do to cross them. -->

### Fix it upstream

When a dependency lacks something or gets it wrong, the fix goes upstream where the project can report it, and the project takes it from a release. A local workaround is temporary and names the issue it waits on, as [a defect found mid-task](../../CONTRIBUTING.md#a-defect-found-mid-task) describes. That holds for a third-party dependency as much as for one the project or its owner maintains; only the latter is fixed upstream by the project itself.

## Code

- Functions are small and clearly nameable.
- Avoid magic numbers and strings: extract a value to a named constant when it has domain meaning or is reused.
- Code should explain itself through its names.
- Design for predictable, deterministic behavior. Time and randomness come from an injected source, so a test controls them.
- Avoid god objects, feature envy, and long method chains.
- Prefer readable code to clever code.

Literal values MAY stay inline when extraction makes code worse, such as protocol literals, header names, package names, CSS selectors, event names, SQL, test fixtures, one-off validation messages, and external API values used once near their boundary.

Function parameters:

- 0–1 parameters: excellent.
- 2 parameters: acceptable.
- 3 or more: refactor into an options object.

Exceptions: framework callbacks, test helpers, tiny local functions, and APIs where an object parameter would hide meaning instead of improving it.

## Concurrency and errors

- Run independent asynchronous work concurrently. Waiting for each in turn needs a reason, given where the code does it.
- Do not swallow errors silently.
- Throw or return errors with enough context to debug them.
- Do not log secrets, tokens, credentials, or private user data.
- Logging is not a substitute for error handling.

## Inputs, failures, and state

Most review findings that hold up are about these, not about style: the [review study in codenhub/codenhub](https://github.com/codenhub/codenhub/blob/main/packages/skills/docs/internal/coding-skill-research.md) records the evidence.

- Validate input from outside the code's control after it is converted, against the limits of what consumes it: `--timeout 1e308` passes "positive number" and becomes an infinite timer. Reject empty, whitespace-only, NaN, Infinity, and partial numbers such as `10s`.
- When required input is missing or matches nothing, fail with a message naming it. A run whose required input was absent never reports success.
- Update in-memory state only after a write succeeds, and never swallow a write error.
- Apply a new option or fix to every path the same input or behavior flows through: each source of the value, sync and async variants, create and update, and every caller. Name any path left out, with the reason.
- A hand-written parser rejects syntax it does not support, naming the file and line, instead of reading it as data.
- Keep input order and any order a contract defines; sort output whose order is unspecified by a defined key with a tie-breaker.

## Testing

- Test behavior, edge cases, and error paths, not just the happy path.
- One behavior per test, named by the behavior it proves, as a sentence (`returns an empty list when the input is null`).
- Unit tests sit next to the code they test.
- Mock the network, timers, and browser APIs. Test code whose job is file or database access against a real temporary directory or database where practical, and mock them elsewhere. Pure logic is tested directly.
- Give each behavior decision a test that fails when the decision is reversed, and see a new test fail before keeping it.
- A test that writes files uses its own directory under the system temporary directory, never the package or the current directory, and removes it afterwards.
- Poll for a condition instead of sleeping a fixed time.
- Prefer observable behavior to implementation details.
- A change in behavior changes its tests in the same change.

Mocking the filesystem and storage everywhere was the earlier rule. It was narrowed because a mock answers only what the test tells it, so it cannot show the containment, symlink, and stale-output bugs recorded in codenhub/codenhub#24, codenhub/codenhub#25, and codenhub/codenhub#293; a real temporary directory does.

The [testing specification](../specs/tests.md) defines the test categories, configuration, scripts, and coverage target.

## Documentation in code

- Comments explain why, not what or how.
- Remove redundant comments, decorations, and outdated docs, in the change that makes them outdated.

Every symbol a published package exports is that package's API and MUST have API documentation in source, even when a README also documents it, in the format the [stack guidelines](stack.md) give. A private package's exports SHOULD have it too: their callers are the project's own code, which a reviewer can read, so a missing entry costs less there. The documentation describes the caller-facing purpose, important inputs, return values or side effects, and observable failure, including the states a caller must handle and the conditions under which it fails. It MUST NOT restate the type signature in prose or describe private implementation details. An example in it MUST be realistic and work against the current API.

When a change touches a package's exports or its observable behavior or failures, it updates the API documentation and every README or document describing them in the same change. Whether every export is documented, and how well, is a review responsibility unless the project enforces it, as the stack guidelines then record.

## Formatting, linting, and type checking

- Code MUST pass `{{verify}}`. [Workspace](../workspace.md) lists what it runs.
- Do not fight the formatter's output.
- Lint rules are enforceable project policy. Change the rule, or add a scoped override with its reason recorded, rather than ignoring it broadly. A local suppression comment says why it is there.

<!-- Conventions that hold across the project's languages and are not in the stack guidelines. A second language with its own naming, formatter, and linter goes in the stack guidelines. -->
