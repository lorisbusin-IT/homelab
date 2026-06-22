-- Ethereal Summit – Alle Remote-Event-Namen als Konstanten
-- C→S = Client feuert, Server empfaengt
-- S→C = Server feuert an einen Client
-- S→All = Server feuert an alle Clients

local RemoteEvents = {
	-- Abbau (C→S / S→C)
	MINE_ORE             = "MineOre",            -- C→S: oreId
	ORE_MINED            = "OreMined",            -- S→C: oreId, resource, amount, coinsGained
	SPAWN_ORE            = "SpawnOre",            -- S→All: oreId, islandIndex, position, resource
	REMOVE_ORE           = "RemoveOre",           -- S→All: oreId

	-- Ressourcen & Coins
	SELL_RESOURCES       = "SellResources",       -- C→S: resourceName, amount
	UPDATE_INVENTORY     = "UpdateInventory",      -- S→C: inventory table
	UPDATE_COINS         = "UpdateCoins",          -- S→C: coins, gems

	-- Inseln
	UNLOCK_ISLAND        = "UnlockIsland",         -- C→S: islandIndex
	ISLAND_UNLOCKED      = "IslandUnlocked",       -- S→All: islandIndex, unlockerName
	REQUEST_ISLAND_DATA  = "RequestIslandData",    -- C→S: (leer)
	ISLAND_DATA_RESPONSE = "IslandDataResponse",   -- S→C: islandData table

	-- Upgrades
	UPGRADE_PURCHASE     = "UpgradePurchase",      -- C→S: upgradeType, targetLevel
	UPGRADE_CONFIRMED    = "UpgradeConfirmed",     -- S→C: upgradeType, newLevel, newCoinBalance

	-- Shop / Monetarisierung
	PURCHASE_DEV_PRODUCT = "PurchaseDevProduct",   -- C→S: productId (loest Prompt aus)
	PURCHASE_CONFIRMED   = "PurchaseConfirmed",    -- S→C: productType, newBalance

	-- Auto-Mine
	START_AUTO_MINE      = "StartAutoMine",        -- C→S: (leer)
	STOP_AUTO_MINE       = "StopAutoMine",         -- C→S: (leer)
	AUTO_MINE_TICK       = "AutoMineTick",          -- S→C: resource, amount, coinsGained

	-- Spieler-Daten
	REQUEST_PLAYER_DATA  = "RequestPlayerData",    -- C→S: (leer)
	PLAYER_DATA_LOADED   = "PlayerDataLoaded",     -- S→C: playerData table

	-- UI-Benachrichtigungen
	SHOW_NOTIFICATION    = "ShowNotification",     -- S→C: message, style (info/success/warning/error)
	UPDATE_LEADERBOARD   = "UpdateLeaderboard",    -- S→All: { topCoins=[], topIsland=[], topOres=[] }

	-- Gems verwenden
	USE_GEMS             = "UseGems",              -- C→S: action, amount
	GEMS_USED            = "GemsUsed",             -- S→C: action, newGemBalance
}

return RemoteEvents
