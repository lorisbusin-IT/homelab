# Ethereal Summit – Roblox Game

Ein magisches Bergbau-Tycoon-Spiel auf schwebenden Inseln. Spieler sammeln Erze, upgraden ihre Ausrüstung, schalten neue Inseln frei und konkurrieren um den Platz auf dem Leaderboard.

**Genre:** Tycoon + Explorer + RPG  
**Engine:** Roblox Studio (Luau)  
**Zielgruppe:** 8–16 Jahre (breite Roblox-Kernzielgruppe)

---

## Spielprinzip

1. Starte auf der **Ankunftsinsel** und baue Stein & Kohle ab
2. Verkaufe Ressourcen für **Coins**
3. Kaufe **Upgrades** (Spitzhacke, Rucksack, Auto-Miner, Verkaufs-Boost)
4. Schalte höhere **schwebende Inseln** frei → seltenere Erze → mehr Coins
5. Steige die **Leaderboard** auf und zeige, wer der beste Bergmann ist

---

## Monetarisierung

| Produkt | Preis | Effekt |
|---|---|---|
| VIP Game Pass | 299 Robux | 2× Ressourcen, VIP-Bereich, Gold-Spitzhacke |
| Auto-Mine Pass | 499 Robux | AFK-Mining ohne aktives Spielen |
| Pet Companion Pass | 199 Robux | Pet mit +15% Gluecksbonus |
| Gem Pack S | 50 Robux | 100 Gems (Premiumwaehrung) |
| Gem Pack L | 200 Robux | 500 Gems |
| Coin Boost ×3 | 75 Robux | 3-fache Coins fuer 1 Stunde |
| Private Server | 50 Robux | Eigener Server |

Roblox Premium Mitglieder erhalten automatisch **1.5× Coins**.

---

## Inseln & Progression

| # | Insel | Freischaltkosten | Beste Ressource |
|---|---|---|---|
| 1 | Ankunftsinsel | Kostenlos | Kohle (3 Coins) |
| 2 | Kristallklippe | 500 | Mondstein (20) |
| 3 | Nebelgipfel | 2.500 | Silber (55) |
| 4 | Aetherfels | 10.000 | Aetherkristall (150) |
| 5 | Wolkenthron | 40.000 | Sternerz (400) |
| 6 | Sturmpeak | 150.000 | Drachenstein (1.200) |
| 7 | Himmelsveste | 500.000 | Monddiamant (4.000) |
| 8 | Ewigkeitsgipfel | 2.000.000 | Sternstaub (15.000) |
| 9 | Gottesthron | 8.000.000 | Aetherherz (60.000) |
| 10 | Etherealer Gipfel | 30.000.000 | Urkristall (250.000) |

---

## Dateistruktur

```
src/
├── ReplicatedStorage/Modules/
│   ├── GameConfig.lua          # Alle Konstanten, Pass-IDs hier eintragen
│   ├── IslandData.lua          # 10 Inseln mit Kosten und Ressourcen
│   ├── ResourceData.lua        # 12 Erze mit Wert, Gewicht, Abbauzeit
│   └── RemoteEvents.lua        # 24 Remote-Event-Namen
├── ServerScriptService/
│   ├── GameManager.server.lua          # Orchestrierung & Heartbeat
│   ├── DataStoreManager.server.lua     # Datenpersistenz
│   ├── MonetizationHandler.server.lua  # Game Passes, Dev Products
│   ├── IslandManager.server.lua        # Insel-Unlock, Upgrades
│   ├── ResourceSystem.server.lua       # Mining, Respawn, AutoMine
│   └── LeaderboardSystem.server.lua    # Globale Ranglisten
└── StarterPlayerScripts/
    ├── PlayerController.client.lua     # Input, Proximity-Mining
    ├── UIManager.client.lua            # HUD, Toasts, Leaderboard-UI
    └── ShopClient.client.lua           # Shop-Panel, Robux-Prompts
```

---

## Setup

Siehe [`assets/placement-guide.md`](assets/placement-guide.md) fuer die vollstaendige Studio-Einrichtung.

**Kurzfassung:**
1. `rojo serve default.project.json` im Projektordner
2. Rojo Plugin in Roblox Studio verbinden
3. Pass-IDs in `GameConfig.lua` nach Veroeffentlichung eintragen
4. Ore-Spawn-Folder fuer alle 10 Inseln im Workspace anlegen
5. Playtesten → Veroeffentlichen

---

## Technischer Stack

- **Sprache:** Luau (Lua 5.1 Superset fuer Roblox)
- **Persistenz:** Roblox DataStoreService (UpdateAsync, merge-safe)
- **Monetarisierung:** MarketplaceService (Game Passes + Developer Products)
- **Rangliste:** OrderedDataStore (3 Boards: Coins, Inseln, Erze)
- **Projekt-Sync:** Rojo (`default.project.json`)
- **Anti-Cheat:** Server-seitige Validierung aller Mining- und Kauf-Events
