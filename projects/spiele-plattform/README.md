# 🎮 Spiele-Plattform

## Beschreibung
Eine Sammlung von 17 klassischen Browser-Spielen mit modernem Design.

## Spiele
1. 🐍 Snake
2. 🟦 Tetris
3. 👾 Space Invaders
4. 👻 Pac-Man
5. 🏓 Pong
6. 💣 Minesweeper
7. 🃏 Memory
8. 2️⃣ 2048
9. 📝 Wordle
10. ❓ Quiz
11. 🔢 Sudoku
12. 🎯 Hangman
13. 🦕 Dino Runner
14. 🚀 Asteroids
15. 🏃 Endless Runner
16. 🎯 Aim Trainer
17. 🎵 Simon Says

## Features
- ✨ Partikel-Effekte
- 🏆 Highscores
- 🎨 Press Start 2P Font
- 📱 Responsive Design

## Technologien
- **Frontend:** HTML5 Canvas, CSS, JavaScript
- **Webserver:** Nginx
- **Font:** Press Start 2P (Google Fonts)

## Installation

```bash
# Container erstellen (Debian 12, 256MB RAM, 4GB Disk)
pct create 130 /var/lib/vz/template/cache/debian-12-standard_12.7-1_amd64.tar.zst \
  --hostname spiele-plattform \
  --memory 256 \
  --rootfs local-lvm:4 \
  --net0 name=eth0,bridge=vmbr0,ip=192.168.1.203/24,gw=192.168.1.1 \
  --unprivileged 1 \
  --start 1

apt update && apt install nginx -y

# Spiele nach /var/www/html/games/ kopieren
systemctl enable --now nginx
```

## Zugriff
- URL: http://192.168.1.203
