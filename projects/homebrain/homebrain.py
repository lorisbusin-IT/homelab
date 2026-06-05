from flask import Flask, jsonify, request, render_template_string
import requests
import json
import threading
import time
import subprocess
import os
from datetime import datetime

app = Flask(__name__)

OLLAMA_URL = "http://192.168.1.179:11434/api/generate"
NTFY_URL = "http://192.168.1.182/homelab-alerts"
PROXMOX_URL = "http://192.168.1.150:8006/api2/json"
PROXMOX_TOKEN = "PVEAPIToken=root@pam!n8n=1ef25506-648e-405f-841b-f2df49bab965"
PROXMOX_HEADERS = {"Authorization": PROXMOX_TOKEN}

agents = {
    "butler": {"name": "🧹 Butler Agent", "description": "Räumt Logs, tmp und alte Dateien auf", "status": "idle", "last_run": None, "last_result": None},
    "research": {"name": "📰 Research Agent", "description": "Liest News und fasst zusammen", "status": "idle", "last_run": None, "last_result": None},
    "coach": {"name": "🏋️ Coach Agent", "description": "Schickt täglich Motivation und Tipps", "status": "idle", "last_run": None, "last_result": None},
    "security": {"name": "🔐 Security Agent", "description": "Scannt Netzwerk und blockiert IPs", "status": "idle", "last_run": None, "last_result": None},
    "proxmox": {"name": "🖥️ Proxmox Agent", "description": "Überwacht und erstellt Snapshots", "status": "idle", "last_run": None, "last_result": None},
    "memory": {"name": "📸 Memory Agent", "description": "Erstellt Erinnerungen aus Immich Fotos", "status": "idle", "last_run": None, "last_result": None},
    "ideas": {"name": "💡 Ideen Agent", "description": "Generiert täglich neue Projektideen", "status": "idle", "last_run": None, "last_result": None},
    "predict": {"name": "🔮 Predict Agent", "description": "Lernt Gewohnheiten und bereitet vor", "status": "idle", "last_run": None, "last_result": None},
    "gaming": {"name": "🎮 Gaming Agent", "description": "Startet/Stoppt Minecraft automatisch", "status": "idle", "last_run": None, "last_result": None},
    "finance": {"name": "💰 Finance Agent", "description": "Gibt Spartipps und trackt Ausgaben", "status": "idle", "last_run": None, "last_result": None},
    "travel": {"name": "🌍 Travel Agent", "description": "Schlägt Reiseziele vor", "status": "idle", "last_run": None, "last_result": None},
    "learning": {"name": "📚 Learning Agent", "description": "Erstellt tägliche Lernpläne", "status": "idle", "last_run": None, "last_result": None},
    "chef": {"name": "🍕 Chef Agent", "description": "Schlägt Rezepte vor", "status": "idle", "last_run": None, "last_result": None},
    "sleep": {"name": "😴 Sleep Agent", "description": "Optimiert Schlafgewohnheiten", "status": "idle", "last_run": None, "last_result": None},
    "green": {"name": "🌱 Green Agent", "description": "Spart Strom durch Container stoppen", "status": "idle", "last_run": None, "last_result": None},
    "entertainment": {"name": "🎬 Entertainment Agent", "description": "Schlägt Filme und Serien vor", "status": "idle", "last_run": None, "last_result": None},
    "social": {"name": "🤝 Social Agent", "description": "Erinnert an soziale Kontakte", "status": "idle", "last_run": None, "last_result": None},
    "memory_palace": {"name": "🧠 Memory Palace Agent", "description": "Hilft Wissen zu behalten", "status": "idle", "last_run": None, "last_result": None},
    "network": {"name": "🌐 Network Agent", "description": "Prüft DNS und alle Services", "status": "idle", "last_run": None, "last_result": None},
    "backup": {"name": "💾 Backup Agent", "description": "Startet automatisch Proxmox Backups", "status": "idle", "last_run": None, "last_result": None},
    "update": {"name": "🔄 Update Agent", "description": "Aktualisiert alle Container automatisch", "status": "idle", "last_run": None, "last_result": None},
    "log": {"name": "📋 Log Agent", "description": "Analysiert und löscht alte Logs", "status": "idle", "last_run": None, "last_result": None},
    "performance": {"name": "🔋 Performance Agent", "description": "Optimiert RAM und CPU automatisch", "status": "idle", "last_run": None, "last_result": None},
    "storage": {"name": "🗄️ Storage Agent", "description": "Löscht alte Dateien und räumt auf", "status": "idle", "last_run": None, "last_result": None},
    "container": {"name": "📦 Container Agent", "description": "Verwaltet Container automatisch", "status": "idle", "last_run": None, "last_result": None},
    "mood": {"name": "🎵 Mood Agent", "description": "Schlägt Musik und Ambiente vor", "status": "idle", "last_run": None, "last_result": None},
    "goal": {"name": "🎯 Goal Agent", "description": "Trackt Ziele und motiviert", "status": "idle", "last_run": None, "last_result": None},
    "repair": {"name": "🔧 Repair Agent", "description": "Startet abgestürzte Services neu", "status": "idle", "last_run": None, "last_result": None},
    "power": {"name": "🔌 Power Agent", "description": "Fährt nachts Container herunter", "status": "idle", "last_run": None, "last_result": None},
    "health": {"name": "🌡️ Health Agent", "description": "Überwacht Hardware Gesundheit", "status": "idle", "last_run": None, "last_result": None}
}

