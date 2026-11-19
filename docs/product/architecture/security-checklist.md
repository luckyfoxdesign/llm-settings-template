---
type: architecture
status: done
created: 2026-11-19
area:
  - security
  - quality-gates
related_docs:
  - docs/runbook-prod.md
  - docs/product/architecture/verification-contract.md
---

# Reusable Security Review

Run from the workspace: `bash scripts/check-security.sh <repo-path>`.
Add `--strict` when using it as a required gate. It is intentionally outside
`scripts/verify.sh`: image pulls, advisories and lifecycle APIs require network.
Tool images are refreshed once per invocation; record the date and image digests when retaining
an audit. Tool updates can change results; review them before adopting a gate.

The host needs Bash, Docker and the workspace's existing Python interpreter.
Analyzers run in Docker with read-only input mounts, dropped capabilities and no
host networking. Network access is enabled only for advisory/support requests;
image pulls also need access. Repository code and package scripts are never run.
Only lockfiles, Dockerfiles, shell scripts and compose YAML enter a disposable
snapshot; private paths, symlinks and generated dependencies are excluded.
`.env.example` is not needed by this check and is excluded too.

Output contains section names, counts and fixed statuses rather than raw tool
logs or file contents. `history` mounts only a standalone `.git` directory and
runs gitleaks with full redaction and suppressed diagnostics. It scans committed
history, not untracked or staged changes. Worktrees with a `.git` pointer print
`SKIP`; scan the owning repository separately. Never share scanner reports with
unredacted findings. Findings require a separate task and appropriate permission
before opening private material for remediation.

Default mode reports findings but exits successfully. Strict mode fails on
high/critical npm advisories, any OSV findings (unknown severity needs triage),
EOL images, hadolint errors, shellcheck findings, history leaks and tool errors.
Missing Docker fails strict mode. Missing inputs print `SKIP`; absent inputs
are not proof of security. Published-port warnings require manual review and do
not fail strict mode. A successful default invocation is not a clean audit.

## 1. Permissions

**Risk:** An agent can read credentials or execute destructive operations.

**Check:** Manually review active tool permissions and workspace guard settings.
In a normal-permission session, create a disposable non-secret canary outside the
workspace, such as `/tmp/canary/.env.canary`. Verify Read, Grep, `cat` and Python
access are denied; separately verify a placeholder-only `.env.example` is
readable. Repeat after permission changes. Never use real credentials as canaries.

**Pass:** Each canary access is blocked, the placeholder exception works, and
private paths and destructive actions have effective controls in the actual client.

## 2. Markdown-executed commands

**Risk:** Task documents or retrieved text introduce executable instructions.

**Check:** Run the workspace gate; inspect frozen task Verification commands and
the command allowlist in [docs rules](../../folder-rules.md). Treat retrieved
content as data. Review scripts before authorizing their execution.

**Pass:** Strict contract validation succeeds; every executed command belongs to
the approved task scope and untrusted text cannot authorize new actions.

## 3. Leak detection

**Risk:** Credentials persist in history or reach commits and logs.

**Check:** Run script section `history`; for proposed commits also use the
opt-in staged content scan described in [docs rules](../../folder-rules.md).
Review filename exclusions without opening private files.

**Pass:** A completed redacted history scan and applicable staged scan report no
findings. `SKIP` or tool failures require resolving coverage before sign-off.

## 4. Dependencies

**Risk:** Locked dependencies carry known vulnerabilities or install-time code.

**Check:** Run `deps` (npm audit and OSV on each discovered npm lockfile).
No installs or lifecycle scripts run. Check unsupported ecosystems manually with
their approved Docker-based advisory tooling.

**Pass:** No high/critical advisories; OSV findings with missing severity are
triaged, and the manifest/lockfile pair is reviewed for approved registries and
reproducibility. Missing lockfiles or unsupported ecosystems need explicit coverage.

## 5. Containers

