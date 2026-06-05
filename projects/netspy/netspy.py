
import nmap
import sqlite3
import time
import threading
from flask import Flask, jsonify
from datetime import datetime

app = Flask(__name__, static_folder='/var/www/html', static_url_path='')

NETWORK = '192.168.1.0/24'

def init_db():
    conn = sqlite3.connect('/opt/netspy.db')
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS devices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ip TEXT UNIQUE,
        mac TEXT,
        hostname TEXT,
        vendor TEXT,
        first_seen TEXT,
        last_seen TEXT,
        online INTEGER
    )''')
    conn.commit()
    conn.close()

def scan_network():
    nm = nmap.PortScanner()
    nm.scan(hosts=NETWORK, arguments='-sn')
    devices = []
    for host in nm.all_hosts():
        if nm[host].state() == 'up':
            mac = nm[host]['addresses'].get('mac', '')
            hostname = nm[host].hostname() or ''
            vendor = nm[host].get('vendor', {}).get(mac, '') if mac else ''
            devices.append({'ip': host, 'mac': mac, 'hostname': hostname, 'vendor': vendor})
    return devices

def update_devices():
    while True:
        try:
            now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            devices = scan_network()
            online_ips = [d['ip'] for d in devices]
            conn = sqlite3.connect('/opt/netspy.db')
            c = conn.cursor()
            c.execute('UPDATE devices SET online=0')
            for d in devices:
                c.execute('''INSERT INTO devices (ip, mac, hostname, vendor, first_seen, last_seen, online)
                    VALUES (?,?,?,?,?,?,1)
                    ON CONFLICT(ip) DO UPDATE SET
                    mac=excluded.mac, hostname=excluded.hostname,
                    vendor=excluded.vendor, last_seen=excluded.last_seen, online=1''',
                    (d['ip'], d['mac'], d['hostname'], d['vendor'], now, now))
            conn.commit()
            conn.close()
            print(f'Scan done: {len(devices)} Geräte online')
        except Exception as e:
            print(f'Scan error: {e}')
        time.sleep(60)

@app.route('/api/devices')
def devices():
    conn = sqlite3.connect('/opt/netspy.db')
    c = conn.cursor()
    c.execute('SELECT * FROM devices ORDER BY online DESC, ip ASC')
    rows = c.fetchall()
    conn.close()
    return jsonify([{
        'id': r[0], 'ip': r[1], 'mac': r[2], 'hostname': r[3],
        'vendor': r[4], 'first_seen': r[5], 'last_seen': r[6], 'online': r[7]
    } for r in rows])

@app.route('/api/scan')
def scan():
    threading.Thread(target=update_devices_once).start()
    return jsonify({'status': 'scanning'})

def update_devices_once():
    try:
        now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        devices = scan_network()
        conn = sqlite3.connect('/opt/netspy.db')
        c = conn.cursor()
        c.execute('UPDATE devices SET online=0')
        for d in devices:
            c.execute('''INSERT INTO devices (ip, mac, hostname, vendor, first_seen, last_seen, online)
                VALUES (?,?,?,?,?,?,1)
                ON CONFLICT(ip) DO UPDATE SET
                mac=excluded.mac, hostname=excluded.hostname,
                vendor=excluded.vendor, last_seen=excluded.last_seen, online=1''',
                (d['ip'], d['mac'], d['hostname'], d['vendor'], now, now))
        conn.commit()
        conn.close()
    except Exception as e:
        print(f'Scan error: {e}')

@app.route('/api/queries')
def queries():
    try:
        import requests as req
        auth = req.post('http://192.168.1.151/api/auth', json={'password':'admin123'}, timeout=5)
        sid = auth.json()['session']['sid']
        r = req.get('http://192.168.1.151/api/queries?max=100', headers={'sid': sid}, timeout=5)
        data = r.json()
        queries = []
        for q in data.get('queries', []):
            queries.append({
                'time': q.get('time',''),
                'domain': q.get('domain',''),
                'client': q.get('client',{}).get('name','') or q.get('client',{}).get('ip',''),
                'status': q.get('status','')
            })
        return jsonify(queries)
    except Exception as e:
        return jsonify({'error': str(e)})

@app.route('/')
def index():
    return app.send_static_file('index.html')

if __name__ == '__main__':
    init_db()
    t = threading.Thread(target=update_devices, daemon=True)
    t.start()
    app.run(host='0.0.0.0', port=5000)
