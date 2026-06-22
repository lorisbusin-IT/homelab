# Ethereal Summit – Roblox Studio Placement Guide

## Voraussetzungen

- Roblox Studio installiert
- Rojo Plugin (empfohlen): `roblox.github.io/rojo` oder Argon Plugin
- API-Dienste aktiviert: Studio → Game Settings → Security → **Allow Studio Access to API Services** = ON

---

## Schritt 1: Projekt importieren (Rojo)

```bash
# Im Projektordner:
rojo serve default.project.json
```

Dann in Roblox Studio:
1. Rojo Plugin öffnen → Connect → `localhost:34872`
2. Sync bestätigen

Alternativ ohne Rojo: Skripte manuell per Drag & Drop in die entsprechenden Services ziehen.

---

## Schritt 2: Terrain und Welt aufbauen

### Basis-Karte (manuell in Studio)

Erstelle 10 schwebende Insel-Parts in **Workspace**, benannt `Island_1` bis `Island_10`:

| Insel | Y-Position | Empfohlene Größe |
|---|---|---|
| Island_1 | 50 | 200×200 studs |
| Island_2 | 120 | 180×180 |
| Island_3 | 200 | 160×160 |
| Island_4 | 310 | 150×150 |
| Island_5 | 450 | 140×140 |
| Island_6 | 620 | 130×130 |
| Island_7 | 830 | 120×120 |
| Island_8 | 1100 | 110×110 |
| Island_9 | 1400 | 100×100 |
| Island_10 | 1800 | 90×90 |

### Spawn-Punkte für Erz-Nodes

Auf jeder Insel: Erstelle einen Folder `OreSpawns_N` (N = Inselnummer) mit **20 Parts** als Spawn-Markierungen.
- Parts: Anchored=true, Transparency=1, Size=3×3×3
- Der `ResourceSystem` nimmt die Positionen aus diesen Parts beim Initialisieren

**Initialisierungscode in GameManager.server.lua hinzufügen** (nach dem Start-Print):

```lua
-- Ore-Spawns aus dem Workspace laden
for islandIdx = 1, GameConfig.MAX_ISLANDS do
    local folder = workspace:FindFirstChild("OreSpawns_" .. islandIdx)
    if folder then
        local positions = {}
        for _, part in ipairs(folder:GetChildren()) do
            if part:IsA("BasePart") then
                table.insert(positions, part.Position)
            end
        end
        ResourceSystem.initializeIsland(islandIdx, positions)
    end
end
```

---

## Schritt 3: Teleport-Treppen / Portale

Erstelle sichtbare Verbindungen zwischen den Inseln:
- **Option A:** Treppen/Spiralen aus Parts die von Insel zu Insel führen
- **Option B:** Portal-Parts mit `TeleportPad` Script → teleportiert Spieler zur nächsten Insel

Beispiel Portal-Script (in einem Part auf Island_1):
```lua
local DESTINATION_Y = 120  -- Island_2 Y-Höhe
local ISLAND_INDEX  = 2

script.Parent.Touched:Connect(function(hit)
    local char = hit.Parent
    local player = game.Players:GetPlayerByCharacter(char)
    if player then
        -- Pruefen ob Insel freigeschaltet (via Bindable oder DataStore Check)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(hrp.Position.X, DESTINATION_Y + 5, hrp.Position.Z)
        end
    end
end)
```

---

## Schritt 4: Beleuchtung (Atmosphäre)

Im **Lighting**-Service empfohlen:
- `Ambient`: RGB(80, 80, 120) – blaustichiges Licht für mystischen Look
- `OutdoorAmbient`: RGB(100, 80, 160)
- `Atmosphere`-Instanz:
  - Density: 0.4
  - Offset: 0.2
  - Color: RGB(100, 120, 200)
  - Decay: RGB(80, 60, 100)
  - Glare: 0.3
  - Haze: 1.5
- `Sky`-Instanz mit passendem Skybox-Asset (z.B. "Galaxy Sky")

---

## Schritt 5: Pass-IDs eintragen

Nach der Veröffentlichung des Spiels (Publish to Roblox):

1. **Game Passes erstellen** auf roblox.com → Create → Game Passes
2. IDs in `src/ReplicatedStorage/Modules/GameConfig.lua` eintragen:

```lua
GameConfig.GAME_PASSES = {
    VIP        = 123456789,   -- Deine echte VIP Pass ID
    AUTO_MINE  = 987654321,   -- Deine echte Auto-Mine Pass ID
    PET        = 111222333,   -- Deine echte Pet Pass ID
}
```

3. **Developer Products erstellen** auf roblox.com → Developer Products
4. Produkt-IDs eintragen:

```lua
GameConfig.DEV_PRODUCTS = {
    GEM_SMALL  = 444555666,
    GEM_LARGE  = 777888999,
    COIN_BOOST = 123789456,
}
```

5. Sync via Rojo und Spiel neu veröffentlichen.

---

## Schritt 6: Maximale Spieleranzahl

Studio → Home → Game Settings → Players:
- **Max Players**: 15–20 (empfohlen für diese Kartengröße)
- **Respawn Time**: 5 Sekunden

---

## Schritt 7: Pre-Launch Checkliste

- [ ] Alle Pass-IDs eingetragen und getestet
- [ ] API Services aktiviert (DataStore)
- [ ] Ore-Spawn-Folder für alle 10 Inseln vorhanden
- [ ] Teleport-Portale / Treppen platziert
- [ ] Beleuchtung und Atmosphäre eingestellt
- [ ] Spielicon (512×512 px) hochgeladen
- [ ] Mind. 3 Thumbnails hochgeladen
- [ ] Spielbeschreibung auf Deutsch UND Englisch
- [ ] Private Server aktiviert (50 Robux empfohlen)
- [ ] In Studio getestet: Join → Mine → Sell → Upgrade → Island Unlock
- [ ] DataStore-Test: Join, spielen, verlassen, rejoinen → Daten erhalten?
- [ ] Monetarisierungs-Test in Published Test Place

---

## Tipps für virales Wachstum

1. **Tägliche Login-Belohnung**: Einfach in GameManager.server.lua implementierbar
2. **Freunde-Bonus**: Wenn du mit Freunden spielst, +10% Coins
3. **Update-Versprechen**: Kündige neue Inseln in der Beschreibung an
4. **Codes/Promo-Codes**: Gut für Giveaways und Social Media
5. **Seasonal Events**: Halloween/Weihnachts-Inseln für zeitlich begrenzte Erze
