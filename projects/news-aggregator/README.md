# 📰 News Aggregator

## Beschreibung
Schweizer News Aggregator der Artikel von Tagesanzeiger und SRF sammelt und übersichtlich darstellt.

## Features
- 📡 RSS Feeds von Tagesanzeiger und SRF
- 📄 Artikel-Volltext Extraktion
- 🗄️ SQLite Datenbank
- 📚 Archiv Funktion
- 🔍 Artikel suchen

## Technologien
- **Backend:** Python Flask
- **RSS:** feedparser
- **Scraping:** BeautifulSoup4
- **Datenbank:** SQLite
- **Frontend:** HTML, CSS, JavaScript

## Installation

```bash
# Container erstellen (Debian 12, 512MB RAM, 8GB Disk)
pct create 127 /var/lib/vz/template/cache/debian-12-standard_12.7-1_amd64.tar.zst \
  --hostname news-aggregator \
  --memory 512 \
  --rootfs local-lvm:8 \
  --net0 name=eth0,bridge=vmbr0,ip=192.168.1.197/24,gw=192.168.1.1 \
  --unprivileged 1 \
  --start 1

# Dependencies installieren
apt update && apt install python3 python3-pip -y
pip3 install flask feedparser beautifulsoup4 requests --break-system-packages

# Service erstellen
cat > /etc/systemd/system/news.service << 'SERVICE'
[Unit]
Description=News Aggregator
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/news.py
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl enable --now news.service
```

## Zugriff
- URL: http://192.168.1.197:5000
