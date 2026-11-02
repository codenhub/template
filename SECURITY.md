# Security

## Reporting a vulnerability

<!-- GitHub's private vulnerability reporting exists only on public repositories, and only once it is enabled in the repository's security settings. A private repository has no such page, so the link below would lead nowhere: say instead where a report goes, such as an issue labelled `type:security`, since only the project's own people can read one, and drop the contact link from `.github/ISSUE_TEMPLATE/config.yml`. -->

Report it privately through [GitHub's private vulnerability reporting](https://github.com/{{owner}}/{{slug}}/security/advisories/new), not in a public issue. Include the version or commit you found it in, the impact, and the smallest reproduction you have. Remove secrets, tokens, and personal data from anything you paste.

A report is acknowledged on GitHub, and the advisory stays private until a fixed version is released.

A vulnerability in a dependency that {{name}} uses goes to that dependency's maintainers. If you are not sure which side it is on, report it here.

## What is in scope

A way to make {{name}} break a guarantee its documentation makes is a vulnerability. [The security guidelines](docs/guidelines/security.md) describe the rules every change follows.

## Supported versions

{{name}} has no releases yet. Fixes land on `main`.
