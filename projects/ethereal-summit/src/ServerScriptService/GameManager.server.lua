-- Ethereal Summit – GameManager v2 (Server-Orchestrierung)
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local GameConfig         = require(ReplicatedStorage.Modules.GameConfig)
local RE                 = require(ReplicatedStorage.Modules.RemoteEvents)
local IslandData         = require(ReplicatedStorage.Modules.IslandData)
local DataStoreManager   = require(script.Parent.DataStoreManager)
local MonetizationHandler= require(script.Parent.MonetizationHandler)
local IslandManager      = require(script.Parent.IslandManager)
local ResourceSystem     = require(script.Parent.ResourceSystem)
local LeaderboardSystem  = require(script.Parent.LeaderboardSystem)
local RebirthSystem      = require(script.Parent.RebirthSystem)
local DailyRewardsSystem = require(script.Parent.DailyRewardsSystem)
local QuestSystem        = require(script.Parent.QuestSystem)
local CodeSystem         = require(script.Parent.CodeSystem)
local AchievementSystem  = require(script.Parent.AchievementSystem)
local PetSystem          = require(script.Parent.PetSystem)
local AnnouncementSystem = require(script.Parent.AnnouncementSystem)
local EventSystem        = require(script.Parent.EventSystem)
local CrateSystem        = require(script.Parent.CrateSystem)

-- ========== Sessions & Events ==========
local Sessions   = {}
MonetizationHandler.setSessions(Sessions)

local EF = Instance.new("Folder")
EF.Name  = "RemoteEvents"
EF.Parent = ReplicatedStorage

for _, eventName in pairs(RE) do
	local re   = Instance.new("RemoteEvent")
	re.Name    = eventName
	re.Parent  = EF
end

ResourceSystem.setEventsFolder(EF)
AnnouncementSystem.setEventsFolder(EF)
EventSystem.setup(EF, AnnouncementSystem, ResourceSystem, Sessions)
ResourceSystem.setLuckyChanceFn(function() return EventSystem.luckyOreChance end)

-- Wait for WorldBuilder to place islands, then initialize ore spawning
task.spawn(function()
	local deadline = os.clock() + 15
	repeat task.wait(0.1) until _G.EtherealWorldReady or os.clock() > deadline
	if not _G.EtherealSpawnPositions then
		warn("[GM] EtherealSpawnPositions missing – ores will not spawn!")
		return
	end
	for i = 1, 10 do
		local positions = _G.EtherealSpawnPositions[i]
		if positions then
			ResourceSystem.initializeIsland(i, positions)
		end
	end
	print("[GM] All 10 islands initialized with ore nodes.")
end)

local function getEv(name)
	return EF:FindFirstChild(name)
end

local function notify(player, message, style)
	local evt = getEv(RE.SHOW_NOTIFICATION)
	if evt then evt:FireClient(player, message, style or "info") end
end

-- ========== Rate-Limit ==========
local RateLimits = {}
local function checkRateLimit(userId, cooldown)
	local now = os.clock()
	local rl  = RateLimits[userId]
	if not rl then RateLimits[userId] = { lastMineTime=now }; return true end
	if now - rl.lastMineTime < cooldown then return false end
	rl.lastMineTime = now
	return true
end

-- ========== Combo-System ==========
local Combos = {}  -- { [userId] = { count, lastMineTime, mult } }

local function getComboMult(comboCount)
	local mult = 1.0
	for _, level in ipairs(GameConfig.COMBO_LEVELS) do
		if comboCount >= level.threshold then
			mult = level.mult
		end
	end
	return mult
end

local function updateCombo(player, session)
	local userId = player.UserId
	local now    = os.clock()
	local combo  = Combos[userId] or { count=0, lastMineTime=0, mult=1.0 }

	if now - combo.lastMineTime > GameConfig.COMBO_TIMEOUT then
		combo.count = 1
	else
		combo.count = combo.count + 1
	end
	combo.lastMineTime  = now
	combo.mult          = getComboMult(combo.count)
	Combos[userId]      = combo
	session.comboMult   = combo.mult

	-- Client informieren
	local evt = getEv(RE.COMBO_UPDATE)
	if evt then evt:FireClient(player, combo.count, combo.mult) end

	-- Achievement pruefen
	AchievementSystem.checkCombo(player, session, combo.count, EF)

	return combo.count, combo.mult
