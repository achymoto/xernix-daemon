# Xernix Burn Address — Honest Status

## What the wallet patch needs

The wallet-layer 1.5% Transaction-Based Destruction (`patches/03-xernix-wallet-burn.patch`)
appends a destination output to every outgoing transfer. The address used for
that output is read at runtime from:

1. Environment variable `XERNIX_BURN_ADDRESS`
2. File `/etc/xernix/burn_address.txt`

If neither is set, **the patch logs a `WARNING` and skips the burn** — the
transfer still goes through. This graceful degradation is intentional: it is
better to send unburned coins than to silently drop a transfer.

## What a real burn address requires

For the burn output to be **truly unspendable** (i.e. nobody, including the
project creator, can sweep the burned funds back), the address must satisfy:

> The public spend key is a valid Ed25519 curve point with **no known
> corresponding private scalar**.

This is a "Nothing-Up-My-Sleeve" (NUMS) construction. The standard way to
achieve it is **hash-to-curve**: take a public domain-separation string,
hash it, and map the hash deterministically to a curve point using a
construction like Elligator2. The result is a public key for which the
discrete-log problem is not pre-solved.

Monero's `monero-wallet-cli --generate-from-spend-key` is **not** suitable
for this. That command takes a *private* spend key, derives the matching
public key, and produces a wallet from which anyone holding the same private
key (e.g. anyone who can re-run the same derivation) can spend.

## Why this repo does not yet ship a burn address

A correct NUMS address generator for Monero requires:

* an Ed25519 hash-to-curve implementation (Elligator2 or a try-and-increment
  loop), and
* the same base58 / address-encoding bytes Monero uses on the live network.

Implementing this correctly without a Python or Rust runtime in the build
image is non-trivial, and shipping an *incorrect* burn-address generator
would be worse than shipping none — funds sent to a "burn" address whose
spend key is publicly recomputable can be swept by anyone, which is fraud,
not deflation.

The repository therefore **does not generate a burn address** at build time.
The default deployment runs the wallet patch with **burn enforcement
disabled at runtime** (the WARNING log path).

## Path to enabling burn

Two options, in increasing order of trust required:

1. **Operator-provided unspendable address.** You generate a NUMS address
   yourself (e.g. with a trusted hash-to-curve tool such as
   [`monero-burn-address`](https://github.com/sech1/monero-burn-address))
   and set `XERNIX_BURN_ADDRESS` on the deployment. Document the seed
   string and the tool you used so anyone can reproduce the derivation.

2. **Consensus-layer burn (planned).** Ship a hard fork that adds a
   `TX_EXTRA_TAG_BURN` validation rule. Coins are then "burned" by being
   provably destroyed at the protocol layer (the daemon refuses to spend
   them), with no NUMS address required. This is on the roadmap and is
   the only mechanism that can be both deflationary and bypass-proof.

Both options are honest about what is happening. Until one is in place,
the dashboard surfaces burn status as `BURN_DISABLED` rather than
`WALLET_LAYER_ENFORCED`.
