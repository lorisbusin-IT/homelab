# 🔧 Caddy Konfiguration Beispiel
meinservice.meinedomain.duckdns.org {
reverse_proxy 192.168.1.XXX:PORT
tls {
dns duckdns DEIN_DUCKDNS_TOKEN
}
}
## Caddy Installation
```bash
apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt update && apt install caddy
```