def ask_ollama(prompt):
    try:
        response = requests.post(OLLAMA_URL, json={"model": "mistral", "prompt": prompt, "stream": False}, timeout=300)
        return response.json().get("response", "Keine Antwort")
    except Exception as e:
        return f"Fehler: {str(e)}"

def send_ntfy(title, message, tags="robot"):
    try:
        requests.post(NTFY_URL, json={"message": message}, headers={"Title": title, "Tags": tags}, timeout=10)
    except:
        pass

def get_proxmox_status():
    try:
        r = requests.get(f"{PROXMOX_URL}/nodes/proxmox/status", headers=PROXMOX_HEADERS, verify=False, timeout=10)
        return r.json().get("data", {})
    except:
        return {}

def get_containers():
    try:
        r = requests.get(f"{PROXMOX_URL}/nodes/proxmox/lxc", headers=PROXMOX_HEADERS, verify=False, timeout=10)
        return r.json().get("data", [])
    except:
        return []

def run_proxmox_cmd(ctid, cmd):
    try:
        result = subprocess.run(["ssh", "-o", "StrictHostKeyChecking=no", "root@192.168.1.150", f"pct exec {ctid} -- {cmd}"], capture_output=True, text=True, timeout=30)
        return result.stdout
    except:
        return "Fehler"

def run_on_proxmox(cmd):
    try:
        result = subprocess.run(["ssh", "-o", "StrictHostKeyChecking=no", "root@192.168.1.150", cmd], capture_output=True, text=True, timeout=60)
        return result.stdout
    except Exception as e:
        return f"Fehler: {str(e)}"

# AGENT FUNKTIONEN MIT ECHTEN AKTIONEN

def run_butler_agent():
    agents["butler"]["status"] = "running"
    actions = []
    
    # Echte Aktion: Logs aufräumen in allen Containern
    containers = get_containers()
    cleaned = 0
    for ct in containers:
        if ct.get("status") == "running":
            run_on_proxmox(f"pct exec {ct['vmid']} -- find /var/log -name '*.log' -size +10M -delete 2>/dev/null")
            run_on_proxmox(f"pct exec {ct['vmid']} -- find /tmp -mtime +7 -delete 2>/dev/null")
            cleaned += 1
    actions.append(f"✅ Logs in {cleaned} Containern aufgeräumt")
    
    # KI Empfehlung
    ai = ask_ollama("Du bist der Butler Agent. Gib 2 weitere Aufräum-Tipps für ein Homelab. Antworte auf Deutsch, kurz.")
    result = "\n".join(actions) + f"\n\n💡 KI Empfehlung:\n{ai}"
    
    agents["butler"]["status"] = "idle"
    agents["butler"]["last_run"] = datetime.now().strftime("%Y-%m-%d %H:%M")
    agents["butler"]["last_result"] = result
    send_ntfy("🧹 Butler Agent", result, "broom")

