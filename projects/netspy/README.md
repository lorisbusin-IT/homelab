# 🔍 NetSpy

## Beschreibung
Professionelles Netzwerk-Scanner Dashboard das alle Geräte im Netzwerk überwacht und kategorisiert.

## Features
- 🔍 Automatisches Netzwerk-Scanning mit Nmap
- 📊 Professionelles Dashboard mit Sidebar
- 🏷️ Geräte kategorisieren und umbenennen
- ⭐ Favoriten markieren
- 📝 Notizen zu Geräten
- 🗺️ Netzwerk-Karte mit Kategorien als Hubs
- 📋 Pi-hole DNS Log Integration
- 🔌 REST API für externe Zugriffe

## Technologien
- **Backend:** Python Flask
- **Scanner:** Nmap
- **Datenbank:** SQLite
- **Frontend:** HTML, CSS, JavaScript
- **DNS Logs:** Pi-hole API

## Installation

```bash
# Container erstellen (Debian 12, PRIVILEGIERT!, 512MB RAM, 8GB Disk)
pct create 128 /var/lib/vz/template/cache/debian-12-standard_12.7-1_amd64.tar.zst \
  --hostname netspy \
  --memory 512 \
  --rootfs local-lvm:8 \
  --net0 name=eth0,bridge=vmbr0,ip=192.168.1.201/24,gw=192.168.1.1 \
  --unprivileged 0 \
  --start 1

# Dependencies installieren
apt update && apt install python3 python3-pip nmap -y
pip3 install flask --break-system-packages

# Service erstellen
cat > /etc/systemd/system/netspy.service << 'SERVICE'
[Unit]
Description=NetSpy
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/netspy.py
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl enable --now netspy.service
```

## API Endpoints
- GET /api/devices - Alle Geräte
- GET /api/devices/new - Neue Geräte

## Zugriff
- URL: http://192.168.1.201:5000
