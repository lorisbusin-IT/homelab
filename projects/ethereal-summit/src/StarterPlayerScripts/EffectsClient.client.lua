-- Ethereal Summit – Effekte, Sounds, Animationen, Ankuendigungen (Client) v3
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local RE           = require(ReplicatedStorage.Modules.RemoteEvents)
local ResourceData = require(ReplicatedStorage.Modules.ResourceData)
local GameConfig   = require(ReplicatedStorage.Modules.GameConfig)

local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")
local Camera       = workspace.CurrentCamera

-- ========== Sound-System ==========
local Sounds = {}

local function createSound(parent, id, volume, pitch)
	local s             = Instance.new("Sound")
	s.SoundId           = id ~= "" and ("rbxassetid://" .. id) or ""
	s.Volume            = volume or 0.5
	s.PlaybackSpeed     = pitch  or 1.0
	s.RollOffMaxDistance= 60
	s.Parent            = parent
	return s
end

local SoundFolder = Instance.new("Folder")
SoundFolder.Name  = "EtherealSounds"
SoundFolder.Parent= Camera

Sounds.mine    = createSound(SoundFolder, "131070686",  0.6, 1.0)
Sounds.break_  = createSound(SoundFolder, "131070685",  0.8, 0.9)
Sounds.coin    = createSound(SoundFolder, "4590662766", 0.5, 1.1)
Sounds.sell    = createSound(SoundFolder, "4590662766", 0.7, 0.8)
Sounds.levelUp = createSound(SoundFolder, "131070649",  0.8, 1.2)
Sounds.unlock  = createSound(SoundFolder, "131072580",  0.8, 1.0)
Sounds.achieve = createSound(SoundFolder, "131070649",  0.9, 1.0)
Sounds.egg     = createSound(SoundFolder, "131070580",  0.8, 1.2)
Sounds.lucky   = createSound(SoundFolder, "131070649",  1.0, 1.5)
Sounds.event   = createSound(SoundFolder, "131072580",  0.9, 0.8)

local function playSound(key)
	local s = Sounds[key]
	if s and s.SoundId ~= "" then s:Play() end
end

-- ========== Screen Shake ==========
local function screenShake(intensity, duration)
	local char     = LocalPlayer.Character
	if not char    then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local elapsed = 0
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		elapsed = elapsed + dt
		if elapsed >= duration then
			humanoid.CameraOffset = Vector3.new(0, 0, 0)
			conn:Disconnect()
			return
		end
		local fade = 1 - (elapsed / duration)
		humanoid.CameraOffset = Vector3.new(
			(math.random() * 2 - 1) * intensity * fade,
			(math.random() * 2 - 1) * intensity * fade,
			0
		)
	end)
end

-- ========== Partikel-Effekte ==========
local function spawnParticle(position, color, count, speedMult)
	count     = count or 3
	speedMult = speedMult or 1
	for _ = 1, count do
		local part          = Instance.new("Part")
		part.Size           = Vector3.new(0.3, 0.3, 0.3)
		part.Position       = position + Vector3.new(
			math.random(-2, 2), math.random(0, 2), math.random(-2, 2)
		)
		part.BrickColor     = BrickColor.new(color or "Bright yellow")
		part.Material       = Enum.Material.Neon
		part.Anchored       = false
		part.CanCollide     = false
		part.CastShadow     = false
		part.Parent         = workspace

		local bv            = Instance.new("BodyVelocity")
		bv.Velocity         = Vector3.new(
			math.random(-5,5) * speedMult,
			math.random(8,15)  * speedMult,
			math.random(-5,5) * speedMult
		)
		bv.MaxForce         = Vector3.new(1e4,1e4,1e4)
		bv.Parent           = part

		task.delay(0.5, function()
			if part.Parent then
				TweenService:Create(part, TweenInfo.new(0.3),
					{ Size=Vector3.new(0,0,0), Transparency=1 }
				):Play()
				task.delay(0.3, function()
					if part.Parent then part:Destroy() end
				end)
			end
		end)
	end
end

