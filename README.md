# {{name}}

{{description}}

## Repository

A pnpm workspace:

- `apps/`: the applications.
- `packages/`: the workspace packages, published as `@{{scope}}/<name>` when they are published at all.
- `docs/`: the guidelines, specifications, and references the code follows.

## Development

```sh
nvm use
pnpm install
pnpm verify
```

`pnpm verify` runs formatting, linting, the build, type checking, and tests. [Tooling](docs/tooling.md) describes every script.

## Documentation

- [Contributing](CONTRIBUTING.md): setup, branches, commits, validation, pull requests, and releases.
- [Agent instructions](AGENTS.md): how AI agents work in this repository.
- [Documentation](docs/README.md): the guidelines, specifications, and references.
- [Security](SECURITY.md): how to report a vulnerability.

## License

[Apache-2.0](LICENSE).
