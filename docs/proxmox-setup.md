# 🔧 Proxmox VE Setup

## Installation

### 1. ISO herunterladen
```bash
# Proxmox VE ISO von https://www.proxmox.com/en/downloads
# Aktuelle Version: Proxmox VE 9.x
```

### 2. USB erstellen
```bash
# Mit Balena Etcher (Windows/Mac/Linux)
# Oder mit dd (Linux):
dd if=proxmox-ve_9.x.iso of=/dev/sdX bs=1M status=progress
```

### 3. Installation
1. Von USB booten
2. "Install Proxmox VE" wählen
3. Festplatte wählen (ext4 reicht)
4. Land: Switzerland, Timezone: Europe/Zurich
5. Passwort setzen
6. IP Adresse setzen (z.B. 192.168.1.150/24)
7. Gateway: 192.168.1.1
8. DNS: 192.168.1.1

### 4. Nach der Installation

#### Kein Enterprise Repository (für Privatnutzer)
```bash
# Enterprise Repo deaktivieren
sed -i 's/^deb/#deb/' /etc/apt/sources.list.d/pve-enterprise.list

# Community Repo aktivieren
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" >> /etc/apt/sources.list

# Updates installieren
apt update && apt upgrade -y
```

#### Keine Subscription Warnung
```bash
sed -Ezi.bak "s/(Ext.Msg.show\(\{[\s\S]*?title: gettext\('No valid sub)/void\(\{\/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
systemctl restart pveproxy.service
```

#### Dark Mode aktivieren
```bash
wget https://raw.githubusercontent.com/Weilbyte/PVEDiscordDark/master/PVEDiscordDark.sh
bash PVEDiscordDark.sh install
```

## Nützliche Proxmox Befehle

```bash
# Container Status
pct list

# Container starten/stoppen
pct start 100
pct stop 100

# In Container einloggen
pct exec 100 -- bash

# Container erstellen
pct create 100 /var/lib/vz/template/cache/debian-12.tar.zst \
  --hostname meincontainer \
  --memory 512 \
  --rootfs local-lvm:8 \
  --net0 name=eth0,bridge=vmbr0,ip=192.168.1.xxx/24,gw=192.168.1.1 \
  --unprivileged 1 \
  --start 1

# VM erstellen (Beispiel)
qm create 106 --name homeassistant --memory 2048 --cores 2 \
  --net0 virtio,bridge=vmbr0 --bootdisk scsi0

# Backup erstellen
vzdump 100 --storage local --compress zstd

# Ressourcen anzeigen
pvesh get /nodes/proxmox/status
```

## Pools erstellen
```bash
# Über Web UI: Datacenter → Pools → Create
# Empfohlene Pools:
# - Core (Pi-hole, WireGuard, Caddy)
# - Media (Jellyfin, Immich, Nextcloud)
# - AI-Tools (Ollama, Open WebUI)
# - Network (NetSpy, Uptime Kuma)
# - Dev (Gitea, n8n, Portainer)
# - Projekte (Eigene Projekte)
```
