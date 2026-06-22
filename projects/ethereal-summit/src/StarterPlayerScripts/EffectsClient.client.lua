-- Ethereal Summit – Effekte, Sounds & Animationen (Client)
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local RE                = require(ReplicatedStorage.Modules.RemoteEvents)
local ResourceData      = require(ReplicatedStorage.Modules.ResourceData)
local GameConfig        = require(ReplicatedStorage.Modules.GameConfig)

local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")
local Camera       = workspace.CurrentCamera

-- ========== Sound-System ==========
local Sounds = {}

local function createSound(parent, id, volume, pitch)
	local s     = Instance.new("Sound")
	s.SoundId   = id ~= "" and ("rbxassetid://" .. id) or ""
	s.Volume    = volume or 0.5
	s.PlaybackSpeed = pitch or 1.0
	s.RollOffMaxDistance = 60
	s.Parent    = parent
	return s
end

-- Sounds in der Camera (immer hoerbar, keine Positionierung)
local SoundFolder = Instance.new("Folder")
SoundFolder.Name  = "EtherealSounds"
SoundFolder.Parent = Camera

-- Roblox Asset IDs fuer freie Sounds (Standard-Roblox-Sounds)
Sounds.mine     = createSound(SoundFolder, "131070686",  0.6, 1.0)   -- Pickaxe Hit
Sounds.break_   = createSound(SoundFolder, "131070685",  0.8, 0.9)   -- Ore Break
Sounds.coin     = createSound(SoundFolder, "4590662766", 0.5, 1.1)   -- Coin Ding
Sounds.sell     = createSound(SoundFolder, "4590662766", 0.7, 0.8)   -- Sell Sound
Sounds.levelUp  = createSound(SoundFolder, "131070649",  0.8, 1.2)   -- Level Up Fanfare
Sounds.unlock   = createSound(SoundFolder, "131072580",  0.8, 1.0)   -- Island Unlock
Sounds.achieve  = createSound(SoundFolder, "131070649",  0.9, 1.0)   -- Achievement
Sounds.egg      = createSound(SoundFolder, "131070580",  0.8, 1.2)   -- Egg Hatch

local function playSound(soundKey)
	local s = Sounds[soundKey]
	if s and s.SoundId ~= "" then
		s:Play()
	end
end

-- ========== Partikel-Effekte ==========
-- Partikel am Erz beim Mining-Hit
local function spawnMineParticle(position, color)
	local part          = Instance.new("Part")
	part.Size           = Vector3.new(0.3, 0.3, 0.3)
	part.Position       = position + Vector3.new(math.random(-1,1), math.random(0,2), math.random(-1,1))
	part.BrickColor     = BrickColor.new(color or "Bright yellow")
	part.Material       = Enum.Material.Neon
	part.Anchored       = false
	part.CanCollide     = false
	part.CastShadow     = false
	part.Parent         = workspace

	-- Physik: kurz hochschmeissen
	local bodyVelocity         = Instance.new("BodyVelocity")
	bodyVelocity.Velocity      = Vector3.new(math.random(-5,5), math.random(8,15), math.random(-5,5))
	bodyVelocity.MaxForce      = Vector3.new(1e4,1e4,1e4)
	bodyVelocity.Parent        = part

	-- Nach 0.5s loschen
	task.delay(0.5, function()
		if part.Parent then
			TweenService:Create(part, TweenInfo.new(0.3), { Size=Vector3.new(0,0,0), Transparency=1 }):Play()
			task.delay(0.3, function() if part.Parent then part:Destroy() end end)
		end
	end)
end