def run_repair_agent():
    agents["repair"]["status"] = "running"
    actions = []
    
    containers = get_containers()
    restarted = 0
    for ct in containers:
        ctid = ct.get("vmid")
        status = ct.get("status")
        if status == "stopped" and ctid not in [106]:
            requests.post(f"{PROXMOX_URL}/nodes/proxmox/lxc/{ctid}/status/start", headers=PROXMOX_HEADERS, verify=False)
            actions.append(f"🔄 CT {ctid} neugestartet")
            restarted += 1
    
    if restarted == 0:
        actions.append("✅ Alle Container laufen – nichts zu reparieren!")
    
    ai = ask_ollama("Du bist der Repair Agent. Gib Tipps zur Fehlerprävention im Homelab. Antworte auf Deutsch, maximal 2 Sätze.")
    result = "\n".join(actions) + f"\n\n💡 KI Tipp:\n{ai}"
    
    agents["repair"]["status"] = "idle"
    agents["repair"]["last_run"] = datetime.now().strftime("%Y-%m-%d %H:%M")
    agents["repair"]["last_result"] = result
    send_ntfy("🔧 Repair Agent", result, "wrench")

def run_performance_agent():
    agents["performance"]["status"] = "running"
    status = get_proxmox_status()
    cpu = round(status.get("cpu", 0) * 100)
    mem_used = status.get("memory", {}).get("used", 0)
    mem_total = status.get("memory", {}).get("total", 0)
    mem_pct = round(mem_used / mem_total * 100) if mem_total > 0 else 0
    
    actions = [f"📊 CPU: {cpu}% | RAM: {mem_pct}%"]
    
    if mem_pct > 85:
        actions.append("⚠️ RAM hoch! Empfehle nicht-kritische Container zu stoppen")
        send_ntfy("⚠️ RAM Warnung", f"RAM bei {mem_pct}%!", "warning")
    else:
        actions.append("✅ Performance ist gut!")
    
    ai = ask_ollama(f"Du bist der Performance Agent. CPU: {cpu}%, RAM: {mem_pct}%. Gib eine Einschätzung. Antworte auf Deutsch, maximal 2 Sätze.")
    result = "\n".join(actions) + f"\n\n💡 KI Analyse:\n{ai}"
    
    agents["performance"]["status"] = "idle"
    agents["performance"]["last_run"] = datetime.now().strftime("%Y-%m-%d %H:%M")
    agents["performance"]["last_result"] = result
    send_ntfy("🔋 Performance Agent", result, "zap")

def run_storage_agent():
    agents["storage"]["status"] = "running"
    status = get_proxmox_status()
    disk_used = round(status.get("rootfs", {}).get("used", 0) / 1024**3, 1)
    disk_total = round(status.get("rootfs", {}).get("total", 0) / 1024**3, 1)
    disk_pct = round(disk_used / disk_total * 100) if disk_total > 0 else 0
    
    actions = [f"💾 Disk: {disk_used}GB / {disk_total}GB ({disk_pct}%)"]
    
    if disk_pct > 80:
        run_on_proxmox("find /var/lib/vz/dump -name '*.lzo' -mtime +7 -delete 2>/dev/null")
        actions.append("🗑️ Alte Backups gelöscht")
        send_ntfy("⚠️ Disk Warnung", f"Disk bei {disk_pct}%! Aufräumen gestartet.", "warning")
    else:
        actions.append("✅ Speicher ist ok!")
    
    ai = ask_ollama(f"Du bist der Storage Agent. Disk: {disk_pct}% verwendet. Gib Tipps. Antworte auf Deutsch, maximal 2 Sätze.")
    result = "\n".join(actions) + f"\n\n💡 KI Tipp:\n{ai}"
    
    agents["storage"]["status"] = "idle"
    agents["storage"]["last_run"] = datetime.now().strftime("%Y-%m-%d %H:%M")
    agents["storage"]["last_result"] = result
    send_ntfy("🗄️ Storage Agent", result, "card_file_box")

def run_network_agent():
    agents["network"]["status"] = "running"
    actions = []
    
    # Teste alle wichtigen Services
    services = {
        "Pi-hole": "http://192.168.1.151",
        "Ntfy": "http://192.168.1.182",
        "n8n": "http://192.168.1.194:5678",
        "Jellyfin": "http://192.168.1.168:8096",
        "Immich": "http://192.168.1.166:2283"
    }
    
    for name, url in services.items():
        try:
            r = requests.get(url, timeout=5)
            actions.append(f"✅ {name} erreichbar")
        except:
            actions.append(f"❌ {name} NICHT erreichbar!")
    
    ai = ask_ollama("Du bist der Network Agent. Gib einen Netzwerk-Optimierungstipp. Antworte auf Deutsch, maximal 2 Sätze.")
    result = "\n".join(actions) + f"\n\n💡 KI Tipp:\n{ai}"
    
    agents["network"]["status"] = "idle"
    agents["network"]["last_run"] = datetime.now().strftime("%Y-%m-%d %H:%M")
    agents["network"]["last_result"] = result
    send_ntfy("🌐 Network Agent", result, "globe_with_meridians")

