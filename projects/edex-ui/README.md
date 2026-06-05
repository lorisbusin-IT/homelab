# 🖥️ eDEX-UI

## Beschreibung
Ein futuristisches Terminal Dashboard inspiriert vom originalen eDEX-UI mit echten Proxmox Daten.

## Features
- 📊 Echte Proxmox API Daten (CPU, RAM, Disk, Uptime)
- 💻 Terminal mit echten Linux Befehlen
- 🎨 Themes: Grün, Rot, Blau, Lila, Orange, Weiss, Inter Milan
- 🥚 Easter Eggs: hack, doom, coffee, rainbow, sudo, rm -rf
- ⌨️ Tab Autocomplete
- 🔊 Sound Effekte
- 📡 Ping Monitor
- 📝 Notes
- 📦 CT Stats Overlays

## Technologien
- **Backend:** Python Flask
- **API:** Proxmox API
- **Frontend:** HTML, CSS, JavaScript
- **Webserver:** Nginx (Port 80) + Flask (Port 5000)

## Installation

```bash
# Container erstellen (Debian 12, 512MB RAM, 8GB Disk)
pct create 133 /var/lib/vz/template/cache/debian-12-standard_12.7-1_amd64.tar.zst \
  --hostname edex-ui \
  --memory 512 \
  --rootfs local-lvm:8 \
  --net0 name=eth0,bridge=vmbr0,ip=192.168.1.206/24,gw=192.168.1.1 \
  --unprivileged 1 \
  --start 1

apt update && apt install python3 python3-pip nginx -y
pip3 install flask requests --break-system-packages

cat > /etc/systemd/system/edex.service << 'SERVICE'
[Unit]
Description=eDEX-UI
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/edex.py
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl enable --now edex.service
```

## Proxmox API Token
Benötigt einen Proxmox API Token mit read-only Rechten:
- Proxmox Web UI → Datacenter → API Tokens → Add

## Zugriff
- URL: http://192.168.1.206
