# Xernix Daemon — pulls pre-built image from GitHub Container Registry.
# The actual Monero compilation happens in GitHub Actions (see .github/workflows/docker-publish.yml).
# This keeps Replit deployment fast (pull ~200 MB image instead of 45-min compile).
FROM ghcr.io/achymoto/xernix-daemon:latest
