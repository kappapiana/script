#!/bin/bash
# Flush DNS caches and trigger a synchronous reload of both network services
sudo resolvectl flush-caches && \
sudo systemctl restart systemd-resolved && \
sudo systemctl restart tailscaled && \
sudo tailscale up --accept-dns=true