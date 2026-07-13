---
description: Setup and configure brain.md MCP connection (first-time setup wizard)
---

You are setting up a brain.md MCP connection for the user. Follow these steps in order.

If you are Claude Code and this skill was installed as a plugin (`/plugin install brain-md@...`), auth is already handled: the plugin prompted for the URL and token at install time via `userConfig` and wired the MCP server itself. Tell the user to run `/plugin configure brain-md@<marketplace>` to change those values instead, and stop here. Use the steps below only for opencode, or a manual (non-plugin) copy install of this skill.

## Step 1: Ask for the brain.md URL

Ask the user: "What is your brain.md instance URL? (e.g. `http://localhost:3000` or `https://brain.example.com`)"

Wait for their answer. Do not proceed until they provide a URL.

## Step 2: Probe the endpoint

Once you have the URL, run this to check if auth is required:

```bash
curl -s -o /dev/null -w "%{http_code}" "{URL}/mcp" -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"brain-md-setup","version":"1.0.0"}},"id":1}'
```

- If the response is `200`: No auth needed. Skip to Step 4.
- If the response is `401`: Auth is required. Proceed to Step 3.

## Step 3: Get credentials (only if 401)

Ask the user: "Your brain.md instance requires authentication. Which method do you want to use?"

Options:
1. **API key**: Ask them to paste it. (Long-lived, from Settings → Security → API Keys)
2. **Password**: Ask them to paste it, then get a session token:

```bash
curl -s -X POST "{URL}/api/auth/login" -H "content-type: application/json" -d '{"password":"THEIR_PASSWORD"}' | jq -r .token
```

If the token call fails, tell the user and ask them to check their password and URL.

## Step 4: Read the current config

Read the file `~/.config/opencode/opencode.jsonc` to see the current config.

## Step 5: Write the updated config

Update the `mcp` section of `~/.config/opencode/opencode.jsonc` with the brain.md connection.

If **no auth** (Step 2 returned 200), write:

```json
"mcp": {
  "brain": {
    "type": "remote",
    "url": "{URL}/mcp"
  }
}
```

If **API key auth**, write:

```json
"mcp": {
  "brain": {
    "type": "remote",
    "url": "{URL}/mcp",
    "headers": {
      "Authorization": "Bearer {API_KEY}"
    }
  }
}
```

If **password auth** (session token), write:

```json
"mcp": {
  "brain": {
    "type": "remote",
    "url": "{URL}/mcp",
    "headers": {
      "Authorization": "Bearer {SESSION_TOKEN}"
    }
  }
}
```

Use the Edit tool to update the file. Preserve all existing config. Only modify the `mcp` section. If there is no `mcp` section, add it after `$schema`.

## Step 6: Confirm

Tell the user:
- The config has been written
- They need to **restart opencode** for the MCP server to connect
- After restart, they can use brain.md tools (e.g. "list notes in my brain vault")

Do NOT attempt to use brain.md tools in this session. The MCP server is not connected until restart.
