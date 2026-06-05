
import feedparser
import requests
from bs4 import BeautifulSoup
from flask import Flask, jsonify, request
import sqlite3
import time
from datetime import datetime
from email.utils import parsedate_to_datetime
import threading

app = Flask(__name__, static_folder='/var/www/html', static_url_path='')

FEEDS = [
    ('Tagesanzeiger', 'https://www.tagesanzeiger.ch/rss.html'),
    ('SRF News', 'https://www.srf.ch/news/bnf/rss/1646'),
]

def init_db():
    conn = sqlite3.connect('/opt/news.db')
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS articles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        link TEXT UNIQUE,
        summary TEXT,
        content TEXT,
        image TEXT,
        source TEXT,
        date TEXT,
        fetched INTEGER
    )''')
    conn.commit()
    conn.close()

def extract_image_from_feed(entry):
    try:
        summary = entry.get('summary','')
        soup = BeautifulSoup(summary, 'html.parser')
        img = soup.find('img')
        if img and img.get('src'):
            return img['src']
        if hasattr(entry, 'media_content'):
            for m in entry.media_content:
                if m.get('url'): return m['url']
        if hasattr(entry, 'media_thumbnail'):
            for m in entry.media_thumbnail:
                if m.get('url'): return m['url']
    except:
        pass
    return ''

def scrape_article(url):
    try:
        headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}
        r = requests.get(url, headers=headers, timeout=10)
        r.encoding = r.apparent_encoding
        soup = BeautifulSoup(r.text, 'html.parser')
        image = ''
        og = soup.find('meta', property='og:image')
        if og and og.get('content'):
            image = og['content']
        for tag in soup(['script','style','nav','header','footer','aside','figure','button','form']):
            tag.decompose()
        article = soup.find('article') or soup.find(class_=['article-body','story-body','article__body','content-body','article-text'])
        if article:
            paras = article.find_all('p')
            if paras:
                content = ' '.join([p.get_text(strip=True) for p in paras if len(p.get_text(strip=True)) > 40])[:4000]
                return content, image
        paras = soup.find_all('p')
        content = ' '.join([p.get_text(strip=True) for p in paras if len(p.get_text(strip=True)) > 40])[:2000]
        return content, image
    except:
        return '', ''

def parse_date(entry):
    try:
        dt = parsedate_to_datetime(entry.published)
        return dt.strftime('%Y-%m-%d %H:%M:%S')
    except:
        pass
    return datetime.now().strftime('%Y-%m-%d %H:%M:%S')

def fetch_feeds():
    conn = sqlite3.connect('/opt/news.db')
    c = conn.cursor()
    for source, url in FEEDS:
        try:
            feed = feedparser.parse(url)
            for entry in feed.entries[:20]:
                link = entry.get('link','')
                title = entry.get('title','')
                raw_summary = entry.get('summary','')
                summary = BeautifulSoup(raw_summary, 'html.parser').get_text(strip=True)[:300]
                date = parse_date(entry)
                image = extract_image_from_feed(entry)
                try:
                    c.execute('INSERT OR IGNORE INTO articles (title,link,summary,content,image,source,date,fetched) VALUES (?,?,?,?,?,?,?,?)',
                        (title, link, summary, '', image, source, date, int(time.time())))
                    conn.commit()
                except:
                    pass
        except Exception as e:
            print(f'Feed error: {e}')
    conn.close()

def scrape_worker():
    while True:
        conn = sqlite3.connect('/opt/news.db')
        c = conn.cursor()
        c.execute('SELECT id, link, image FROM articles WHERE content="" LIMIT 3')
        rows = c.fetchall()
        conn.close()
        for row in rows:
            content, image = scrape_article(row[1])
            conn = sqlite3.connect('/opt/news.db')
            c = conn.cursor()
            if image and not row[2]:
                c.execute('UPDATE articles SET content=?, image=? WHERE id=?', (content, image, row[0]))
            else:
                c.execute('UPDATE articles SET content=? WHERE id=?', (content, row[0]))
            conn.commit()
            conn.close()
            time.sleep(4)
        time.sleep(60)

@app.route('/api/news')
def news():
    source = request.args.get('source','all')
    date = request.args.get('date','today')
    conn = sqlite3.connect('/opt/news.db')
    c = conn.cursor()
    today = datetime.now().strftime('%Y-%m-%d')
    if source == 'all':
        if date == 'today':
            c.execute('SELECT * FROM articles WHERE date LIKE ? ORDER BY date DESC LIMIT 50', (today+'%',))
        else:
            c.execute('SELECT * FROM articles WHERE date NOT LIKE ? ORDER BY date DESC LIMIT 100', (today+'%',))
    else:
        if date == 'today':
            c.execute('SELECT * FROM articles WHERE source=? AND date LIKE ? ORDER BY date DESC LIMIT 50', (source, today+'%'))
        else:
            c.execute('SELECT * FROM articles WHERE source=? AND date NOT LIKE ? ORDER BY date DESC LIMIT 100', (source, today+'%'))
    rows = c.fetchall()
    conn.close()
    articles = [{'id':r[0],'title':r[1],'link':r[2],'summary':r[3],'content':r[4],'image':r[5],'source':r[6],'date':r[7]} for r in rows]
    return jsonify(articles)

@app.route('/api/refresh')
def refresh():
    fetch_feeds()
    return jsonify({'status':'ok'})

@app.route('/')
def index():
    return app.send_static_file('index.html')

if __name__ == '__main__':
    init_db()
    fetch_feeds()
    t = threading.Thread(target=scrape_worker, daemon=True)
    t.start()
    app.run(host='0.0.0.0', port=5000)
