-- Ethereal Summit – Pet-System (Server)
local GameConfig = require(game.ReplicatedStorage.Modules.GameConfig)

local PetSystem  = {}

-- Gewichteten Zufallstyp aus einem Pool auswaehlen
local function pickWeighted(weightTable)
	local total = 0
	for _, w in pairs(weightTable) do total = total + w end

	local roll = math.random() * total
	local cumul = 0
	for key, w in pairs(weightTable) do
		cumul = cumul + w
		if roll <= cumul then return key end
	end
	-- Fallback
	return next(weightTable)
end

-- Zufaelliges Pet aus einem Pool auswaehlen
local function pickPetType(eggType)
	local pool  = GameConfig.EGG_PET_POOL[eggType] or GameConfig.EGG_PET_POOL.common
	local idx   = math.random(1, #pool)
	return pool[idx]
end

-- Ein Pet-Ei oeffnen
-- Gibt (success, petData, message) zurueck
function PetSystem.openEgg(session, eggType)
	local data = session.data
	if not data then return false, nil, "Keine Daten" end

	local eggDef = GameConfig.PET_EGGS[eggType]
	if not eggDef then return false, nil, "Unbekannter Ei-Typ" end

	-- Preis abziehen
	if eggDef.costType == "coins" then
		if data.coins < eggDef.cost then
			return false, nil, "Nicht genug Coins (benoetigt: " .. eggDef.cost .. ")"
		end
		data.coins = data.coins - eggDef.cost
	elseif eggDef.costType == "gems" then
		if (data.gems or 0) < eggDef.cost then
			return false, nil, "Nicht genug Gems (benoetigt: " .. eggDef.cost .. ")"
		end
		data.gems = data.gems - eggDef.cost
	end

	-- Raritaet und Typ auswaehlen
	local weights   = GameConfig.EGG_RARITY_WEIGHTS[eggType]
	local rarity    = pickWeighted(weights)
	local petType   = pickPetType(eggType)

	-- Pet erstellen
	data.pets = data.pets or { owned={}, equipped={nil,nil,nil}, nextId=1 }
	local petId = "pet_" .. (data.pets.nextId or 1)
	data.pets.nextId = (data.pets.nextId or 1) + 1

	data.pets.owned[petId] = {
		petType = petType,
		rarity  = rarity,
		level   = 1,
	}

	local petData = {
		id      = petId,
		petType = petType,
		rarity  = rarity,
		level   = 1,
		name    = GameConfig.PET_TYPES[petType] and GameConfig.PET_TYPES[petType].name or petType,
	}

	return true, petData, "Pet erhalten!"
end

-- Pet equippen (Slot 1-3)
function PetSystem.equipPet(session, petId, slot)
	local data = session.data
	if not data or not data.pets then return false, "Keine Pets" end

	if slot < 1 or slot > GameConfig.PET_SLOTS then
		return false, "Ungueltiger Slot"
	end

	-- Pruefen ob Spieler das Pet besitzt
	if petId ~= nil and not data.pets.owned[petId] then
		return false, "Pet nicht vorhanden"
	end

	data.pets.equipped = data.pets.equipped or {nil,nil,nil}
	data.pets.equipped[slot] = petId

	return true, "Pet in Slot " .. slot .. " ausgeruestet"
end

-- Pet-Level erhoehen
function PetSystem.levelUpPet(session, petId)
	local data = session.data
	if not data or not data.pets then return false, 0, "Keine Pets" end

	local pet = data.pets.owned[petId]
	if not pet then return false, 0, "Pet nicht gefunden" end

	if pet.level >= GameConfig.PET_MAX_LEVEL then
		return false, pet.level, "Pet bereits auf Max-Level"
	end

	local cost = GameConfig.PET_LEVEL_COSTS[pet.level]
	if not cost then return false, pet.level, "Kein Level-Up moeglich" end

	if (data.gems or 0) < cost then
		return false, pet.level, "Nicht genug Gems (benoetigt: " .. cost .. ")"
	end

	data.gems  = data.gems - cost
	pet.level  = pet.level + 1

	return true, pet.level, "Pet auf Level " .. pet.level .. " gebracht"
end

-- Alle aktiven Pet-Multiplikatoren berechnen
function PetSystem.getMultipliers(session)
	local data   = session and session.data
	local result = { coinMult=1.0, luckBonus=0.0, mineTimeReduction=0.0 }

	if not data or not data.pets then return result end

	local equipped = data.pets.equipped or {}
	local owned    = data.pets.owned    or {}

	for _, petId in ipairs(equipped) do
		if petId then
			local pet     = owned[petId]
			if pet then
				local typeDef = GameConfig.PET_TYPES[pet.petType]
				local rarMult = GameConfig.RARITY_MULT[pet.rarity] or 1.0
				if typeDef then
					local bonus = typeDef.baseBonus * rarMult * pet.level
					if typeDef.effect == "coins" then
						result.coinMult = result.coinMult + bonus
					elseif typeDef.effect == "luck" then
						result.luckBonus = result.luckBonus + bonus
					elseif typeDef.effect == "speed" then
						result.mineTimeReduction = result.mineTimeReduction + bonus
					end
				end
			end
		end
	end

	return result
end

-- Pet-Daten fuer UI aufbereiten
function PetSystem.getUIData(data)
	if not data or not data.pets then
		return { owned={}, equipped={nil,nil,nil} }
	end

	local petList = {}
	for petId, pet in pairs(data.pets.owned or {}) do
		local typeDef = GameConfig.PET_TYPES[pet.petType]
		table.insert(petList, {
			id      = petId,
			petType = pet.petType,
			name    = typeDef and typeDef.name or pet.petType,
			rarity  = pet.rarity,
			level   = pet.level,
			effect  = typeDef and typeDef.effect or "coins",
		})
	end

	return {
		owned    = petList,
		equipped = data.pets.equipped or {nil,nil,nil},
		nextLevelCosts = GameConfig.PET_LEVEL_COSTS,
	}
end

return PetSystem
