# 📦 Container Übersicht

## Alle Container

| CT | Name | IP | Port | RAM | Disk |
|----|------|----|------|-----|------|
| 100 | Pi-hole | 192.168.1.151 | 80 | 512MB | 8GB |
| 101 | Vaultwarden | 192.168.1.154 | 8000 | 256MB | 8GB |
| 102 | WireGuard | 192.168.1.159 | 1008 | 256MB | 4GB |
| 103 | Uptime Kuma | 192.168.1.161 | 3001 | 512MB | 8GB |
| 105 | Crafty Controller | 192.168.1.163 | 8443 | 2GB | 16GB |
| 106 | Home Assistant (VM) | 192.168.1.165 | 8123 | 2GB | 32GB |
| 107 | Immich | 192.168.1.166 | 2283 | 2GB | 32GB |
| 108 | Jellyfin | 192.168.1.168 | 8096 | 2GB | 16GB |
| 109 | Nextcloud | 192.168.1.169 | 443 | 1GB | 32GB |
| 111 | Open WebUI | 192.168.1.180 | 8080 | 1GB | 16GB |
| 113 | Ollama | 192.168.1.179 | 11434 | 4GB | 32GB |
| 114 | Ntfy | 192.168.1.182 | 80 | 256MB | 4GB |
| 116 | Docker + Portainer | 192.168.1.187 | 9443 | 2GB | 32GB |
| 119 | Romm | 192.168.1.195 | 80 | 512MB | 16GB |
| 120 | Gitea | 192.168.1.193 | 3000 | 512MB | 16GB |
| 121 | n8n | 192.168.1.194 | 5678 | 1GB | 16GB |
| 123 | IT-Tools | 192.168.1.198 | 80 | 256MB | 4GB |
| 124 | Homarr | 192.168.1.199 | 7575 | 512MB | 8GB |
| 125 | Caddy | 192.168.1.200 | 443 | 256MB | 4GB |
| 126 | Weltmap | 192.168.1.196 | 80 | 256MB | 4GB |
| 127 | News Aggregator | 192.168.1.197 | 5000 | 512MB | 8GB |
| 128 | NetSpy | 192.168.1.201 | 5000 | 512MB | 8GB |
| 130 | Spiele-Plattform | 192.168.1.203 | 80 | 256MB | 4GB |
| 131 | BeatLab Studio | 192.168.1.204 | 5000 | 512MB | 8GB |
| 133 | eDEX-UI | 192.168.1.206 | 5000 | 512MB | 8GB |

## Container Template herunterladen
```bash
# Debian 12 Template herunterladen
pveam update
pveam download local debian-12-standard_12.7-1_amd64.tar.zst
```

## Standard Container erstellen
```bash
# Basis Container mit Debian 12
pct create XXX /var/lib/vz/template/cache/debian-12-standard_12.7-1_amd64.tar.zst \
  --hostname SERVICENAME \
  --memory 512 \
  --swap 512 \
  --rootfs local-lvm:8 \
  --net0 name=eth0,bridge=vmbr0,ip=192.168.1.XXX/24,gw=192.168.1.1 \
  --nameserver 192.168.1.151 \
  --unprivileged 1 \
  --features nesting=1 \
  --start 1

# In Container einloggen
pct exec XXX -- bash

# System updaten
apt update && apt upgrade -y
```
