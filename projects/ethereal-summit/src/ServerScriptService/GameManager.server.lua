-- Ethereal Summit – GameManager (Server-Orchestrierung)
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local GameConfig         = require(ReplicatedStorage.Modules.GameConfig)
local RemoteEventsConfig = require(ReplicatedStorage.Modules.RemoteEvents)
local IslandData         = require(ReplicatedStorage.Modules.IslandData)
local DataStoreManager   = require(script.Parent.DataStoreManager)
local MonetizationHandler= require(script.Parent.MonetizationHandler)
local IslandManager      = require(script.Parent.IslandManager)
local ResourceSystem     = require(script.Parent.ResourceSystem)
local LeaderboardSystem  = require(script.Parent.LeaderboardSystem)

-- Sitzungs-Tabelle: ephemere Daten pro Spieler (nicht persistiert)
local Sessions = {}

-- MonetizationHandler bekommt Zugriff auf Sessions
MonetizationHandler.setSessions(Sessions)

-- RemoteEvents-Ordner erstellen
local EventsFolder = Instance.new("Folder")
EventsFolder.Name  = "RemoteEvents"
EventsFolder.Parent = ReplicatedStorage

for _, eventName in pairs(RemoteEventsConfig) do
	local re   = Instance.new("RemoteEvent")
	re.Name    = eventName
	re.Parent  = EventsFolder
end

ResourceSystem.setEventsFolder(EventsFolder)

-- Hilfsfunktion: RemoteEvent-Referenz holen
local function getEvent(name)
	return EventsFolder:FindFirstChild(name)
end

-- Hilfsfunktion: Benachrichtigung an Client senden
local function notify(player, message, style)
	local evt = getEvent(RemoteEventsConfig.SHOW_NOTIFICATION)
	if evt then evt:FireClient(player, message, style or "info") end
end

-- Rate-Limit pro Spieler: { [userId] = { lastMineTime, mineCount } }
local RateLimits = {}

local function checkRateLimit(userId, cooldown)
	local now     = os.clock()
	local rl      = RateLimits[userId]
	if not rl then
		RateLimits[userId] = { lastMineTime = now }
		return true
	end
	if now - rl.lastMineTime < cooldown then
		return false
	end
	rl.lastMineTime = now
	return true
end

-- Spieler-Join-Handler
local function onPlayerAdded(player)
	LeaderboardSystem.cachePlayerName(player)

	local data    = DataStoreManager.LoadData(player)
	local session = {
		data        = data,
		passes      = {},
		isPremium   = false,
		autoMining  = false,
		sessionStart= os.time(),
		lastSave    = os.time(),
	}
	Sessions[player.UserId] = session

	-- Game Passes und Premium pruefen
	MonetizationHandler.loadPassesForPlayer(player, session)

	-- Initiale Daten an Client senden (nach kurzem Delay fuer Client-Ladung)
	task.delay(1, function()
		if not player.Parent then return end
		local evt = getEvent(RemoteEventsConfig.PLAYER_DATA_LOADED)
		if evt then evt:FireClient(player, data) end
	end)

	print("[GameManager] " .. player.Name .. " beigetreten. Insel: " .. data.highestIsland)
end

-- Spieler-Leave-Handler
local function onPlayerRemoving(player)
	local session = Sessions[player.UserId]
	if session and session.data then
		-- Spielzeit aktualisieren
		local elapsed = os.time() - session.sessionStart
		session.data.stats.playTime = (session.data.stats.playTime or 0) + elapsed
		DataStoreManager.SaveData(player, session.data)
		print("[GameManager] " .. player.Name .. " gespeichert und entfernt.")
	end
	Sessions[player.UserId] = nil
	RateLimits[player.UserId] = nil
end

-- Remote Event Handler: Mining
getEvent(RemoteEventsConfig.MINE_ORE).OnServerEvent:Connect(function(player, oreId)
	local session = Sessions[player.UserId]
	if not session then return end

	if type(oreId) ~= "string" then return end  -- Anti-Cheat: Typ pruefen

	-- Rate-Limit: 0.4 Sekunden zwischen Events
	if not checkRateLimit(player.UserId, 0.4) then return end

	local success, resource, amount, coinsGained =
		ResourceSystem.processMineRequest(player, oreId, session, MonetizationHandler)

	if not success then return end

	-- Client bestaetigen
	local evt = getEvent(RemoteEventsConfig.ORE_MINED)
	if evt then
		evt:FireClient(player, oreId, resource, amount, coinsGained)
	end

	-- Coin- und Inventar-Update senden
	if resource then
		local coinEvt = getEvent(RemoteEventsConfig.UPDATE_COINS)
		if coinEvt then coinEvt:FireClient(player, session.data.coins, session.data.gems) end

		local invEvt = getEvent(RemoteEventsConfig.UPDATE_INVENTORY)
		if invEvt then invEvt:FireClient(player, session.data.inventory) end
	end
end)

