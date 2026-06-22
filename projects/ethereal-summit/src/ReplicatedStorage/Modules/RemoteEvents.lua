-- Ethereal Summit – Alle Remote-Event-Namen v2
-- C→S = Client feuert, Server empfaengt
-- S→C = Server feuert an einen Client
-- S→All = Server feuert an alle Clients

local RemoteEvents = {
	-- Abbau
	MINE_ORE             = "MineOre",
	ORE_MINED            = "OreMined",
	SPAWN_ORE            = "SpawnOre",
	REMOVE_ORE           = "RemoveOre",

	-- Ressourcen & Coins
	SELL_RESOURCES       = "SellResources",
	UPDATE_INVENTORY     = "UpdateInventory",
	UPDATE_COINS         = "UpdateCoins",

	-- Inseln
	UNLOCK_ISLAND        = "UnlockIsland",
	ISLAND_UNLOCKED      = "IslandUnlocked",
	REQUEST_ISLAND_DATA  = "RequestIslandData",
	ISLAND_DATA_RESPONSE = "IslandDataResponse",

	-- Upgrades
	UPGRADE_PURCHASE     = "UpgradePurchase",
	UPGRADE_CONFIRMED    = "UpgradeConfirmed",

	-- Shop / Monetarisierung
	PURCHASE_DEV_PRODUCT = "PurchaseDevProduct",
	PURCHASE_CONFIRMED   = "PurchaseConfirmed",

	-- Auto-Mine
	START_AUTO_MINE      = "StartAutoMine",
	STOP_AUTO_MINE       = "StopAutoMine",
	AUTO_MINE_TICK       = "AutoMineTick",

	-- Spieler-Daten
	REQUEST_PLAYER_DATA  = "RequestPlayerData",
	PLAYER_DATA_LOADED   = "PlayerDataLoaded",

	-- UI
	SHOW_NOTIFICATION    = "ShowNotification",
	UPDATE_LEADERBOARD   = "UpdateLeaderboard",

	-- Gems
	USE_GEMS             = "UseGems",
	GEMS_USED            = "GemsUsed",

	-- Mining Combo (NEU)
	COMBO_UPDATE         = "ComboUpdate",    -- S→C: comboCount, multValue

	-- Rebirth (NEU)
	REBIRTH_REQUEST      = "RebirthRequest", -- C→S
	REBIRTH_RESULT       = "RebirthResult",  -- S→C: success, newMult, rebirths

	-- Daily Rewards (NEU)
	REQUEST_DAILY_DATA   = "RequestDailyData",   -- C→S
	DAILY_DATA_RESPONSE  = "DailyDataResponse",  -- S→C: streak, nextReward, canClaim
	CLAIM_DAILY_REWARD   = "ClaimDailyReward",   -- C→S
	DAILY_REWARD_GRANTED = "DailyRewardGranted", -- S→C: reward, newStreak

	-- Quests (NEU)
	REQUEST_QUEST_DATA   = "RequestQuestData",   -- C→S
	QUEST_DATA_RESPONSE  = "QuestDataResponse",  -- S→C: dailyQuests, weeklyQuest
	CLAIM_QUEST_REWARD   = "ClaimQuestReward",   -- C→S: questId
	QUEST_PROGRESS_UPDATE= "QuestProgressUpdate",-- S→C: questId, newProgress, done

	-- Promo-Codes (NEU)
	REDEEM_CODE          = "RedeemCode",         -- C→S: code
	CODE_RESULT          = "CodeResult",          -- S→C: success, message, reward

	-- Achievements (NEU)
	ACHIEVEMENT_UNLOCKED = "AchievementUnlocked",-- S→C: achievId, display, reward

	-- Pet-System (NEU)
	OPEN_PET_EGG         = "OpenPetEgg",         -- C→S: eggType
	PET_EGG_RESULT       = "PetEggResult",        -- S→C: petId, petType, rarity, level
	EQUIP_PET            = "EquipPet",            -- C→S: petId, slot
	PET_EQUIPPED         = "PetEquipped",          -- S→C: slot, petId, newMultipliers
	LEVEL_UP_PET         = "LevelUpPet",          -- C→S: petId
	PET_LEVELED          = "PetLeveled",           -- S→C: petId, newLevel
	REQUEST_PET_DATA     = "RequestPetData",      -- C→S
	PET_DATA_RESPONSE    = "PetDataResponse",     -- S→C: pets table

	-- Tutorial (NEU)
	TUTORIAL_COMPLETE    = "TutorialComplete",    -- C→S: (neuer Spieler fertig)
}

return RemoteEvents
