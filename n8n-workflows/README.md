# 🤖 n8n Automation Workflows

## Übersicht
Alle Workflows schicken Benachrichtigungen via Ntfy.

## Workflows

### 1. 🌤️ Täglicher Wetterbericht
- **Trigger:** Täglich 08:00
- **API:** wttr.in/Zurich
- **Daten:** Temperatur, Wetter, Luftfeuchtigkeit, Wind

### 2. 🖥️ Homelab Status Report
- **Trigger:** Täglich 08:00
- **API:** Proxmox API
- **Daten:** CPU, RAM, Disk, Uptime

### 3. 📸 Immich Foto Zusammenfassung
- **Trigger:** Täglich 08:00
- **API:** Immich API
- **Daten:** Neuestes Foto

### 4. 🎮 Minecraft Server Status
- **Trigger:** Alle 5 Minuten
- **API:** Crafty Controller API
- **Daten:** Online/Offline Status

### 5. 🖥️ Neues Gerät im Netzwerk
- **Trigger:** Alle 5 Minuten
- **API:** NetSpy API
- **Daten:** Neue Geräte mit IP und MAC

### 6. ⚠️ Service Down Alert
- **Trigger:** Uptime Kuma Webhook
- **Daten:** Service Name, Status

### 7. 🔥 Proxmox CPU/RAM/Disk Alert
- **Trigger:** Alle 5 Minuten
- **Schwellwert:** >80%
- **Daten:** Aktuelle Auslastung
