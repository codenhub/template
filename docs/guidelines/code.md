---
status: APPROVED
last_updated: 2026-11-08
scope: Coding conventions for every package and app in the workspace.
---

# Coding guidelines

This document outlines the patterns, conventions, and guidelines to follow when working on this codebase. The [testing specification](../specs/tests.md) owns how tests are organized and run, and the [security guidelines](security.md) own how code keeps the project's security commitments.

## Naming

- Files and folders: kebab-case (`user-service.ts`, `api-routes/`).
- Variables and functions: camelCase (`getUserById`, `isValid`).
- Classes and types: PascalCase (`UserService`, `ApiResponse`).
- Constants and enums: UPPER_SNAKE_CASE (`MAX_RETRY_ATTEMPTS`).
- Booleans: prefixed with is, has, can, or should (`isLoading`, `hasPermission`).
- Arrays: plural nouns (`users`, `items`).
- Functions: verb phrases (`calculateTotal`, `fetchUser`).

Name by domain intent. Avoid names that say only the type or the mechanism, such as `data`, `item`, `manager`, or `helper`, unless the scope makes the meaning obvious.

## Architecture and design

- Single responsibility: each function, class, and module does one thing well.
- High cohesion: logic that belongs together stays together.
- Loose coupling: minimize dependencies between modules.
- Prefer dependency injection to hard-coding. Whatever makes code hard to test or tied to one environment, such as the clock, randomness, the network, and storage, arrives as a dependency.
- Group related files in a folder with an `index.ts` entrypoint.
- Keep each package's public surface small and intentional.
- Do not add compatibility layers unless there is a real consumer, persisted data, shipped behavior, or explicit requirement that needs one.
- Do not add a dependency unless simple in-house code is clearly worse.

<!-- project:start -->

<!-- Where the project's architecture is recorded (for example `docs/architecture.md`), its layout and dependency direction, runtime boundaries, and what code must do to cross them. -->

<!-- project:end -->

### Fix it upstream

When a dependency the project or its owner maintains lacks something or gets it wrong, the fix goes upstream, and the project takes it from a release. A local workaround is temporary and is marked with the upstream issue it waits on:

```ts
// Workaround for <owner>/<repo>#123: <what it works around>.
```

Searching for the issue reference then finds every workaround to remove once the fix ships. A third-party dependency gets the same treatment where the project reports the problem upstream.

## Code

- Functions are small and clearly nameable.
- Prefer `const` to `let`; never use `var`.
- Avoid magic numbers and strings: extract a value to a named constant when it has domain meaning or is reused.
- Code should explain itself through its names.
- Design for predictable, deterministic behavior. Time and randomness come from an injected source, so a test controls them.
- Avoid god objects, feature envy, and long method chains.
- Prefer readable code to clever code.

Literal values MAY stay inline when extraction makes code worse, such as protocol literals, header names, package names, CSS selectors, event names, SQL, test fixtures, one-off validation messages, and external API values used once near their boundary.

Function parameters:

- 0–1 parameters: excellent.
- 2 parameters: acceptable.
- 3 or more: refactor into a typed options object.

Exceptions: framework callbacks, test helpers, tiny local functions, and APIs where an object parameter would hide meaning instead of improving it.

## TypeScript

- Use strict TypeScript; `tsconfig.base.json` sets the flags.
- Prefer `unknown` to `any`. Validate `unknown` at the boundary before use.
- Prefer interfaces for object shapes and type aliases for unions and intersections.
- Use type-only imports when importing only types.
- Keep casts narrow and close to the boundary that justifies them.
- Do not export types or values that are not part of the package or module API.

## Modules and imports

- Prefer named exports, except where a tool or framework requires a default export, such as config files or framework routes.
- Use barrel files only as package or folder entrypoints.
- Do not deep-import another package's internals unless the subpath is part of its `exports`.
- Keep dependency direction clear: shared code does not import app-specific code.

## Async and errors

- Use `async`/`await` for asynchronous code.
- Run independent async work in parallel with `Promise.all()`. Sequential awaits in a loop need a reason, given in the comment on the lint suppression they require.
- Do not swallow errors silently.
- Throw or return errors with enough context to debug them.
- Do not log secrets, tokens, credentials, or private user data.
- `console` is for examples, CLIs, debugging utilities, entrypoints reporting startup failures, and deliberate diagnostics. Casual logging is not a substitute for error handling.

## Testing

- Test behavior, edge cases, and error paths, not just the happy path.
- One behavior per test, with a descriptive name (`shouldReturnEmptyWhenNull`).
- Unit tests sit next to the code they test.
- Mock only real boundaries, such as the network, storage, the filesystem, timers, and browser APIs. Pure logic is tested directly.
- Prefer observable behavior to implementation details.
- A change in behavior changes its tests in the same change.

The [testing specification](../specs/tests.md) defines the test categories, configuration, scripts, and coverage target.

## Documentation in code

- Comments explain why, not what or how.
- Remove redundant comments, decorations, and outdated docs, in the change that makes them outdated.

Every symbol exported from a package entrypoint, through `package.json` `exports`, is that package's API and MUST have TSDoc in source, even when a README also documents it. That includes functions, classes and their public members, interfaces, type aliases, constants, and configuration objects. The TSDoc describes the caller-facing purpose, important inputs, return values or side effects, and observable failure. It MUST NOT restate the type signature in prose or describe private implementation details. Specifically, it:

- Opens with a one-sentence summary of what the symbol does for the caller, in the present tense. Longer explanation goes in `@remarks`.
- Documents every parameter and type parameter with `@param` and `@typeParam`, giving intent and any constraint, unit, or accepted range rather than the type. A `@param` MAY be left out only when the name already fixes the meaning exactly.
- Documents the returned value with `@returns`, including the states a caller must handle, such as an empty collection, `null`, or a failed result. Leave it out for `void`.
- Gives one `@throws` per error type, with the condition that triggers it. A symbol that reports failure by return value instead says so where a reader would expect a throw.
- Gives `@defaultValue` to an optional parameter or property whose default a caller cannot infer.
- Carries `@deprecated` with the replacement and, when known, the version that removes it.
- Documents each public member of a class or interface with its own TSDoc. A bare member is an incomplete API.
- Prefers `{@link OtherSymbol}` to repeating another symbol's contract.

`@example` blocks are encouraged for any non-obvious usage; each MUST be realistic and compile against the current API.

An export needed only to compose entrypoints SHOULD stay out of public entrypoints. When one cannot, mark it `@internal`.

When a change touches a package's `exports`, its exported symbols, or its observable behavior or failures, it updates the TSDoc and every README or document describing them in the same change. oxlint checks the structure of the tags; whether every export is documented, and how well, is a review responsibility.

## Formatting, linting, and type checking

- Code MUST pass `pnpm verify`. [Tooling](../tooling.md) lists what it runs; while working, `pnpm format:check`, `pnpm lint:check`, and `pnpm typecheck` run its parts on their own.
- oxfmt formats code and JSON, and Prettier formats Markdown. Do not fight the formatter's output.
- Lint rules are enforceable project policy. Change the rule, or add a scoped override with its reason recorded, rather than ignoring it broadly. A local suppression comment says why it is there.

<!-- project:start -->

<!-- Conventions for the project's own languages, frameworks, and styling, for example a section per framework or a second language with its own naming, formatter, and linter. Leave empty when there are none. -->

<!-- project:end -->