-- Coin-Float-Anzeige ueber dem Erz
local function showCoinFloat(worldPosition, amount)
	if not amount or amount <= 0 then return end

	local ScreenGui    = PlayerGui:FindFirstChild("EtherealSummitHUD")
	if not ScreenGui then return end

	local lbl          = Instance.new("TextLabel")
	lbl.Size           = UDim2.new(0, 120, 0, 30)
	lbl.BackgroundTransparency = 1
	lbl.Text           = "+" .. math.floor(amount) .. " Coins"
	lbl.TextColor3     = Color3.fromRGB(255, 220, 50)
	lbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
	lbl.TextStrokeTransparency = 0.5
	lbl.Font           = Enum.Font.GothamBold
	lbl.TextSize       = 18
	lbl.ZIndex         = 20
	lbl.Parent         = ScreenGui

	-- Startposition: Weltposition auf Screen projizieren
	local screenPos, onScreen = Camera:WorldToScreenPoint(worldPosition)
	if not onScreen then lbl:Destroy(); return end

	lbl.Position = UDim2.new(0, screenPos.X - 60, 0, screenPos.Y - 20)

	-- Nach oben floaten und ausbleden
	TweenService:Create(lbl, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, screenPos.X - 60, 0, screenPos.Y - 80),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()

	task.delay(1.5, function() if lbl.Parent then lbl:Destroy() end end)
end

-- ========== HP-Balken ueber Erzen ==========
local OreHPBars = {}  -- { [oreId] = BillboardGui }

local function createHPBar(orePart, oreId, maxHp)
	local billboard         = Instance.new("BillboardGui")
	billboard.Name          = "HPBar_" .. oreId
	billboard.Size          = UDim2.new(0, 60, 0, 8)
	billboard.StudsOffset   = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop   = false
	billboard.Parent        = orePart

	local bg                = Instance.new("Frame")
	bg.Size                 = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3     = Color3.fromRGB(40, 40, 40)
	bg.BorderSizePixel      = 0
	bg.Parent               = billboard
	Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

	local bar               = Instance.new("Frame")
	bar.Name                = "Bar"
	bar.Size                = UDim2.new(1, 0, 1, 0)
	bar.BackgroundColor3    = Color3.fromRGB(80, 220, 80)
	bar.BorderSizePixel     = 0
	bar.Parent              = bg
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

	OreHPBars[oreId] = { billboard=billboard, bar=bar, hp=maxHp, maxHp=maxHp }
end

