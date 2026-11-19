---
type: architecture
status: done
created: 2026-11-01
area:
  - workspace
  - external-research
related_docs:
  - AGENTS.md
  - README.md
---

# Optional Exa research

Exa supplements external research; the workspace works without it. The policy is owned by `.agents/skills/exa-research/SKILL.md`, read at conversation startup to resolve preferences. Task lifecycle procedures and verification gates remain the source of completion evidence.

## Enable and disable

Research defaults to context-dependent `auto` mode. An actual MCP connection is still needed to make calls; the template does not install or connect a client automatically.

On first use, the agent asks how to use Exa: automatically without an account (recommended), automatically through an account with OAuth, or off. The question does not block work. Until answered, auto mode uses an existing connection if available and otherwise falls back to the ordinary workflow. The setup preference does not silently change an existing connection's access method.

After the answer, the agent saves the two non-secret settings in workspace-root `.exa-preferences`, which is gitignored. For example:

```text
mode: auto
access: keyless
```

Valid values are `auto`/`off` for mode and `keyless`/`oauth` for access. Saved settings avoid repeating the question in later conversations. Explicit choices already given in the conversation take precedence; do not ask again. A session-only override does not change the saved preference unless the user asks to remember it. Delete the local preference file to choose again at the next startup. No credentials are stored here.

- `Exa: auto` — let the agent use Exa when external information is relevant, for this conversation. This is the default unless saved settings say off.
- `Exa: off` — use the original workflow, including ordinary web tools when needed, for this conversation.
- `Use Exa to check this API's current limits` or `$exa-research` — use Exa for this request only, even if the mode was off.

Examples: auto mode may help check an unfamiliar SDK's compatibility. Renaming a local function, running tests, and closing a task normally need no Exa. Missing tools or service limits never require connecting Exa to finish ordinary work.

## Connect only when wanted

The inert examples in `_templates/exa/` expose only basic search and fetch. They do not load automatically, contain no credentials, and install no packages. Merge the relevant example into your client's configuration without overwriting existing settings; restart or reconnect the client afterward. Do not configure a second Exa connection if one already exists.

- Codex: merge `codex-config.toml` into the project's `.codex/config.toml` in a trusted workspace. `required = false` keeps server startup optional. For an independent code repo, configure the client in the root from which you work, or use an existing client-level connection.
- Claude Code: merge `claude-mcp.json` into the project `.mcp.json` and approve the server through the client if prompted.
- Other clients: add the same hosted MCP URL using the client's remote HTTP MCP settings.

The examples use keyless access. To use your Exa account's monthly free credits instead, replace the URL with:

```text
https://mcp.exa.ai/mcp?login&tools=web_search_exa,web_fetch_exa
```

Complete browser sign-in through the client. Authentication is managed by the client; do not copy keys or OAuth data into this template. No account connection or global client settings are changed by the template.

Shared skill discovery: the root Claude skill links to `.agents/skills/exa-research`; `bash scripts/link-workspace-skills.sh <repo>` also exposes it in independent repos. Re-run that helper for repos linked before this skill was added. Their template instructions already require reading parent workspace rules.

## Free access and fallback

Exa documents keyless search/fetch with free rate limits, separately from authenticated team usage with monthly free credits. These are different limits. Monthly credits and prices can change; consult the dashboard and official pricing instead of treating a local call count as a dollar balance.

Keep the account on free access without purchased credits or auto-recharge. The agent never buys credits or changes billing. Instructions and a three-call request budget reduce usage; they cannot enforce an account spending cap if paid billing is enabled elsewhere.

On a limit or service failure, the skill stops further Exa calls for the conversation and returns to local tools and the ordinary web tools. It does not switch access modes to bypass a limit. There is no monthly scheduler, balance polling, or persistent quota database; a newly enabled conversation can encounter the same limit and fall back again. If external verification is impossible through all available tools, report that specific gap.

## Sources

Checked 2026-11-01:

- [Exa MCP: connection, access modes, tool selection](https://exa.ai/docs/get-started/exa-mcp).
- [Exa pricing and free credits](https://exa.ai/docs/admin/pricing).
- [Codex MCP configuration](https://developers.openai.com/codex/mcp/).

## Acceptance scenarios

| Situation | Expected behavior |
|---|---|
| First conversation, no saved preference | Ask once without blocking work; default auto, existing connection or ordinary fallback |
| Later conversation with saved preference | Reuse mode/access choice without asking again |
| User selects OAuth, no account connection | Save preference; client sign-in is needed; continue ordinary work meanwhile |
| Auto mode, local refactor | Local tools; no Exa calls |
| Auto mode, unresolved public SDK question | Focused lookup, official sources, at most 3 Exa calls |
| Exa not connected | Immediate ordinary fallback; no installation prompt |
| Credits exhausted, 429, auth failure, or service failure | One brief notice; no further Exa calls in this conversation |
| Next user request after a limit | Keep using fallback unless user reports restored access and requests retry |
| Ordinary web tools also unavailable | Continue independent local work; identify unverifiable external facts |
| User says Exa off | Stop Exa use; preserve existing verification gates |
