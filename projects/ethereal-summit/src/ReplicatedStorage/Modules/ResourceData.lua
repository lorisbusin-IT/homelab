-- Ethereal Summit – Ressourcen-Definitionen
-- value: Coins pro Einheit beim Verkauf
-- spawnWeight: Hoehere Zahl = haeufiger (relative Wahrscheinlichkeit)
-- mineTime: Basis-Abbauzeit in Sekunden (reduziert durch Spitzhacken-Upgrade)
-- color: BrickColor-Name fuer die Part-Darstellung in Studio

local ResourceData = {
	Stein          = { value=1,       spawnWeight=500, color="Medium stone grey", mineTime=1.0 },
	Kohle          = { value=3,       spawnWeight=300, color="Black",             mineTime=1.5 },
	Kupfer         = { value=8,       spawnWeight=200, color="Bright orange",     mineTime=2.0 },
	Mondstein      = { value=20,      spawnWeight=120, color="Light blue",        mineTime=2.5 },
	Silber         = { value=55,      spawnWeight=80,  color="Silver",            mineTime=3.0 },
	Aetherkristall = { value=150,     spawnWeight=50,  color="Cyan",              mineTime=3.5 },
	Sternerz       = { value=400,     spawnWeight=30,  color="Bright yellow",     mineTime=4.0 },
	Drachenstein   = { value=1200,    spawnWeight=18,  color="Bright red",        mineTime=5.0 },
	Monddiamant    = { value=4000,    spawnWeight=10,  color="White",             mineTime=6.0 },
	Sternstaub     = { value=15000,   spawnWeight=5,   color="Hot pink",          mineTime=7.0 },
	Aetherherz     = { value=60000,   spawnWeight=2,   color="Bright violet",     mineTime=8.0 },
	Urkristall     = { value=250000,  spawnWeight=1,   color="Gold",              mineTime=10.0},
}

-- Geordnete Liste fuer UI-Anzeige (wertvollste zuerst)
ResourceData.ORDER = {
	"Urkristall", "Aetherherz", "Sternstaub", "Monddiamant",
	"Drachenstein", "Sternerz", "Aetherkristall", "Silber",
	"Mondstein", "Kupfer", "Kohle", "Stein",
}

-- Hilfsfunktion: Gewichteten Zufalls-Ressourcentyp aus einer Liste auswaehlen
function ResourceData.pickWeighted(availableResources, luckBonus)
	luckBonus = luckBonus or 0
	local totalWeight = 0
	local entries = {}

	for _, name in ipairs(availableResources) do
		local data = ResourceData[name]
		if data then
			-- Gluecksbonus reduziert das Gewicht haeufiger Ressourcen leicht
			local weight = data.spawnWeight * (1 - luckBonus * 0.5)
			weight = math.max(weight, 1)
			totalWeight = totalWeight + weight
			table.insert(entries, { name=name, weight=weight })
		end
	end

	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, entry in ipairs(entries) do
		cumulative = cumulative + entry.weight
		if roll <= cumulative then
			return entry.name
		end
	end

	return entries[#entries].name
end

return ResourceData
