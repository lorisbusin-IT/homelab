-- Ethereal Summit – Zentrale Konfiguration v2
-- WICHTIG: Pass-IDs und Produkt-IDs nach der Veroeffentlichung hier eintragen

local GameConfig = {}

-- ========== Game Pass IDs ==========
GameConfig.GAME_PASSES = {
	VIP         = 0,   -- 299 Robux: 2x Ressourcen, VIP-Bereich, Gold-Spitzhacke
	AUTO_MINE   = 0,   -- 499 Robux: AFK-Mining
	PET         = 0,   -- 199 Robux: Pet mit +15% Gluecksbonus
	BATTLE_PASS = 0,   -- 349 Robux/Monat: Exklusive Quests, 3x Daily Rewards, Cosmetics
	LUCKY_EGG   = 0,   -- 249 Robux: Taeglich 1 kostenloses Ei
}

-- ========== Developer Product IDs ==========
GameConfig.DEV_PRODUCTS = {
	GEM_SMALL    = 0,  -- 50 Robux → 100 Gems
	GEM_LARGE    = 0,  -- 200 Robux → 500 Gems
	GEM_XL       = 0,  -- 400 Robux → 1200 Gems (+20% Bonus)
	COIN_BOOST   = 0,  -- 75 Robux → 3x Coins 1h
	COIN_BOOST5  = 0,  -- 150 Robux → 5x Coins 3h
}

-- Gem-Mengen pro Kauf
GameConfig.GEM_AMOUNTS = {
	GEM_SMALL   = 100,
	GEM_LARGE   = 500,
	GEM_XL      = 1200,
}

-- ========== Multiplikatoren ==========
GameConfig.PREMIUM_MULTIPLIER  = 1.5
GameConfig.VIP_MULTIPLIER      = 2.0
GameConfig.PET_LUCK_BONUS      = 0.15
GameConfig.COIN_BOOST_MULT     = 3.0
GameConfig.COIN_BOOST_DURATION = 3600
GameConfig.COIN_BOOST5_MULT    = 5.0
GameConfig.COIN_BOOST5_DURATION= 10800  -- 3 Stunden

-- ========== Spielwelt ==========
GameConfig.MAX_ISLANDS         = 10
GameConfig.ORE_NODES_PER_ISLAND= 20
GameConfig.MAX_ACTIVE_NODES    = 12

-- ========== Speichern ==========
GameConfig.DATA_SAVE_INTERVAL  = 60
GameConfig.DATA_VERSION        = 2

-- ========== Upgrades ==========
GameConfig.UPGRADE_COSTS = {
	pickaxe   = {200, 1000, 8000, 60000},
	backpack  = {300, 1500, 12000, 80000},
	autoMiner = {5000, 25000, 100000},
	sellBoost = {400, 2000, 15000, 100000},
}
GameConfig.PICKAXE_TIME_REDUCTION = 0.25
GameConfig.BACKPACK_CAPACITY      = {50, 100, 200, 400, 800}
GameConfig.SELL_BOOST_MULT        = {1.0, 1.1, 1.25, 1.5, 2.0}

-- ========== Leaderboard ==========
GameConfig.LEADERBOARD_UPDATE_INTERVAL = 60
GameConfig.LEADERBOARD_TOP_COUNT       = 10

-- ========== Gems ==========
GameConfig.GEM_TO_COIN_RATE = 100

-- ========== Rebirth-System ==========
-- Kosten (Coins) fuer jeden Rebirth (Index = Rebirth-Nummer)
GameConfig.REBIRTH_COSTS = {
	1000000, 5000000, 20000000, 80000000, 300000000
}
-- Permanenter Coin-Multiplikator pro Rebirth (+25% pro Rebirth)
GameConfig.REBIRTH_MULT_PER_REBIRTH = 0.25
GameConfig.MAX_REBIRTHS = 5

