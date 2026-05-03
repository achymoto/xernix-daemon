#!/usr/bin/env bash
# start-seed-node.sh — Xernix testnet seed node entrypoint.
#
# Configuration is supplied via environment variables. A static config file
# lives at /etc/xernix/xernix.conf for reference, but is not loaded by
# default — env vars override every knob below so the same image can ship
# unchanged across environments.

set -euo pipefail

DATA_DIR="${XERNIX_DATA_DIR:-/var/lib/xernix}"
LOG_DIR="${XERNIX_LOG_DIR:-/var/log/xernix}"
LOG_LEVEL="${XERNIX_LOG_LEVEL:-1}"
P2P_BIND_PORT="${XERNIX_P2P_PORT:-28080}"
RPC_BIND_PORT="${XERNIX_RPC_PORT:-28081}"
ZMQ_BIND_PORT="${XERNIX_ZMQ_PORT:-28082}"
SEED_NODES="${XERNIX_SEED_NODES:-}"
RPC_RESTRICTED="${XERNIX_RPC_RESTRICTED:-1}"

mkdir -p "$DATA_DIR" "$LOG_DIR"

ARGS=(
  --testnet
  --data-dir "$DATA_DIR"
  --log-file "$LOG_DIR/xernixd.log"
  --log-level "$LOG_LEVEL"
  --p2p-bind-ip 0.0.0.0
  --p2p-bind-port "$P2P_BIND_PORT"
  --rpc-bind-ip 0.0.0.0
  --rpc-bind-port "$RPC_BIND_PORT"
  --zmq-rpc-bind-ip 0.0.0.0
  --zmq-rpc-bind-port "$ZMQ_BIND_PORT"
  --confirm-external-bind
  --non-interactive
  --no-igd
)

if [[ "$RPC_RESTRICTED" == "1" ]]; then
  ARGS+=(--restricted-rpc)
fi

if [[ -n "$SEED_NODES" ]]; then
  IFS=',' read -ra NODES <<< "$SEED_NODES"
  for node in "${NODES[@]}"; do
    ARGS+=(--add-priority-node "$node")
  done
fi

echo "[xernix] launching xernixd with: ${ARGS[*]}"
exec /usr/local/bin/xernixd "${ARGS[@]}"
