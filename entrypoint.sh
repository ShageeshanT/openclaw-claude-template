#!/bin/bash
set -e

chown -R openclaw:openclaw /data
chmod 700 /data

if [ ! -d /data/.linuxbrew ]; then
  cp -a /home/linuxbrew/.linuxbrew /data/.linuxbrew
fi

rm -rf /home/linuxbrew/.linuxbrew
ln -sfn /data/.linuxbrew /home/linuxbrew/.linuxbrew

# Persist Claude Code CLI credentials on the Railway volume so the OAuth login
# done once via `railway ssh` survives every redeploy.
# OpenClaw's `--method cli` Anthropic auth reads ~/.claude/, so we point that
# at /data/.claude and the subscription credentials become permanent state.
mkdir -p /data/.claude
chown -R openclaw:openclaw /data/.claude
rm -rf /home/openclaw/.claude
ln -sfn /data/.claude /home/openclaw/.claude

exec gosu openclaw node src/server.js
