# 🗺️ Weltmap

## Beschreibung
Interaktive Weltkarte um besuchte Orte und Wunschziele zu markieren.

## Features
- 📍 Orte als "Besucht" oder "Wunschliste" markieren
- 📝 Notizen zu jedem Ort hinzufügen
- 📊 Statistiken (Anzahl besuchte Länder, Orte etc.)
- 💾 Daten werden im localStorage gespeichert
- 🌍 OpenStreetMap als Kartenbasis

## Technologien
- **Frontend:** HTML, CSS, JavaScript
- **Karte:** Leaflet.js + OpenStreetMap
- **Webserver:** Nginx
- **Datenbank:** localStorage (kein Backend nötig)

## Installation

```bash
# Container erstellen (Debian 12, 256MB RAM, 4GB Disk)
pct create 126 /var/lib/vz/template/cache/debian-12-standard_12.7-1_amd64.tar.zst \
  --hostname weltmap \
  --memory 256 \
  --rootfs local-lvm:4 \
  --net0 name=eth0,bridge=vmbr0,ip=192.168.1.196/24,gw=192.168.1.1 \
  --unprivileged 1 \
  --start 1

# Nginx installieren
apt update && apt install nginx -y

# index.html nach /var/www/html/ kopieren
systemctl enable --now nginx
```

## Zugriff
- URL: http://192.168.1.196