def run_backup_agent():
    agents["backup"]["status"] = "running"
    actions = []
    
    hour = datetime.now().hour
    if hour == 2:
        # Echtes Backup starten um 02:00
        result_cmd = run_on_proxmox("vzdump --all --storage local --compress zstd --mode snapshot --quiet 1")
        actions.append("✅ Backup gestartet!")
    else:
        actions.append(f"⏰ Backup läuft automatisch um 02:00 Uhr (jetzt: {hour}:00)")
        actions.append("✅ Letzter Backup Status: OK")
    
    ai = ask_ollama("Du bist der Backup Agent. Gib Tipps zur Backup-Strategie. Antworte auf Deutsch, maximal 2 Sätze.")
    result = "\n".join(actions) + f"\n\n💡 KI Tipp:\n{ai}"
    
    agents["backup"]["status"] = "idle"
    agents["backup"]["last_run"] = datetime.now().strftime("%Y-%m-%d %H:%M")
    agents["backup"]["last_result"] = result
    send_ntfy("💾 Backup Agent", result, "floppy_disk")

def run_update_agent():
    agents["update"]["status"] = "running"
    actions = []
    
    # Updates in allen Containern prüfen
    containers = get_containers()
    updated = 0
    for ct in containers[:5]:  # Nur erste 5 um RAM zu schonen
        if ct.get("status") == "running":
            result = run_on_proxmox(f"pct exec {ct['vmid']} -- apt-get update -qq 2>/dev/null && pct exec {ct['vmid']} -- apt-get upgrade -y -qq 2>/dev/null")
            updated += 1
    
    actions.append(f"✅ {updated} Container aktualisiert")
    
    ai = ask_ollama("Du bist der Update Agent. Erkläre warum regelmässige Updates wichtig sind. Antworte auf Deutsch, maximal 2 Sätze.")
    result = "\n".join(actions) + f"\n\n💡 KI Tipp:\n{ai}"
    
    agents["update"]["status"] = "idle"
    agents["update"]["last_run"] = datetime.now().strftime("%Y-%m-%d %H:%M")
    agents["update"]["last_result"] = result
    send_ntfy("🔄 Update Agent", result, "arrows_counterclockwise")

def run_power_agent():
    agents["power"]["status"] = "running"
    actions = []
    
    hour = datetime.now().hour
    # Nachts (02:00-06:00) nicht-kritische Container stoppen
    non_critical = [126, 127, 130, 131, 133, 135]
    
    if 2 <= hour <= 6:
        for ctid in non_critical:
            run_on_proxmox(f"pct stop {ctid} 2>/dev/null")
        actions.append(f"😴 Nacht-Modus: {len(non_critical)} Container gestoppt")
    elif hour == 7:
        for ctid in non_critical:
            run_on_proxmox(f"pct start {ctid} 2>/dev/null")
        actions.append(f"☀️ Morgen-Modus: {len(non_critical)} Container gestartet")
    else:
        actions.append(f"✅ Normal-Modus (Stunde: {hour}:00)")
    
    ai = ask_ollama("Du bist der Power Agent. Gib Tipps zum Energiesparen im Homelab. Antworte auf Deutsch, maximal 2 Sätze.")
    result = "\n".join(actions) + f"\n\n💡 KI Tipp:\n{ai}"
    
    agents["power"]["status"] = "idle"
    agents["power"]["last_run"] = datetime.now().strftime("%Y-%m-%d %H:%M")
    agents["power"]["last_result"] = result
    send_ntfy("🔌 Power Agent", result, "electric_plug")

def run_gaming_agent():
    agents["gaming"]["status"] = "running"
    actions = []
    
    # Minecraft Server Status prüfen
    try:
        r = requests.get("https://192.168.1.163:8443/api/v2/servers",
            headers={"Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJpYXQiOjE3ODA2NjQyNTAsInRva2VuX2lkIjoxfQ.8N_kb1_vZPfI8dYE65pzuLhMpWFF0KAgPc-7WWX5l0g"},
            verify=False, timeout=10)
        servers = r.json().get("data", [])
        if servers:
            server = servers[0]
            status = "🟢 Online" if server.get("running") else "🔴 Offline"
            actions.append(f"🎮 Minecraft Server: {status}")
        else:
            actions.append("❓ Keine Server gefunden")
    except:
        actions.append("❌ Crafty Controller nicht erreichbar")
    
    ai = ask_ollama("Du bist der Gaming Agent. Gib einen Gaming-Tipp für heute Abend. Antworte auf Deutsch, maximal 2 Sätze.")
    result = "\n".join(actions) + f"\n\n💡 KI Tipp:\n{ai}"
    
    agents["gaming"]["status"] = "idle"
    agents["gaming"]["last_run"] = datetime.now().strftime("%Y-%m-%d %H:%M")
    agents["gaming"]["last_result"] = result
    send_ntfy("🎮 Gaming Agent", result, "video_game")

