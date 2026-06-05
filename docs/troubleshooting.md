# 🔧 Troubleshooting

## Container startet nicht

```bash
# Status prüfen
pct status 100

# Logs anzeigen
pct exec 100 -- journalctl -xe

# Container neu starten
pct stop 100 && pct start 100
```

## Service nicht erreichbar

```bash
# Ist der Service aktiv?
pct exec 100 -- systemctl status SERVICENAME

# Port offen?
pct exec 100 -- ss -tlnp

# Firewall?
pct exec 100 -- iptables -L
```

## Proxmox Web UI nicht erreichbar

```bash
# Auf Proxmox Host direkt:
systemctl restart pveproxy
systemctl restart pvedaemon
```

## Container hat kein Internet

```bash
# DNS prüfen
pct exec 100 -- ping 1.1.1.1
pct exec 100 -- ping google.com

# Gateway prüfen
pct exec 100 -- ip route

# Pi-hole läuft?
pct exec 100 -- nslookup google.com 192.168.1.151
```

## Disk voll

```bash
# Speicher prüfen
df -h

# Alte Backups löschen
ls -lh /var/lib/vz/dump/
rm /var/lib/vz/dump/ALTE_BACKUP_DATEI

# Docker aufräumen
docker system prune -a
```
