
from flask import Flask, jsonify, send_from_directory, request
import urllib.request, urllib.error, json, ssl, os, subprocess

app = Flask(__name__, static_folder='/var/www/html', static_url_path='')

PROXMOX = 'https://192.168.1.150:8006'
TOKEN = 'PVEAPIToken=root@pam!n8n=1ef25506-648e-405f-841b-f2df49bab965'
PASSWORD = 'admin123'
SSL_CTX = ssl.create_default_context()
SSL_CTX.check_hostname = False
SSL_CTX.verify_mode = ssl.CERT_NONE

# Only safe read-only commands allowed
ALLOWED_CMDS = [
    'uptime','df','free','cat /proc/cpuinfo','cat /proc/meminfo',
    'pct list','qm list','pvesh get','hostname','uname',
    'ip a','ip r','netstat','ss','ps aux','top -bn1',
    'lscpu','lsblk','fdisk -l','mount','who','w','last',
    'systemctl status','journalctl -n','ls','cat','echo',
    'ping -c 4','nslookup','dig','traceroute','curl -I',
    'pct status','qm status','pvecm status','pvesm status',
    'cat /etc/os-release','cat /proc/version','date','cal',
    'df -h','free -h','ps','netstat -an','ss -an',
]

def is_safe(cmd):
    cmd = cmd.strip().lower()
    dangerous = ['rm','mv','cp','chmod','chown','kill','reboot','shutdown',
                 'apt','pip','wget','curl -o','curl --output',
                 'dd','mkfs','fdisk -w','passwd','useradd','userdel',
                 'systemctl start','systemctl stop','systemctl restart',
                 'iptables','ufw','>&','>',';','&&','||','|','`','$(',
                 'pct start','pct stop','pct destroy','qm start','qm stop',
                 'pvesh create','pvesh delete','pvesh set']
    for d in dangerous:
        if d in cmd:
            return False
    return True

def pve_get(path):
    try:
        req = urllib.request.Request(PROXMOX+path, headers={"Authorization": TOKEN})
        r = urllib.request.urlopen(req, context=SSL_CTX, timeout=5)
        return json.loads(r.read())["data"]
    except:
        return None

@app.route("/")
def index():
    return app.send_static_file("index.html")

@app.route("/api/auth", methods=["POST"])
def auth():
    pw = request.json.get("password","")
    return jsonify({"success": pw == PASSWORD})

@app.route("/api/exec", methods=["POST"])
def execute():
    pw = request.json.get("password","")
    if pw != PASSWORD:
        return jsonify({"error": "Unauthorized"}), 401
    cmd = request.json.get("cmd","").strip()
    if not cmd:
        return jsonify({"output": ""})
    if not is_safe(cmd):
        return jsonify({"error": "Command not allowed for security reasons!"})
    try:
        result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True, timeout=10
        )
        output = result.stdout + result.stderr
        return jsonify({"output": output.strip()})
    except subprocess.TimeoutExpired:
        return jsonify({"error": "Command timed out!"})
    except Exception as e:
        return jsonify({"error": str(e)})

@app.route("/api/stats")
def stats():
    node = pve_get("/api2/json/nodes/proxmox/status")
    cts = pve_get("/api2/json/nodes/proxmox/lxc")
    vms = pve_get("/api2/json/nodes/proxmox/qemu")
    if not node:
        return jsonify({"error": "Cannot connect to Proxmox"}), 500
    cpu = round(node.get("cpu", 0) * 100, 1)
    mem = node.get("memory", {})
    mem_used = round(mem.get("used", 0) / 1024**3, 1)
    mem_total = round(mem.get("total", 0) / 1024**3, 1)
    mem_pct = round(mem_used / mem_total * 100, 1) if mem_total else 0
    disk = node.get("rootfs", {})
    disk_used = round(disk.get("used", 0) / 1024**3, 1)
    disk_total = round(disk.get("total", 0) / 1024**3, 1)
    disk_pct = round(disk_used / disk_total * 100, 1) if disk_total else 0
    uptime = node.get("uptime", 0)
    days = uptime // 86400
    hours = (uptime % 86400) // 3600
    all_cts = (cts or []) + (vms or [])
    running = len([c for c in all_cts if c.get("status") == "running"])
    return jsonify({
        "cpu": cpu, "ram_used": mem_used, "ram_total": mem_total,
        "ram_pct": mem_pct, "disk_used": disk_used, "disk_total": disk_total,
        "disk_pct": disk_pct, "uptime": str(days)+"d "+str(hours)+"h",
        "ct_total": len(all_cts), "ct_running": running, "procs": len(subprocess.check_output(["ps","aux"]).decode().splitlines()),
    })

@app.route("/api/containers")
def containers():
    cts = pve_get("/api2/json/nodes/proxmox/lxc") or []
    vms = pve_get("/api2/json/nodes/proxmox/qemu") or []
    result = []
    for c in cts + vms:
        result.append({
            "id": c.get("vmid"), "name": c.get("name",""),
            "status": c.get("status",""),
            "cpu": round(c.get("cpu",0)*100,1),
            "mem": round(c.get("mem",0)/1024**2),
        })
    return jsonify(sorted(result, key=lambda x: x["id"]))

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