-- Coin-Float-Anzeige
local function showCoinFloat(worldPos, amount, isLucky)
	if not amount or amount <= 0 then return end
	local ScreenGui = PlayerGui:FindFirstChild("EtherealSummitHUD")
	if not ScreenGui then return end

	local lbl                  = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(0, isLucky and 200 or 130, 0, 36)
	lbl.BackgroundTransparency = 1
	lbl.Text                   = (isLucky and "⭐ LUCKY! +" or "+") .. math.floor(amount) .. " Coins"
	lbl.TextColor3             = isLucky and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 220, 50)
	lbl.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
	lbl.TextStrokeTransparency = 0.4
	lbl.Font                   = Enum.Font.GothamBold
	lbl.TextSize               = isLucky and 22 or 18
	lbl.ZIndex                 = 20
	lbl.Parent                 = ScreenGui

	local screenPos, onScreen = Camera:WorldToScreenPoint(worldPos)
	if not onScreen then lbl:Destroy(); return end

	local halfW = lbl.Size.X.Offset / 2
	lbl.Position = UDim2.new(0, screenPos.X - halfW, 0, screenPos.Y - 20)

	TweenService:Create(lbl, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position               = UDim2.new(0, screenPos.X - halfW, 0, screenPos.Y - 110),
		TextTransparency       = 1,
		TextStrokeTransparency = 1,
	}):Play()
	task.delay(1.8, function() if lbl.Parent then lbl:Destroy() end end)
end

-- ========== HP-Balken ueber Erzen ==========
local OreHPBars = {}

local function createHPBar(orePart, oreId, maxHp, isLucky, isBoss)
	local billboard         = Instance.new("BillboardGui")
	billboard.Name          = "HPBar_" .. oreId
	billboard.Size          = UDim2.new(0, isBoss and 100 or 60, 0, 10)
	billboard.StudsOffset   = Vector3.new(0, isBoss and 5 or 2.5, 0)
	billboard.AlwaysOnTop   = false
	billboard.Parent        = orePart

	local bg                = Instance.new("Frame")
	bg.Size                 = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3     = Color3.fromRGB(30, 30, 30)
	bg.BorderSizePixel      = 0
	bg.Parent               = billboard
	Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

	local bar               = Instance.new("Frame")
	bar.Name                = "Bar"
	bar.Size                = UDim2.new(1, 0, 1, 0)
	bar.BackgroundColor3    = isBoss and Color3.fromRGB(220, 50, 220)
		or (isLucky and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(80, 220, 80))
	bar.BorderSizePixel     = 0
	bar.Parent              = bg
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

	OreHPBars[oreId] = { billboard=billboard, bar=bar, hp=maxHp, maxHp=maxHp }
end

