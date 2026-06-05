# 💾 Backup Strategie

## Proxmox Backups

```bash
# Manuelles Backup eines Containers
vzdump 100 --storage local --compress zstd --mode snapshot

# Alle Container sichern
vzdump --all --storage local --compress zstd --mode snapshot

# Backup Schedule in Proxmox Web UI einrichten:
# Datacenter → Backup → Add
# Schedule: täglich um 02:00
# Storage: local
# Compression: ZSTD
```

## Wichtige Daten sichern

```bash
# Vaultwarden Daten
cp -r /vw-data /backup/vaultwarden-$(date +%Y%m%d)

# Pi-hole Konfiguration
pihole -a teleporter export

# n8n Workflows exportieren
# n8n Web UI → Settings → Export
```

## Backup auf externen Speicher

```bash
# Mit rsync auf NAS oder externe Festplatte
rsync -avz /var/lib/vz/dump/ user@nas:/backup/proxmox/

# Mit rclone auf Cloud (z.B. Backblaze B2)
rclone sync /var/lib/vz/dump/ b2:mein-backup-bucket/proxmox/
```
