-- Ethereal Summit – Zentrale Konfiguration
-- WICHTIG: Pass-IDs und Produkt-IDs nach der Veroeffentlichung hier eintragen

local GameConfig = {}

-- Game Pass IDs (nach Veroeffentlichung bei roblox.com/develop eintragen)
GameConfig.GAME_PASSES = {
	VIP        = 0,   -- 299 Robux: 2x Ressourcen, VIP-Bereich, Gold-Spitzhacke
	AUTO_MINE  = 0,   -- 499 Robux: AFK-Mining
	PET        = 0,   -- 199 Robux: Pet mit +15% Gluecksbonus
}

-- Developer Product IDs (einmalige Kaeufe, wiederholbar)
GameConfig.DEV_PRODUCTS = {
	GEM_SMALL   = 0,  -- 50 Robux → 100 Gems
	GEM_LARGE   = 0,  -- 200 Robux → 500 Gems
	COIN_BOOST  = 0,  -- 75 Robux → 3x Coin-Boost fuer 1 Stunde
}

-- Gem-Mengen pro Kauf
GameConfig.GEM_AMOUNTS = {
	GEM_SMALL  = 100,
	GEM_LARGE  = 500,
}

-- Multiplikatoren
GameConfig.PREMIUM_MULTIPLIER  = 1.5   -- Roblox Premium Mitglieder
GameConfig.VIP_MULTIPLIER      = 2.0   -- VIP Game Pass
GameConfig.PET_LUCK_BONUS      = 0.15  -- +15% Chance auf seltene Erze
GameConfig.COIN_BOOST_MULT     = 3.0   -- Dev Product Coin Boost
GameConfig.COIN_BOOST_DURATION = 3600  -- Sekunden (1 Stunde)

-- Spielwelt
GameConfig.MAX_ISLANDS         = 10
GameConfig.ORE_NODES_PER_ISLAND = 20   -- Spawn-Punkte pro Insel
GameConfig.MAX_ACTIVE_NODES    = 12    -- Maximal aktive Erz-Nodes pro Insel (60%)

-- Speichern
GameConfig.DATA_SAVE_INTERVAL  = 60    -- Auto-Save alle 60 Sekunden
GameConfig.DATA_VERSION        = 1     -- Schema-Version fuer Migrationen

-- Upgrade-Kosten (Coins), Index = Zielstufe
GameConfig.UPGRADE_COSTS = {
	pickaxe  = {200, 1000, 8000, 60000},    -- Stufen 2–5
	backpack = {300, 1500, 12000, 80000},
	autoMiner= {5000, 25000, 100000},       -- Max Stufe 3
	sellBoost= {400, 2000, 15000, 100000},
}

-- Upgrade-Effekte
GameConfig.PICKAXE_TIME_REDUCTION = 0.25  -- Sekunden Abzug pro Stufe
GameConfig.BACKPACK_CAPACITY      = {50, 100, 200, 400, 800}  -- Slots je Stufe
GameConfig.SELL_BOOST_MULT        = {1.0, 1.1, 1.25, 1.5, 2.0} -- Multiplikator je Stufe

-- Leaderboard
GameConfig.LEADERBOARD_UPDATE_INTERVAL = 60  -- Sekunden
GameConfig.LEADERBOARD_TOP_COUNT       = 10

-- Gem-zu-Coins Kurs (im Shop)
GameConfig.GEM_TO_COIN_RATE = 100  -- 1 Gem = 100 Coins

return GameConfig
