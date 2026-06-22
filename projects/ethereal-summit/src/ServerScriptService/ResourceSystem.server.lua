-- Ethereal Summit – Ressourcen-System (Server)
local ResourceData   = require(game.ReplicatedStorage.Modules.ResourceData)
local IslandData     = require(game.ReplicatedStorage.Modules.IslandData)
local GameConfig     = require(game.ReplicatedStorage.Modules.GameConfig)

local ResourceSystem = {}

-- Aktive Ore-Nodes: { [oreId] = { islandIndex, position, resource, hp, maxHp, respawning } }
local OreNodes       = {}
local OreCounter     = 0
local EventsFolder   = nil  -- wird von GameManager gesetzt

function ResourceSystem.setEventsFolder(folder)
	EventsFolder = folder
end

-- Neue eindeutige Ore-ID generieren
local function newOreId()
	OreCounter = OreCounter + 1
	return "ore_" .. OreCounter
end

-- Effektive Abbauzeit fuer einen Spieler berechnen (Upgrade-Reduktion)
local function getEffectiveMineTime(baseTime, session)
	if not session or not session.data then return baseTime end
	local pickaxeLevel = session.data.upgrades.pickaxe or 1
	local reduction    = (pickaxeLevel - 1) * GameConfig.PICKAXE_TIME_REDUCTION
	return math.max(0.5, baseTime - reduction)
end

-- Einen neuen Ore-Node auf einer Insel spawnen
function ResourceSystem.spawnOreNode(islandIndex, position)
	local island   = IslandData[islandIndex]
	if not island then return end

	local luckBonus  = 0  -- Wird bei spezifischem Spieler-Context genutzt
	local resource   = ResourceData.pickWeighted(island.resources, luckBonus)
	local resData    = ResourceData[resource]
	if not resData then return end

	local oreId      = newOreId()
	local maxHp      = math.ceil(resData.mineTime * 2)

	OreNodes[oreId] = {
		islandIndex = islandIndex,
		position    = position,
		resource    = resource,
		hp          = maxHp,
		maxHp       = maxHp,
		respawning  = false,
	}

	-- Alle Clients informieren
	if EventsFolder then
		local evt = EventsFolder:FindFirstChild("SpawnOre")
		if evt then
			evt:FireAllClients(oreId, islandIndex, position, resource, maxHp)
		end
	end

	return oreId
end

-- Ore-Node entfernen und Respawn planen
local function removeAndRespawn(oreId, respawnTime, islandIndex, position)
	if EventsFolder then
		local evt = EventsFolder:FindFirstChild("RemoveOre")
		if evt then evt:FireAllClients(oreId) end
	end

	OreNodes[oreId] = nil

	task.delay(respawnTime, function()
		ResourceSystem.spawnOreNode(islandIndex, position)
	end)
end

-- Mining-Anfrage verarbeiten (vom GameManager aufgerufen nach Rate-Limit-Check)
-- Gibt (success, resource, amount, coinsGained) zurueck
function ResourceSystem.processMineRequest(player, oreId, session, monetizationHandler)
	local node = OreNodes[oreId]
	if not node then return false, nil, 0, 0 end

	-- Zugangs-Kontrolle
	local data = session.data
	if not data.unlockedIslands[node.islandIndex] then
		return false, nil, 0, 0
	end

	-- HP reduzieren
	node.hp = node.hp - 1

	if node.hp > 0 then
		-- Noch nicht abgebaut – Fortschritt zurueckmelden
		return true, nil, 0, 0
	end

	-- Erz vollstaendig abgebaut
	local resource   = node.resource
	local resData    = ResourceData[resource]
	local amount     = 1

	-- Inventar-Kapazitaet pruefen
	local maxSlots   = GameConfig.BACKPACK_CAPACITY[data.upgrades.backpack] or 50
	local totalItems = 0
	for _, qty in pairs(data.inventory) do totalItems = totalItems + qty end

	if totalItems >= maxSlots then
		-- Inventar voll: direkt verkaufen
		local coinMult   = monetizationHandler and monetizationHandler.getCoinMultiplier(session) or 1
		local baseValue  = resData.value
		local coinsGained = math.floor(baseValue * coinMult)
		data.coins = data.coins + coinsGained
		data.stats.totalCoinsEarned = data.stats.totalCoinsEarned + coinsGained
		data.stats.totalOresMined   = data.stats.totalOresMined + 1

		local respawnTime = resData.mineTime * IslandData.RESPAWN_MULTIPLIER
		removeAndRespawn(oreId, respawnTime, node.islandIndex, node.position)
		return true, resource, amount, coinsGained
	end

	-- Ins Inventar legen
	data.inventory[resource] = (data.inventory[resource] or 0) + amount
	data.stats.totalOresMined = data.stats.totalOresMined + 1

	local respawnTime = resData.mineTime * IslandData.RESPAWN_MULTIPLIER
	removeAndRespawn(oreId, respawnTime, node.islandIndex, node.position)

	return true, resource, amount, 0
end

-- Alle Ressourcen eines Spielers verkaufen (oder bestimmte Menge)
function ResourceSystem.sellResources(session, resourceName, amount, monetizationHandler)
	local data = session.data
	if not data then return 0 end

	local coinsTotal = 0

	if resourceName and resourceName ~= "" then
		-- Einzelne Ressource verkaufen
		local available = data.inventory[resourceName] or 0
		local toSell    = math.min(amount or available, available)
		if toSell <= 0 then return 0 end

		local resData   = ResourceData[resourceName]
		if not resData then return 0 end

		local coinMult  = monetizationHandler and monetizationHandler.getCoinMultiplier(session) or 1
		coinsTotal      = math.floor(resData.value * toSell * coinMult)

		data.inventory[resourceName] = available - toSell
		if data.inventory[resourceName] == 0 then
			data.inventory[resourceName] = nil
		end
	else
		-- Alles verkaufen
		local coinMult = monetizationHandler and monetizationHandler.getCoinMultiplier(session) or 1
		for resName, qty in pairs(data.inventory) do
			local resData = ResourceData[resName]
			if resData and qty > 0 then
				coinsTotal = coinsTotal + math.floor(resData.value * qty * coinMult)
			end
		end
		data.inventory = {}
	end

	data.coins = data.coins + coinsTotal
	data.stats.totalCoinsEarned = data.stats.totalCoinsEarned + coinsTotal
	return coinsTotal
end

-- Auto-Mine Tick: Eine Ressource auf der aktuellen Insel automatisch abbauen
function ResourceSystem.autoMineTick(session, islandIndex, monetizationHandler)
	local data = session.data
	if not data then return nil, 0, 0 end

	-- Freien Ore-Node auf der Insel finden
	local targetId   = nil
	local targetNode = nil

	for oreId, node in pairs(OreNodes) do
		if node.islandIndex == islandIndex and not node.respawning then
			targetId   = oreId
			targetNode = node
			break
		end
	end

	if not targetId then return nil, 0, 0 end

	return ResourceSystem.processMineRequest(
		nil, targetId, session, monetizationHandler
	)
end

-- Ore-Nodes fuer eine Insel initialisieren (beim Server-Start)
function ResourceSystem.initializeIsland(islandIndex, spawnPositions)
	local island = IslandData[islandIndex]
	if not island then return end

	for i, pos in ipairs(spawnPositions) do
		if i <= GameConfig.MAX_ACTIVE_NODES then
			ResourceSystem.spawnOreNode(islandIndex, pos)
		end
	end
end

-- Alle Ore-Nodes zurueckgeben (fuer Debugging)
function ResourceSystem.getOreNodes()
	return OreNodes
end

return ResourceSystem
