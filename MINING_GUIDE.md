# How to Mine Xernix (XRX)

This guide is for **end-users** who want to mine XRX on their own computer.
For operator / seed-node setup, see `DEPLOYMENT.md` instead.

---

## Quick facts

| | |
|---|---|
| Algorithm | RandomX (CPU-only, ASIC-resistant) |
| Block time | ~2 minutes |
| Block reward | 0.6 XRX (tail emission, perpetual) |
| Total supply cap | 21,000,000 XRX |
| Burn per transaction | 1.5% (wallet-layer) |
| Network | Testnet (pre-launch) |
| Hardware needed | Any modern CPU (Intel / AMD / ARM) |
| GPU mining | **Not supported** (RandomX is CPU-only by design) |
| Electricity cost | Low (CPU mining = ~50–100W) |

---

## What you need

- A computer with a recent CPU (4+ cores recommended)
- Linux, macOS, or Windows
- ~2 GB free RAM
- ~10 GB free disk space (for the blockchain)
- A working internet connection
- About 30 minutes to set up

---

## Step 1 — Get the Xernix daemon

You have two options:

### Option A: Pre-built binary (easier, when available)

Once the project ships releases on GitHub, download the binary for your OS from:

```
https://github.com/<your-username>/xernix/releases
```

### Option B: Build from source (works today)

```bash
# 1. Get the Xernix repo
git clone https://github.com/<your-username>/xernix.git
cd xernix/xernix-daemon

# 2. Build the Docker image (Monero v0.18.3.4 + Xernix patches)
docker build -t xernix:latest .

# This takes 25–45 minutes the first time.
```

If you don't want Docker, follow `DEPLOYMENT.md` for a manual compile.

---

## Step 2 — Run a Xernix node

```bash
docker run -d \
  --name xernix-node \
  -p 28080:28080 \
  -p 28081:28081 \
  -v xernix-data:/home/xernix/.xernix \
  xernix:latest
```

Check it's running:

```bash
docker logs -f xernix-node
```

You should see lines like:

```
[INFO ] Xernix testnet starting
[INFO ] Loading blockchain from /home/xernix/.xernix/lmdb
[INFO ] Connecting to seed nodes...
[INFO ] Synced height: 1234 / 1234
```

When it says **"Synced"**, you are connected to the Xernix network.

---

## Step 3 — Create your wallet

```bash
docker exec -it xernix-node xernix-wallet-cli \
  --testnet \
  --generate-new-wallet /home/xernix/.xernix/my-wallet \
  --daemon-address 127.0.0.1:28081
```

Follow the prompts:

1. Choose a strong password
2. **Write down the 25-word seed phrase** on paper. Keep it offline. This is the only way to recover your wallet.
3. The wallet will display your XRX address (starts with `Xt...`)

⚠️ **Anyone with your seed phrase can steal your XRX. Never share it.**

---

## Step 4 — Start mining

Inside the wallet CLI, run:

```
start_mining 4
```

The number `4` is how many CPU threads to use. Recommended: half your CPU cores.

The wallet will display:

```
Mining started with 4 threads
Hashrate: 1234 H/s
```

That's it. You are now mining XRX.

To stop:

```
stop_mining
```

---

## Step 5 — Check your balance

```
balance
```

Mined coins take **60 blocks (~2 hours)** to mature before you can spend them.

---

## Pool mining (when pools exist)

Solo mining at 1 KH/s on a typical laptop, you might find 1 block every few weeks.
For more regular rewards, join a mining pool:

```
start_mining 4 --pool-address pool.example.com:3333 --wallet-address Xt...
```

(Pools will be listed on the official Xernix site once the community grows.)

---

## How to send XRX

```
transfer Xt<recipient-address> <amount>
```

Example:

```
transfer Xt7Hk...8mP 5.0
```

The wallet will:

1. Show you the fee
2. Show you the **1.5% burn output** (this is the Xernix burn mechanism)
3. Ask you to confirm

After confirmation, the transaction is broadcast to the Xernix network.

---

## Privacy

Xernix inherits Monero's privacy by default:

- ✅ Ring signatures (your transaction is hidden among 16 others)
- ✅ Stealth addresses (recipient identity is hidden)
- ✅ RingCT (transaction amount is hidden)
- ✅ Bulletproofs+ (efficient zero-knowledge proofs)
- ✅ Tor support (`--tx-proxy` option)

Your XRX transactions are **untraceable by default**. No setup required.

---

## Troubleshooting

### "Daemon not running"
```bash
docker restart xernix-node
docker logs -f xernix-node
```

### "Could not connect to peers"
Check your firewall allows TCP port 28080 outbound.

### "Wallet refused"
Make sure the daemon is fully synced (`sync_info` in the wallet should show 100%).

### "Out of memory" during build
The Monero build needs ~4 GB RAM. Add swap or use a bigger machine.

---

## Verify you are on the real Xernix network

The Xernix testnet has these unique constants:

```
Network ID UUID:    78 65 72 6e 69 78 2d 74 65 73 74 2d 6e 65 74 01
                    (ASCII: "xernix-test-net" + 0x01)
Genesis nonce:      21000000
Address prefix:     88 (addresses start with "Xt")
P2P port:           28080
RPC port:           28081
```

If your daemon is on a different network ID, you are on the wrong chain.

---

## Get help

- GitHub Issues: `https://github.com/<your-username>/xernix/issues`
- Reddit: r/Xernix (when it exists)
- Discord/Telegram: links on the official site

---

## Disclaimer

Xernix is **pre-launch testnet software**. The XRX you mine has **no current
market value**. There is no guarantee XRX will ever be listed on an exchange
or have any value. Mine for fun, learning, or to support a decentralized
privacy-preserving currency — not for profit speculation.

Mining electricity costs are paid by you. Mined coins are yours to keep.
The project creator receives no portion of mining rewards.
