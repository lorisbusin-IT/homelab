from flask import Flask, request, jsonify, send_from_directory
import os, json

app = Flask(__name__, static_folder='/var/www/html', static_url_path='')

UPLOAD_DIR = '/var/www/html/uploads'
BEATS_FILE = '/opt/beats.json'
os.makedirs(UPLOAD_DIR, exist_ok=True)

@app.route('/')
def index():
    return app.send_static_file('index.html')

@app.route('/api/upload', methods=['POST'])
def upload():
    if 'file' not in request.files:
        return jsonify({'error': 'No file'}), 400
    f = request.files['file']
    if f.filename == '':
        return jsonify({'error': 'No filename'}), 400
    path = os.path.join(UPLOAD_DIR, f.filename)
    f.save(path)
    return jsonify({'filename': f.filename, 'url': '/uploads/' + f.filename})

@app.route('/uploads/<path:filename>')
def serve_upload(filename):
    return send_from_directory(UPLOAD_DIR, filename)

@app.route('/api/tracks')
def tracks():
    files = [f for f in os.listdir(UPLOAD_DIR) if f.endswith(('.mp3','.wav','.ogg','.m4a'))]
    return jsonify(files)

@app.route('/api/beats', methods=['GET'])
def get_beats():
    if os.path.exists(BEATS_FILE):
        return jsonify(json.load(open(BEATS_FILE)))
    return jsonify([])

@app.route('/api/beats', methods=['POST'])
def save_beats():
    json.dump(request.json, open(BEATS_FILE, 'w'))
    return jsonify({'status': 'ok'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
