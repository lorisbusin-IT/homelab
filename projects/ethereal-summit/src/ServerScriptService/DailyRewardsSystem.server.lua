-- Ethereal Summit – Daily Rewards & Login-Streak (Server)
local GameConfig         = require(game.ReplicatedStorage.Modules.GameConfig)

local DailyRewardsSystem = {}

-- Heutigen Tag als String (YYYYDDD fuer Eindeutigkeit)
local function todayKey()
	return os.date("%Y%j")  -- z.B. "2025180"
end

-- Pruefen ob Spieler heute schon geclaimt hat
function DailyRewardsSystem.canClaim(data)
	if not data.daily then
		data.daily = { lastClaimDay="0", streak=0, longestStreak=0 }
	end
	return data.daily.lastClaimDay ~= todayKey()
end

-- Streak pruefen (gestern geclaimed = streak weiter, aelter = reset)
local function getYesterdayKey()
	local t = os.time() - 86400
	return os.date("%Y%j", t)
end

-- Tagelichen Reward claimt
-- Gibt (success, reward, newStreak) zurueck
function DailyRewardsSystem.claimReward(session)
	local data = session.data
	if not data then return false, nil, 0 end

	if not DailyRewardsSystem.canClaim(data) then
		return false, nil, data.daily.streak
	end

	-- Streak berechnen
	local yesterday = getYesterdayKey()
	if data.daily.lastClaimDay == yesterday then
		data.daily.streak = (data.daily.streak or 0) + 1
	else
		data.daily.streak = 1  -- Streak reset oder neu
	end

	if data.daily.streak > (data.daily.longestStreak or 0) then
		data.daily.longestStreak = data.daily.streak
	end

	-- Welcher Reward? (Zyklus von 7 Tagen)
	local dayInCycle = ((data.daily.streak - 1) % 7) + 1
	local reward     = GameConfig.DAILY_REWARDS[dayInCycle]

	-- Battle Pass: doppelte Belohnung
	local mult = 1
	if session.passes and session.passes.battlePass then
		mult = GameConfig.BATTLE_PASS_DAILY_MULT
	end

	-- Belohnung geben
	if reward.type == "coins" then
		data.coins = data.coins + (reward.amount * mult)
	elseif reward.type == "gems" then
		data.gems = (data.gems or 0) + (reward.amount * mult)
	elseif reward.type == "boost" then
		data.boosts = data.boosts or {}
		data.boosts.coinBoostExpiry = os.time() + reward.amount
		data.boosts.coinBoostMult   = GameConfig.COIN_BOOST_MULT
	end

	data.daily.lastClaimDay = todayKey()

	-- Achievement-Tracking fuer Streak
	if not data.stats then data.stats = {} end
	-- AchievementSystem prueft streak separat

	return true, { type=reward.type, amount=reward.amount * mult, day=dayInCycle }, data.daily.streak
end

-- Daten fuer UI (canClaim, streak, naechster Reward)
function DailyRewardsSystem.getUIData(data)
	if not data.daily then
		data.daily = { lastClaimDay="0", streak=0, longestStreak=0 }
	end

	local streak      = data.daily.streak or 0
	local dayInCycle  = (streak % 7) + 1  -- naechster Tag
	local nextReward  = GameConfig.DAILY_REWARDS[dayInCycle]

	return {
		canClaim    = DailyRewardsSystem.canClaim(data),
		streak      = streak,
		longestStreak = data.daily.longestStreak or 0,
		nextReward  = nextReward,
		dayInCycle  = dayInCycle,
		allRewards  = GameConfig.DAILY_REWARDS,
	}
end

return DailyRewardsSystem