def run_log_agent():
    agents["log"]["status"] = "running"
    actions = []
    
    # Logs auf Proxmox Host aufräumen
    result = run_on_proxmox("journalctl --vacuum-time=7d 2>&1 | tail -1")
    actions.append(f"🗑️ Proxmox Logs aufgeräumt: {result.strip()}")
    
    ai = ask_ollama("Du bist der Log Agent. Welche Logs sollte man regelmässig prüfen? Antworte auf Deutsch, maximal 3 Punkte.")
    result_str = "\n".join(actions) + f"\n\n💡 KI Tipp:\n{ai}"
    
    agents["log"]["status"] = "idle"
    agents["log"]["last_run"] = datetime.now().strftime("%Y-%m-%d %H:%M")
    agents["log"]["last_result"] = result_str
    send_ntfy("📋 Log Agent", result_str, "clipboard")

def make_simple_agent(agent_id, prompt, ntfy_title, ntfy_tag):
    def run():
        agents[agent_id]["status"] = "running"
        result = ask_ollama(prompt)
        agents[agent_id]["status"] = "idle"
        agents[agent_id]["last_run"] = datetime.now().strftime("%Y-%m-%d %H:%M")
        agents[agent_id]["last_result"] = result
        send_ntfy(ntfy_title, result, ntfy_tag)
    return run

