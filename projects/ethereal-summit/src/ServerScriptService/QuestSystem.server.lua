-- Ethereal Summit – Quest-System (Server)
local GameConfig  = require(game.ReplicatedStorage.Modules.GameConfig)

local QuestSystem = {}

-- Heutiges Datum als Zahl fuer Reset-Vergleich
local function todayTimestamp()
	local t = os.date("*t")
	return os.time({year=t.year, month=t.month, day=t.day, hour=0, min=0, sec=0})
end

-- Wochenbeginn (Montag)
local function weekStartTimestamp()
	local t     = os.date("*t")
	local today = os.time({year=t.year, month=t.month, day=t.day, hour=0, min=0, sec=0})
	local wday  = t.wday == 1 and 7 or (t.wday - 1)  -- Montag=1
	return today - (wday - 1) * 86400
end

-- Zufaellige Daily Quests generieren (3 aus Pool, oder 4 mit Battle Pass)
local function generateDailyQuests(hasBattlePass)
	local pool    = {}
	for _, q in ipairs(GameConfig.DAILY_QUEST_POOL) do
		table.insert(pool, q)
	end

	-- Mischen
	for i = #pool, 2, -1 do
		local j = math.random(1, i)
		pool[i], pool[j] = pool[j], pool[i]
	end

	local count   = hasBattlePass and 4 or 3
	local selected = {}
	for i = 1, math.min(count, #pool) do
		table.insert(selected, {
			id       = pool[i].id,
			display  = pool[i].display,
			type     = pool[i].type,
			goal     = pool[i].goal,
			reward   = pool[i].reward,
			progress = 0,
			done     = false,
			claimed  = false,
		})
	end

	-- Battle Pass Extra Quest
	if hasBattlePass then
		local bpq = GameConfig.BATTLE_PASS_EXTRA_QUEST
		table.insert(selected, {
			id       = bpq.id,
			display  = bpq.display,
			type     = bpq.type,
			goal     = bpq.goal,
			reward   = bpq.reward,
			progress = 0,
			done     = false,
			claimed  = false,
		})
	end

	return selected
end

-- Weekly Quest initialisieren
local function generateWeeklyQuest()
	local wq = GameConfig.WEEKLY_QUEST
	return {
		id       = wq.id,
		display  = wq.display,
		type     = wq.type,
		goal     = wq.goal,
		reward   = wq.reward,
		progress = 0,
		done     = false,
		claimed  = false,
	}
end

-- Quests refreshen falls Tag/Woche abgelaufen
function QuestSystem.refreshIfNeeded(session)
	local data = session.data
	if not data.quests then
		data.quests = { daily={}, weekly={progress=0,done=false}, lastDailyReset=0, lastWeeklyReset=0 }
	end

	local today     = todayTimestamp()
	local weekStart = weekStartTimestamp()
	local hasBP     = session.passes and session.passes.battlePass

	-- Daily Reset
	if data.quests.lastDailyReset < today then
		data.quests.daily          = generateDailyQuests(hasBP)
		data.quests.lastDailyReset = today
	end

	-- Weekly Reset
	if data.quests.lastWeeklyReset < weekStart then
		data.quests.weekly          = generateWeeklyQuest()
		data.quests.lastWeeklyReset = weekStart
	end
end

-- Quest-Fortschritt aktualisieren
-- questType: "mine", "earn", "sell", "egg", "upgrade", "island", "mine_rare"
function QuestSystem.updateProgress(session, questType, amount, eventsFolder, player)
	local data = session.data
	if not data or not data.quests then return end

	local updated = {}

	-- Daily Quests
	for _, quest in ipairs(data.quests.daily or {}) do
		if quest.type == questType and not quest.done then
			quest.progress = quest.progress + (amount or 1)
			if quest.progress >= quest.goal then
				quest.progress = quest.goal
				quest.done     = true
			end
			table.insert(updated, { id=quest.id, progress=quest.progress, done=quest.done })
		end
	end

	-- Weekly Quest
	local wq = data.quests.weekly
	if wq and wq.type == questType and not wq.done then
		wq.progress = wq.progress + (amount or 1)
		if wq.progress >= wq.goal then
			wq.progress = wq.goal
			wq.done     = true
		end
		table.insert(updated, { id=wq.id, progress=wq.progress, done=wq.done })
	end

	-- Client informieren
	if eventsFolder and player and #updated > 0 then
		local evt = eventsFolder:FindFirstChild("QuestProgressUpdate")
		if evt then
			for _, upd in ipairs(updated) do
				evt:FireClient(player, upd.id, upd.progress, upd.done)
			end
		end
	end
end

-- Quest-Belohnung auszahlen
function QuestSystem.claimReward(session, questId)
	local data = session.data
	if not data or not data.quests then return false, "Keine Quests" end

	-- In Daily Quests suchen
	for _, quest in ipairs(data.quests.daily or {}) do
		if quest.id == questId then
			if not quest.done    then return false, "Quest nicht abgeschlossen" end
			if quest.claimed     then return false, "Belohnung bereits eingeloest" end

			quest.claimed = true
			local reward  = quest.reward
			if reward.coins then data.coins = data.coins + reward.coins end
			if reward.gems  then data.gems  = (data.gems or 0) + reward.gems end
			return true, reward
		end
	end

	-- Weekly Quest pruefen
	local wq = data.quests.weekly
	if wq and wq.id == questId then
		if not wq.done   then return false, "Weekly Quest nicht abgeschlossen" end
		if wq.claimed    then return false, "Belohnung bereits eingeloest" end
		wq.claimed = true
		local reward = wq.reward
		if reward.coins then data.coins = data.coins + reward.coins end
		if reward.gems  then data.gems  = (data.gems or 0) + reward.gems end
		return true, reward
	end

	return false, "Quest nicht gefunden"
end

-- UI-Daten zusammenstellen
function QuestSystem.getUIData(data)
	return {
		daily  = data.quests and data.quests.daily  or {},
		weekly = data.quests and data.quests.weekly or {},
	}
end

return QuestSystem
