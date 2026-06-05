# 🛠️ Setup Guide

## Proxmox Installation
1. Proxmox VE ISO herunterladen von https://www.proxmox.com
2. Auf USB flashen mit Balena Etcher
3. Installieren und IP setzen

## Container erstellen
- Template: Debian 12
- Unprivileged: Ja
- RAM: je nach Service 512MB - 2GB
- Disk: je nach Service 8GB - 32GB

## Netzwerk Setup
- Feste IPs ab 192.168.1.150 vergeben
- Pi-hole als DNS Server setzen
- WireGuard für VPN Zugang
