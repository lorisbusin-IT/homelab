-- Ethereal Summit – Rebirth/Prestige-System (Server)
local GameConfig    = require(game.ReplicatedStorage.Modules.GameConfig)
local IslandData    = require(game.ReplicatedStorage.Modules.IslandData)

local RebirthSystem = {}

-- Pruefen ob Spieler rebirthen kann
function RebirthSystem.canRebirth(session)
	local data = session and session.data
	if not data then return false, "Keine Daten" end

	local rebirths = data.rebirths or 0
	if rebirths >= GameConfig.MAX_REBIRTHS then
		return false, "Maximale Rebirth-Anzahl erreicht"
	end

	-- Muss Insel 10 freigeschaltet haben
	if not data.unlockedIslands[GameConfig.MAX_ISLANDS] then
		return false, "Schalte zuerst alle 10 Inseln frei"
	end

	-- Muss genug Coins haben
	local cost = GameConfig.REBIRTH_COSTS[rebirths + 1]
	if not cost then return false, "Kein weiterer Rebirth moeglich" end

	if data.coins < cost then
		return false, "Benoetigt " .. cost .. " Coins (du hast " .. math.floor(data.coins) .. ")"
	end

	return true, cost
end

-- Rebirth durchfuehren
function RebirthSystem.performRebirth(session)
	local canDo, costOrMsg = RebirthSystem.canRebirth(session)
	if not canDo then return false, costOrMsg end

	local data = session.data
	local cost = costOrMsg

	-- Coins abziehen und Rebirth-Zaehler erhoehen
	data.coins    = data.coins - cost
	data.rebirths = (data.rebirths or 0) + 1

	-- Multiplikator berechnen (+25% pro Rebirth)
	data.rebirthMult = 1.0 + (data.rebirths * GameConfig.REBIRTH_MULT_PER_REBIRTH)

	-- Reset: Coins, Inventory, Inseln
	data.coins           = 0
	data.inventory       = {}
	data.highestIsland   = 1
	data.unlockedIslands = {[1] = true}

	-- Upgrades, Pets, Passes und Achievements bleiben erhalten

	-- Achievement-Fortschritt aktualisieren
	if not data.stats then data.stats = {} end
	-- stats.rebirths wird von AchievementSystem getrackt

	return true, data.rebirths, data.rebirthMult
end

-- Anzeige-Text fuer Rebirth-Abzeichen
function RebirthSystem.getRebirthBadge(rebirths)
	if rebirths <= 0 then return "" end
	local symbols = {"I","II","III","IV","V"}
	return "[Rebirth " .. (symbols[rebirths] or tostring(rebirths)) .. "] "
end

-- Naechste Rebirth-Kosten fuer UI
function RebirthSystem.getNextRebirthCost(data)
	local rebirths = data.rebirths or 0
	if rebirths >= GameConfig.MAX_REBIRTHS then return nil end
	return GameConfig.REBIRTH_COSTS[rebirths + 1]
end

return RebirthSystem
