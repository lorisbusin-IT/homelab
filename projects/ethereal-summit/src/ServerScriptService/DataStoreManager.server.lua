-- Ethereal Summit – Datenpersistenz v2
local DataStoreService = game:GetService("DataStoreService")
local GameConfig       = require(game.ReplicatedStorage.Modules.GameConfig)

local DataStoreManager = {}
local PlayerStore      = DataStoreService:GetDataStore("EtherealSummit_v2")
local ReceiptStore     = DataStoreService:GetDataStore("EtherealSummit_Receipts_v1")

local function defaultData()
	return {
		-- Kern
		coins            = 0,
		gems             = 0,
		highestIsland    = 1,
		unlockedIslands  = {[1] = true},
		inventory        = {},
		upgrades         = { pickaxe=1, backpack=1, autoMiner=0, sellBoost=1 },
		passes           = { vip=false, autoMine=false, pet=false, battlePass=false, luckyEgg=false },
		boosts           = { coinBoostExpiry=0, coinBoostMult=GameConfig.COIN_BOOST_MULT },

		-- Statistiken
		stats            = { totalCoinsEarned=0, totalOresMined=0, playTime=0 },

		-- Rebirth
		rebirths         = 0,
		rebirthMult      = 1.0,

		-- Daily Rewards
		daily            = { lastClaimDay="0", streak=0, longestStreak=0 },

		-- Quests
		quests           = {
			daily           = {},
			weekly          = { progress=0, done=false },
			lastDailyReset  = 0,
			lastWeeklyReset = 0,
		},

		-- Promo-Codes
		usedCodes        = {},

		-- Achievements
		achievements     = {},

		-- Pets
		pets             = {
			owned    = {},         -- { [petId]={ type, rarity, level } }
			equipped = {nil,nil,nil},
			nextId   = 1,
		},

		-- Tutorial
		tutorialDone     = false,

		-- Meta
		version          = GameConfig.DATA_VERSION,
		firstJoin        = os.time(),
		lastSave         = os.time(),
	}
end

-- Migration von v1 → v2: fehlende Felder ergaenzen
local function migrate(data)
	local d = defaultData()

	-- Neue Felder hinzufuegen falls nicht vorhanden
	if not data.rebirths then data.rebirths = 0 end
	if not data.rebirthMult then data.rebirthMult = 1.0 end
	if not data.daily then data.daily = d.daily end
	if not data.quests then data.quests = d.quests end
	if not data.quests.daily then data.quests.daily = {} end
	if not data.quests.weekly then data.quests.weekly = { progress=0, done=false } end
	if not data.quests.lastDailyReset then data.quests.lastDailyReset = 0 end
	if not data.quests.lastWeeklyReset then data.quests.lastWeeklyReset = 0 end
	if not data.usedCodes then data.usedCodes = {} end
	if not data.achievements then data.achievements = {} end
	if not data.pets then data.pets = d.pets end
	if not data.tutorialDone then data.tutorialDone = false end
	if not data.passes then data.passes = d.passes end
	if not data.passes.battlePass then data.passes.battlePass = false end
	if not data.passes.luckyEgg then data.passes.luckyEgg = false end
	if not data.stats then data.stats = d.stats end
	if not data.upgrades.sellBoost then data.upgrades.sellBoost = 1 end
	if not data.boosts then data.boosts = d.boosts end

	data.version = GameConfig.DATA_VERSION
	return data
end

function DataStoreManager.LoadData(player)
	local key = "player_" .. player.UserId
	local success, result = pcall(function()
		return PlayerStore:GetAsync(key)
	end)

	if not success then
		warn("[DataStore] Laden fehlgeschlagen fuer " .. player.Name .. ": " .. tostring(result))
		return defaultData()
	end

	if result == nil then
		return defaultData()
	end

	return migrate(result)
end

function DataStoreManager.SaveData(player, data)
	local key = "player_" .. player.UserId
	data.lastSave = os.time()

	local success, err = pcall(function()
		PlayerStore:UpdateAsync(key, function()
			return data
		end)
	end)

	if not success then
		task.wait(2)
		pcall(function()
			PlayerStore:UpdateAsync(key, function() return data end)
		end)
		warn("[DataStore] Speichern fehlgeschlagen fuer " .. player.Name .. ": " .. tostring(err))
	end
end

function DataStoreManager.IsReceiptProcessed(receiptId)
	local key = "receipt_" .. receiptId
	local success, result = pcall(function()
		return ReceiptStore:GetAsync(key)
	end)
	return success and result == true
end

function DataStoreManager.MarkReceiptProcessed(receiptId)
	local key = "receipt_" .. receiptId
	pcall(function()
		ReceiptStore:SetAsync(key, true)
	end)
end

return DataStoreManager
