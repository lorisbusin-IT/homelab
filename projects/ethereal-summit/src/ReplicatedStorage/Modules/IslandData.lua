-- Ethereal Summit – Insel-Definitionen
-- unlockCost: Coins benoetigt zum Freischalten
-- height: Y-Position in Studs (fuer Spawn und Zugangs-Check)
-- resources: Welche Erze auf dieser Insel spawnen koennen

local IslandData = {
	[1]  = {
		name        = "Ankunftsinsel",
		unlockCost  = 0,
		height      = 50,
		resources   = {"Stein", "Kohle"},
		description = "Dein Startpunkt. Einfache Erze, aber ein guter Anfang.",
	},
	[2]  = {
		name        = "Kristallklippe",
		unlockCost  = 500,
		height      = 120,
		resources   = {"Kohle", "Kupfer", "Mondstein"},
		description = "Erste Kristalle schimmern zwischen den Felsen.",
	},
	[3]  = {
		name        = "Nebelgipfel",
		unlockCost  = 2500,
		height      = 200,
		resources   = {"Kupfer", "Silber", "Mondstein"},
		description = "Der Nebel birgt wertvolle Silberadern.",
	},
	[4]  = {
		name        = "Aetherfels",
		unlockCost  = 10000,
		height      = 310,
		resources   = {"Silber", "Aetherkristall"},
		description = "Aetherische Energie durchzieht das Gestein.",
	},
	[5]  = {
		name        = "Wolkenthron",
		unlockCost  = 40000,
		height      = 450,
		resources   = {"Aetherkristall", "Sternerz"},
		description = "Hoch ueber den Wolken – Sternerz glitzert ueberall.",
	},
	[6]  = {
		name        = "Sturmpeak",
		unlockCost  = 150000,
		height      = 620,
		resources   = {"Sternerz", "Drachenstein"},
		description = "Blitze erhellen das Drachenstein-Vorkommen.",
	},
	[7]  = {
		name        = "Himmelsveste",
		unlockCost  = 500000,
		height      = 830,
		resources   = {"Drachenstein", "Monddiamant"},
		description = "Eine uralte Festung aus Monddiamant-Bloecken.",
	},
	[8]  = {
		name        = "Ewigkeitsgipfel",
		unlockCost  = 2000000,
		height      = 1100,
		resources   = {"Monddiamant", "Sternstaub"},
		description = "Sternstaub faellt hier wie Schnee.",
	},
	[9]  = {
		name        = "Gottesthron",
		unlockCost  = 8000000,
		height      = 1400,
		resources   = {"Sternstaub", "Aetherherz"},
		description = "Das pulsierende Herz des Aethers schlaegt hier.",
	},
	[10] = {
		name        = "Etherealer Gipfel",
		unlockCost  = 30000000,
		height      = 1800,
		resources   = {"Aetherherz", "Urkristall"},
		description = "Der hoechste Punkt – nur die Besten erreichen ihn.",
	},
}

-- Respawn-Zeit: mineTime * 3 Sekunden pro Erz-Node
IslandData.RESPAWN_MULTIPLIER = 3

return IslandData