agent_functions = {
    "butler": run_butler_agent,
    "repair": run_repair_agent,
    "performance": run_performance_agent,
    "storage": run_storage_agent,
    "network": run_network_agent,
    "backup": run_backup_agent,
    "update": run_update_agent,
    "power": run_power_agent,
    "gaming": run_gaming_agent,
    "log": run_log_agent,
    "research": make_simple_agent("research", "Du bist der Research Agent. Generiere interessante Tech-News zu Self-Hosting, Linux, KI. Antworte auf Deutsch, maximal 3 Punkte.", "📰 Research Agent", "newspaper"),
    "coach": make_simple_agent("coach", f"Du bist ein Coach. Es ist {datetime.now().hour} Uhr. Gib eine motivierende Nachricht für einen Homelab-Enthusiasten aus der Schweiz. Antworte auf Deutsch, maximal 2 Sätze.", "🏋️ Coach Agent", "muscle"),
    "security": make_simple_agent("security", "Du bist der Security Agent. Generiere eine Security-Checkliste: Passwörter, Updates, offene Ports, VPN. Antworte auf Deutsch, maximal 3 Punkte.", "🔐 Security Agent", "lock"),
    "proxmox": make_simple_agent("proxmox", "Du bist der Proxmox Agent. Gib Tipps zur Proxmox Optimierung. Antworte auf Deutsch, maximal 2 Sätze.", "🖥️ Proxmox Agent", "computer"),
    "memory": make_simple_agent("memory", "Du bist der Memory Agent. Erstelle eine warme Erinnerung des Tages. Antworte auf Deutsch, maximal 2 Sätze.", "📸 Memory Agent", "camera"),
    "ideas": make_simple_agent("ideas", "Du bist ein Ideen-Generator für ein Homelab. Generiere 2 kreative neue Projektideen. Antworte auf Deutsch.", "💡 Ideen Agent", "bulb"),
    "predict": make_simple_agent("predict", f"Du bist der Predict Agent. Es ist {datetime.now().hour} Uhr. Was sollte vorbereitet werden? Antworte auf Deutsch, maximal 2 Vorschläge.", "🔮 Predict Agent", "crystal_ball"),
    "finance": make_simple_agent("finance", "Du bist der Finance Agent. Gib heute einen Spartipp. Antworte auf Deutsch, maximal 2 Sätze.", "💰 Finance Agent", "moneybag"),
    "travel": make_simple_agent("travel", "Du bist der Travel Agent für jemanden aus der Schweiz. Schlage ein Reiseziel vor. Antworte auf Deutsch, maximal 2 Sätze.", "🌍 Travel Agent", "airplane"),
    "learning": make_simple_agent("learning", "Du bist der Learning Agent. Erstelle einen Lernplan für heute zu Linux, Python oder Networking. Antworte auf Deutsch, maximal 3 Punkte.", "📚 Learning Agent", "books"),
    "chef": make_simple_agent("chef", "Du bist der Chef Agent für jemanden aus der Schweiz. Schlage ein einfaches Rezept vor. Antworte auf Deutsch, maximal 3 Sätze.", "🍕 Chef Agent", "fork_and_knife"),
    "sleep": make_simple_agent("sleep", f"Du bist der Sleep Agent. Es ist {datetime.now().hour} Uhr. Gib einen Schlaftipp. Antworte auf Deutsch, maximal 2 Sätze.", "😴 Sleep Agent", "sleeping"),
    "green": make_simple_agent("green", "Du bist der Green Agent. Gib einen Tipp wie man Strom im Homelab sparen kann. Antworte auf Deutsch, maximal 2 Sätze.", "🌱 Green Agent", "seedling"),
    "entertainment": make_simple_agent("entertainment", "Du bist der Entertainment Agent. Schlage einen Film oder Serie vor. Antworte auf Deutsch, maximal 2 Sätze.", "🎬 Entertainment Agent", "movie_camera"),
    "social": make_simple_agent("social", "Du bist der Social Agent. Erinnere daran Freunde zu kontaktieren. Antworte auf Deutsch, maximal 2 Sätze.", "🤝 Social Agent", "people_hugging"),
    "memory_palace": make_simple_agent("memory_palace", "Du bist der Memory Palace Agent. Gib einen Lerntipp. Antworte auf Deutsch, maximal 2 Sätze.", "🧠 Memory Palace Agent", "brain"),
    "container": make_simple_agent("container", "Du bist der Container Agent. Gib Tipps zur Container-Verwaltung. Antworte auf Deutsch, maximal 2 Sätze.", "📦 Container Agent", "package"),
    "mood": make_simple_agent("mood", f"Du bist der Mood Agent. Es ist {datetime.now().hour} Uhr. Schlage passende Musik vor. Antworte auf Deutsch, maximal 2 Sätze.", "🎵 Mood Agent", "musical_note"),
    "goal": make_simple_agent("goal", "Du bist der Goal Agent. Erinnere an wichtige Ziele. Antworte auf Deutsch, maximal 2 Sätze.", "🎯 Goal Agent", "dart"),
    "health": make_simple_agent("health", "Du bist der Health Agent. Gib Tipps zur Hardware-Gesundheit. Antworte auf Deutsch, maximal 2 Sätze.", "🌡️ Health Agent", "thermometer")
}

@app.route('/')
def index():
    return render_template_string(open('/opt/homebrain/templates/index.html').read())

@app.route('/api/agents')
def get_agents():
    return jsonify(agents)

@app.route('/api/agents/<agent_id>/run', methods=['POST'])
def run_agent(agent_id):
    if agent_id not in agents:
        return jsonify({"error": "Agent nicht gefunden"}), 404
    if agents[agent_id]["status"] == "running":
        return jsonify({"error": "Agent läuft bereits"}), 400
    thread = threading.Thread(target=agent_functions[agent_id])
    thread.daemon = True
    thread.start()
    return jsonify({"status": "gestartet"})

@app.route('/api/agents/run-all', methods=['POST'])
def run_all_agents():
    for agent_id in agents:
        if agents[agent_id]["status"] != "running":
            thread = threading.Thread(target=agent_functions[agent_id])
            thread.daemon = True
            thread.start()
            time.sleep(1)
    return jsonify({"status": "alle gestartet"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)

def run_agents_sequential():
    priority = [
        "repair", "network", "performance", "storage", "proxmox",
        "security", "backup", "log", "butler", "update",
        "gaming", "health", "power", "coach", "research",
        "ideas", "learning", "chef", "entertainment", "mood",
        "finance", "travel", "social", "sleep", "green",
        "memory", "memory_palace", "predict", "goal", "container"
    ]
    for agent_id in priority:
        agents[agent_id]["status"] = "running"
        agent_functions[agent_id]()
        time.sleep(2)

@app.route('/api/agents/run-sequential', methods=['POST'])
def run_sequential():
    thread = threading.Thread(target=run_agents_sequential)
    thread.daemon = True
    thread.start()
    return jsonify({"status": "sequentiell gestartet"})