local function updateHPBar(oreId, currentHp)
	local data = OreHPBars[oreId]
	if not data then return end
	local ratio = math.max(0, currentHp / data.maxHp)
	data.hp = currentHp
	TweenService:Create(data.bar, TweenInfo.new(0.1), {
		Size = UDim2.new(ratio, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(
			math.floor(220 * (1 - ratio) + 80 * ratio),
			math.floor(80 * (1 - ratio) + 220 * ratio),
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
	ComboLabel.Position     = UDim2.new(0, 0, 0, 0)
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

-- ========== Events abonnieren ==========
local function connectEffectEvents(eventsFolder)
	-- Ore gemined: Sound + Partikel + HP-Bar-Update
	local minedEvt = eventsFolder:FindFirstChild(RE.ORE_MINED)
	if minedEvt then
		minedEvt.OnClientEvent:Connect(function(oreId, resource, amount, coinsGained)
			playSound("mine")
			if resource then
				-- Partikeleffekt
				local oreData = OreHPBars[oreId]
				local pos = oreData and oreData.billboard and oreData.billboard.Parent
					and oreData.billboard.Parent.Position
					or Vector3.new(0, 50, 0)

				local resData = ResourceData[resource]
				local color   = resData and resData.color or "Bright yellow"
				for i = 1, 3 do
					spawnMineParticle(pos, color)
				end

				playSound("break_")
				if coinsGained and coinsGained > 0 then
					playSound("coin")
					showCoinFloat(pos, coinsGained)
				end
				removeHPBar(oreId)
			else
				-- Noch nicht fertig: HP-Bar aktualisieren
				local data = OreHPBars[oreId]
				if data then
					updateHPBar(oreId, (data.hp or 1) - 1)
				end
			end
		end)
	end

	-- Neues Erz gespawnt: HP-Bar erstellen
	local spawnEvt = eventsFolder:FindFirstChild(RE.SPAWN_ORE)
	if spawnEvt then
		spawnEvt.OnClientEvent:Connect(function(oreId, islandIndex, position, resource, maxHp)
			-- Kurz warten bis Part existiert
			task.delay(0.1, function()
				local part = workspace:FindFirstChild("Ore_" .. oreId)
				if part then
					createHPBar(part, oreId, maxHp or 4)
				end
			end)
		end)
	end

	-- Erz entfernt: HP-Bar loeschen
	local removeEvt = eventsFolder:FindFirstChild(RE.REMOVE_ORE)
	if removeEvt then
		removeEvt.OnClientEvent:Connect(function(oreId)
			removeHPBar(oreId)
		end)
	end

	-- Verkauf-Sound
	local sellEvt = eventsFolder:FindFirstChild(RE.UPDATE_COINS)
	if sellEvt then
		sellEvt.OnClientEvent:Connect(function()
			-- Nur bei explizitem Sell (kein Auto)
		end)
	end

	-- Insel freigeschaltet: Fanfare
	local islandEvt = eventsFolder:FindFirstChild(RE.ISLAND_UNLOCKED)
	if islandEvt then
		islandEvt.OnClientEvent:Connect(function(islandIndex, unlockerName)
			if unlockerName == LocalPlayer.DisplayName then
				playSound("unlock")
			end
		end)
	end

	-- Achievement: Sound
	local achievEvt = eventsFolder:FindFirstChild(RE.ACHIEVEMENT_UNLOCKED)
	if achievEvt then
		achievEvt.OnClientEvent:Connect(function(achievId, display, reward)
			playSound("achieve")
		end)
	end

	-- Pet Ei: Hatch-Sound
	local eggEvt = eventsFolder:FindFirstChild(RE.PET_EGG_RESULT)
	if eggEvt then
		eggEvt.OnClientEvent:Connect(function(success, petData)
			if success then playSound("egg") end
		end)
	end

	-- Combo-Update
	local comboEvt = eventsFolder:FindFirstChild(RE.COMBO_UPDATE)
	if comboEvt then
		comboEvt.OnClientEvent:Connect(function(comboCount, multValue)
			if not ComboFrame then return end

			ComboFrame.Visible = true
			ComboLabel.Text    = "COMBO x" .. comboCount
			local bonus        = math.floor((multValue - 1.0) * 100)
			ComboMultLabel.Text = "+" .. bonus .. "% Coins"

			-- Farbe nach Combo-Staerke
			if comboCount >= 30 then
				ComboFrame.BackgroundColor3 = Color3.fromRGB(180, 20, 180)
			elseif comboCount >= 15 then
				ComboFrame.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
			elseif comboCount >= 5 then
				ComboFrame.BackgroundColor3 = Color3.fromRGB(200, 100, 10)
			else
				ComboFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			end

			-- Pulse-Animation
			TweenService:Create(ComboFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 200, 0, 70)
			}):Play()
			task.delay(0.1, function()
				if ComboFrame then
					TweenService:Create(ComboFrame, TweenInfo.new(0.2), {
						Size = UDim2.new(0, 180, 0, 60)
					}):Play()
				end
			end)

			-- Auto-Ausblenden nach Timeout
			if comboHideTimer then task.cancel(comboHideTimer) end
			comboHideTimer = task.delay(GameConfig.COMBO_TIMEOUT + 0.5, function()
				if ComboFrame then ComboFrame.Visible = false end
			end)
		end)
	end

	-- Upgrade bestätigt: Level-Up Sound
	local upgradeEvt = eventsFolder:FindFirstChild(RE.UPGRADE_CONFIRMED)
	if upgradeEvt then
		upgradeEvt.OnClientEvent:Connect(function(upgradeType, newLevel)
			if newLevel and newLevel > 1 then
				playSound("levelUp")
			end
		end)
	end
end

-- ========== Initialisierung ==========
task.spawn(function()
	local eventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	if not eventsFolder then return end

	task.wait(1)  -- Auf HUD warten
	createComboUI()
	connectEffectEvents(eventsFolder)
end)