-- ========== Daily Rewards ==========
-- 7-Tage-Zyklus (wiederholt sich danach)
GameConfig.DAILY_REWARDS = {
	{ type="coins", amount=500   },   -- Tag 1
	{ type="coins", amount=1000  },   -- Tag 2
	{ type="gems",  amount=50    },   -- Tag 3
	{ type="coins", amount=2000  },   -- Tag 4
	{ type="gems",  amount=100   },   -- Tag 5
	{ type="coins", amount=5000  },   -- Tag 6
	{ type="boost", amount=3600  },   -- Tag 7: Coin Boost 1h gratis
}
-- Battle Pass Spieler bekommen doppelte Belohnungen
GameConfig.BATTLE_PASS_DAILY_MULT = 2

-- ========== Mining Combo ==========
GameConfig.COMBO_TIMEOUT  = 3.0   -- Sekunden ohne Mining → Combo bricht ab
GameConfig.COMBO_LEVELS   = {
	{ threshold=1,  mult=1.0 },
	{ threshold=5,  mult=1.5 },
	{ threshold=15, mult=2.0 },
	{ threshold=30, mult=3.0 },
}

-- ========== Quest-System ==========
-- Pool taeglich zufaellig gezogener Quests (3 werden ausgewaehlt)
GameConfig.DAILY_QUEST_POOL = {
	{ id="mine_100",    display="Baue 100 Erze ab",        type="mine",    goal=100,    reward={coins=500}  },
	{ id="mine_500",    display="Baue 500 Erze ab",        type="mine",    goal=500,    reward={coins=2000} },
	{ id="earn_1000",   display="Verdiene 1.000 Coins",    type="earn",    goal=1000,   reward={gems=25}    },
	{ id="earn_10000",  display="Verdiene 10.000 Coins",   type="earn",    goal=10000,  reward={gems=75}    },
	{ id="sell_all",    display="Verkaufe dein Inventar",  type="sell",    goal=1,      reward={coins=300}  },
	{ id="open_egg",    display="Oeffne 1 Pet-Ei",         type="egg",     goal=1,      reward={coins=500}  },
	{ id="upgrade_any", display="Verbessere ein Upgrade",  type="upgrade", goal=1,      reward={gems=30}    },
	{ id="reach_island",display="Schalte eine Insel frei", type="island",  goal=1,      reward={gems=50}    },
	{ id="mine_50_rare",display="Baue 50 seltene Erze ab", type="mine_rare",goal=50,   reward={gems=100}   },
}
GameConfig.WEEKLY_QUEST = {
	id="weekly_ores", display="Baue 2.000 Erze ab diese Woche",
	type="mine", goal=2000, reward={gems=500}
}
-- Battle Pass Spieler: 1 extra Quest taeglich
GameConfig.BATTLE_PASS_EXTRA_QUEST = {
	id="bp_elite", display="[BP] Verdiene 100.000 Coins", type="earn", goal=100000, reward={gems=200}
}

-- ========== Promo-Codes ==========
-- Codes werden hier gepflegt (Gross-/Kleinschreibung egal)
GameConfig.PROMO_CODES = {
	["ETHEREAL100"]   = { type="gems",  amount=100,  description="Startercode" },
	["SUMMIT500"]     = { type="gems",  amount=500,  description="Special Code" },
	["WELCOME"]       = { type="coins", amount=5000, description="Willkommensbonus" },
	["YOUTUBER"]      = { type="boost", amount=3600, description="Creator Code" },
	["RELEASE2025"]   = { type="gems",  amount=250,  description="Launch Event" },
}

