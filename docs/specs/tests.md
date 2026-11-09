---
status: APPROVED
last_updated: 2026-11-08
scope: Test categories, where each lives, and coverage expectations.
---

# Tests

This document defines how the project is tested: what kinds of tests exist, where they live, how they run, and what they are expected to cover. The conventions for writing an individual test are in the [coding guidelines](../guidelines/code.md#testing), and the runners, file names, configuration, and commands of the project's stack are in [stack tests](stack-tests.md).

## Principles

- **Test behavior, not implementation.** A test verifies what a caller can observe, not how the code produces it.
- **Fast and deterministic.** A flaky test is a bug. Time, randomness, and the network come from sources a test controls; a test that depends on real timing, the network, or a real window does not belong in the default suite.
- **Error paths count.** Failure cases are tested as carefully as the happy path, and inputs and edge cases early.
- **No permanent absence checks.** A test asserting only that a removed name, class, or token is gone (`not.toContain("old-name")`) verifies nothing about current behavior: it is indistinguishable from asserting the absence of a string that never existed. Such a check earns its place only while a rename or removal is in flight, as a guard against a forgotten reference; delete it once the change is verified, in the same pull request. A durable rule, such as "no compatibility aliases", is a lint rule or repository check, not a permanent unit test.

## Categories

| Category    | Where                                      | Runs                                     | Covers                                                                       |
| ----------- | ------------------------------------------ | ---------------------------------------- | ---------------------------------------------------------------------------- |
| Unit        | Next to the code it tests                  | With the default suite                   | One module, its boundaries replaced by fakes.                                |
| Integration | In the package or app it belongs to        | With the default suite                   | Several modules together, or a real boundary such as a database or a server. |
| Browser     | In the package or app, apart from its code | Apart from the default suite, on its own | Full user journeys, rendering, and visual regression in real browsers.       |

The default suite is what the gate's test step runs. Add a category only when the project has tests for it: an empty suite, or a script that passes without running anything, misleads more than a missing one.

Manual usage scenarios, such as a playground used during development, are outside these categories.

### Unit tests

- A test file is named after the file it covers, as [stack tests](stack-tests.md#runners-and-file-names) gives.
- What to mock, and what to test against real temporary state instead, is owned by the [coding guidelines](../guidelines/code.md#testing).
- Do not import test utilities across distant packages, except from a package or subpath that exists to share them.

### Integration tests

- Integration tests live inside the package or app they belong to. Do not add a repository-root `tests/` directory by default.
- When a journey or orchestration genuinely spans packages, a dedicated workspace package for those tests is allowed, rather than placing them in one of the packages they cross.

### Browser tests

- Browser suites are configured and run apart from the default suite, so the loop everyone runs constantly stays fast and needs no browser installed.
- A suite SHOULD cover every engine its users run, because catching what one engine does differently is what the suite is for.
- In CI, a failed browser test is retried once and a pass on the retry is reported as flaky, not as passed; locally it is not retried. [Stack tests](stack-tests.md#browser-suites) gives the setting and the evidence behind it.
- Add visual regression tests once a component has an agreed visual design, not for placeholder interfaces.

## Coverage

The coverage script writes a report, as [stack tests](stack-tests.md#coverage) describes. The suggested target is **80%**. It guides development and review; it is not a gate and never fails a build, because a coverage threshold that blocks merges gets satisfied with tests that execute lines without asserting anything.

## Not covered by automated tests

Behavior that no automated test reaches is listed here with how it is verified instead, usually by hand, and why a suite was not added. A gap that is written down can be judged; a gap nobody recorded is found by a user.

<!-- Project-specific categories and suites (for example conformance suites, a security suite, a second language's test runner), where they live, the gaps listed under "Not covered by automated tests", and per-area coverage targets. -->
