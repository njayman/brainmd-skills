---
name: brain-md
description: >
  Use when working with brain.md vault instances via MCP: reading, writing,
  searching notes, managing tasks, or authenticating with remote brain.md
  servers. Covers all MCP tools, auth flows (API keys, OAuth 2.1, session
  tokens), error handling, and multi-vault patterns. Trigger on mentions of
  brain.md, brain vault, notes search, note MCP, or knowledge vault.
license: MIT
metadata:
  author: njayman
  version: "1.1.0"
  category: knowledge-management
  protocol: mcp
---

# brain.md MCP Skill

Teaches agents how to authenticate with and use brain.md vault instances via MCP.

## Quick Setup

### Claude Code (plugin install, recommended)

```
/plugin marketplace add njayman/brainmd-skills
/plugin install brain-md@brain-md-marketplace
```

Claude Code prompts for your brain.md URL and, optionally, an API key or session token. The plugin wires the MCP connection itself: no config file editing, no restart-and-hope. To change the URL or token later, run `/plugin configure brain-md@brain-md-marketplace`.

### opencode

Run `/brain-md` for an interactive wizard: it probes your instance, detects whether auth is required, and writes the MCP config to `opencode.jsonc`. Restart opencode after.

### Manual Setup (any other agent)

The brain.md MCP server exposes a single endpoint: `POST /mcp`. Transport is streamable HTTP (2024-11-05 spec), stateless JSON-RPC per request.

Any agent that supports MCP with streamable HTTP transport works. Set:
- **Endpoint:** `https://YOUR-BRAIN-INSTANCE/mcp`
- **Auth header (if required):** `Authorization: Bearer YOUR_API_KEY`

For a project-local Claude Code `.mcp.json` instead of the plugin, use:

```json
{
  "mcpServers": {
    "brain": {
      "type": "streamable-http",
      "url": "https://YOUR-BRAIN-INSTANCE/mcp",
      "headers": {
        "Authorization": "Bearer YOUR_API_KEY"
      }
    }
  }
}
```

## Authentication

### Detecting Auth

A 401 response with `WWW-Authenticate` header means auth is required. Discover the auth server:

```
GET /.well-known/oauth-protected-resource
```

### API Keys (Recommended)

Long-lived, named, no expiry. Generated in the brain.md web UI: Settings → Security → API Keys → Generate. Token shown once at creation.

### Session Tokens

24-hour TTL, created via login:

```bash
curl -X POST https://brain.example.com/api/auth/login \
  -H 'content-type: application/json' \
  -d '{"password":"YOUR_PASSWORD"}' | jq -r .token
```

Session tokens are persisted to `/.brain/tokens.json` since v0.4.2. Use `scripts/get-session-token.sh` for a helper.

### OAuth 2.1

Full MCP authorization spec (2025-11-25). PKCE S256 mandatory. For Claude.ai web connectors. See [references/auth.md](references/auth.md) for details.

## MCP Tools

### Read/Search

| Tool | Key Params | Description |
|------|-----------|-------------|
| `search_notes` | `query`, `scope?` | Full-text search, optional folder filter |
| `similar_notes` | `query`, `k?` | Semantic/vector search via RAG |
| `read_note` | `path` | Read note content + mtime |
| `list_notes` | `folder?` | List all notes/folders |

### Knowledge Graph

| Tool | Key Params | Description |
|------|-----------|-------------|
| `get_backlinks` | `path` | Backlinks for a note |
| `find_related` | `path`, `k?`, `scope?` | Semantically close notes |
| `semantic_outline` | `path` | Cluster chunks into topical groups |
| `compare_notes` | `path_a`, `path_b` | Similarity score + diff + shared headings |

### Tasks

| Tool | Key Params | Description |
|------|-----------|-------------|
| `get_tasks` | `filter?` | Aggregate tasks (open/done/all) |
| `find_similar_tasks` | `query` | Semantic search across task lines |

### Write

| Tool | Key Params | Description |
|------|-----------|-------------|
| `write_note` | `path`, `content` | Create or overwrite note |
| `append_note` | `path`, `content` | Append paragraph with blank-line separator |

### Context

| Tool | Key Params | Description |
|------|-----------|-------------|
| `context_for_query` | `query`, `budget_tokens?` | Pack top-relevant chunks under token budget |
| `find_orphans` | `min_isolation?` | Notes with zero backlinks + low neighbors |
| `weekly_digest` | `since?` | Topic clusters from recent modifications |
| `list_tags` | none | All tags with usage counts |
| `current_datetime` | none | Server's current date/time/timezone |