-- Remote Event Handler: Ressourcen verkaufen
getEvent(RemoteEventsConfig.SELL_RESOURCES).OnServerEvent:Connect(function(player, resourceName, amount)
	local session = Sessions[player.UserId]
	if not session then return end

	local coinsGained = ResourceSystem.sellResources(session, resourceName, amount, MonetizationHandler)

	local coinEvt = getEvent(RemoteEventsConfig.UPDATE_COINS)
	if coinEvt then coinEvt:FireClient(player, session.data.coins, session.data.gems) end

	local invEvt = getEvent(RemoteEventsConfig.UPDATE_INVENTORY)
	if invEvt then invEvt:FireClient(player, session.data.inventory) end

	if coinsGained > 0 then
		notify(player, "+" .. coinsGained .. " Coins!", "success")
	end
end)

-- Remote Event Handler: Insel freischalten
getEvent(RemoteEventsConfig.UNLOCK_ISLAND).OnServerEvent:Connect(function(player, islandIndex)
	local session = Sessions[player.UserId]
	if not session then return end

	if type(islandIndex) ~= "number" then return end
	islandIndex = math.floor(islandIndex)

	local success, msg = IslandManager.unlockIsland(session, islandIndex)

	if success then
		DataStoreManager.SaveData(player, session.data)

		local unlockEvt = getEvent(RemoteEventsConfig.ISLAND_UNLOCKED)
		if unlockEvt then unlockEvt:FireAllClients(islandIndex, player.DisplayName) end

		local coinEvt = getEvent(RemoteEventsConfig.UPDATE_COINS)
		if coinEvt then coinEvt:FireClient(player, session.data.coins, session.data.gems) end

		notify(player, "Insel freigeschaltet: " .. (IslandData[islandIndex] and IslandData[islandIndex].name or "?"), "success")
	else
		notify(player, msg, "warning")
	end
end)

-- Remote Event Handler: Upgrade kaufen
getEvent(RemoteEventsConfig.UPGRADE_PURCHASE).OnServerEvent:Connect(function(player, upgradeType, targetLevel)
	local session = Sessions[player.UserId]
	if not session then return end

	if type(upgradeType) ~= "string" or type(targetLevel) ~= "number" then return end
	targetLevel = math.floor(targetLevel)

	local success, newLevel, msg = IslandManager.purchaseUpgrade(session, upgradeType, targetLevel)

	local evt = getEvent(RemoteEventsConfig.UPGRADE_CONFIRMED)
	if evt then evt:FireClient(player, upgradeType, newLevel, session.data.coins) end

	if success then
		notify(player, upgradeType .. " auf Stufe " .. newLevel .. " verbessert!", "success")
	else
		notify(player, msg, "warning")
	end
end)

-- Remote Event Handler: Spieler-Daten anfordern
getEvent(RemoteEventsConfig.REQUEST_PLAYER_DATA).OnServerEvent:Connect(function(player)
	local session = Sessions[player.UserId]
	if not session then return end

	local evt = getEvent(RemoteEventsConfig.PLAYER_DATA_LOADED)
	if evt then evt:FireClient(player, session.data) end
end)

-- Remote Event Handler: Island-Daten anfordern
getEvent(RemoteEventsConfig.REQUEST_ISLAND_DATA).OnServerEvent:Connect(function(player)
	local evt = getEvent(RemoteEventsConfig.ISLAND_DATA_RESPONSE)
	if evt then evt:FireClient(player, IslandData) end
end)

-- Remote Event Handler: Auto-Mine starten
getEvent(RemoteEventsConfig.START_AUTO_MINE).OnServerEvent:Connect(function(player)
	local session = Sessions[player.UserId]
	if not session then return end
	if not session.passes.autoMine then
		notify(player, "Auto-Mine Pass benoetigt!", "warning")
		return
	end
	session.autoMining = true
end)

