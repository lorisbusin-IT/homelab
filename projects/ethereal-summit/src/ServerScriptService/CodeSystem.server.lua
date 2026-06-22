-- Ethereal Summit – Promo-Code-System (Server)
local GameConfig  = require(game.ReplicatedStorage.Modules.GameConfig)

local CodeSystem  = {}

-- Rate-Limit: max 3 Code-Einloesungen pro Stunde
local RateLimits  = {}  -- { [userId] = { count, resetTime } }

local function checkRateLimit(userId)
	local now = os.time()
	local rl  = RateLimits[userId]
	if not rl or now > rl.resetTime then
		RateLimits[userId] = { count=1, resetTime=now + 3600 }
		return true
	end
	if rl.count >= 3 then return false end
	rl.count = rl.count + 1
	return true
end

-- Code einloesen
-- Gibt (success, message, reward) zurueck
function CodeSystem.redeemCode(session, rawCode)
	local data = session.data
	if not data then return false, "Keine Spielerdaten", nil end

	if not rawCode or type(rawCode) ~= "string" then
		return false, "Ungueltige Eingabe", nil
	end

	-- Normalisieren: Grossbuchstaben, keine Leerzeichen
	local code = rawCode:upper():gsub("%s", "")

	if #code < 3 or #code > 30 then
		return false, "Code zu kurz oder zu lang", nil
	end

	-- Rate-Limit pruefen
	if not checkRateLimit(session.userId or 0) then
		return false, "Zu viele Versuche. Warte eine Stunde.", nil
	end

	-- Bereits eingeloest?
	data.usedCodes = data.usedCodes or {}
	if data.usedCodes[code] then
		return false, "Code bereits verwendet", nil
	end

	-- Gueltigkeit pruefen
	local reward = GameConfig.PROMO_CODES[code]
	if not reward then
		return false, "Ungültiger Code", nil
	end

	-- Belohnung geben
	data.usedCodes[code] = true

	if reward.type == "gems" then
		data.gems = (data.gems or 0) + reward.amount
	elseif reward.type == "coins" then
		data.coins = data.coins + reward.amount
	elseif reward.type == "boost" then
		data.boosts = data.boosts or {}
		data.boosts.coinBoostExpiry = os.time() + reward.amount
		data.boosts.coinBoostMult   = GameConfig.COIN_BOOST_MULT
	end

	return true, "Code eingeloest: " .. reward.description, reward
end

return CodeSystem