For full tool schemas and examples, see [references/tools.md](references/tools.md).

## Token Efficiency

`write_note` overwrites the whole file — no server-side patch tool exists yet. For a large note, every edit round-trips the entire content twice (once in via `read_note`, once out via `write_note`), even for a one-line change. To keep this cheap:

- Don't restate the note's full content in your response text before calling `write_note`/`append_note` — that duplicates the payload (once as prose, once as the tool arg) for no reason. Call the tool directly.
- Use `append_note` instead of `write_note` whenever the change is purely additive (new entry, closed-out task, journal line) — it skips the read-modify-write round trip entirely.
- **Checklists don't qualify as append-only.** Ticking a checkbox or editing an existing bullet is a modification, not an addition — `append_note` can't do it, so any note with checkboxes you expect to toggle will keep needing full `write_note` round-trips for its entire lifetime, no matter how you write to it initially.
- **Size is a signal, not just an outcome.** If `read_note` returns something in the tens of KB and you're about to send the same size back via `write_note` for a one-line change, that's the moment to split — not after it's grown further. Waiting until a note is "too big" means paying the round-trip cost every single edit until you finally do the split.

### Pattern: hot/cold note split

A note that both grows over time *and* needs existing lines edited in place (a project tracker, a running status log with checkboxes) will always be expensive under a full-overwrite-only write tool. Instead of one note that gets fully resent on every touch, split by how each part changes:

- **Hot note** (small, edited often): current status only — a short table or a handful of lines that get overwritten frequently. Cheap to round-trip because it stays small by construction.
- **Cold notes** (append-only, one per phase/entry/day): the detailed narrative — what happened, why, code-level specifics. Write once with `append_note` (or `write_note` on creation) and never touch again once that phase/entry is closed.
- **Checklist notes** (isolated, edited in place but rarely grow): keep QA/todo checklists in their own note, separate from the hot status note and the cold log. Toggling a box still costs a full round-trip, but at least it's the checklist's size being resent, not the entire log dragged along with it.

Link them with `[[wikilinks]]` from the hot note rather than inlining everything in one file. This is the difference between re-sending a few hundred bytes on every status update versus re-sending an ever-growing multi-KB file every time, which is what happens if status, log, and checklist all live in one note that keeps getting appended to and then re-overwritten.

## Common Workflows

**Research:** `search_notes` → `similar_notes` → `read_note` → `write_note`

**Tasks:** `get_tasks(filter: "open")` → work → `write_note` or `append_note`

**Knowledge graph:** `get_backlinks` → `find_related` → `compare_notes`

**RAG injection:** `context_for_query(query, budget_tokens: 4000)` → inject into prompt

**Daily digest:** `weekly_digest(since: "24h")` + `get_tasks(filter: "open")` → summary

**Orphan cleanup:** `find_orphans(min_isolation: 0.7)` → review → act

## Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| `401 Unauthorized` | No auth or expired token | Re-authenticate |
| `401` after restart | In-memory tokens cleared | Use API keys (persisted) |
| `404` | Note path doesn't exist | Use `list_notes` to find path |
| Rate limit | Too many requests | Add delay between calls |

**Token TTLs:**
- Session tokens (V53): 24h
- API keys (V66): no expiry
- OAuth access tokens (V63): 24h (refresh: 7d)

## Multi-Instance

Multiple vaults work by naming each MCP server distinctly:

```json
{
  "mcp": {
    "brain-personal": {
      "type": "remote",
      "url": "https://brain.zero.party/mcp",
      "headers": { "Authorization": "Bearer {env:BRAIN_PERSONAL_KEY}" }
    },
    "brain-work": {
      "type": "remote",
      "url": "https://brain.work.example.com/mcp",
      "headers": { "Authorization": "Bearer {env:BRAIN_WORK_KEY}" }
    }
  }
}
```

Use `scope` param in `search_notes` and `find_related` to limit searches to specific folders.

## References

- [Tool Reference](references/tools.md): full schemas, params, and examples for all 16+ tools
- [Authentication](references/auth.md): OAuth 2.1 flow, token management, multi-instance auth
- [Error Reference](references/errors.md): detailed error codes and recovery procedures

## Related

- brain.md GitHub: [github.com/mi4uu/brain.md](https://github.com/mi4uu/brain.md)
- MCP spec: [spec.modelcontextprotocol.io](https://spec.modelcontextprotocol.io)
- Agent Skills: [agentskills.io](https://agentskills.io)