end

-- ========== PlayerAdded ==========
local function onPlayerAdded(player)
	LeaderboardSystem.cachePlayerName(player)
	local data    = DataStoreManager.LoadData(player)
	local session = {
		data        = data,
		passes      = {},
		isPremium   = false,
		autoMining  = false,
		comboMult   = 1.0,
		petMults    = { coinMult=1.0, luckBonus=0, mineTimeReduction=0 },
		sessionStart= os.time(),
		userId      = player.UserId,
	}
	Sessions[player.UserId] = session

	MonetizationHandler.loadPassesForPlayer(player, session)
	QuestSystem.refreshIfNeeded(session)

	-- Pet-Multiplikatoren berechnen
	session.petMults = PetSystem.getMultipliers(session)

	task.delay(1.5, function()
		if not player.Parent then return end
		local evt = getEv(RE.PLAYER_DATA_LOADED)
		if evt then evt:FireClient(player, data) end

		-- Achievement-Check beim Join
		AchievementSystem.checkAll(player, session, EF)

		-- Daily Reward automatisch anzeigen (Client entscheidet ob Claim)
		local dailyEvt = getEv(RE.DAILY_DATA_RESPONSE)
		if dailyEvt then
			dailyEvt:FireClient(player, DailyRewardsSystem.getUIData(data))
		end
	end)
	print("[GM] " .. player.Name .. " joined. Rebirth: " .. (data.rebirths or 0))
end

local function onPlayerRemoving(player)
	local session = Sessions[player.UserId]
	if session and session.data then
		local elapsed = os.time() - session.sessionStart
		session.data.stats.playTime = (session.data.stats.playTime or 0) + elapsed
		DataStoreManager.SaveData(player, session.data)
	end
	Sessions[player.UserId]  = nil
	RateLimits[player.UserId] = nil
	Combos[player.UserId]     = nil
end

-- ========== Mining ==========
getEv(RE.MINE_ORE).OnServerEvent:Connect(function(player, oreId)
	local session = Sessions[player.UserId]
	if not session then return end
	if type(oreId) ~= "string" then return end
	if not checkRateLimit(player.UserId, 0.4) then return end

	updateCombo(player, session)

	-- Boss Ore pruefen (spezieller Ore-ID Prefix)
	if type(oreId) == "string" and oreId:sub(1, 5) == "BOSS_" then
		local hit, lastHit = EventSystem.hitBossOre(player, session)
		if hit then
			local coinEvt = getEv(RE.UPDATE_COINS)
			if coinEvt then coinEvt:FireClient(player, session.data.coins, session.data.gems) end
			notify(player, "+" .. GameConfig.EVENTS.boss.hitReward.gems .. " Gems – Boss Treffer!", "success")
			if lastHit then
				notify(player, "+" .. GameConfig.EVENTS.boss.bonusReward.gems .. " Gems – LETZTER SCHLAG!", "success")
				AchievementSystem.checkAll(player, session, EF)
			end
		end
		return
	end

	-- Event Coin-Multiplikator bestimmen
	do
		local evtMult = EventSystem.globalCoinMult
		if EventSystem.activeEvent and EventSystem.activeEvent.type == "meteor" then
			local nodes = ResourceSystem.getOreNodes()
			local node  = nodes[oreId]
			if node and node.islandIndex == EventSystem.activeEvent.islandIndex then
				evtMult = math.max(evtMult, EventSystem.activeEvent.coinMult or 1)
			end
		end
		session.eventCoinMult = evtMult
	end

	local success, resource, amount, coinsGained, isLucky =
		ResourceSystem.processMineRequest(player, oreId, session, MonetizationHandler)
	if not success then return end

	local evt = getEv(RE.ORE_MINED)
	if evt then evt:FireClient(player, oreId, resource, amount, coinsGained) end

	if resource then
		-- Lucky Ore Ankuendigung
		if isLucky then
			AnnouncementSystem.announce(
				"⭐ " .. player.Name .. " hat ein LUCKY ORE gefunden! " ..
				(coinsGained > 0 and ("+" .. math.floor(coinsGained) .. " Coins!") or ""),
				"gold"
			)
			local luckyEvt = getEv(RE.LUCKY_ORE_BROKEN)
			if luckyEvt then luckyEvt:FireAllClients(player.Name, resource, coinsGained) end
		end

		-- Quest-Fortschritt: "mine"
		QuestSystem.updateProgress(session, "mine", 1, EF, player)

		-- Seltene Erze fuer Quest tracken
		local resData = require(ReplicatedStorage.Modules.ResourceData)
		if resData[resource] and (resData[resource].spawnWeight or 500) <= 30 then
			QuestSystem.updateProgress(session, "mine_rare", 1, EF, player)
		end

		local coinEvt = getEv(RE.UPDATE_COINS)
		if coinEvt then coinEvt:FireClient(player, session.data.coins, session.data.gems) end
		local invEvt = getEv(RE.UPDATE_INVENTORY)
		if invEvt then invEvt:FireClient(player, session.data.inventory) end

		AchievementSystem.checkAll(player, session, EF)
	end
end)

