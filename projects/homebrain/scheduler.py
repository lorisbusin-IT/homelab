import requests
import time
from datetime import datetime

HOMEBRAIN_URL = "http://localhost:5000"

def run_agent(agent_id):
    try:
        requests.post(f"{HOMEBRAIN_URL}/api/agents/{agent_id}/run", timeout=5)
        print(f"[{datetime.now().strftime('%H:%M')}] ▶ {agent_id} gestartet")
    except:
        pass

def wait_for_agent(agent_id, max_wait=400):
    for _ in range(max_wait):
        try:
            r = requests.get(f"{HOMEBRAIN_URL}/api/agents", timeout=5)
            if r.json().get(agent_id, {}).get("status") == "idle":
                return True
        except:
            pass
        time.sleep(1)
    return False

while True:
    hour = datetime.now().hour
    minute = datetime.now().minute

    # Alle 5 Minuten – kritische Agents
    if minute % 5 == 0:
        for agent_id in ["repair", "network", "performance", "storage", "health"]:
            run_agent(agent_id)
            wait_for_agent(agent_id)

    # Alle 15 Minuten – Gaming und Security
    if minute % 15 == 0:
        for agent_id in ["gaming", "security"]:
            run_agent(agent_id)
            wait_for_agent(agent_id)

    # Täglich 07:00 – Morgen Agents
    if hour == 7 and minute == 0:
        for agent_id in ["coach", "research", "weather", "learning", "chef", "goal", "predict"]:
            run_agent(agent_id)
            wait_for_agent(agent_id)

    # Täglich 08:00 – Verwaltungs Agents
    if hour == 8 and minute == 0:
        for agent_id in ["butler", "log", "update", "backup", "proxmox"]:
            run_agent(agent_id)
            wait_for_agent(agent_id)

    # Täglich 12:00 – Mittags Agents
    if hour == 12 and minute == 0:
        for agent_id in ["ideas", "entertainment", "mood", "finance"]:
            run_agent(agent_id)
            wait_for_agent(agent_id)

    # Täglich 18:00 – Abend Agents
    if hour == 18 and minute == 0:
        for agent_id in ["travel", "social", "memory", "green"]:
            run_agent(agent_id)
            wait_for_agent(agent_id)

    # Täglich 21:00 – Nacht Agents
    if hour == 21 and minute == 0:
        for agent_id in ["sleep", "memory_palace", "power"]:
            run_agent(agent_id)
            wait_for_agent(agent_id)

    # Täglich 02:00 – Nacht Modus (Container stoppen)
    if hour == 2 and minute == 0:
        run_agent("power")
        wait_for_agent("power")
        run_agent("backup")
        wait_for_agent("backup")

    # Täglich 07:00 – Morgen Modus (Container starten)
    if hour == 7 and minute == 1:
        run_agent("power")
        wait_for_agent("power")

    time.sleep(60)
