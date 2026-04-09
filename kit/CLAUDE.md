# Exocortex Kit — AI Instructions

This file ships with the Exocortex Kit from functionalmultiplicity.com. It tells Claude Code how to maintain itself.

## MCP Server Health Check — Startup Protocol

On the **first user message of each session**, before responding to the user's request, silently run the MCP Audit Protocol below. Do not ask permission — just do it. Only interrupt the user if action is needed.

### Frequency

Check the timestamp in `~/.exocortex-kit/last_audit`. If the file exists and is less than 24 hours old, skip the audit entirely and respond to the user normally. If missing or stale, run the audit and update the timestamp when done.

### MCP Audit Protocol

For each MCP server listed in `~/.exocortex-kit/manifest.json`:

1. **Version check**: Run `npm view <package> version` (for npm packages) or `pip index versions <package>` (for Python packages). Compare to the version pinned in the manifest.
   - Patch/minor update available → note it, no action yet.
   - Major version bump → flag to user after responding to their request.

2. **Security check**: Run `npm audit --json` in the package directory if applicable. If any **high or critical** severity vulnerabilities are found, warn the user immediately before doing anything else.

3. **Staleness check**: Run `npm view <package> time --json` and check the `modified` date. If the package has not been updated in 12+ months, flag it as potentially abandoned.

4. **Start test**: For servers configured with a `command` in the config, attempt to start the process and confirm it exits cleanly or produces expected output within 5 seconds. If it fails to start, flag it.

### Reporting

- **No issues found**: Say nothing. Respond to the user's request normally.
- **Updates available (non-urgent)**: After responding to the user's request, append a single line: `[Kit] Updates available for N server(s). Say "update kit" to review.`
- **Security issue found**: Before responding to the user's request, warn: `[Kit] Security advisory: <package> has a known vulnerability (severity). Recommend disabling until patched. Say "show details" for more.`
- **Server won't start**: `[Kit] <server-name> failed to start. It may need reinstalling or has been removed upstream. Say "fix kit" to troubleshoot.`

### User Commands

When the user says any of the following, act accordingly:

- **"update kit"** — Show a table of available updates (package, current version, latest version, change type). Ask which to apply. Update the manifest after applying.
- **"fix kit"** — Diagnose broken servers. Try reinstalling. If the package no longer exists on npm/PyPI, search for a replacement and suggest it.
- **"kit status"** — Run the full audit immediately regardless of debounce, and report all findings.
- **"check [server-name] security"** — WebSearch for recent CVEs, security advisories, or incident reports for that specific MCP server. Report what you find.

### Self-Healing

If a server fails the start test:
1. Check if the package is still published on its registry.
2. If yes, attempt `npm install` / `pip install` to refresh.
3. If no (package yanked/removed), disable it in the config and notify the user.

Do not silently remove servers. Always tell the user what changed and why.

### Manifest Format

`~/.exocortex-kit/manifest.json` looks like this:

```json
{
  "version": "1.0.0",
  "servers": {
    "memory": {
      "package": "@anthropic/mcp-memory",
      "registry": "npm",
      "pinned_version": "1.2.0",
      "required": true
    },
    "garmin": {
      "package": "garmin-mcp",
      "registry": "npm",
      "pinned_version": "0.9.1",
      "required": false
    }
  }
}
```

- `required: true` servers get auto-healed. `required: false` servers get flagged but not auto-fixed.
- The manifest is the source of truth for what the kit manages. Servers the user adds manually outside the manifest are not touched.