-- ========== Verkaufen ==========
getEv(RE.SELL_RESOURCES).OnServerEvent:Connect(function(player, resourceName, amount)
	local session = Sessions[player.UserId]
	if not session then return end

	local coinsGained = ResourceSystem.sellResources(session, resourceName, amount, MonetizationHandler)

	if coinsGained > 0 then
		QuestSystem.updateProgress(session, "sell", 1, EF, player)
		QuestSystem.updateProgress(session, "earn", coinsGained, EF, player)
	end

	local coinEvt = getEv(RE.UPDATE_COINS)
	if coinEvt then coinEvt:FireClient(player, session.data.coins, session.data.gems) end
	local invEvt = getEv(RE.UPDATE_INVENTORY)
	if invEvt then invEvt:FireClient(player, session.data.inventory) end

	if coinsGained > 0 then
		notify(player, "+" .. math.floor(coinsGained) .. " Coins!", "success")
	end

	AchievementSystem.checkAll(player, session, EF)
end)

-- ========== Insel freischalten ==========
getEv(RE.UNLOCK_ISLAND).OnServerEvent:Connect(function(player, islandIndex)
	local session = Sessions[player.UserId]
	if not session then return end
	if type(islandIndex) ~= "number" then return end
	islandIndex = math.floor(islandIndex)

	local success, msg = IslandManager.unlockIsland(session, islandIndex)
	if success then
		DataStoreManager.SaveData(player, session.data)
		local unlockEvt = getEv(RE.ISLAND_UNLOCKED)
		if unlockEvt then unlockEvt:FireAllClients(islandIndex, player.DisplayName) end
		local coinEvt = getEv(RE.UPDATE_COINS)
		if coinEvt then coinEvt:FireClient(player, session.data.coins, session.data.gems) end

		QuestSystem.updateProgress(session, "island", 1, EF, player)
		AchievementSystem.checkAll(player, session, EF)
		notify(player, "Insel freigeschaltet: " .. (IslandData[islandIndex] and IslandData[islandIndex].name or "?"), "success")
	else
		notify(player, msg, "warning")
	end
end)

-- ========== Upgrade ==========
getEv(RE.UPGRADE_PURCHASE).OnServerEvent:Connect(function(player, upgradeType, targetLevel)
	local session = Sessions[player.UserId]
	if not session then return end
	if type(upgradeType) ~= "string" or type(targetLevel) ~= "number" then return end
	targetLevel = math.floor(targetLevel)

	local success, newLevel, msg = IslandManager.purchaseUpgrade(session, upgradeType, targetLevel)
	local evt = getEv(RE.UPGRADE_CONFIRMED)
	if evt then evt:FireClient(player, upgradeType, newLevel, session.data.coins) end

	if success then
		QuestSystem.updateProgress(session, "upgrade", 1, EF, player)
		AchievementSystem.checkAll(player, session, EF)
		notify(player, upgradeType .. " auf Stufe " .. newLevel .. "!", "success")
	else
		notify(player, msg, "warning")
	end
end)