local function updateHPBar(oreId, currentHp)
	local data = OreHPBars[oreId]
	if not data then return end
	local ratio = math.max(0, currentHp / data.maxHp)
	data.hp     = currentHp
	TweenService:Create(data.bar, TweenInfo.new(0.1), {
		Size = UDim2.new(ratio, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(
			math.floor(220*(1-ratio) + 80*ratio),
			math.floor(80*(1-ratio) + 220*ratio),
			50
		),
	}):Play()
end

local function removeHPBar(oreId)
	local data = OreHPBars[oreId]
	if data and data.billboard and data.billboard.Parent then
		data.billboard:Destroy()
	end
	OreHPBars[oreId] = nil
end

-- ========== Lucky Ore Glow ==========
local LuckyOres = {}

local function makeLuckyOreEffect(part, oreId)
	local light       = Instance.new("PointLight")
	light.Brightness  = 3
	light.Range       = 14
	light.Color       = Color3.fromRGB(255, 215, 0)
	light.Parent      = part

	local billboard       = Instance.new("BillboardGui")
	billboard.Size        = UDim2.new(0, 90, 0, 28)
	billboard.StudsOffset = Vector3.new(0, 4.5, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent      = part

	local lbl         = Instance.new("TextLabel")
	lbl.Size          = UDim2.new(1, 0, 1, 0)
	lbl.Text          = "⭐ LUCKY!"
	lbl.TextColor3    = Color3.fromRGB(255, 220, 50)
	lbl.BackgroundTransparency = 1
	lbl.Font          = Enum.Font.GothamBold
	lbl.TextSize      = 17
	lbl.Parent        = billboard

	local entry = { part=part, light=light, running=true }
	LuckyOres[oreId] = entry

	task.spawn(function()
		local hue = 0
		while entry.running and part and part.Parent do
			hue = (hue + 0.04) % 1
			light.Color = Color3.fromHSV(hue, 1, 1)
			part.Color  = Color3.fromHSV(hue, 0.65, 1)
			task.wait(0.05)
		end
	end)

	task.spawn(function()
		while entry.running and part and part.Parent do
			task.wait(0.4)
			if part.Parent then spawnParticle(part.Position, "Bright yellow", 1, 0.4) end
		end
	end)
end

local function removeLuckyOreEffect(oreId)
	local e = LuckyOres[oreId]
	if e then e.running = false end
	LuckyOres[oreId] = nil
end

-- Boss Ore Glow
local function makeBossOreEffect(part)
	local light       = Instance.new("PointLight")
	light.Brightness  = 5
	light.Range       = 20
	light.Color       = Color3.fromRGB(220, 50, 220)
	light.Parent      = part

	local billboard       = Instance.new("BillboardGui")
	billboard.Size        = UDim2.new(0, 120, 0, 34)
	billboard.StudsOffset = Vector3.new(0, 6, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent      = part

	local lbl         = Instance.new("TextLabel")
	lbl.Size          = UDim2.new(1, 0, 1, 0)
	lbl.Text          = "💎 BOSS!"
	lbl.TextColor3    = Color3.fromRGB(220, 100, 255)
	lbl.BackgroundTransparency = 1
	lbl.Font          = Enum.Font.GothamBold
	lbl.TextSize      = 20
	lbl.Parent        = billboard

	local running = true
	task.spawn(function()
		while running and part and part.Parent do
			TweenService:Create(light, TweenInfo.new(0.5), { Range=22 }):Play()
			task.wait(0.5)
			if part.Parent then
				TweenService:Create(light, TweenInfo.new(0.5), { Range=16 }):Play()
			end
			task.wait(0.5)
		end
	end)
end

-- ========== Combo-UI ==========
local ComboFrame     = nil
local ComboLabel     = nil
local ComboMultLabel = nil
local comboHideTimer = nil

local function createComboUI()
	local ScreenGui = PlayerGui:WaitForChild("EtherealSummitHUD", 5)
	if not ScreenGui then return end

	ComboFrame              = Instance.new("Frame")
	ComboFrame.Name         = "ComboFrame"
	ComboFrame.Size         = UDim2.new(0, 180, 0, 60)
	ComboFrame.Position     = UDim2.new(0.5, -90, 0, 140)
	ComboFrame.BackgroundColor3 = Color3.fromRGB(200, 100, 10)
	ComboFrame.BackgroundTransparency = 0.2
	ComboFrame.BorderSizePixel = 0
	ComboFrame.Visible      = false
	ComboFrame.ZIndex       = 15
	ComboFrame.Parent       = ScreenGui
	Instance.new("UICorner", ComboFrame).CornerRadius = UDim.new(0, 10)

	ComboLabel              = Instance.new("TextLabel")
	ComboLabel.Size         = UDim2.new(1, 0, 0.5, 0)
	ComboLabel.Text         = "COMBO x1"
	ComboLabel.TextColor3   = Color3.fromRGB(255, 255, 255)
	ComboLabel.BackgroundTransparency = 1
	ComboLabel.Font         = Enum.Font.GothamBold
	ComboLabel.TextSize     = 18
	ComboLabel.ZIndex       = 16
	ComboLabel.Parent       = ComboFrame

	ComboMultLabel          = Instance.new("TextLabel")
	ComboMultLabel.Size     = UDim2.new(1, 0, 0.5, 0)
	ComboMultLabel.Position = UDim2.new(0, 0, 0.5, 0)
	ComboMultLabel.Text     = "+0% Coins"
	ComboMultLabel.TextColor3 = Color3.fromRGB(255, 230, 100)
	ComboMultLabel.BackgroundTransparency = 1
	ComboMultLabel.Font     = Enum.Font.Gotham
	ComboMultLabel.TextSize = 14
	ComboMultLabel.ZIndex   = 16
	ComboMultLabel.Parent   = ComboFrame
end

-- ========== Ankuendigungs-Banner ==========
local AnnounceBanner = nil
local AnnounceLabel  = nil
local AnnounceQueue  = {}
local AnnounceActive = false

local ANNOUNCE_COLORS = {
	gold   = Color3.fromRGB(255, 215, 0),
	green  = Color3.fromRGB(50,  200, 50),
	red    = Color3.fromRGB(220, 50,  50),
	blue   = Color3.fromRGB(50,  150, 255),
	purple = Color3.fromRGB(180, 50,  220),
}

local function processAnnounceQueue()
	if AnnounceActive or #AnnounceQueue == 0 then return end
	AnnounceActive = true

	local entry       = table.remove(AnnounceQueue, 1)
	local msg, color  = entry[1], entry[2]
	AnnounceLabel.Text       = msg
	AnnounceLabel.TextColor3 = ANNOUNCE_COLORS[color] or ANNOUNCE_COLORS.gold
	AnnounceBanner.Visible   = true

	TweenService:Create(AnnounceBanner,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.15, 0, 0, 10) }
	):Play()

	task.delay(3.8, function()
		TweenService:Create(AnnounceBanner, TweenInfo.new(0.3),
			{ Position = UDim2.new(0.15, 0, 0, -54) }
		):Play()
		task.delay(0.35, function()
			AnnounceBanner.Visible = false
			AnnounceActive         = false
			processAnnounceQueue()
		end)
	end)
end

local function queueAnnounce(msg, color)
	if #AnnounceQueue >= 6 then return end
	table.insert(AnnounceQueue, { msg, color })
	processAnnounceQueue()
end

local function createAnnounceBanner()
	local ScreenGui = PlayerGui:WaitForChild("EtherealSummitHUD", 5)
	if not ScreenGui then return end

	AnnounceBanner              = Instance.new("Frame")
	AnnounceBanner.Name         = "AnnounceBanner"
	AnnounceBanner.Size         = UDim2.new(0.7, 0, 0, 44)
	AnnounceBanner.Position     = UDim2.new(0.15, 0, 0, -54)
	AnnounceBanner.BackgroundColor3 = Color3.fromRGB(10, 10, 30)
	AnnounceBanner.BackgroundTransparency = 0.1
	AnnounceBanner.BorderSizePixel = 0
	AnnounceBanner.Visible      = false
	AnnounceBanner.ZIndex       = 30
	AnnounceBanner.Parent       = ScreenGui
	Instance.new("UICorner", AnnounceBanner).CornerRadius = UDim.new(0, 10)

	local stripe            = Instance.new("Frame")
	stripe.Size             = UDim2.new(0, 6, 1, 0)
	stripe.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	stripe.BorderSizePixel  = 0
	stripe.ZIndex           = 31
	stripe.Parent           = AnnounceBanner
	Instance.new("UICorner", stripe).CornerRadius = UDim.new(0, 3)

	AnnounceLabel               = Instance.new("TextLabel")
	AnnounceLabel.Size          = UDim2.new(1, -18, 1, 0)
	AnnounceLabel.Position      = UDim2.new(0, 14, 0, 0)
	AnnounceLabel.Text          = ""
	AnnounceLabel.TextColor3    = Color3.fromRGB(255, 215, 0)
	AnnounceLabel.BackgroundTransparency = 1
	AnnounceLabel.Font          = Enum.Font.GothamBold
	AnnounceLabel.TextSize      = 14
	AnnounceLabel.TextWrapped   = false
	AnnounceLabel.TextXAlignment= Enum.TextXAlignment.Left
	AnnounceLabel.ZIndex        = 31
	AnnounceLabel.Parent        = AnnounceBanner
end

-- ========== Event-Banner ==========
local EventBanner = nil
local EventLabel  = nil
local EventTimer  = nil
local eventEndTs  = 0

local function createEventBanner()
	local ScreenGui = PlayerGui:WaitForChild("EtherealSummitHUD", 5)
	if not ScreenGui then return end

	EventBanner              = Instance.new("Frame")
	EventBanner.Name         = "EventBanner"
	EventBanner.Size         = UDim2.new(0, 280, 0, 52)
	EventBanner.Position     = UDim2.new(0.5, -140, 0, 60)
	EventBanner.BackgroundColor3 = Color3.fromRGB(180, 50, 10)
	EventBanner.BackgroundTransparency = 0.1
	EventBanner.BorderSizePixel = 0
	EventBanner.Visible      = false
	EventBanner.ZIndex       = 24
	EventBanner.Parent       = ScreenGui
	Instance.new("UICorner", EventBanner).CornerRadius = UDim.new(0, 10)

	EventLabel               = Instance.new("TextLabel")
	EventLabel.Size          = UDim2.new(1, -10, 0.55, 0)
	EventLabel.Position      = UDim2.new(0, 5, 0, 2)
	EventLabel.Text          = ""
	EventLabel.TextColor3    = Color3.fromRGB(255, 255, 255)
	EventLabel.BackgroundTransparency = 1
	EventLabel.Font          = Enum.Font.GothamBold
	EventLabel.TextSize      = 15
	EventLabel.ZIndex        = 25
	EventLabel.Parent        = EventBanner

	EventTimer               = Instance.new("TextLabel")
	EventTimer.Size          = UDim2.new(1, -10, 0.45, 0)
	EventTimer.Position      = UDim2.new(0, 5, 0.55, 0)
	EventTimer.Text          = ""
	EventTimer.TextColor3    = Color3.fromRGB(255, 220, 100)
	EventTimer.BackgroundTransparency = 1
	EventTimer.Font          = Enum.Font.Gotham
	EventTimer.TextSize      = 13
	EventTimer.ZIndex        = 25
	EventTimer.Parent        = EventBanner

	RunService.Heartbeat:Connect(function()
		if not EventBanner or not EventBanner.Visible then return end
		local rem = math.floor(eventEndTs - os.clock())
		if rem <= 0 then EventBanner.Visible = false
		else EventTimer.Text = rem .. "s verbleibend" end
	end)
end

local EVENT_NAMES = {
	meteor        = "☄️  METEOR – 3x Coins!",
	meteor_warning= "☄️  METEOR WARNUNG!",
	goldrush      = "💰 GOLD RUSH – 2x Coins!",
	luckyhour     = "🍀 LUCKY HOUR – 30% Lucky!",
	boss          = "💎 BOSS ERZ – Insel 10!",
	boss_warning  = "💎 BOSS kommt – Insel 10!",
}
local EVENT_COLORS = {
	meteor=Color3.fromRGB(180,60,10), goldrush=Color3.fromRGB(160,130,10),
	luckyhour=Color3.fromRGB(20,130,50), boss=Color3.fromRGB(110,20,150),
	meteor_warning=Color3.fromRGB(180,60,10), boss_warning=Color3.fromRGB(110,20,150),
}

-- ========== Boss HP-UI ==========
local BossHPFrame = nil
local BossHPBar   = nil

local function createBossHPUI()
	local ScreenGui = PlayerGui:WaitForChild("EtherealSummitHUD", 5)
	if not ScreenGui or BossHPFrame then return end

	BossHPFrame              = Instance.new("Frame")
	BossHPFrame.Name         = "BossHPFrame"
	BossHPFrame.Size         = UDim2.new(0, 420, 0, 42)
	BossHPFrame.Position     = UDim2.new(0.5, -210, 0, 120)
	BossHPFrame.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
	BossHPFrame.BackgroundTransparency = 0.12
	BossHPFrame.BorderSizePixel = 0
	BossHPFrame.Visible      = false
	BossHPFrame.ZIndex       = 23
	BossHPFrame.Parent       = ScreenGui
	Instance.new("UICorner", BossHPFrame).CornerRadius = UDim.new(0, 8)

	local bossLbl            = Instance.new("TextLabel")
	bossLbl.Size             = UDim2.new(1, 0, 0.45, 0)
	bossLbl.Text             = "💎  BOSS ERZ"
	bossLbl.TextColor3       = Color3.fromRGB(210, 90, 255)
	bossLbl.BackgroundTransparency = 1
	bossLbl.Font             = Enum.Font.GothamBold
	bossLbl.TextSize         = 13
	bossLbl.ZIndex           = 24
	bossLbl.Parent           = BossHPFrame

	local bg                 = Instance.new("Frame")
	bg.Size                  = UDim2.new(0.9, 0, 0.38, 0)
	bg.Position              = UDim2.new(0.05, 0, 0.55, 0)
	bg.BackgroundColor3      = Color3.fromRGB(40, 10, 50)
	bg.BorderSizePixel       = 0
	bg.ZIndex                = 24
	bg.Parent                = BossHPFrame
	Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

	BossHPBar                = Instance.new("Frame")
	BossHPBar.Size           = UDim2.new(1, 0, 1, 0)
	BossHPBar.BackgroundColor3 = Color3.fromRGB(200, 50, 220)
	BossHPBar.BorderSizePixel= 0
	BossHPBar.ZIndex         = 25
	BossHPBar.Parent         = bg
	Instance.new("UICorner", BossHPBar).CornerRadius = UDim.new(1, 0)
end

-- ========== Events verbinden ==========
local function connectEffectEvents(eventsFolder)

	local minedEvt = eventsFolder:FindFirstChild(RE.ORE_MINED)
	if minedEvt then
		minedEvt.OnClientEvent:Connect(function(oreId, resource, amount, coinsGained)
			playSound("mine")
			screenShake(0.12, 0.15)

			if resource then
				local oreData = OreHPBars[oreId]
				local pos     = oreData and oreData.billboard and oreData.billboard.Parent
					and oreData.billboard.Parent.Position or Vector3.new(0, 50, 0)

				local resData = ResourceData[resource]
				local color   = resData and resData.color or "Bright yellow"
				local isLucky = LuckyOres[oreId] ~= nil

				if isLucky then
					screenShake(0.5, 0.4)
					playSound("lucky")
					spawnParticle(pos, "Bright yellow", 12, 2.0)
					spawnParticle(pos, "Hot pink",       8, 1.8)
					spawnParticle(pos, "Cyan",           6, 1.5)
					removeLuckyOreEffect(oreId)
				else
					spawnParticle(pos, color, 3, 1.0)
					playSound("break_")
				end

				if coinsGained and coinsGained > 0 then
					playSound("coin")
					showCoinFloat(pos, coinsGained, isLucky)
				end
				removeHPBar(oreId)
			else
				local data = OreHPBars[oreId]
				if data then updateHPBar(oreId, (data.hp or 1) - 1) end
			end
		end)
	end

	local spawnEvt = eventsFolder:FindFirstChild(RE.SPAWN_ORE)
	if spawnEvt then
		spawnEvt.OnClientEvent:Connect(function(oreId, islandIndex, position, resource, maxHp, isLucky, isBoss)
			task.delay(0.1, function()
				local part = workspace:FindFirstChild("Ore_" .. oreId)
				if part then
					createHPBar(part, oreId, maxHp or 4, isLucky, isBoss)
					if isLucky then makeLuckyOreEffect(part, oreId) end
					if isBoss  then makeBossOreEffect(part) end
				end
			end)
		end)
	end

	local removeEvt = eventsFolder:FindFirstChild(RE.REMOVE_ORE)
	if removeEvt then
		removeEvt.OnClientEvent:Connect(function(oreId)
			removeHPBar(oreId)
			removeLuckyOreEffect(oreId)
		end)
	end

	local islandEvt = eventsFolder:FindFirstChild(RE.ISLAND_UNLOCKED)
	if islandEvt then
		islandEvt.OnClientEvent:Connect(function(islandIndex, unlockerName)
			if unlockerName == LocalPlayer.DisplayName then
				playSound("unlock")
				screenShake(0.35, 0.5)
			end
		end)
	end

	local achievEvt = eventsFolder:FindFirstChild(RE.ACHIEVEMENT_UNLOCKED)
	if achievEvt then
		achievEvt.OnClientEvent:Connect(function()
			playSound("achieve")
		end)
	end

	local eggEvt = eventsFolder:FindFirstChild(RE.PET_EGG_RESULT)
	if eggEvt then
		eggEvt.OnClientEvent:Connect(function(success)
			if success then playSound("egg") end
		end)
	end

	local upgradeEvt = eventsFolder:FindFirstChild(RE.UPGRADE_CONFIRMED)
	if upgradeEvt then
		upgradeEvt.OnClientEvent:Connect(function(upgradeType, newLevel)
			if newLevel and newLevel > 1 then playSound("levelUp") end
		end)
	end

	local comboEvt = eventsFolder:FindFirstChild(RE.COMBO_UPDATE)
	if comboEvt then
		comboEvt.OnClientEvent:Connect(function(comboCount, multValue)
			if not ComboFrame then return end
			ComboFrame.Visible  = true
			ComboLabel.Text     = "COMBO x" .. comboCount
			local bonus         = math.floor((multValue - 1.0) * 100)
			ComboMultLabel.Text = "+" .. bonus .. "% Coins"

			if     comboCount >= 30 then ComboFrame.BackgroundColor3 = Color3.fromRGB(180, 20, 180)
			elseif comboCount >= 15 then ComboFrame.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
			elseif comboCount >= 5  then ComboFrame.BackgroundColor3 = Color3.fromRGB(200, 100, 10)
			else                         ComboFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			end

			TweenService:Create(ComboFrame, TweenInfo.new(0.1),
				{ Size = UDim2.new(0, 200, 0, 70) }):Play()
			task.delay(0.12, function()
				if ComboFrame then
					TweenService:Create(ComboFrame, TweenInfo.new(0.2),
						{ Size = UDim2.new(0, 180, 0, 60) }):Play()
				end
			end)

			if comboHideTimer then task.cancel(comboHideTimer) end
			comboHideTimer = task.delay(GameConfig.COMBO_TIMEOUT + 0.5, function()
				if ComboFrame then ComboFrame.Visible = false end
			end)
		end)
	end

	-- Server-Ankuendigungen
	local annEvt = eventsFolder:FindFirstChild(RE.SERVER_ANNOUNCEMENT)
	if annEvt then
		annEvt.OnClientEvent:Connect(function(message, color)
			queueAnnounce(message, color)
		end)
	end

	-- Event gestartet
	local evtStartedEvt = eventsFolder:FindFirstChild(RE.EVENT_STARTED)
	if evtStartedEvt then
		evtStartedEvt.OnClientEvent:Connect(function(eventType, duration, islandIndex)
			playSound("event")

			if EventBanner then
				if EVENT_COLORS[eventType] then
					EventBanner.BackgroundColor3 = EVENT_COLORS[eventType]
				end
				if EventLabel then EventLabel.Text = EVENT_NAMES[eventType] or eventType end
				eventEndTs         = os.clock() + (duration or 30)
				EventBanner.Visible = true

				EventBanner.Position = UDim2.new(0.5, -140, 0, 40)
				TweenService:Create(EventBanner,
					TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{ Position = UDim2.new(0.5, -140, 0, 60) }
				):Play()
			end

			if eventType == "boss" and BossHPFrame then
				BossHPFrame.Visible = true
			end
		end)
	end

	-- Event beendet
	local evtEndedEvt = eventsFolder:FindFirstChild(RE.EVENT_ENDED)
	if evtEndedEvt then
		evtEndedEvt.OnClientEvent:Connect(function(eventType)
			if EventBanner then EventBanner.Visible = false end
			if eventType == "boss" and BossHPFrame then BossHPFrame.Visible = false end
		end)
	end

	-- Boss Ore Treffer
	local bossHitEvt = eventsFolder:FindFirstChild(RE.BOSS_ORE_HIT)
	if bossHitEvt then
		bossHitEvt.OnClientEvent:Connect(function(oreId, hp, maxHp, playerName)
			if BossHPBar then
				TweenService:Create(BossHPBar, TweenInfo.new(0.15),
					{ Size = UDim2.new(math.max(0, hp/maxHp), 0, 1, 0) }
				):Play()
			end
			screenShake(0.08, 0.1)
			local data = OreHPBars[oreId]
			if data then updateHPBar(oreId, hp) end
		end)
	end
end

-- ========== Initialisierung ==========
task.spawn(function()
	local eventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	if not eventsFolder then return end

	task.wait(1)
	createComboUI()
	createAnnounceBanner()
	createEventBanner()
	createBossHPUI()
	connectEffectEvents(eventsFolder)
end)
