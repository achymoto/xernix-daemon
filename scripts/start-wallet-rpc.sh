#!/usr/bin/env bash
# start-wallet-rpc.sh — Xernix wallet RPC entrypoint.
#
# SECURITY: this script REQUIRES authentication on the wallet RPC by default.
# An unauthenticated wallet RPC exposed to the network is equivalent to
# publishing your private keys.
#
# Provide credentials via XERNIX_WALLET_RPC_LOGIN="user:password".
# Only set XERNIX_WALLET_RPC_DISABLE_LOGIN=1 if the RPC is on a private
# Docker network that is NOT reachable from the public internet.

set -euo pipefail

WALLET_DIR="${XERNIX_WALLET_DIR:-/var/lib/xernix/wallet}"
RPC_BIND_PORT="${XERNIX_WALLET_RPC_PORT:-28083}"
DAEMON_ADDRESS="${XERNIX_DAEMON_ADDRESS:-127.0.0.1:28081}"
RPC_LOGIN="${XERNIX_WALLET_RPC_LOGIN:-}"
DISABLE_LOGIN="${XERNIX_WALLET_RPC_DISABLE_LOGIN:-0}"

mkdir -p "$WALLET_DIR"

ARGS=(
  --testnet
  --wallet-dir "$WALLET_DIR"
  --rpc-bind-ip 0.0.0.0
  --rpc-bind-port "$RPC_BIND_PORT"
  --daemon-address "$DAEMON_ADDRESS"
  --confirm-external-bind
  --non-interactive
)

if [[ -n "$RPC_LOGIN" ]]; then
  ARGS+=(--rpc-login "$RPC_LOGIN")
elif [[ "$DISABLE_LOGIN" == "1" ]]; then
  echo "[xernix] WARNING: wallet RPC starting WITHOUT authentication." >&2
  echo "[xernix] This is only acceptable on a private/internal network." >&2
  ARGS+=(--disable-rpc-login)
else
  echo "[xernix] FATAL: wallet RPC requires XERNIX_WALLET_RPC_LOGIN=user:pass" >&2
  echo "[xernix] To intentionally run without auth on a private network," >&2
  echo "[xernix] set XERNIX_WALLET_RPC_DISABLE_LOGIN=1." >&2
  exit 2
fi

echo "[xernix] launching wallet RPC with: ${ARGS[*]}"
exec /usr/local/bin/xernix-wallet-rpc "${ARGS[@]}"