-- ========== Rebirth ==========
getEv(RE.REBIRTH_REQUEST).OnServerEvent:Connect(function(player)
	local session = Sessions[player.UserId]
	if not session then return end

	local success, rebirthsOrMsg, newMult = RebirthSystem.performRebirth(session)
	local evt = getEv(RE.REBIRTH_RESULT)
	if evt then evt:FireClient(player, success, rebirthsOrMsg, newMult) end

	if success then
		DataStoreManager.SaveData(player, session.data)
		local pdEvt = getEv(RE.PLAYER_DATA_LOADED)
		if pdEvt then pdEvt:FireClient(player, session.data) end
		AchievementSystem.checkAll(player, session, EF)
		AnnouncementSystem.announce(
			"🔥 " .. player.Name .. " hat Rebirth " .. rebirthsOrMsg .. " erreicht! +" ..
			math.floor(GameConfig.REBIRTH_MULT_PER_REBIRTH * 100) .. "% permanente Coins!",
			"purple"
		)
		notify(player, "Rebirth " .. rebirthsOrMsg .. "! +" .. math.floor(GameConfig.REBIRTH_MULT_PER_REBIRTH*100) .. "% Coins permanent!", "success")
	else
		notify(player, rebirthsOrMsg, "warning")
	end
end)

-- ========== Daily Reward ==========
getEv(RE.REQUEST_DAILY_DATA).OnServerEvent:Connect(function(player)
	local session = Sessions[player.UserId]
	if not session then return end
	local evt = getEv(RE.DAILY_DATA_RESPONSE)
	if evt then evt:FireClient(player, DailyRewardsSystem.getUIData(session.data)) end
end)

getEv(RE.CLAIM_DAILY_REWARD).OnServerEvent:Connect(function(player)
	local session = Sessions[player.UserId]
	if not session then return end

	local success, reward, newStreak = DailyRewardsSystem.claimReward(session)
	local evt = getEv(RE.DAILY_REWARD_GRANTED)
	if evt then evt:FireClient(player, success, reward, newStreak) end

	if success then
		DataStoreManager.SaveData(player, session.data)
		local coinEvt = getEv(RE.UPDATE_COINS)
		if coinEvt then coinEvt:FireClient(player, session.data.coins, session.data.gems) end
		AchievementSystem.checkAll(player, session, EF)
		notify(player, "Taegl. Belohnung abgeholt! Streak: " .. newStreak .. " Tage", "success")
	else
		notify(player, "Heute bereits abgeholt!", "warning")
	end
end)

-- ========== Quests ==========
getEv(RE.REQUEST_QUEST_DATA).OnServerEvent:Connect(function(player)
	local session = Sessions[player.UserId]
	if not session then return end
	QuestSystem.refreshIfNeeded(session)
	local evt = getEv(RE.QUEST_DATA_RESPONSE)
	if evt then evt:FireClient(player, QuestSystem.getUIData(session.data)) end
end)

getEv(RE.CLAIM_QUEST_REWARD).OnServerEvent:Connect(function(player, questId)
	local session = Sessions[player.UserId]
	if not session then return end
	if type(questId) ~= "string" then return end

	local success, reward = QuestSystem.claimReward(session, questId)
	if success then
		local coinEvt = getEv(RE.UPDATE_COINS)
		if coinEvt then coinEvt:FireClient(player, session.data.coins, session.data.gems) end
		local txt = reward.coins and ("+" .. reward.coins .. " Coins") or ("+" .. (reward.gems or 0) .. " Gems")
		notify(player, "Quest-Belohnung: " .. txt, "success")
		AchievementSystem.checkAll(player, session, EF)
	else
		notify(player, reward, "warning")
	end
end)

-- ========== Promo-Codes ==========
getEv(RE.REDEEM_CODE).OnServerEvent:Connect(function(player, code)
	local session = Sessions[player.UserId]
	if not session then return end
	session.userId = player.UserId

	local success, message, reward = CodeSystem.redeemCode(session, code)
	local evt = getEv(RE.CODE_RESULT)
	if evt then evt:FireClient(player, success, message, reward) end

	if success then
		DataStoreManager.SaveData(player, session.data)
		local coinEvt = getEv(RE.UPDATE_COINS)
		if coinEvt then coinEvt:FireClient(player, session.data.coins, session.data.gems) end
		notify(player, message, "success")
	else
		notify(player, message, "warning")
	end
end)