-- Remote Event Handler: Auto-Mine stoppen
getEvent(RemoteEventsConfig.STOP_AUTO_MINE).OnServerEvent:Connect(function(player)
	local session = Sessions[player.UserId]
	if session then session.autoMining = false end
end)

-- Remote Event Handler: Gems verwenden
getEvent(RemoteEventsConfig.USE_GEMS).OnServerEvent:Connect(function(player, action, amount)
	local session = Sessions[player.UserId]
	if not session or not session.data then return end
	local data = session.data

	if type(amount) ~= "number" or amount <= 0 then return end
	amount = math.floor(amount)

	if data.gems < amount then
		notify(player, "Nicht genug Gems!", "warning")
		return
	end

	if action == "gem_to_coins" then
		local coinsGained = amount * GameConfig.GEM_TO_COIN_RATE
		data.gems  = data.gems - amount
		data.coins = data.coins + coinsGained

		local evt = getEvent(RemoteEventsConfig.GEMS_USED)
		if evt then evt:FireClient(player, action, data.gems) end

		local coinEvt = getEvent(RemoteEventsConfig.UPDATE_COINS)
		if coinEvt then coinEvt:FireClient(player, data.coins, data.gems) end

		notify(player, "+" .. coinsGained .. " Coins!", "success")
	end
end)

-- Haupt-Tick: Auto-Save, Auto-Mine, Leaderboard
local autoSaveTimer     = 0
local leaderboardTimer  = 0
local autoMineCooldowns = {}  -- { [userId] = lastAutoMineTick }

RunService.Heartbeat:Connect(function(dt)
	autoSaveTimer    = autoSaveTimer + dt
	leaderboardTimer = leaderboardTimer + dt

	-- Auto-Save
	if autoSaveTimer >= GameConfig.DATA_SAVE_INTERVAL then
		autoSaveTimer = 0
		for userId, session in pairs(Sessions) do
			local player = Players:GetPlayerByUserId(userId)
			if player and session.data then
				local elapsed = os.time() - session.sessionStart
				session.data.stats.playTime = (session.data.stats.playTime or 0) + elapsed
				session.sessionStart = os.time()
				DataStoreManager.SaveData(player, session.data)
				LeaderboardSystem.updatePlayer(player, session.data)
			end
		end
	end

	-- Leaderboard-Broadcast
	if leaderboardTimer >= GameConfig.LEADERBOARD_UPDATE_INTERVAL then
		leaderboardTimer = 0
		LeaderboardSystem.broadcastLeaderboard(EventsFolder)
	end

	-- Auto-Mine Ticks (alle 5 Sekunden pro Spieler)
	for userId, session in pairs(Sessions) do
		if session.autoMining and session.passes.autoMine then
			local player   = Players:GetPlayerByUserId(userId)
			local lastTick = autoMineCooldowns[userId] or 0

			if os.clock() - lastTick >= 5 then
				autoMineCooldowns[userId] = os.clock()

				if player and player.Character then
					local islandIdx = IslandManager.getActiveIsland(player.Character)
					local success, resource, amount, coinsGained =
						ResourceSystem.autoMineTick(session, islandIdx, MonetizationHandler)

					if success and resource then
						local evt = getEvent(RemoteEventsConfig.AUTO_MINE_TICK)
						if evt then evt:FireClient(player, resource, amount, coinsGained) end

						local coinEvt = getEvent(RemoteEventsConfig.UPDATE_COINS)
						if coinEvt then coinEvt:FireClient(player, session.data.coins, session.data.gems) end

						local invEvt = getEvent(RemoteEventsConfig.UPDATE_INVENTORY)
						if invEvt then invEvt:FireClient(player, session.data.inventory) end
					end
				end
			end
		end
	end
end)

-- Alle Daten beim Server-Shutdown speichern
game:BindToClose(function()
	print("[GameManager] Server wird beendet – Alle Daten werden gespeichert...")
	for userId, session in pairs(Sessions) do
		local player = Players:GetPlayerByUserId(userId)
		if player and session.data then
			DataStoreManager.SaveData(player, session.data)
		end
	end
	print("[GameManager] Alle Daten gespeichert.")
end)

-- Bestehende Spieler registrieren (falls Script spaet geladen)
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

print("[GameManager] Ethereal Summit gestartet!")
