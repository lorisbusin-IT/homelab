# 🏠 Homelab by Loris

> Ein vollständiges Self-Hosted Homelab auf einem Proxmox VE Server – inspiriert von der Community, gebaut für den Alltag.

## 🖥️ Hardware

| Komponente | Details |
|------------|---------|
| Gerät | Lenovo ThinkCentre M720q Tiny |
| CPU | Intel i5-8400T (6 Kerne, 1.7-3.3GHz) |
| RAM | 16GB DDR4 |
| SSD | 256GB |
| OS | Proxmox VE 9.2.3 |

## 📁 Struktur
homelab/
├── docs/          # Dokumentation
├── projects/      # Eigene Projekte
├── n8n-workflows/ # Automation Workflows
└── config/        # Konfigurationsbeispiele
## 🚀 Quick Start

1. Proxmox VE installieren
2. Container nach Anleitung erstellen
3. Services konfigurieren
4. n8n Workflows importieren

## 📚 Dokumentation

- [Hardware & Setup](docs/hardware.md)
- [Netzwerk](docs/networking.md)
- [Services](docs/services.md)
- [Container Setup](docs/containers.md)
- [n8n Workflows](n8n-workflows/README.md)
- [Eigene Projekte](projects/README.md)

## ⭐ Features

- 🔒 Sicherer Fernzugriff via WireGuard VPN
- 🌐 HTTPS für alle Services via Caddy
- 🚫 Ad-Blocking via Pi-hole
- 📊 Monitoring via Uptime Kuma
- 🤖 Automation via n8n
- 📱 Push Benachrichtigungen via Ntfy
- 🤖 Lokale KI via Ollama + Open WebUI
