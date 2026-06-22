-- Ethereal Summit – Achievement-System (Server)
local GameConfig        = require(game.ReplicatedStorage.Modules.GameConfig)

local AchievementSystem = {}

-- Achievement-Definitionen als Lookup
local AchievById = {}
for _, ach in ipairs(GameConfig.ACHIEVEMENTS) do
	AchievById[ach.id] = ach
end

-- Achievement erteilen und Belohnung geben
local function grant(player, session, achievId, eventsFolder)
	local data = session.data
	if not data then return end
	if data.achievements[achievId] then return end  -- bereits erhalten

	data.achievements[achievId] = true
	local ach = AchievById[achievId]
	if not ach then return end

	-- Belohnung auszahlen
	if ach.reward.coins then data.coins = data.coins + ach.reward.coins end
	if ach.reward.gems  then data.gems  = (data.gems or 0) + ach.reward.gems end

	-- Client benachrichtigen
	if eventsFolder and player then
		local evt = eventsFolder:FindFirstChild("AchievementUnlocked")
		if evt then
			evt:FireClient(player, achievId, ach.display, ach.reward)
		end
	end
end

-- Alle relevanten Achievements pruefen
function AchievementSystem.checkAll(player, session, eventsFolder)
	local data = session.data
	if not data or not data.stats then return end

	local ores    = data.stats.totalOresMined    or 0
	local earned  = data.stats.totalCoinsEarned  or 0
	local island  = data.highestIsland           or 1
	local rebirths= data.rebirths                or 0
	local streak  = (data.daily and data.daily.streak) or 0

	-- Erz-Achievements
	if ores >= 1       then grant(player, session, "first_ore",    eventsFolder) end
	if ores >= 100     then grant(player, session, "ore_100",      eventsFolder) end
	if ores >= 1000    then grant(player, session, "ore_1000",     eventsFolder) end
	if ores >= 10000   then grant(player, session, "ore_10000",    eventsFolder) end
	if ores >= 100000  then grant(player, session, "ore_100000",   eventsFolder) end

	-- Coin-Achievements
	if earned >= 1000       then grant(player, session, "coins_1000", eventsFolder) end
	if earned >= 1000000    then grant(player, session, "coins_1m",   eventsFolder) end
	if earned >= 1000000000 then grant(player, session, "coins_1b",   eventsFolder) end

	-- Insel-Achievements
	if island >= 5  then grant(player, session, "island_5",  eventsFolder) end
	if island >= 10 then grant(player, session, "island_10", eventsFolder) end

	-- Rebirth-Achievements
	if rebirths >= 1 then grant(player, session, "first_rebirth", eventsFolder) end
	if rebirths >= 5 then grant(player, session, "rebirth_5",     eventsFolder) end

	-- Streak-Achievements
	if streak >= 7  then grant(player, session, "streak_7",  eventsFolder) end
	if streak >= 30 then grant(player, session, "streak_30", eventsFolder) end

	-- Pet-Achievements werden bei PetSystem.openEgg gecheckt

	-- Alle Upgrades auf Max pruefen
	local upgrades  = data.upgrades or {}
	local allMaxed  = 0
	if (upgrades.pickaxe  or 0) >= 5 then allMaxed = allMaxed + 1 end
	if (upgrades.backpack or 0) >= 5 then allMaxed = allMaxed + 1 end
	if (upgrades.sellBoost or 0) >= 5 then allMaxed = allMaxed + 1 end
	if (upgrades.autoMiner or 0) >= 3 then allMaxed = allMaxed + 1 end
	if allMaxed >= 4 then grant(player, session, "all_upgrades", eventsFolder) end
end

-- Spezifisches Achievement pruefen und erteilen (fuer Pet-Oeffnung etc.)
function AchievementSystem.grantIfApplicable(player, session, achievId, eventsFolder)
	grant(player, session, achievId, eventsFolder)
end

-- Combo-Achievement
function AchievementSystem.checkCombo(player, session, comboCount, eventsFolder)
	if comboCount >= 30 then
		grant(player, session, "combo_30", eventsFolder)
	end
end

return AchievementSystem
