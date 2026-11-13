---
status: APPROVED
last_updated: 2026-11-13
scope: How code keeps the project's security commitments, for anyone writing or reviewing a change.
---

# Security guidelines

This document says how code handles secrets, untrusted input, and what leaves the process, so the same problem is solved the same way everywhere. Vulnerabilities are reported as [SECURITY.md](../../SECURITY.md) describes, never in a public issue.

<!-- What the project protects and from whom: its trust boundary in a sentence or two, and the document that states what must hold (for example an architecture document or a spec of security invariants). Say that where that document and this one disagree, that document wins and this one is fixed. -->

## Secrets

When the project stores or issues secrets:

- **Random values** for anything security-relevant come from the runtime's cryptographically secure generator, such as `crypto.getRandomValues` in JavaScript or `secrets` in Python, injected where code needs to be testable. Never a general-purpose generator such as `Math.random` or `random`.
- **High-entropy tokens** the project issues, such as session ids, one-time codes, reset tokens, and API keys, are stored as a digest, never as the value. A leaked database then holds nothing a client can present.
- **Passwords** go through a memory-hard key derivation function where the runtime allows, with the algorithm and parameters stored next to each hash so they can be upgraded on the next login.
- **Recoverable secrets**, ones the project must read back, are encrypted with an authenticated cipher, with a key id stored beside each ciphertext so the key can be rotated.
- **Comparisons** of a secret or digest against input are constant-time.
- **Showing a secret** happens once, in the response to the action that created it, and that response is never cached.
- **Secrets in the repository** do not exist. Configuration reads them from the environment or a secret store; examples use obvious placeholders.

## Never in logs, errors, or responses

- An error message names the field, never its value.
- An unexpected error reaches the caller as a generic failure. Its detail goes only to the log, which redacts known secret-bearing fields.
- URLs can carry codes and tokens in their query strings. Log the path, not the full URL.
- Page content, form values, and anything a user typed stay out of logs.
- Where a leak would matter, a test proves it: it feeds known secrets through the flow and asserts they never appear in what was logged, returned, or stored.

## Untrusted input

- Every input crossing a trust boundary is validated at that boundary, before any other code sees it, and parsed into a typed value. What does not parse is rejected, not passed along.
- Every input has a size bound, such as a request body, an uploaded file, or a file read from disk, and every string and collection in a schema has a maximum. The read itself enforces the bound: an input of exactly the limit is accepted, and once the read finds more than the limit, it stops and the input is rejected, never truncated and parsed as if it were whole. Reading at most `limit + 1` bytes and rejecting when the extra byte exists is enough; a reader that works in chunks of a fixed maximum size can stop at the first chunk that crosses the limit, but not one that takes chunks of any size a stream hands it. Checking the size after reading the whole input is too late, because the memory is already used. A size check before the read can reject an input early, but it is not the bound, because another program can grow a file between the check and the read.
- Files a user can edit by hand, such as settings, sessions, and caches, are untrusted input too. A file that does not parse is set aside and replaced with defaults, and every value read from one is checked as if it came from a request. A file over its size bound counts as one that does not parse: the read stops at the bound as it does for any input, and the file is set aside and replaced with defaults rather than stopping the program.
- Do not build URLs, paths, or redirects from values a client controls, such as the `Host` or `X-Forwarded-*` headers. A redirect target comes from an allowlist and is compared exactly.
- Do not build a query, command, or HTML by concatenating input. Use parameters, argument arrays, and escaping by default.

## Web responses and sessions

When the project serves web requests:

- Every response goes through one place that sets the security headers, including a Content Security Policy. A route never loosens them.
- No inline script, unless it carries a per-response nonce.
- Authenticated pages and every response holding a secret are not cached.
- Session cookies are `HttpOnly`, `Secure`, and `SameSite=Lax` or stricter, and `__Host-` prefixed where possible.
- Every state-changing request uses a non-GET method and is protected against cross-site request forgery.
- Every authorization check runs on the server, declared where the route is defined, before the handler runs.

## Outbound calls and dependencies

- The project calls only services it needs for the feature at hand, or that its operator configured. No telemetry, update checks, or third-party lookups without a recorded decision and, where users are affected, a way to turn them off.
- Every dependency is a trust decision. The rule in [Coding guidelines](code.md#architecture-and-design) on adding dependencies applies with extra force to anything that runs at install time or handles secrets.

<!-- Domain rules: how this project's own boundaries are kept in code, one section per concern (for example permissions and capabilities, IPC commands, injected scripts, sessions, audit entries). Link each rule to the spec or test that enforces it. -->

## Reviewing a change

A change that touches any of the above names it in its pull request and adds or updates its tests. The [pull request template](../../.github/pull_request_template.md) carries the check. Ask:

- Does it add a way for untrusted input to reach the code? Is that input validated and bounded at the boundary?
- Does a secret, token, user's data, or full URL now reach a log, error, or response, other than the one that shows a new secret to its creator?
- Does it store a secret, and is it stored as a digest or encrypted as above?
- Does it add a permission, capability, endpoint, or outbound call? Is that named in the pull request and tested?
- Does it read a file a user can edit, and check what it reads?

<!-- Review questions specific to this project's boundaries. -->
