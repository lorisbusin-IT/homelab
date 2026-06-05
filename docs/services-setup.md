# 🛠️ Services Installation

## Pi-hole (CT 100)

```bash
# Container: Debian 12, 512MB RAM, 8GB Disk, IP: 192.168.1.151

# Installation
curl -sSL https://install.pi-hole.net | bash

# Nach Installation
# Web UI: http://192.168.1.151/admin
# Passwort setzen:
pihole -a -p DEIN_PASSWORT

# Router DNS auf 192.168.1.151 setzen!
```

## Vaultwarden (CT 101)

```bash
# Container: Debian 12, 256MB RAM, 8GB Disk, IP: 192.168.1.154

# Docker installieren
curl -fsSL https://get.docker.com | sh

# Vaultwarden starten
docker run -d \
  --name vaultwarden \
  --restart always \
  -v /vw-data:/data \
  -p 8000:80 \
  vaultwarden/server:latest

# Web UI: http://192.168.1.154:8000
```

## WireGuard (CT 102)

```bash
# Container: Debian 12, PRIVILEGIERT!, 256MB RAM, IP: 192.168.1.159
# Port 10086/UDP am Router weiterleiten!

# Installation mit wg-easy
docker run -d \
  --name wg-easy \
  --restart always \
  --cap-add NET_ADMIN \
  --cap-add SYS_MODULE \
  -e WG_HOST=DEINE_DUCKDNS_DOMAIN \
  -e PASSWORD=DEIN_PASSWORT \
  -v ~/.wg-easy:/etc/wireguard \
  -p 51820:51820/udp \
  -p 51821:51821/tcp \
  ghcr.io/wg-easy/wg-easy

# Web UI: http://192.168.1.159:51821
```

## Uptime Kuma (CT 103)

```bash
# Container: Debian 12, 512MB RAM, 8GB Disk, IP: 192.168.1.161

# Node.js installieren
curl -fsSL https://deb.nodesource.com/setup_18.x | bash
apt install -y nodejs

# Uptime Kuma installieren
npm install pm2 -g
git clone https://github.com/louislam/uptime-kuma.git
cd uptime-kuma
npm run setup
pm2 start server/server.js --name uptime-kuma
pm2 save && pm2 startup

# Web UI: http://192.168.1.161:3001
```

## Immich (CT 107)

```bash
# Container: Debian 12, 2GB RAM, 32GB Disk, IP: 192.168.1.166

# Docker installieren
curl -fsSL https://get.docker.com | sh

# Immich installieren
mkdir /opt/immich && cd /opt/immich
wget https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
wget -O .env https://github.com/immich-app/immich/releases/latest/download/example.env

# .env anpassen
nano .env
# UPLOAD_LOCATION=/opt/immich/library
# DB_PASSWORD=DEIN_PASSWORT

docker compose up -d

# Web UI: http://192.168.1.166:2283
```

## Jellyfin (CT 108)

```bash
# Container: Debian 12, 2GB RAM, 16GB Disk, IP: 192.168.1.168

# Repository hinzufügen
curl -fsSL https://repo.jellyfin.org/install-debuntu.sh | bash

# Jellyfin installieren
apt install jellyfin -y
systemctl enable --now jellyfin

# Web UI: http://192.168.1.168:8096
```

## Nextcloud (CT 109)

```bash
# Container: Debian 12, 1GB RAM, 32GB Disk, IP: 192.168.1.169

# Nextcloud AIO (empfohlen)
docker run -d \
  --name nextcloud-aio-mastercontainer \
  --restart always \
  -p 8080:8080 \
  -v nextcloud_aio_mastercontainer:/mnt/docker-aio-config \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  nextcloud/all-in-one:latest

# Setup: http://192.168.1.169:8080
```

## Ollama + Open WebUI (CT 113 + 111)

```bash
# Ollama (CT 113) - 4GB RAM, 32GB Disk
curl -fsSL https://ollama.ai/install.sh | sh
systemctl enable --now ollama

# Modelle herunterladen
ollama pull llama3.2
ollama pull mistral

# Open WebUI (CT 111) - 1GB RAM, 16GB Disk
docker run -d \
  --name open-webui \
  --restart always \
  -p 8080:8080 \
  -e OLLAMA_BASE_URL=http://192.168.1.179:11434 \
  -v open-webui:/app/backend/data \
  ghcr.io/open-webui/open-webui:main

# Web UI: http://192.168.1.180:8080
```

## Ntfy (CT 114)

```bash
# Container: Debian 12, 256MB RAM, 4GB Disk, IP: 192.168.1.182

# Installation
apt install ntfy -y
systemctl enable --now ntfy

# Konfiguration
nano /etc/ntfy/server.yml
# base-url: http://192.168.1.182
# listen-http: :80

systemctl restart ntfy

# Test
curl -d "Hallo Homelab!" http://192.168.1.182/homelab-alerts
```

## Gitea (CT 120)

```bash
# Container: Debian 12, 512MB RAM, 16GB Disk, IP: 192.168.1.193

# Git und Dependencies
apt install git -y

# Gitea herunterladen
wget https://dl.gitea.com/gitea/1.21.0/gitea-1.21.0-linux-amd64 -O /usr/local/bin/gitea
chmod +x /usr/local/bin/gitea

# User erstellen
adduser --system --shell /bin/bash --gecos 'Gitea' --group --disabled-password --home /home/gitea gitea

# Service erstellen
cat > /etc/systemd/system/gitea.service << 'SERVICE'
[Unit]
Description=Gitea
After=network.target

[Service]
User=gitea
WorkingDirectory=/home/gitea
ExecStart=/usr/local/bin/gitea web --port 3000
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl enable --now gitea
# Web UI: http://192.168.1.193:3000
```

## n8n (CT 121)

```bash
# Container: Debian 12, 1GB RAM, 16GB Disk, IP: 192.168.1.194

# Node.js installieren
curl -fsSL https://deb.nodesource.com/setup_20.x | bash
apt install -y nodejs

# n8n installieren
npm install -g n8n

# Service erstellen
cat > /etc/systemd/system/n8n.service << 'SERVICE'
[Unit]
Description=n8n
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/n8n start
Restart=always
Environment=N8N_PORT=5678

[Install]
WantedBy=multi-user.target
SERVICE

systemctl enable --now n8n
# Web UI: http://192.168.1.194:5678
```

## Homarr (CT 124)

```bash
# Container: Debian 12, 512MB RAM, 8GB Disk, IP: 192.168.1.199

docker run -d \
  --name homarr \
  --restart always \
  -p 7575:7575 \
  -v /opt/homarr/configs:/app/data/configs \
  -v /opt/homarr/icons:/app/public/icons \
  ghcr.io/ajnart/homarr:latest

# Web UI: http://192.168.1.199:7575
```

## Caddy (CT 125)

```bash
# Container: Debian 12, 256MB RAM, 4GB Disk, IP: 192.168.1.200

# Caddy installieren
apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt update && apt install caddy -y

# Caddy mit DuckDNS Plugin bauen
# https://caddyserver.com/download?package=github.com%2Fcaddy-dns%2Fduckdns

# Caddyfile Beispiel
cat > /etc/caddy/Caddyfile << 'CADDY'
{
    email deine@email.com
}

jellyfin.deine-domain.duckdns.org {
    reverse_proxy 192.168.1.168:8096
}

nextcloud.deine-domain.duckdns.org {
    reverse_proxy 192.168.1.169:443
}
CADDY

systemctl restart caddy
```
