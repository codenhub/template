---
status: IMPLEMENTED
last_updated: 2026-11-08
scope: Index of the project documentation.
---

# Documentation

`docs/` holds durable project knowledge. [Contributing](../CONTRIBUTING.md) contains the contributor workflow, and [agent instructions](../AGENTS.md) contain how agents work here. The [documentation guidelines](guidelines/documentation.md) define how these documents are written, what their status means, and how they change.

Every document in `docs/` is listed here. Adding, moving, or deleting one updates this index in the same change.

<!--
Where a newcomer should start, and the project's overview documents, for example:

## Overview

| Document                        | Contains                                    |
| ------------------------------- | ------------------------------------------- |
| [Architecture](architecture.md) | What goes where and why. Start here.        |
| [Roadmap](roadmap.md)           | Current focus, what is planned, what is not. |
-->

## Guidelines

| Document                                     | Contains                                                                                         |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| [Brand](guidelines/brand.md)                 | The name, the voice, and the visual identity, and why each was chosen.                           |
| [Code](guidelines/code.md)                   | Naming, design, errors, inputs and state, testing practices, and documentation in code.          |
| [Documentation](guidelines/documentation.md) | Metadata, prompts, status and authority, recording decisions, exceptions, layout, and the voice. |
| [Stack](guidelines/stack.md)                 | The conventions of the project's languages and the tools that check them.                        |
| [Security](guidelines/security.md)           | Secrets, untrusted input, what stays out of logs, and reviewing a change.                        |

<!-- The project's own guidelines, as rows of the table above. Delete the Brand row when the project has no brand guidelines or keeps them elsewhere. -->

## Repository references

| Document                  | Contains                                                                                                                            |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| [Workspace](workspace.md) | The root scripts and what each guarantees, the shared tool configurations, the pinned toolchain, installs, and dependency versions. |
| [Tooling](tooling.md)     | Setup, how the scripts are implemented, the compiler and test runner configuration, narrowing a run, and adding a package.          |
| [CI](ci.md)               | The verification jobs, the setup action, action pinning, dependency updates, and branch protection.                                 |

<!-- The project's own references for one repository area or process (for example assets or releases), as a table with the same columns. -->

## Specifications

| Document                            | Contains                                                               |
| ----------------------------------- | ---------------------------------------------------------------------- |
| [Tests](specs/tests.md)             | Test categories, where each lives, and coverage.                       |
| [Stack tests](specs/stack-tests.md) | The stack's runners, file names, configuration, scripts, and commands. |

<!-- The project's own specifications, as a table with the same columns, and any further sections such as guides for the people who use or run what the project ships. -->
