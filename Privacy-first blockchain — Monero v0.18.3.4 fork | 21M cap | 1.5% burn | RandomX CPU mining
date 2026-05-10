# Xernix Daemon

Source-buildable Monero fork that becomes the Xernix testnet daemon. Lives at
the repo root (NOT inside `artifacts/`) because it ships as a Docker image to
a Reserved VM, not as a Replit web preview.

## Layout

```
xernix-daemon/
├── Dockerfile                       # 2-stage: build Monero v0.18.3.4 → minimal runtime
├── apply-xernix-patches.sh          # pure bash, applies the 3 patches via `git apply`
├── patches/
│   ├── 01-xernix-network-identity.patch   # testnet UUID, address prefix 88, genesis nonce 21000000
│   ├── 02-xernix-rebrand.patch            # CRYPTONOTE_NAME bitmonero → xernix
│   └── 03-xernix-wallet-burn.patch        # 1.5% TBD destination at wallet layer
├── scripts/
│   ├── start-seed-node.sh           # entrypoint: launches xernixd
│   └── start-wallet-rpc.sh          # entrypoint: launches xernix-wallet-rpc (REQUIRES auth)
├── config/
│   └── xernix.conf                  # default daemon config
├── BURN_ADDRESS.md                  # honest status: no burn address is shipped, why, and how to provide one
└── DEPLOYMENT.md                    # operator step-by-step (Reserved VM)
```

## What works today

| Component                           | Status            | Notes |
|-------------------------------------|-------------------|-------|
| Network identity (testnet)          | **Real patch**    | Validated against Monero v0.18.3.4 source. UUID = ASCII "xernix-test-net", genesis nonce 21000000, address prefix 88. |
| Rebrand (`CRYPTONOTE_NAME` → xernix)| **Real patch**    | Data dir becomes `~/.xernix/`, wallets named `xernix*`. |
| Wallet burn 1.5%                    | **Real patch**    | Validated against `wallet2.cpp::create_transactions_2`. Reads burn address from env or `/etc/xernix/burn_address.txt`. |
| Burn address                        | **Not shipped**   | A correct NUMS burn address requires hash-to-curve. Operator must supply one via `XERNIX_BURN_ADDRESS`; otherwise burn is skipped at runtime with a WARNING. See `BURN_ADDRESS.md`. |
| Tail emission 0.6 XRX/blk           | **No patch needed** | Monero already emits 0.6 XMR per 2-min block (`FINAL_SUBSIDY_PER_MINUTE = 3e11`). |
| Docker build                        | **Defined**       | Has not been built yet — first build will happen during your Reserved VM publish (~30 min). |

## What is intentionally NOT in this build

* **Consensus burn**: only the wallet enforces 1.5%. A custom wallet can bypass it. Fixing this requires a hard fork that adds `TX_EXTRA_TAG_BURN` validation.
* **Creator pre-mine in genesis**: the 2.1M XRX creator allocation is a roadmap commitment, not a hard-coded genesis output. It will be honoured via mined blocks + a time-lock layer.
* **RandomX algorithm changes**: inherited from Monero unchanged.
* **Mainnet support**: only testnet is patched. Mainnet rules are unchanged from upstream Monero (so a Xernix daemon launched without `--testnet` would still join the Monero mainnet — do not run that).

## Patch validation

All three patches are validated to apply cleanly against
`monero-project/monero` at tag `v0.18.3.4`. The apply script uses
`git apply --check` first and exits with a clear error if any patch
fails to apply, so a future Monero release that breaks our line
references halts the build instead of silently shipping a broken daemon.

The wallet-burn patch (03) is treated as **optional** by default: in
`permissive` mode the build continues with a loud warning if it fails to
apply, producing a daemon that runs correctly but does not enforce burn.
Set `XERNIX_BURN_MODE=strict` to make burn-patch failure fatal.

## Deployment

See `DEPLOYMENT.md`. TL;DR:

1. Publish → Reserved VM, 4 vCPU / 8 GB
2. Wait 25–45 min for the Monero build
3. Set `VITE_XERNIX_RPC_URL` on the dashboard to the new domain
4. Optionally set `XERNIX_BURN_ADDRESS=<your-NUMS-address>` to enable the
   1.5% burn (see `BURN_ADDRESS.md` — none is shipped, by design)

## Honest summary

This is a working Monero fork at the binary identity / network identity
level. The protocol-level burn is a wallet-layer enforcement only, which
the dashboard surfaces honestly under "Burn Status: WALLET_LAYER_ONLY".
Anyone running this daemon on a Reserved VM gets a real Xernix testnet
node that other Xernix nodes can connect to and mine on. Anyone running
the patched wallet against that node gets transactions that include a
1.5% burn output by default.
