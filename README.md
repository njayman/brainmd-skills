# brain-md Agent Skill

A skill that teaches AI agents how to use brain.md vault instances via MCP. Works with any Agent Skills-compatible agent.

## What It Does

- Authenticate with brain.md instances (API keys, session tokens, OAuth 2.1)
- Use all 16+ MCP tools: search, read, write, relate, and manage notes
- Handle errors and token refresh
- Connect to multiple brain.md vaults

## Install

### Claude Code (plugin, recommended)

```
/plugin marketplace add njayman/brainmd-skills
/plugin install brain-md@brain-md-marketplace
```

You'll be prompted for your brain.md URL and, optionally, an API key or session token, since this repo bundles the MCP server config, so that's the entire setup. Change the values later with `/plugin configure brain-md@brain-md-marketplace`.

Or manually copy the `brain-md/` folder to `~/.claude/skills/brain-md/` (no bundled MCP auth in this mode, see [Manual Configuration](#manual-configuration)).

### opencode

Copy the skill folder and command to your opencode config:

```bash
cp -r brain-md ~/.config/opencode/skills/brain-md
cp brain-md/commands/setup.md ~/.config/opencode/command/brain-md.md
```

Then run `/brain-md` to configure the connection.

### VS Code / GitHub Copilot

Copy the `brain-md/` folder to `.agents/skills/brain-md/` in your project root.

### Cursor

Copy the `brain-md/` folder to `.cursor/skills/brain-md/` in your project root.

### Roo Code

Copy the `brain-md/` folder to `.roo/skills/brain-md/` in your project root.

### Any Agent Skills-Compatible Tool

Copy the `brain-md/` folder to whichever skill directory your agent scans:

| Agent | Default Skill Directory |
|-------|------------------------|
| Claude Code | `~/.claude/skills/` or `.claude/skills/` |
| opencode | `~/.config/opencode/skills/` or `.opencode/skills/` |
| VS Code / Copilot | `.agents/skills/` |
| Cursor | `.cursor/skills/` |
| Roo Code | `.roo/skills/` |
| OpenHands | `.agent/skills/` |
| Gemini CLI | `.gemini/skills/` |

## Configure MCP Connection

Claude Code plugin installs configure themselves at install time (see above). Skip this section unless you used a manual copy install or a different agent.

### opencode: Run `/brain-md`

The `/brain-md` command runs an interactive wizard that:
1. Probes your brain.md instance
2. Detects if auth is required
3. Configures API key or session token
4. Writes the MCP config to `opencode.jsonc`

After setup, restart opencode.

### Manual Configuration

#### opencode (`opencode.json`)

```json
{
  "mcp": {
    "brain": {
      "type": "remote",
      "url": "https://YOUR-BRAIN-INSTANCE/mcp",
      "headers": {
        "Authorization": "Bearer {env:BRAIN_API_KEY}"
      }
    }
  }
}
```

### Claude Code (`.mcp.json`)

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

### Get an API Key

1. Open your brain.md instance in a browser
2. Go to Settings → Security → API Keys
3. Click Generate
4. Copy the token (shown once)

Or use a session token:

```bash
export BRAIN_API_KEY=$(scripts/get-session-token.sh https://brain.example.com YOUR_PASSWORD)
```

## Usage

Once installed and configured, just mention brain.md in your conversation:

- "Search my brain vault for notes about machine learning"
- "Read the note at Research/AI/neural-networks.md"
- "What tasks are open in my brain vault?"
- "Find notes related to this one"
- "Get a weekly digest of recent changes"

The agent will activate the brain-md skill and use the appropriate MCP tools.

## Development

### Structure

```
brainmd-skills/
├── .claude-plugin/
│   └── marketplace.json      # Lists brain-md as an installable plugin
├── brain-md/
│   ├── .claude-plugin/
│   │   └── plugin.json       # Plugin manifest: userConfig + bundled MCP server
│   ├── SKILL.md              # Main skill (loaded on activation)
│   ├── commands/
│   │   └── setup.md          # /brain-md setup wizard (opencode / manual installs)
│   ├── references/
│   │   ├── tools.md          # Full tool schemas and examples
│   │   ├── auth.md           # Auth flows and token management
│   │   └── errors.md         # Error codes and recovery
│   └── scripts/
│       └── get-session-token.sh
├── LICENSE
└── README.md
```

### Testing

**Claude Code plugin:**
1. `claude plugin validate ./brain-md --strict` and `claude plugin validate . --strict`
2. `claude plugin marketplace add "$(pwd)"` then `claude plugin install brain-md@brain-md-marketplace --config endpoint=https://YOUR-BRAIN-INSTANCE`
3. `claude plugin details brain-md@brain-md-marketplace`, confirm no duplicate skill/command names
4. Ask: "List all notes in my brain vault" and confirm the agent calls `list_notes` on the `brain` MCP server

**opencode / manual:**
1. Install the skill and command in your agent
2. Run `/brain-md` to configure the connection
3. Restart your agent
4. Ask: "List all notes in my brain vault"
5. Verify the agent activates the skill and calls `list_notes`

### Contributing

1. Fork the repo
2. Make changes to `SKILL.md` or references
3. Test with your agent
4. Submit a PR

## License

MIT
