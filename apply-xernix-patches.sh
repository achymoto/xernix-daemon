#!/usr/bin/env bash
# apply-xernix-patches.sh
#
# Applies the Xernix protocol patches to a freshly-cloned Monero source tree.
# All patches are pure git unified-diff format and are applied with
# `git apply --check` first to fail fast if Monero upstream has drifted.
#
# Usage: apply-xernix-patches.sh /path/to/monero
#
# Exit codes:
#   0  all patches applied successfully
#   1  bad arguments / required file missing
#   2  a required patch failed to apply (Monero upstream drifted, re-base
#      patches against the pinned MONERO_REF)
#
# Build mode controls strictness for the wallet-layer burn patch only:
#   strict      -> burn patch MUST apply, otherwise hard-fail (recommended)
#   permissive  -> burn patch is best-effort (default — keeps the build green
#                  even when the burn patch fails to apply, which means the
#                  resulting daemon does NOT enforce burn even at wallet
#                  layer; the daemon itself is otherwise correct).

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 /path/to/monero/source" >&2
  exit 1
fi

MONERO_DIR="$1"
PATCH_DIR="$(cd "$(dirname "$0")"/patches && pwd)"
XERNIX_BURN_MODE="${XERNIX_BURN_MODE:-permissive}"

[[ -d "$MONERO_DIR/.git" ]] || { echo "[xernix] FATAL: $MONERO_DIR is not a git repo (need git apply)" >&2; exit 1; }
[[ -d "$PATCH_DIR" ]]       || { echo "[xernix] FATAL: patches dir not found: $PATCH_DIR" >&2; exit 1; }

echo "[xernix] Monero src:  $MONERO_DIR"
echo "[xernix] Patches dir: $PATCH_DIR"
echo "[xernix] Burn mode:   $XERNIX_BURN_MODE"

cd "$MONERO_DIR"

apply_required() {
  local p="$1"
  echo "[xernix] applying REQUIRED patch: $(basename "$p")"
  if ! git apply --check "$p" 2>&1 | sed 's/^/[xernix]   /'; then
    echo "[xernix] FATAL: required patch failed --check: $p" >&2
    echo "[xernix] Monero source has drifted from the pinned MONERO_REF." >&2
    echo "[xernix] Re-generate the patch against the new MONERO_REF and retry." >&2
    exit 2
  fi
  git apply "$p"
}

apply_optional() {
  local p="$1"
  echo "[xernix] applying OPTIONAL patch: $(basename "$p")  (mode=$XERNIX_BURN_MODE)"
  if git apply --check "$p" >/dev/null 2>&1; then
    git apply "$p"
    echo "[xernix]   ok"
  else
    if [[ "$XERNIX_BURN_MODE" == "strict" ]]; then
      echo "[xernix] FATAL: burn patch failed --check in strict mode" >&2
      git apply --check "$p" 2>&1 | sed 's/^/[xernix]   /' >&2 || true
      exit 2
    fi
    echo "[xernix] WARNING: burn patch did not apply." >&2
    echo "[xernix] Daemon will build successfully but burn will NOT be enforced," >&2
    echo "[xernix] not even at the wallet layer. Re-base patches/03-*.patch and rebuild," >&2
    echo "[xernix] or set XERNIX_BURN_MODE=strict to make this fatal." >&2
  fi
}

# Required: identity + rebrand. Without these the build is "Monero with extra
# steps", not Xernix.
apply_required "$PATCH_DIR/01-xernix-network-identity.patch"
apply_required "$PATCH_DIR/02-xernix-rebrand.patch"

# Optional in permissive mode: wallet burn. Always run last so that an upstream
# wallet2.cpp drift never blocks the network/identity changes.
apply_optional "$PATCH_DIR/03-xernix-wallet-burn.patch"

echo "[xernix] all patches handled."
