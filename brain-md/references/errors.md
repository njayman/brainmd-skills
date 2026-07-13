# Error Reference

Detailed error codes and recovery procedures for brain.md MCP.

## HTTP Errors

### 401 Unauthorized

**Causes:**
- No auth header provided
- Expired session token (V53)
- Revoked API key
- Malformed token

**Recovery:**
1. Check if auth is required: a 401 with `WWW-Authenticate` header confirms it
2. If using session tokens, re-authenticate via `POST /api/auth/login`
3. If using API keys, verify the key is valid in Settings → Security → API Keys
4. If using OAuth, attempt token refresh via the refresh token

**Prevention:** Use API keys (V66) instead of session tokens for long-lived integrations.

### 404 Not Found

**Causes:**
- Note path doesn't exist
- Typo in path
- Case sensitivity (paths are case-sensitive)
- Note was deleted

**Recovery:**
1. Use `list_notes` to discover available paths
2. Use `search_notes` to find the correct note
3. Check for trailing/leading whitespace in path strings

### 429 Rate Limited

**Causes:**
- Too many requests in a short window
- Bulk operations hitting rate limits

**Recovery:**
1. Add delays between sequential calls (500ms-1s recommended)
2. Batch operations where possible
3. Use `context_for_query` instead of multiple `read_note` calls

### 500 Internal Server Error

**Causes:**
- brain.md server issue
- Database corruption
- Resource exhaustion

**Recovery:**
1. Retry once after a short delay
2. Check brain.md server health/logs
3. If persistent, check the brain.md GitHub issues

## MCP-Specific Errors

### Transport Errors

| Error | Meaning | Fix |
|-------|---------|-----|
| `MCP-32600` | Parse error | Check JSON-RPC formatting |
| `MCP-32601` | Method not found | Tool name may be wrong |
| `MCP-32602` | Invalid params | Check tool parameter schema |
| `MCP-32603` | Internal error | Server-side issue, retry later |

### Connection Errors

| Error | Meaning | Fix |
|-------|---------|-----|
| `ECONNREFUSED` | Server not running | Start brain.md instance |
| `ETIMEDOUT` | Server too slow | Check network, increase timeout |
| `ECONNRESET` | Connection dropped | Retry, check server health |

## Token Recovery

### Session Token Expired

```bash
# Re-authenticate
curl -X POST https://brain.example.com/api/auth/login \
  -H 'content-type: application/json' \
  -d '{"password":"YOUR_PASSWORD"}' | jq -r .token
```

### OAuth Token Refresh

```bash
curl -X POST https://brain.example.com/oauth/token \
  -H 'content-type: application/json' \
  -d '{
    "grant_type": "refresh_token",
    "refresh_token": "YOUR_REFRESH_TOKEN",
    "client_id": "YOUR_CLIENT_ID"
  }'
```

## Gotchas

- Session tokens (V53) are in-memory by default. Pre-v0.4.2: lost on server restart. v0.4.2+: persisted to `/.brain/tokens.json`.
- API key names are visible in the UI. Use descriptive names for auditability.
- OAuth access tokens expire in 24h. The refresh token lasts 7d. If both expire, re-register the client.
- `list_notes` returns folders too. Filter by type if you only want notes.
- `search_notes` is full-text, not semantic. Use `similar_notes` for semantic search.
- `context_for_query` may return chunks from multiple notes. Check the source path in each chunk.
- Paths are case-sensitive. `Notes/Foo.md` and `notes/foo.md` are different notes.
