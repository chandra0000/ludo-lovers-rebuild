# Security policy

The current `main` application is local-first. Private rooms, accounts, online
chat, wallets and authoritative hosting in draft PRs are not a released service.
Do not deploy those drafts as a secure multiplayer backend.

Report suspected vulnerabilities privately through this repository's GitHub
private vulnerability reporting option **if enabled**, or request a private
contact from the maintainer without posting exploit details, credentials or user
data in a public issue. No response SLA or enabled reporting setting is implied.
Include the exact revision, affected mode/platform, minimal reproduction and
impact. Use test accounts/data. Never include signing keys or service-role tokens.

## Maintainer controls

- Review dependency/security update PRs; no automatic merge or SDK upgrade.
- Workflows pin third-party actions by commit, use read-only default permissions,
  and do not persist checkout credentials. Dependabot proposes updates weekly.
- The Dependency security workflow checks exact hosted Pub versions against OSV.
  A failed/unreachable/incomplete scan is an error, never a clean result. SDK,
  native tooling, undisclosed vulnerabilities and runtime authorization are
  outside this scan. A clean advisory report is not production approval.
- Keep debug VM-service relaxations restricted to isolated QA runtimes.
- Treat saved local preferences as untrusted local state, never online identity,
  currency, authentication or authoritative remote match results.
- Before an online release, require authenticated membership/seat enforcement,
  server-owned dice/rules, atomic version/idempotency checks, least-privilege
  database grants/RLS, bounded request/upstream time, rate limits and abuse tests.
  Load, reconnect, session-revocation and privacy acceptance remain separate gates.
