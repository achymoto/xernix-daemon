# Xernix daemon — built from a Monero source fork.
# Stage 1: build the daemon and CLI wallet from a renamed Monero clone.
# Stage 2: minimal runtime image that only ships the binaries + entry scripts.
#
# This Dockerfile is intended to be deployed on a Replit Reserved VM (or any
# Docker host with at least 4 vCPU + 8 GB RAM). The build step takes 25–45
# minutes depending on the machine. See README.md for deployment steps.

ARG MONERO_REF=v0.18.3.4
ARG XERNIX_NETWORK=testnet

# ---------------------------------------------------------------------------
# Stage 1 — builder
# ---------------------------------------------------------------------------
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake pkg-config git ca-certificates \
    libboost-all-dev libssl-dev libzmq3-dev libunbound-dev \
    libsodium-dev libunwind8-dev liblzma-dev libreadline6-dev \
    libldns-dev libexpat1-dev libgtest-dev doxygen graphviz \
    libpgm-dev libnorm-dev libusb-1.0-0-dev libudev-dev \
    libhidapi-dev libprotobuf-dev protobuf-compiler libssl-dev \
    python3 ccache curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

ARG MONERO_REF
RUN git clone --recursive --depth 1 --branch ${MONERO_REF} \
    https://github.com/monero-project/monero.git monero

# Copy Xernix patches and apply them to the Monero source tree.
COPY apply-xernix-patches.sh /src/apply-xernix-patches.sh
COPY patches/ /src/patches/

RUN chmod +x /src/apply-xernix-patches.sh && /src/apply-xernix-patches.sh /src/monero

WORKDIR /src/monero

# Compile the daemon and wallet binaries. -j uses all available CPUs.
RUN make release-static -j"$(nproc)"

# ---------------------------------------------------------------------------
# Stage 2 — runtime
# ---------------------------------------------------------------------------
FROM ubuntu:22.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    libboost-system-dev libboost-thread-dev libboost-filesystem-dev \
    libboost-program-options-dev libboost-chrono-dev libboost-regex-dev \
    libboost-serialization-dev libboost-locale-dev libssl3 libzmq5 \
    libunbound8 libsodium23 libunwind8 libreadline8 libpgm-5.3-0 \
    libnorm1 libhidapi-libusb0 ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

# Renamed binaries: monerod -> xernixd, monero-wallet-cli -> xernix-wallet-cli.
COPY --from=builder /src/monero/build/release/bin/monerod          /usr/local/bin/xernixd
COPY --from=builder /src/monero/build/release/bin/monero-wallet-cli /usr/local/bin/xernix-wallet-cli
COPY --from=builder /src/monero/build/release/bin/monero-wallet-rpc /usr/local/bin/xernix-wallet-rpc

COPY config/xernix.conf       /etc/xernix/xernix.conf
COPY scripts/start-seed-node.sh /usr/local/bin/start-seed-node.sh
COPY scripts/start-wallet-rpc.sh /usr/local/bin/start-wallet-rpc.sh
RUN chmod +x /usr/local/bin/start-seed-node.sh /usr/local/bin/start-wallet-rpc.sh \
    && mkdir -p /var/lib/xernix /var/log/xernix \
    && useradd -r -u 1500 -d /var/lib/xernix xernix \
    && chown -R xernix:xernix /var/lib/xernix /var/log/xernix /etc/xernix

USER xernix
WORKDIR /var/lib/xernix

# P2P, RPC, and ZMQ ports for the Xernix testnet.
EXPOSE 28080 28081 28082

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -fs http://127.0.0.1:28081/get_info >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/start-seed-node.sh"]