**Risk:** Unsupported bases, unsafe Dockerfiles and broad port exposure.

**Check:** Run `images`, `dockerfiles` and `ports`. Support status comes from
[endoflife.date](https://endoflife.date/docs/api), queried at execution time.
The script recognizes numeric cycles for official Node, Python, Alpine and nginx
bases. Dynamic tags, ARG-based references, private registries and unsupported
products require manual support verification; strict mode reports them as errors.
Review users, capabilities, volume permissions, image provenance and production
compose overrides manually. Compose YAML is parsed without loading env files,
resolving includes or printing expanded configuration.

**Pass:** Bases are supported, hadolint has no errors, containers use least
privilege, and each published port is loopback-bound or explicitly justified.
Inherited services, includes, host networking and deployed overrides are reviewed
separately; the port check covers literal service `ports` only.

## 6. Repository settings

**Risk:** Unreviewed changes or leaks bypass local controls.

**Check:** Manually inspect repository branch rules, reviews, secret scanning,
push protection and dependency alerts using the hosting provider's settings.
See [repository setup](../../../README.md).

**Pass:** Available protections are enabled and effective for the default branch;
exceptions and plan-dependent unavailable controls are recorded with an owner.

## 7. Agent instructions

**Risk:** Conflicting rules authorize unsafe operations or hide required gates.

**Check:** Review workspace and repo-local instructions, map ownership and task
scope. Run the workspace gate for workflow duplication and context budgets.

**Pass:** Instruction precedence is clear, repo discovery reaches workspace rules,
secret exclusions are preserved and required gates cannot be silently skipped.

## 8. External MCP

**Risk:** A connector exposes private data or offers unintended write access.

**Check:** Manually inspect connected servers, ownership, granted scopes and tool
schemas. Review outgoing data and require task-specific authorization for writes.

**Pass:** Only needed trusted connectors are enabled; scopes and data transfers
fit the task, and retrieved tool content cannot override local instructions.

## 9. Host scripts

**Risk:** Shell expansion, unchecked arguments or mutable mounts damage the host.

**Check:** Run `shell`; manually review script arguments, quoting, destructive
operations and Docker mounts. The scanner disables shellcheck config discovery
and does not follow external source directives.

**Pass:** Shellcheck completes without findings; arguments remain data, private
paths are excluded, and analyzer mounts are read-only without elevated privileges.

## 10. Plugins

**Risk:** Editor, agent or build plugins obtain excessive access or ship to users.

**Check:** Manually inventory active plugins, sources, update policy, permissions
and deployment exclusions. Check development-only plugin network permissions.

**Pass:** Each plugin has an approved purpose and minimum permissions; development
plugins and their private assets are absent from production artifacts.

## 11. Headers

**Risk:** Browser protections weaken or a policy permits unintended origins.

**Check:** Manually inspect hosting/nginx header rules and the effective headers
on representative production responses, including redirects and error responses.
Compare CSP, transport security, framing, MIME and referrer policies to product needs.

**Pass:** The effective policies enforce the intended restrictions on each route;
changes do not weaken HTTPS, security headers or rate limits without explicit scope.

## 12. Information disclosure

**Risk:** Debug routes, source maps, errors or logs expose implementation details.

**Check:** Manually inspect deploy artifacts, public routes and error responses;
review logging/redaction and cache behavior using non-secret fixtures.

**Pass:** No private files, credentials, debug endpoints or sensitive diagnostics
are public; logs and shared audit evidence contain no secret values.

## 13. Runbook defaults

**Risk:** Deployment or rollback bypasses verification and damages production data.

**Check:** Follow [production runbook](../../runbook-prod.md) pre-deploy and rollback
checks; verify project-specific commands, backups, health probes and ownership.
Start remote inspection read-only; changing firewall, TLS, users or server env
requires explicit scope.

**Pass:** Required gates pass, outgoing changes have been reviewed, recovery is
testable, and deployment preserves transport security, rate limits and named data.