-- ========== Pets ==========
getEv(RE.OPEN_PET_EGG).OnServerEvent:Connect(function(player, eggType)
	local session = Sessions[player.UserId]
	if not session then return end
	if type(eggType) ~= "string" then return end

	local success, petData, msg = PetSystem.openEgg(session, eggType)
	local evt = getEv(RE.PET_EGG_RESULT)
	if evt then evt:FireClient(player, success, petData, msg) end

	if success then
		-- Pet-Multiplikatoren aktualisieren
		session.petMults = PetSystem.getMultipliers(session)
		local coinEvt = getEv(RE.UPDATE_COINS)
		if coinEvt then coinEvt:FireClient(player, session.data.coins, session.data.gems) end

		QuestSystem.updateProgress(session, "egg", 1, EF, player)
		AchievementSystem.grantIfApplicable(player, session, "first_pet", EF)
		if petData and petData.rarity == "legendary" then
			AchievementSystem.grantIfApplicable(player, session, "legendary_pet", EF)
			AnnouncementSystem.announce(
				"🐉 " .. player.Name .. " hat ein LEGENDAERES Pet gezogen: " .. petData.name .. "!",
				"purple"
			)
		end
		notify(player, petData.rarity:upper() .. " Pet: " .. petData.name .. " erhalten!", "success")
	else
		notify(player, msg, "warning")
	end
end)

getEv(RE.EQUIP_PET).OnServerEvent:Connect(function(player, petId, slot)
	local session = Sessions[player.UserId]
	if not session then return end
	if type(slot) ~= "number" then return end
	slot = math.floor(slot)

	local success, msg = PetSystem.equipPet(session, petId, slot)
	if success then
		session.petMults = PetSystem.getMultipliers(session)
		local evt = getEv(RE.PET_EQUIPPED)
		if evt then evt:FireClient(player, slot, petId, session.petMults) end
	else
		notify(player, msg, "warning")
	end
end)

getEv(RE.LEVEL_UP_PET).OnServerEvent:Connect(function(player, petId)
	local session = Sessions[player.UserId]
	if not session then return end
	if type(petId) ~= "string" then return end

	local success, newLevel, msg = PetSystem.levelUpPet(session, petId)
	local evt = getEv(RE.PET_LEVELED)
	if evt then evt:FireClient(player, success, petId, newLevel, msg) end

	if success then
		session.petMults = PetSystem.getMultipliers(session)
		local coinEvt = getEv(RE.UPDATE_COINS)
		if coinEvt then coinEvt:FireClient(player, session.data.coins, session.data.gems) end
		notify(player, "Pet auf Level " .. newLevel .. "!", "success")
	else
		notify(player, msg, "warning")
	end
end)

getEv(RE.REQUEST_PET_DATA).OnServerEvent:Connect(function(player)
	local session = Sessions[player.UserId]
	if not session then return end
	local evt = getEv(RE.PET_DATA_RESPONSE)
	if evt then evt:FireClient(player, PetSystem.getUIData(session.data)) end
end)

-- ========== Gems ==========
getEv(RE.USE_GEMS).OnServerEvent:Connect(function(player, action, amount)
	local session = Sessions[player.UserId]
	if not session then return end
	local data = session.data
	if type(amount) ~= "number" or amount <= 0 then return end
	amount = math.floor(amount)
	if data.gems < amount then notify(player, "Nicht genug Gems!", "warning"); return end

	if action == "gem_to_coins" then
		local coinsGained = amount * GameConfig.GEM_TO_COIN_RATE
		data.gems  = data.gems - amount
		data.coins = data.coins + coinsGained
		local evt = getEv(RE.GEMS_USED)
		if evt then evt:FireClient(player, action, data.gems) end
		local coinEvt = getEv(RE.UPDATE_COINS)
		if coinEvt then coinEvt:FireClient(player, data.coins, data.gems) end
		notify(player, "+" .. coinsGained .. " Coins!", "success")
	end
end)

-- ========== Sonstiges ==========
getEv(RE.REQUEST_PLAYER_DATA).OnServerEvent:Connect(function(player)
	local session = Sessions[player.UserId]
	if not session then return end
	local evt = getEv(RE.PLAYER_DATA_LOADED)
	if evt then evt:FireClient(player, session.data) end
end)

