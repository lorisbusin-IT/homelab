# 🌐 Netzwerk Setup

## Übersicht
Internet
│
▼
Swisscom Internet-Box 5 (192.168.1.1)
│
▼
Proxmox Host (192.168.1.150)
│
├── Pi-hole (192.168.1.151) - DNS
├── WireGuard (192.168.1.159) - VPN
├── Caddy (192.168.1.200) - Reverse Proxy
└── Alle anderen Services...

## IP Schema

| Bereich | Verwendung |
|---------|------------|
| 192.168.1.1 | Router |
| 192.168.1.2-149 | Normale Geräte |
| 192.168.1.150 | Proxmox Host |
| 192.168.1.151-210 | Homelab Services |

## Pi-hole Setup

```bash
# Installation
curl -sSL https://install.pi-hole.net | bash

# Router DNS setzen
# Internet-Box 5: Einstellungen → Netzwerk → DNS
# DNS 1: 192.168.1.151
# DNS 2: 1.1.1.1 (Fallback)

# Lokale DNS Einträge (optional)
# /etc/pihole/custom.list
192.168.1.168 jellyfin.local
192.168.1.166 immich.local
```

## DuckDNS Setup

```bash
# 1. Account erstellen auf duckdns.org
# 2. Domain erstellen (z.B. mein-homelab.duckdns.org)
# 3. Token kopieren

# Auto-Update Cronjob
mkdir -p /opt/duckdns
cat > /opt/duckdns/duck.sh << 'DUCK'
echo url="https://www.duckdns.org/update?domains=DEINE_DOMAIN&token=DEIN_TOKEN&ip=" | curl -k -o /opt/duckdns/duck.log -K -
DUCK

chmod +x /opt/duckdns/duck.sh
# Cronjob alle 5 Minuten
echo "*/5 * * * * /opt/duckdns/duck.sh" | crontab -
```

## WireGuard VPN

```bash
# Port am Router weiterleiten
# Internet-Box 5: Einstellungen → Portweiterleitung
# Port: 10086 UDP → 192.168.1.159:10086

# Nach VPN Verbindung erreichbar:
# Alle Services über interne IPs zugänglich
# Kein Internetzugriff nötig
```

## Caddy Reverse Proxy

```bash
# Vorteile von Caddy:
# - Automatisches HTTPS via Let's Encrypt
# - Einfache Konfiguration
# - DuckDNS Plugin für wildcard Zertifikate

# Ports am Router weiterleiten:
# 80 TCP → 192.168.1.200:80
# 443 TCP → 192.168.1.200:443
```

## Firewall Empfehlungen

```bash
# Auf Proxmox Host
# Nur nötige Ports öffnen:
# 8006 - Proxmox Web UI (nur intern!)
# 22 - SSH (nur intern!)

# Services nie direkt ins Internet!
# Immer via Caddy Reverse Proxy oder WireGuard
```
