# Authentication Reference

Detailed auth flows for brain.md MCP connections.

## Auth Methods

### API Keys (V66, Recommended)

- Long-lived, no expiry (unless set at creation)
- Named keys for auditability
- Persisted to `/.brain/api-keys.json`
- Generated via web UI only: Settings → Security → API Keys → Generate
- Token shown ONCE at creation: copy it immediately

Best for: MCP clients, CI/CD, automated workflows.

### Session Tokens (V53)

- 24-hour TTL
- Created via `POST /api/auth/login`
- Persisted to `/.brain/tokens.json` since v0.4.2 (survives restarts)
- Previously in-memory only (pre-v0.4.2: lost on restart)

Best for: Web UI sessions, short-lived scripts.

### OAuth 2.1 (V63)

Full MCP authorization spec (2025-11-25):

- PKCE S256 mandatory
- Dynamic Client Registration (RFC 7591)
- Audience-bound access tokens (RFC 8707)
- Refresh-token rotation: 24h access, 7d refresh

Best for: Claude.ai web connectors, third-party integrations.

## Getting a Token

### API Key

Use the brain.md web UI:
1. Open your brain.md instance
2. Go to Settings → Security → API Keys
3. Click Generate
4. Copy the token (shown once)

### Session Token

```bash
curl -X POST https://brain.example.com/api/auth/login \
  -H 'content-type: application/json' \
  -d '{"password":"YOUR_PASSWORD"}' | jq -r .token
```

Or use the helper script: `scripts/get-session-token.sh`

## Detecting Auth Requirement

When a request returns 401:

```json
{
  "status": 401,
  "headers": {
    "WWW-Authenticate": "Bearer realm=\"brain.md\", resource_metadata=\"/.well-known/oauth-protected-resource\""
  }
}
```

Fetch the resource metadata to discover the auth server:

```bash
curl https://brain.example.com/.well-known/oauth-protected-resource
```

## Token TTL Reference

| Method | TTL | Persisted | Recovery |
|--------|-----|-----------|----------|
| API key (V66) | No expiry | Yes | N/A |
| Session token (V53) | 24h | Yes (v0.4.2+) | Re-login |
| OAuth access (V63) | 24h | Yes | Refresh token (7d) |

## opencode Configuration

Use `{env:VAR}` interpolation for secrets:

```json
{
  "mcp": {
    "brain": {
      "type": "remote",
      "url": "https://brain.example.com/mcp",
      "headers": {
        "Authorization": "Bearer {env:BRAIN_API_KEY}"
      }
    }
  }
}
```

Set the env var: `export BRAIN_API_KEY=your_key_here`

## Claude Code Configuration

Claude Code reads `.mcp.json` from the project root:

```json
{
  "mcpServers": {
    "brain": {
      "type": "streamable-http",
      "url": "https://brain.example.com/mcp",
      "headers": {
        "Authorization": "Bearer YOUR_API_KEY"
      }
    }
  }
}
```

For project-local config, add `.mcp.json` to `.gitignore`.
