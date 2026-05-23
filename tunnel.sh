#!/usr/bin/env bash
set -e

PORT="${PORT:-4000}"
APP_URL="http://localhost:$PORT"

# ── Colors ──────────────────────────────────────────────────
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Personal Hub — Cloudflare Tunnel 🚀    ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""

# ── 1. Check / install cloudflared ──────────────────────────
if ! command -v cloudflared &>/dev/null; then
  echo -e "${YELLOW}⚠  cloudflared not found. Installing...${NC}"
  if [ -f "./cloudflared.deb" ]; then
    sudo dpkg -i ./cloudflared.deb
  else
    echo -e "${CYAN}↓  Downloading latest cloudflared...${NC}"
    curl -sLO https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    sudo dpkg -i cloudflared-linux-amd64.deb
    rm -f cloudflared-linux-amd64.deb
  fi
  echo -e "${GREEN}✔  cloudflared installed.${NC}"
else
  echo -e "${GREEN}✔  cloudflared found: $(cloudflared --version 2>&1 | head -1)${NC}"
fi

# ── 2. Check if Phoenix is already running ──────────────────
if curl -s --max-time 2 "$APP_URL" >/dev/null 2>&1; then
  echo -e "${GREEN}✔  Phoenix already running on port $PORT${NC}"
  START_PHX=false
else
  echo -e "${YELLOW}▶  Starting Phoenix on port $PORT...${NC}"
  START_PHX=true
  MIX_ENV=prod PHX_HOST=localhost PHX_SCHEME=http PORT=$PORT mix phx.server &
  PHX_PID=$!

  # Wait for Phoenix to become ready (up to 30s)
  echo -n "   Waiting for server"
  for i in $(seq 1 30); do
    if curl -s --max-time 1 "$APP_URL" >/dev/null 2>&1; then
      break
    fi
    echo -n "."
    sleep 1
  done
  echo ""

  if ! curl -s --max-time 2 "$APP_URL" >/dev/null 2>&1; then
    echo -e "${RED}✘  Phoenix didn't start in time. Check logs above.${NC}"
    exit 1
  fi
  echo -e "${GREEN}✔  Phoenix is up!${NC}"
fi

# ── 3. Start Cloudflare Tunnel ──────────────────────────────
echo ""
echo -e "${CYAN}🌍  Opening Cloudflare Tunnel → $APP_URL${NC}"
echo -e "${CYAN}   (Your public URL will appear below)${NC}"
echo ""

# Trap cleanup on exit
cleanup() {
  echo ""
  echo -e "${YELLOW}⏹  Shutting down...${NC}"
  if [ "$START_PHX" = true ] && [ -n "$PHX_PID" ]; then
    kill $PHX_PID 2>/dev/null || true
    echo -e "${GREEN}✔  Phoenix stopped.${NC}"
  fi
  echo -e "${GREEN}✔  Tunnel closed. Bye!${NC}"
}
trap cleanup EXIT INT TERM

cloudflared tunnel --url "$APP_URL"