getEv(RE.REQUEST_ISLAND_DATA).OnServerEvent:Connect(function(player)
	local evt = getEv(RE.ISLAND_DATA_RESPONSE)
	if evt then evt:FireClient(player, IslandData) end
end)

getEv(RE.START_AUTO_MINE).OnServerEvent:Connect(function(player)
	local session = Sessions[player.UserId]
	if not session then return end
	if not session.passes.autoMine then notify(player, "Auto-Mine Pass benoetigt!", "warning"); return end
	session.autoMining = true
end)

getEv(RE.STOP_AUTO_MINE).OnServerEvent:Connect(function(player)
	local session = Sessions[player.UserId]
	if session then session.autoMining = false end
end)

getEv(RE.TUTORIAL_COMPLETE).OnServerEvent:Connect(function(player)
	local session = Sessions[player.UserId]
	if session and session.data then
		session.data.tutorialDone = true
	end
end)

-- ========== Mystery Crates ==========
getEv(RE.OPEN_CRATE).OnServerEvent:Connect(function(player, crateType)
	local session = Sessions[player.UserId]
	if not session then return end
	if type(crateType) ~= "string" then return end

	local success, result, msg = CrateSystem.openCrate(
		session, crateType, AnnouncementSystem, PetSystem, player
	)
	local evt = getEv(RE.CRATE_RESULT)
	if evt then evt:FireClient(player, success, result, msg) end

	if success then
		if result and result.petInfo then
			session.petMults = PetSystem.getMultipliers(session)
			AchievementSystem.grantIfApplicable(player, session, "first_pet", EF)
			if result.petInfo.rarity == "legendary" then
				AchievementSystem.grantIfApplicable(player, session, "legendary_pet", EF)
			end
		end
		local coinEvt = getEv(RE.UPDATE_COINS)
		if coinEvt then coinEvt:FireClient(player, session.data.coins, session.data.gems) end
		notify(player, result and result.display or "Kiste geoeffnet!", "success")
		AchievementSystem.checkAll(player, session, EF)
	else
		notify(player, msg, "warning")
	end
end)

-- ========== Haupt-Tick ==========
local autoSaveTimer    = 0
local leaderboardTimer = 0
local autoMineCD       = {}

RunService.Heartbeat:Connect(function(dt)
	autoSaveTimer    = autoSaveTimer + dt
	leaderboardTimer = leaderboardTimer + dt

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

	if leaderboardTimer >= GameConfig.LEADERBOARD_UPDATE_INTERVAL then
		leaderboardTimer = 0
		LeaderboardSystem.broadcastLeaderboard(EF)
	end

	for userId, session in pairs(Sessions) do
		if session.autoMining and session.passes.autoMine then
			local player  = Players:GetPlayerByUserId(userId)
			local lastTick = autoMineCD[userId] or 0
			if os.clock() - lastTick >= 5 then
				autoMineCD[userId] = os.clock()
				if player and player.Character then
					local islandIdx = IslandManager.getActiveIsland(player.Character)
					local ok, resource, amount, coinsGained =
						ResourceSystem.autoMineTick(session, islandIdx, MonetizationHandler)
					if ok and resource then
						local evt = getEv(RE.AUTO_MINE_TICK)
						if evt then evt:FireClient(player, resource, amount, coinsGained) end
						local coinEvt = getEv(RE.UPDATE_COINS)
						if coinEvt then coinEvt:FireClient(player, session.data.coins, session.data.gems) end
						local invEvt = getEv(RE.UPDATE_INVENTORY)
						if invEvt then invEvt:FireClient(player, session.data.inventory) end
						QuestSystem.updateProgress(session, "mine", 1, EF, player)
					end
				end
			end
		end
	end
end)

game:BindToClose(function()
	print("[GM] Server wird beendet – Daten speichern...")
	for userId, session in pairs(Sessions) do
		local player = Players:GetPlayerByUserId(userId)
		if player and session.data then
			DataStoreManager.SaveData(player, session.data)
		end
	end
end)

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, p) end

print("[GM] Ethereal Summit v2 gestartet!")
