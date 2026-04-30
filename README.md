# OpenClaw Railway Template — Claude Subscription Edition

Deploy OpenClaw on Railway with a browser-first setup flow. No SSH required for onboarding — and now with **Claude Pro/Max subscription auth** so you don't have to pay per-token for an Anthropic API key.

> **Fork notice.** This is a fork of [codetitlan/openclaw-railway-template](https://github.com/codetitlan/openclaw-railway-template) maintained by [@ShageeshanT](https://github.com/ShageeshanT). The headline addition is **Claude Code subscription auth** as an Anthropic provider option, so you can power OpenClaw with your existing Pro/Max plan instead of an API key. The Claude Code CLI is baked into the image, the OAuth credentials live on the Railway volume, and a one-time `railway ssh` login covers every redeploy after that. See [Use Your Claude Pro/Max Subscription Instead of an API Key](#use-your-claude-promax-subscription-instead-of-an-api-key) below.

IF YOU ARE UPGRADING FROM A PREVIOW VERSION REMOVE THE ENV VAR 'OPENCLAW_ENTRY' AS NOW OPENCLAW IS INSTALLED VIA NPM

## Read This First

This template exposes your OpenClaw gateway to the public internet.

- Review OpenClaw security guidance: <https://docs.openclaw.ai/gateway/security>
- Use a strong `SETUP_PASSWORD`
- If you only use chat channels, consider disabling public networking after setup

## What You Get

- OpenClaw Gateway + Control UI at `/` and `/openclaw`
- Setup Wizard at `/setup` (Basic auth protected)
- Optional browser TUI at `/tui`
- Persistent state on Railway volume (`/data`)
- Health endpoint at `/healthz`
- Diagnostics and logs via setup tools + `/logs`

## Quick Start (Railway)

1. Deploy this template to Railway.
2. Ensure a volume is mounted at `/data`.
3. Set variables:
   - `SETUP_PASSWORD` (required)
   - `OPENCLAW_STATE_DIR=/data/.openclaw`
   - `OPENCLAW_WORKSPACE_DIR=/data/workspace`
   - Optional: `ENABLE_WEB_TUI=true`
4. Open `https://<your-domain>/setup` and complete onboarding.
5. Open `https://<your-domain>/openclaw` from the setup page.

## Use Your Claude Pro/Max Subscription Instead of an API Key

This template ships with the Claude Code CLI baked into the image and a
persistent `~/.claude/` directory pinned to the Railway volume. That means you
can power OpenClaw with your Anthropic Pro/Max subscription quota — zero
per-token cost — instead of paying for an API key.

The setup wizard exposes this as a new auth method:
**Anthropic → Claude Code subscription (login via SSH, no API key needed)**.

### One-time login (via Railway SSH)

```bash
railway ssh           # opens a shell in your running container
claude                # starts the device-flow OAuth login
                      # paste the URL into a browser, sign in, paste the code back
exit
```

Credentials are written to `~/.claude/`, which `entrypoint.sh` symlinks to
`/data/.claude/` — they survive every redeploy and container restart until the
OAuth refresh token is invalidated.

### Then in the wizard

1. Open `/setup`.
2. Provider Group → **Anthropic**, Auth Method → **Claude Code subscription…**.
3. Click **Re-check login status** — it should report credentials detected.
4. Pick a model (e.g. `anthropic/claude-sonnet-4`) and click Run setup.

The wrapper will skip the API-key path during onboarding and run
`openclaw models auth login --provider anthropic --method cli` so OpenClaw
uses the local Claude CLI as its Anthropic backend.

### Caveats

- **OAuth refresh** — `~/.claude/` is auto-refreshed by the CLI as long as the
  refresh token is valid. If you log out from another device, SSH back in and
  re-run `claude` to re-authenticate.
- **Subscription quota** — hourly/daily rate limits still apply. Heavy usage
  can stall.
- **Anthropic policy** — Anthropic's stance on third-party tools using Pro/Max
  has shifted multiple times; OpenClaw's docs currently consider this sanctioned
  but that may change without notice. If you start getting `401`s after a
  policy update, fall back to the API-key path.
- **One sub, one deployment** — the credentials in `/data/.claude/` are
  account-bound. Don't share the volume across multiple Railway services.

## Environment Variables

### Required

- `SETUP_PASSWORD`: password for `/setup`

### Recommended

- `OPENCLAW_STATE_DIR=/data/.openclaw`
- `OPENCLAW_WORKSPACE_DIR=/data/workspace`
- `OPENCLAW_GATEWAY_TOKEN` (stable token across redeploys)

### Optional

- `PORT=8080`
- `INTERNAL_GATEWAY_PORT=18789`
- `INTERNAL_GATEWAY_HOST=127.0.0.1`
- `ENABLE_WEB_TUI=false`
- `TUI_IDLE_TIMEOUT_MS=300000`
- `TUI_MAX_SESSION_MS=1800000`

## Day-1 Setup Checklist

- Confirm `/setup` loads and accepts password
- Run onboarding once
- Verify `/healthz` returns `{ "ok": true, ... }`
- Open `/openclaw` via setup link
- If using Telegram/Discord, approve pending devices from setup tools

## Chat Token Prep

### Telegram

1. Message `@BotFather`
2. Run `/newbot`
3. Copy bot token (looks like `123456789:AA...`)
4. Paste into setup wizard

### Discord

1. Create app in Discord Developer Portal
2. Add bot + copy bot token
3. Invite bot to server (`bot`, `applications.commands` scopes)
4. Enable required intents for your use case

## Web TUI (`/tui`)

Disabled by default. Set `ENABLE_WEB_TUI=true` to enable.

Built-in safeguards:

- Protected by `SETUP_PASSWORD`
- Single active session
- Idle timeout
- Max session duration

## Local Smoke Test

```bash
docker build -t openclaw-railway-template .

docker run --rm -p 8080:8080 \
  -e PORT=8080 \
  -e SETUP_PASSWORD=test \
  -e OPENCLAW_STATE_DIR=/data/.openclaw \
  -e OPENCLAW_WORKSPACE_DIR=/data/workspace \
  -e ENABLE_WEB_TUI=true \
  -v $(pwd)/.tmpdata:/data \
  openclaw-railway-template
```

- Setup: `http://localhost:8080/setup` (password: `test`)
- UI: `http://localhost:8080/openclaw`
- TUI: `http://localhost:8080/tui`

## Troubleshooting

### Control UI says disconnected / auth error

- Open `/setup` first, then click the OpenClaw UI link from there.
- Approve pending devices in setup if pairing is required.

### 502 / gateway unavailable

- Check `/healthz`
- Run doctor from setup (`openclaw doctor --repair`)
- Verify `/data` volume is mounted and writable

### Setup keeps resetting after redeploy

- `OPENCLAW_STATE_DIR` or `OPENCLAW_WORKSPACE_DIR` is not on `/data`
- Fix both vars and redeploy

### TUI not visible

- Set `ENABLE_WEB_TUI=true`
- Redeploy and reload `/setup`

## Useful Endpoints

- `/setup` - onboarding + management
- `/openclaw` - Control UI
- `/healthz` - public health
- `/logs` - live server logs UI

## Support

Need help? Open an issue or use Railway Station support for this template.

## Credits

- Upstream template: [codetitlan/openclaw-railway-template](https://github.com/codetitlan/openclaw-railway-template) — MIT-licensed. The setup wizard, gateway lifecycle, reverse proxy, web TUI, log viewer, and the entire Railway packaging are their work. This fork stands on top of it.
- OpenClaw: [openclaw/openclaw](https://github.com/openclaw/openclaw) — the AI assistant platform this template deploys.
- Claude Code CLI: [@anthropic-ai/claude-code](https://www.npmjs.com/package/@anthropic-ai/claude-code) — what makes the subscription path possible.

What this fork adds on top of upstream:

- Claude Code CLI baked into the Docker image
- `~/.claude/` symlinked to the persistent `/data` volume in `entrypoint.sh`
- New `claude-cli` auth choice in the setup wizard with a live login-status check
- Pre-flight credential check + post-onboard `openclaw models auth login --method cli` wiring
- Documentation for the one-time `railway ssh` device-flow login

Everything else is upstream — full credit to the original maintainers.

## License

MIT — see [LICENSE](./LICENSE). The upstream copyright is preserved as MIT requires; the additions in this fork are dual-attributed to the upstream maintainers and [@ShageeshanT](https://github.com/ShageeshanT).