-- ========== Achievement-System ==========
GameConfig.ACHIEVEMENTS = {
	{ id="first_ore",    display="Erster Schritt",      desc="Baue dein erstes Erz ab",           type="mine",    goal=1,         reward={coins=50}   },
	{ id="ore_100",      display="Fleissig",            desc="Baue 100 Erze ab",                  type="mine",    goal=100,       reward={coins=500}  },
	{ id="ore_1000",     display="Bergmann",            desc="Baue 1.000 Erze ab",                type="mine",    goal=1000,      reward={coins=2000} },
	{ id="ore_10000",    display="Meisterbergmann",     desc="Baue 10.000 Erze ab",               type="mine",    goal=10000,     reward={gems=100}   },
	{ id="ore_100000",   display="Legendaerer Bergmann",desc="Baue 100.000 Erze ab",              type="mine",    goal=100000,    reward={gems=500}   },
	{ id="coins_1000",   display="Sparfuchs",           desc="Sammle 1.000 Coins",                type="earn",    goal=1000,      reward={coins=200}  },
	{ id="coins_1m",     display="Millionaer",          desc="Sammle 1.000.000 Coins",            type="earn",    goal=1000000,   reward={gems=200}   },
	{ id="coins_1b",     display="Milliardaer",         desc="Sammle 1.000.000.000 Coins",        type="earn",    goal=1000000000,reward={gems=1000}  },
	{ id="island_5",     display="Halbzeit",            desc="Erreiche Insel 5",                  type="island",  goal=5,         reward={gems=100}   },
	{ id="island_10",    display="Gipfelstuermer",      desc="Erreiche den Etherealen Gipfel",    type="island",  goal=10,        reward={gems=500}   },
	{ id="first_rebirth",display="Wiedergeboren",       desc="Erlebe deinen ersten Rebirth",      type="rebirth", goal=1,         reward={gems=1000}  },
	{ id="rebirth_5",    display="Unsterblich",         desc="Rebirth 5x",                        type="rebirth", goal=5,         reward={gems=5000}  },
	{ id="first_pet",    display="Tierfreund",          desc="Oeffne dein erstes Pet-Ei",         type="egg",     goal=1,         reward={coins=500}  },
	{ id="legendary_pet",display="Legende",             desc="Erhalte ein Legendaeres Pet",       type="leg_pet", goal=1,         reward={gems=300}   },
	{ id="streak_7",     display="Treuer Spieler",      desc="7-Tage Login-Streak",               type="streak",  goal=7,         reward={gems=100}   },
	{ id="streak_30",    display="Hingebungsvoll",      desc="30-Tage Login-Streak",              type="streak",  goal=30,        reward={gems=500}   },
	{ id="combo_30",     display="Combo-Meister",       desc="Erreiche Combo x30",                type="combo",   goal=30,        reward={coins=5000} },
	{ id="all_upgrades", display="Ausgeruestet",        desc="Alle Upgrades auf Max-Stufe",       type="upgrade", goal=4,         reward={gems=200}   },
}

-- ========== Pet-System ==========
-- Ei-Typen
GameConfig.PET_EGGS = {
	common    = { name="Normales Ei",       cost=100,   costType="coins", color="Medium stone grey" },
	rare      = { name="Seltenes Ei",       cost=500,   costType="gems",  color="Bright blue"       },
	legendary = { name="Legendaeres Ei",    cost=999,   costType="gems",  color="Gold"              },
}
-- Raritaeten mit Gewichten pro Ei-Typ
GameConfig.PET_RARITIES = {
	common    = { display="Gewoehnlich",    color="White"        },
	uncommon  = { display="Ungewoehnlich",  color="Bright green" },
	rare      = { display="Selten",         color="Bright blue"  },
	epic      = { display="Episch",         color="Bright violet"},
	legendary = { display="Legendaer",      color="Gold"         },
}
-- Spawn-Chancen je Ei-Typ (Summe = 100)
GameConfig.EGG_RARITY_WEIGHTS = {
	common    = { common=60, uncommon=25, rare=10,  epic=4,  legendary=1  },
	rare      = { common=30, uncommon=35, rare=22,  epic=10, legendary=3  },
	legendary = { common=5,  uncommon=15, rare=30,  epic=35, legendary=15 },
}
-- Pet-Definitionen (Typ → Effekt pro Rarity)
GameConfig.PET_TYPES = {
	dragon  = { name="Drache",      effect="coins",   baseBonus=0.05  },  -- +5% Coins pro Level
	phoenix = { name="Phoenix",     effect="luck",    baseBonus=0.03  },  -- +3% Luck pro Level
	wolf    = { name="Wolf",        effect="speed",   baseBonus=0.10  },  -- -10% MineTime pro Level
	fairy   = { name="Fee",         effect="coins",   baseBonus=0.04  },
	golem   = { name="Golem",       effect="coins",   baseBonus=0.08  },
	unicorn = { name="Einhorn",     effect="luck",    baseBonus=0.05  },
	demon   = { name="Daemon",      effect="coins",   baseBonus=0.12  },
	angel   = { name="Engel",       effect="luck",    baseBonus=0.07  },
}
-- Rarity-Multiplikator fuer den Bonus
GameConfig.RARITY_MULT = {
	common=1.0, uncommon=1.5, rare=2.5, epic=4.0, legendary=8.0
}
-- Pet-Leveling (Gems-Kosten pro Level-Aufstieg)
GameConfig.PET_LEVEL_COSTS = {10, 25, 60, 120, 250, 500, 1000, 2000, 5000}  -- Level 1→2 bis 9→10
GameConfig.PET_MAX_LEVEL  = 10
GameConfig.PET_SLOTS      = 3

