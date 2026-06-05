# 🌐 Netzwerk Setup

## IP Schema
Alle Homelab Services bekommen feste IPs ab .150

## Pi-hole Setup
1. LXC Container erstellen (Debian 12)
2. Installation: `curl -sSL https://install.pi-hole.net | bash`
3. Router DNS auf Pi-hole IP setzen
4. Alle Geräte bekommen automatisch Ad-Blocking

## WireGuard Setup
1. LXC Container erstellen (privilegiert!)
2. WireGuard installieren
3. Port 10086 am Router weiterleiten
4. Client Config generieren und importieren

## Caddy Reverse Proxy
1. LXC Container erstellen
2. Caddy installieren
3. Caddyfile konfigurieren
4. DuckDNS Token für automatisches HTTPS

## DuckDNS
- Kostenlose DDNS Domain
- Automatisches Update per Cronjob
- Zusammen mit Caddy für HTTPS
