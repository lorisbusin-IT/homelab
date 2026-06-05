# 🎵 BeatLab Studio

## Beschreibung
Eine vollständige Online DAW (Digital Audio Workstation) direkt im Browser.

## Features
- 🥁 Drum Sequencer mit 9 Spuren und realistischen Sounds
- 🎹 Piano mit mehreren Oktaven und Wellenformen
- 🎸 Gitarre mit Akkorden und Fret-Ansicht
- 🎚️ Mixer mit FX:
  - Hall (Reverb)
  - Echo (Delay)
  - Bass Boost
  - Höhen
  - Speed
  - Pitch
  - Kompressor
  - Verzerrer
- 💾 Beats speichern und laden via API

## Technologien
- **Backend:** Python Flask
- **Audio:** Web Audio API
- **Frontend:** HTML, CSS, JavaScript
- **Storage:** JSON Dateien

## Installation

```bash
# Container erstellen (Debian 12, 512MB RAM, 8GB Disk)
pct create 131 /var/lib/vz/template/cache/debian-12-standard_12.7-1_amd64.tar.zst \
  --hostname beatlab \
  --memory 512 \
  --rootfs local-lvm:8 \
  --net0 name=eth0,bridge=vmbr0,ip=192.168.1.204/24,gw=192.168.1.1 \
  --unprivileged 1 \
  --start 1

apt update && apt install python3 python3-pip nginx -y
pip3 install flask --break-system-packages

cat > /etc/systemd/system/beat.service << 'SERVICE'
[Unit]
Description=BeatLab Studio
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/beat.py
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl enable --now beat.service
```

## Zugriff
- URL: http://192.168.1.204:5000
