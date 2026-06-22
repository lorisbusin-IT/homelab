-- Ethereal Summit – Timed Server Events (Meteor, Gold Rush, Lucky Hour, Boss)
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local EventSystem = {}

-- ========== Oeffentlicher Zustand ==========
EventSystem.globalCoinMult  = 1.0                          -- Gold Rush Multiplikator
EventSystem.luckyOreChance  = GameConfig.LUCKY_ORE_CHANCE  -- Lucky Hour erhoeht das
EventSystem.activeEvent     = nil   -- { type, endTime, islandIndex }
EventSystem.bossOre         = nil   -- { oreId, hp, maxHp, participants={} }

-- ========== Interne Referenzen ==========
local _ef     = nil  -- RemoteEvents Folder
local _ann    = nil  -- AnnouncementSystem
local _res    = nil  -- ResourceSystem
local _sess   = nil  -- Sessions-Tabelle

function EventSystem.setup(eventsFolder, announceSys, resourceSys, sessions)
	_ef   = eventsFolder
	_ann  = announceSys
	_res  = resourceSys
	_sess = sessions

	-- Erste Events gestaffelt einplanen (nicht sofort beim Start)
	local now = os.clock()
	_timers = {
		meteor    = now + 120,   -- 2 min
		goldrush  = now + 300,   -- 5 min
		luckyhour = now + 480,   -- 8 min
		boss      = now + 600,   -- 10 min
	}
end

local _timers = {}

local function fireAll(evtName, ...)
	if not _ef then return end
	local evt = _ef:FindFirstChild(evtName)
	if evt then evt:FireAllClients(...) end
end

local function ann(msg, color)
	if _ann then _ann.announce(msg, color) end
end

-- ========== Meteor ==========
local function runMeteor()
	local cfg          = GameConfig.EVENTS.meteor
	local targetIsland = math.random(2, GameConfig.MAX_ISLANDS)

	ann("☄️  METEOR WARNUNG! Einschlag auf Insel " .. targetIsland .. " in " .. cfg.warning .. " Sekunden!", "red")
	fireAll("EventStarted", "meteor_warning", cfg.warning, targetIsland)

	task.delay(cfg.warning, function()
		ann("💥 METEOR EINSCHLAG auf Insel " .. targetIsland .. "! " .. cfg.coinMult .. "x Coins fuer " .. cfg.duration .. "s!", "red")
		fireAll("EventStarted", "meteor", cfg.duration, targetIsland)

		EventSystem.activeEvent = {
			type        = "meteor",
			endTime     = os.clock() + cfg.duration,
			islandIndex = targetIsland,
			coinMult    = cfg.coinMult,
		}

		-- Extra Lucky Ores auf der Insel spawnen
		if _res then
			for i = 1, cfg.oreCount do
				task.spawn(function()
					task.wait(math.random() * 8)
					local pos = Vector3.new(
						math.random(-25, 25), 18 + targetIsland * 14, math.random(-25, 25)
					)
					_res.spawnOreNode(targetIsland, pos, true)  -- forceLucky = true
				end)
			end
		end

		task.delay(cfg.duration, function()
			if EventSystem.activeEvent and EventSystem.activeEvent.type == "meteor" then
				EventSystem.activeEvent = nil
			end
			fireAll("EventEnded", "meteor")
			ann("Meteor-Event beendet!", "gold")
		end)
	end)
end

-- ========== Gold Rush ==========
local function runGoldRush()
	local cfg = GameConfig.EVENTS.goldrush

	ann("💰 GOLD RUSH! " .. cfg.coinMult .. "x Coins fuer alle – " .. (cfg.duration/60) .. " Minuten!", "gold")
	fireAll("EventStarted", "goldrush", cfg.duration, nil)
	EventSystem.globalCoinMult = cfg.coinMult
	EventSystem.activeEvent    = { type="goldrush", endTime=os.clock()+cfg.duration }

	task.delay(cfg.duration, function()
		EventSystem.globalCoinMult = 1.0
		if EventSystem.activeEvent and EventSystem.activeEvent.type == "goldrush" then
			EventSystem.activeEvent = nil
		end
		fireAll("EventEnded", "goldrush")
		ann("Gold Rush ist vorbei!", "gold")
	end)
end

