-- Ethereal Summit – Insel-Management (Server)
local IslandData = require(game.ReplicatedStorage.Modules.IslandData)
local GameConfig = require(game.ReplicatedStorage.Modules.GameConfig)

local IslandManager = {}

-- Pruefen ob Spieler Zugang zu einer bestimmten Insel hat
function IslandManager.isAccessAllowed(session, islandIndex)
	if not session or not session.data then return false end
	return session.data.unlockedIslands[islandIndex] == true
end

-- Aktuelle Insel eines Spielers anhand seiner Y-Position bestimmen
function IslandManager.getActiveIsland(character)
	if not character then return 1 end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return 1 end

	local playerY  = rootPart.Position.Y
	local bestIdx  = 1

	for i = GameConfig.MAX_ISLANDS, 1, -1 do
		local island = IslandData[i]
		if island and playerY >= (island.height - 30) then
			bestIdx = i
			break
		end
	end

	return bestIdx
end

-- Insel freischalten: Coins abziehen, Insel in Daten eintragen
-- Gibt (success: bool, message: string) zurueck
function IslandManager.unlockIsland(session, islandIndex)
	if not session or not session.data then
		return false, "Keine Sitzungsdaten"
	end

	local data   = session.data
	local island = IslandData[islandIndex]

	if not island then
		return false, "Ungueltige Insel"
	end

	if data.unlockedIslands[islandIndex] then
		return false, "Insel bereits freigeschaltet"
	end

	-- Vorgaenger-Insel muss freigeschaltet sein
	if islandIndex > 1 and not data.unlockedIslands[islandIndex - 1] then
		return false, "Vorgaenger-Insel nicht freigeschaltet"
	end

	if data.coins < island.unlockCost then
		return false, "Nicht genug Coins (benoetigt: " .. island.unlockCost .. ")"
	end

	data.coins = data.coins - island.unlockCost
	data.unlockedIslands[islandIndex] = true

	if islandIndex > data.highestIsland then
		data.highestIsland = islandIndex
	end

	return true, island.name
end

-- Upgrade kaufen
-- Gibt (success: bool, newLevel: number, message: string) zurueck
function IslandManager.purchaseUpgrade(session, upgradeType, targetLevel)
	if not session or not session.data then
		return false, 0, "Keine Sitzungsdaten"
	end

	local data         = session.data
	local costs        = GameConfig.UPGRADE_COSTS[upgradeType]
	local currentLevel = data.upgrades[upgradeType]

	if not costs then return false, 0, "Unbekanntes Upgrade" end
	if not currentLevel then return false, 0, "Upgrade nicht verfuegbar" end
	if targetLevel ~= currentLevel + 1 then return false, 0, "Falsche Upgrade-Stufe" end

	local costIndex = targetLevel - 1
	local cost      = costs[costIndex]

	if not cost then return false, 0, "Max-Stufe erreicht" end
	if data.coins < cost then return false, currentLevel, "Nicht genug Coins" end

	data.coins = data.coins - cost
	data.upgrades[upgradeType] = targetLevel

	return true, targetLevel, "Upgrade erfolgreich"
end

return IslandManager
