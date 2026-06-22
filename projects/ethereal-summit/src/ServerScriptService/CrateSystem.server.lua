-- Ethereal Summit – Mystery Crates
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig        = require(ReplicatedStorage.Modules.GameConfig)

local CrateSystem = {}

local function weightedRandom(pool)
	local total = 0
	for _, item in ipairs(pool) do total = total + item.weight end
	local roll  = math.random() * total
	local cum   = 0
	for _, item in ipairs(pool) do
		cum = cum + item.weight
		if roll <= cum then return item end
	end
	return pool[#pool]
end

-- Gibt (success, result, message) zurueck
-- result = { type, amount, display, rarity, eggType, petInfo }
function CrateSystem.openCrate(session, crateType, announceSys, petSystem, player)
	local crate = GameConfig.CRATES[crateType]
	if not crate then return false, nil, "Unbekannte Kiste" end

	local data = session.data

	-- Kosten abziehen
	if crate.costType == "coins" then
		if data.coins < crate.cost then return false, nil, "Nicht genug Coins" end
		data.coins = data.coins - crate.cost
	elseif crate.costType == "gems" then
		if data.gems < crate.cost then return false, nil, "Nicht genug Gems" end
		data.gems = data.gems - crate.cost
	end

	local reward = weightedRandom(crate.pool)
	local result = { type=reward.type, rarity="common" }

	if reward.type == "coins" then
		data.coins     = data.coins + reward.amount
		data.stats.totalCoinsEarned = (data.stats.totalCoinsEarned or 0) + reward.amount
		result.amount  = reward.amount
		result.display = "+" .. reward.amount .. " Coins"

	elseif reward.type == "gems" then
		data.gems      = data.gems + reward.amount
		result.amount  = reward.amount
		result.display = "+" .. reward.amount .. " Gems"
		result.rarity  = reward.amount >= 75 and "rare" or "common"

	elseif reward.type == "egg" then
		result.eggType = reward.eggType
		result.display = "Pet-Ei: " .. (reward.eggType or "common")

		if petSystem and player then
			local ok, petData = petSystem.openEgg(session, reward.eggType)
			if ok and petData then
				result.petInfo = petData
				result.rarity  = petData.rarity
				result.display = petData.rarity:upper() .. " Pet: " .. petData.name
				if petData.rarity == "legendary" then
					if announceSys then
						announceSys.announce(
							"🥚 " .. player.Name .. " hat ein LEGENDAERES Pet aus einer Kiste gezogen!",
							"purple"
						)
					end
				end
			end
		else
			-- Kein PetSystem verfuegbar: Fallback auf Gem-Equivalent
			data.gems      = data.gems + 50
			result.display = "+50 Gems (Ei-Ersatz)"
		end
	end

	-- Ankuendigung fuer seltene Funde
	if result.rarity == "rare" or result.rarity == "epic" or result.rarity == "legendary" then
		if announceSys and player then
			announceSys.announce(
				"✨ " .. player.Name .. " hat " .. result.display .. " aus der " .. crate.name .. " erhalten!",
				"gold"
			)
		end
	end

	return true, result, "Kiste geoeffnet!"
end

return CrateSystem