-- ========== Lucky Hour ==========
local function runLuckyHour()
	local cfg = GameConfig.EVENTS.luckyhour
	local pct = math.floor(cfg.luckyChance * 100)

	ann("🍀 LUCKY HOUR! " .. pct .. "% Lucky Ores fuer " .. (cfg.duration/60) .. " Minuten!", "green")
	fireAll("EventStarted", "luckyhour", cfg.duration, nil)
	EventSystem.luckyOreChance = cfg.luckyChance
	EventSystem.activeEvent    = { type="luckyhour", endTime=os.clock()+cfg.duration }

	task.delay(cfg.duration, function()
		EventSystem.luckyOreChance = GameConfig.LUCKY_ORE_CHANCE
		if EventSystem.activeEvent and EventSystem.activeEvent.type == "luckyhour" then
			EventSystem.activeEvent = nil
		end
		fireAll("EventEnded", "luckyhour")
		ann("Lucky Hour ist vorbei!", "green")
	end)
end

-- ========== Boss Ore ==========
local function runBoss()
	local cfg = GameConfig.EVENTS.boss

	ann("💎 BOSS ERZ erscheint auf Insel 10 in " .. cfg.warning .. " Sekunden! Schnell hin!", "purple")
	fireAll("EventStarted", "boss_warning", cfg.warning, 10)

	task.delay(cfg.warning, function()
		if EventSystem.bossOre then return end  -- bereits aktiv

		ann("⚔️  BOSS ERZ ist da! Insel 10! Letzter Schlag gewinnt " .. cfg.bonusReward.gems .. " Gems!", "purple")

		local bossId = "BOSS_" .. math.floor(os.clock())
		local maxHp  = cfg.bossHp
		EventSystem.bossOre    = { oreId=bossId, hp=maxHp, maxHp=maxHp, participants={} }
		EventSystem.activeEvent = { type="boss", endTime=os.clock()+cfg.duration }

		-- SpawnOre fuer alle Clients feuern (isBoss=true als 7. Argument)
		if _ef then
			local se = _ef:FindFirstChild("SpawnOre")
			if se then se:FireAllClients(bossId, 10, Vector3.new(0, 200, 0), "crystal", maxHp, false, true) end
		end

		task.delay(cfg.duration, function()
			if EventSystem.bossOre then
				ann("Das Boss Erz ist entkommen! Beim naechsten Mal schafft ihr es!", "red")
				EventSystem.bossOre = nil
			end
			if EventSystem.activeEvent and EventSystem.activeEvent.type == "boss" then
				EventSystem.activeEvent = nil
			end
			fireAll("EventEnded", "boss")
		end)
	end)
end

-- ========== Boss Ore Treffer (vom GameManager aufgerufen) ==========
function EventSystem.hitBossOre(player, session)
	if not EventSystem.bossOre then return false, false end
	local boss = EventSystem.bossOre
	local cfg  = GameConfig.EVENTS.boss

	boss.hp = boss.hp - 1
	boss.participants[player.UserId] = true

	-- Kleinen Gem-Reward fuer jeden Treffer
	session.data.gems = session.data.gems + (cfg.hitReward.gems or 0)

	-- HP-Update an alle
	fireAll("BossOreHit", boss.oreId, boss.hp, boss.maxHp, player.Name)

	local lastHit = boss.hp <= 0
	if lastHit then
		ann("🏆 " .. player.Name .. " hat das BOSS ERZ zerstört und " .. cfg.bonusReward.gems .. " Gems gewonnen!", "purple")
		session.data.gems = session.data.gems + cfg.bonusReward.gems

		EventSystem.bossOre = nil
		if EventSystem.activeEvent and EventSystem.activeEvent.type == "boss" then
			EventSystem.activeEvent = nil
		end
		fireAll("EventEnded", "boss")
	end

	return true, lastHit
end

-- ========== Heartbeat: Event-Timer ==========
local lastTick = 0
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	if now - lastTick < 1 then return end
	lastTick = now

	if not _timers.meteor then return end

	if now >= _timers.meteor then
		_timers.meteor = now + GameConfig.EVENTS.meteor.interval
		task.spawn(runMeteor)
	end
	if now >= _timers.goldrush then
		_timers.goldrush = now + GameConfig.EVENTS.goldrush.interval
		task.spawn(runGoldRush)
	end
	if now >= _timers.luckyhour then
		_timers.luckyhour = now + GameConfig.EVENTS.luckyhour.interval
		task.spawn(runLuckyHour)
	end
	if now >= _timers.boss then
		_timers.boss = now + GameConfig.EVENTS.boss.interval
		task.spawn(runBoss)
	end
end)

return EventSystem
