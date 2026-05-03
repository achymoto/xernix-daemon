# Xernix Seed Node — Deployment Guide

This guide is what you (the operator) follow to bring a Xernix seed node
online on a Replit Reserved VM. Every step lists what you do and what
the system does, so there are no surprises.

## TL;DR

```
1. Click Publish → Reserved VM in the Replit workspace
2. Choose: 4 vCPU / 8 GB RAM (minimum for a comfortable Monero build)
3. Set environment: XERNIX_NETWORK=testnet
4. Wait 25–45 min for the Docker build of Monero v0.18.3.4
5. Copy the public URL into VITE_XERNIX_RPC_URL on the dashboard artifact
6. Restart the dashboard — Node Status flips to LIVE_RPC
```

That's it. The rest of this document explains *why* each step is needed
and what to do when it goes wrong.

## What gets built

The `xernix-daemon/Dockerfile` defines a 2-stage build:

* **Stage 1 (`builder`)** — Ubuntu 22.04, clones Monero v0.18.3.4, runs
  `apply-xernix-patches.sh` (3 patches: network identity, rebrand,
  optional wallet burn), then `make release-static -j$(nproc)`.
* **Stage 2 (`runtime`)** — Ubuntu 22.04 minimal, copies only the three
  produced binaries (`xernixd`, `xernix-wallet-cli`, `xernix-wallet-rpc`)
  and the entry scripts. Final image is ~250 MB.

The build is pure: no network access during stage 2, no secrets baked
in, all configuration via env vars at runtime.

## Resource requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU      | 2 vCPU  | 4 vCPU      |
| RAM      | 4 GB    | 8 GB        |
| Disk     | 10 GB   | 50 GB       |
| Network  | 1 Mbps  | 10 Mbps     |

Build-time RAM peaks during `monero-blockchain-import`-style link steps.
With < 4 GB RAM the build will OOM on the final link of `monerod`.

## Step-by-step

### 1. Choose Reserved VM, not Autoscale

The Xernix daemon is a long-running stateful P2P process. It must:

* Listen on TCP port 28080 for peers
* Maintain a connection pool that survives restarts
* Hold the blockchain on a persistent volume

Autoscale deployments are stateless and ephemeral. Reserved VM is the
only correct choice.

### 2. Wire the publish step to `xernix-daemon/`

The Dockerfile lives at `xernix-daemon/Dockerfile`. When you initiate
the publish flow, point the build context at this directory. You may
need to update the Replit publishing config to set:

```
build.dockerfile = "xernix-daemon/Dockerfile"
build.context    = "xernix-daemon/"
```

### 3. Set environment variables

| Variable                       | Purpose                                                   | Default      |
|--------------------------------|-----------------------------------------------------------|--------------|
| `XERNIX_NETWORK`               | `testnet` (only supported value for now)                  | `testnet`    |
| `XERNIX_BURN_MODE`             | `strict` to fail build if burn patch breaks               | `permissive` |
| `XERNIX_WALLET_RPC_LOGIN`      | `username:password` for wallet RPC auth (REQUIRED)        | — (wallet RPC refuses to start without this) |
| `XERNIX_BURN_ADDRESS`          | Optional NUMS burn address; enables 1.5% burn at runtime  | unset (burn disabled, transfers proceed without burn) |

`XERNIX_WALLET_RPC_LOGIN` is enforced by `scripts/start-wallet-rpc.sh`. Do
not bypass it — an unauthenticated wallet RPC on a public IP is a "drain
my wallet" URL.

### 4. Wait for the build

The build takes 25–45 minutes depending on the Reserved VM size. You
can follow progress in the Replit deployment logs. Look for:

* `[xernix] applying REQUIRED patch: 01-xernix-network-identity.patch` — patches
* `[xernix] all patches handled.`                                       — patches done
* `make[2]: Leaving directory '.../monero/build/release/src/daemon'`    — daemon linked
* `[INFO] xernixd starting on 28080 (P2P) / 28081 (RPC)`                — running

If the patches fail to apply, the build halts with exit code 2 and a
clear message naming the patch that drifted. Re-base that patch against
the new `MONERO_REF` and rebuild.

### 5. Configure the burn address (optional, default disabled)

The wallet patch only enforces the 1.5 % burn when a valid Xernix burn
address is provided. **No burn address is shipped with this build** —
see `BURN_ADDRESS.md` for the full explanation, but the short version is:
generating a true unspendable address requires hash-to-curve, and shipping
a placeholder would create a publicly-spendable wallet pretending to be
a burn sink (i.e. fraud).

To enable burn yourself, generate a NUMS Xernix testnet address with a
trusted external tool, then either:

```bash
# Option A: pass via env var on the deployment
export XERNIX_BURN_ADDRESS="<your-NUMS-address>"

# Option B: persist on disk inside the container
echo "<your-NUMS-address>" > /etc/xernix/burn_address.txt
```

Restart the wallet RPC after either change. If neither is configured,
every outgoing transfer logs a `WARNING` and goes through *unburned* —
the daemon itself runs perfectly.

### 6. Connect the dashboard

In the dashboard artifact (`artifacts/randomx-dashboard`), set the env
var:

```
VITE_XERNIX_RPC_URL=https://<your-reserved-vm-domain>/
```

Restart the dashboard workflow. The Node Status page will switch from
`MOCK` / `ERROR` to `LIVE_RPC` and start polling `get_info` every 15 s.

## Troubleshooting

| Symptom                                   | Likely cause                                       | Fix                                                                  |
|-------------------------------------------|----------------------------------------------------|----------------------------------------------------------------------|
| Build OOM during link                     | < 4 GB RAM                                         | Increase Reserved VM size                                            |
| `wallet burn patch did not apply`         | wallet2.cpp drifted in the pinned MONERO_REF       | Re-base `patches/03-xernix-wallet-burn.patch`; rebuild               |
| `FATAL: required patch failed --check`    | cryptonote_config.h drifted                        | Re-base patches 01 / 02 against the new MONERO_REF                   |
| Node Status stays in `ERROR_RPC`          | RPC URL wrong, port closed, or HTTPS missing       | Curl `${URL}/get_info` directly to confirm reachability               |
| Wallet RPC refuses to start               | `XERNIX_WALLET_RPC_LOGIN` env var missing          | Set `XERNIX_WALLET_RPC_LOGIN=user:pass` and restart                   |
| Daemon syncs forever                      | NETWORK_ID mismatch with peers                     | Confirm patch 01 was applied; check `~/.xernix/p2pstate.bin`          |

## What is *not* in this build

Be honest with the people running this:

* **Consensus burn**: not implemented. Only the wallet enforces 1.5 %.
* **Tail emission tweak**: untouched — Monero's existing 0.6 XMR / 2-min
  block matches our target of 0.6 XRX / block, so no patch needed.
* **Creator pre-mine UTXOs**: not in the genesis tx. The 2.1 M XRX
  allocation is a roadmap commitment to be honoured via mined blocks
  + a time-lock smart-contract layer, not a hard-coded genesis output.
* **RandomX algorithm**: inherited from Monero unchanged — Xernix is
  a Monero fork, not a CryptoNight variant.
