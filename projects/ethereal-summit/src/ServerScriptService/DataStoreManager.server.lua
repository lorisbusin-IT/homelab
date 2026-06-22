-- Ethereal Summit – Datenpersistenz (Server)
local DataStoreService = game:GetService("DataStoreService")
local GameConfig       = require(game.ReplicatedStorage.Modules.GameConfig)

local DataStoreManager = {}
local PlayerStore      = DataStoreService:GetDataStore("EtherealSummit_v1")
local ReceiptStore     = DataStoreService:GetDataStore("EtherealSummit_Receipts_v1")

-- Standard-Daten fuer neue Spieler
local function defaultData()
	return {
		coins            = 0,
		gems             = 0,
		highestIsland    = 1,
		unlockedIslands  = {[1] = true},
		inventory        = {},
		upgrades         = { pickaxe=1, backpack=1, autoMiner=0, sellBoost=1 },
		passes           = { vip=false, autoMine=false, pet=false },
		boosts           = { coinBoostExpiry=0, coinBoostMult=GameConfig.COIN_BOOST_MULT },
		stats            = { totalCoinsEarned=0, totalOresMined=0, playTime=0 },
		version          = GameConfig.DATA_VERSION,
		firstJoin        = os.time(),
		lastSave         = os.time(),
	}
end

-- Schema-Migration: Fehlende Felder in alten Saves ergaenzen
local function migrate(data)
	local defaults = defaultData()
	if not data.gems then data.gems = 0 end
	if not data.stats then data.stats = defaults.stats end
	if not data.boosts then data.boosts = defaults.boosts end
	if not data.upgrades.sellBoost then data.upgrades.sellBoost = 1 end
	if not data.passes then data.passes = defaults.passes end
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
		PlayerStore:UpdateAsync(key, function(oldData)
			return data
		end)
	end)

	if not success then
		-- Einmal wiederholen bei Fehler
		task.wait(2)
		pcall(function()
			PlayerStore:UpdateAsync(key, function() return data end)
		end)
		warn("[DataStore] Speichern fehlgeschlagen fuer " .. player.Name .. ": " .. tostring(err))
	end
end

-- Pruefen ob eine Receipt-ID bereits verarbeitet wurde (Anti-Doppel-Grant)
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