-- Pet-Typen per Rarity (welche Typen aus welchem Ei kommen koennen)
GameConfig.EGG_PET_POOL = {
	common    = {"dragon","phoenix","wolf","fairy"},
	rare      = {"dragon","phoenix","wolf","golem","unicorn"},
	legendary = {"dragon","phoenix","golem","demon","angel","unicorn"},
}

-- ========== Lucky Ores ==========
GameConfig.LUCKY_ORE_CHANCE      = 0.05   -- 5% aller Ore-Spawns
GameConfig.LUCKY_ORE_MULTIPLIER  = 5      -- 5x Coins + Particles + Ankuendigung
GameConfig.LUCKY_ORE_HP_MULT     = 2      -- Doppelt so viel HP (haerter abzubauen)

-- ========== Timed Server Events ==========
GameConfig.EVENTS = {
	meteor = {
		interval    = 600,   -- alle 10 Minuten
		warning     = 30,    -- 30s Vorwarnung
		duration    = 90,    -- 90s aktiv
		oreCount    = 15,    -- Extra Lucky Erze beim Einschlag
		coinMult    = 3.0,   -- 3x Coins auf der Einschlags-Insel
		name        = "METEOR EINSCHLAG",
		icon        = "meteorite",
	},
	goldrush = {
		interval    = 900,   -- alle 15 Minuten
		warning     = 15,
		duration    = 180,   -- 3 Minuten
		coinMult    = 2.0,   -- 2x Coins server-weit
		name        = "GOLD RUSH",
		icon        = "goldrush",
	},
	luckyhour = {
		interval    = 1200,  -- alle 20 Minuten
		warning     = 15,
		duration    = 300,   -- 5 Minuten
		luckyChance = 0.30,  -- 30% Lucky Ores statt 5%
		name        = "LUCKY HOUR",
		icon        = "luckyhour",
	},
	boss = {
		interval      = 1800,  -- alle 30 Minuten
		warning       = 60,
		duration      = 120,
		bossHp        = 150,
		hitReward     = { gems = 5  },  -- Jeder Treffer
		bonusReward   = { gems = 200 }, -- Letzter Schlag
		name          = "BOSS ERZ",
		icon          = "boss",
	},
}

-- ========== Mystery Crates ==========
GameConfig.CRATES = {
	bronze = {
		name     = "Bronze-Kiste",
		cost     = 1000,
		costType = "coins",
		pool = {
			{ type="coins", amount=500,   weight=40 },
			{ type="coins", amount=2000,  weight=25 },
			{ type="coins", amount=5000,  weight=15 },
			{ type="gems",  amount=10,    weight=10 },
			{ type="gems",  amount=25,    weight=7  },
			{ type="egg",   eggType="common",    weight=3  },
		},
	},
	silver = {
		name     = "Silber-Kiste",
		cost     = 5000,
		costType = "coins",
		pool = {
			{ type="coins", amount=2000,  weight=30 },
			{ type="coins", amount=10000, weight=20 },
			{ type="gems",  amount=25,    weight=20 },
			{ type="gems",  amount=75,    weight=15 },
			{ type="egg",   eggType="common", weight=10 },
			{ type="egg",   eggType="rare",   weight=5  },
		},
	},
	gold = {
		name     = "Gold-Kiste",
		cost     = 500,
		costType = "gems",
		pool = {
			{ type="gems",  amount=100,   weight=30 },
			{ type="gems",  amount=250,   weight=25 },
			{ type="coins", amount=50000, weight=20 },
			{ type="egg",   eggType="rare",      weight=15 },
			{ type="egg",   eggType="legendary", weight=10 },
		},
	},
}

return GameConfig
