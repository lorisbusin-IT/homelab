-- Ethereal Summit – Tutorial fuer neue Spieler (Client)
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RE          = require(ReplicatedStorage.Modules.RemoteEvents)
local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local TUTORIAL_STEPS = {
	{
		title   = "Willkommen bei Ethereal Summit!",
		text    = "Drücke E (oder Tippe) um Erze abzubauen.\nGehe zu einem leuchtenden Stein!",
		arrow   = true,
		trigger = "mine",   -- Abgeschlossen wenn Spieler mined
		goal    = 1,
	},
	{
		title   = "Super! Verkaufe deine Erze",
		text    = "Klicke auf 'Alles verkaufen' um\ndeine Erze in Coins umzutauschen.",
		arrow   = false,
		trigger = "sell",
		goal    = 1,
	},
	{
		title   = "Gib dein Geld aus!",
		text    = "Öffne den Shop (rechts oben)\nund kaufe ein Upgrade!",
		arrow   = false,
		trigger = "upgrade",
		goal    = 1,
	},
	{
		title   = "Neue Inseln freischalten",
		text    = "Sammle genug Coins und schalte\ndie nächste Insel frei – bessere Erze warten!",
		arrow   = false,
		trigger = "island",
		goal    = 1,
	},
	{
		title   = "Du bist bereit!",
		text    = "Schau dir tägliche Belohnungen,\nQuests und Achievements an. Viel Erfolg!",
		arrow   = false,
		trigger = "done",
		goal    = 0,
	},
}

local currentStep    = 1
local stepProgress   = {}
local tutorialActive = false
local TutorialGui    = nil
local StepTitle      = nil
local StepText       = nil
local StepProgress   = nil
local ArrowPart      = nil

-- ========== UI erstellen ==========
local function createTutorialUI()
	local ScreenGui = PlayerGui:WaitForChild("EtherealSummitHUD", 5)
	if not ScreenGui then return end

	TutorialGui              = Instance.new("Frame")
	TutorialGui.Name         = "TutorialFrame"
	TutorialGui.Size         = UDim2.new(0, 320, 0, 100)
	TutorialGui.Position     = UDim2.new(0.5, -160, 1, -120)
	TutorialGui.BackgroundColor3 = Color3.fromRGB(10, 20, 50)
	TutorialGui.BackgroundTransparency = 0.1
	TutorialGui.BorderSizePixel = 0
	TutorialGui.ZIndex       = 20
	TutorialGui.Visible      = false
	TutorialGui.Parent       = ScreenGui
	Instance.new("UICorner", TutorialGui).CornerRadius = UDim.new(0, 12)

	-- Fortschritts-Punkte oben
	StepProgress             = Instance.new("Frame")
	StepProgress.Size        = UDim2.new(1, -20, 0, 10)
	StepProgress.Position    = UDim2.new(0, 10, 0, 8)
	StepProgress.BackgroundTransparency = 1
	StepProgress.ZIndex      = 21
	StepProgress.Parent      = TutorialGui
	Instance.new("UIListLayout", StepProgress).FillDirection = Enum.FillDirection.Horizontal
	local layoutPad = Instance.new("UIListLayout", StepProgress)
	layoutPad.FillDirection = Enum.FillDirection.Horizontal
	layoutPad.Padding = UDim.new(0, 6)

	for i = 1, #TUTORIAL_STEPS do
		local dot              = Instance.new("Frame")
		dot.Name               = "Dot" .. i
		dot.Size               = UDim2.new(0, 8, 0, 8)
		dot.BackgroundColor3   = Color3.fromRGB(80, 80, 120)
		dot.BorderSizePixel    = 0
		dot.ZIndex             = 22
		dot.Parent             = StepProgress
		Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
	end

	StepTitle                = Instance.new("TextLabel")
	StepTitle.Size           = UDim2.new(1, -20, 0, 22)
	StepTitle.Position       = UDim2.new(0, 10, 0, 22)
	StepTitle.Text           = ""
	StepTitle.TextColor3     = Color3.fromRGB(255, 220, 80)
	StepTitle.BackgroundTransparency = 1
	StepTitle.Font           = Enum.Font.GothamBold
	StepTitle.TextSize       = 15
	StepTitle.TextXAlignment = Enum.TextXAlignment.Left
	StepTitle.ZIndex         = 21
	StepTitle.Parent         = TutorialGui

	StepText                 = Instance.new("TextLabel")
	StepText.Size            = UDim2.new(1, -20, 0, 40)
	StepText.Position        = UDim2.new(0, 10, 0, 46)
	StepText.Text            = ""
	StepText.TextColor3      = Color3.fromRGB(200, 200, 220)
	StepText.BackgroundTransparency = 1
	StepText.Font            = Enum.Font.Gotham
	StepText.TextSize        = 13
	StepText.TextXAlignment  = Enum.TextXAlignment.Left
	StepText.TextWrapped     = true
	StepText.ZIndex          = 21
	StepText.Parent          = TutorialGui
end

-- Fortschritts-Dots aktualisieren
local function updateDots()
	if not StepProgress then return end
	for i, dot in ipairs(StepProgress:GetChildren()) do
		if dot:IsA("Frame") then
			dot.BackgroundColor3 = i <= currentStep
				and Color3.fromRGB(100, 200, 100)
				or  Color3.fromRGB(60, 60, 100)
		end
	end
end

-- Schritt anzeigen
local function showStep(stepIdx)
	if not TutorialGui then return end
	local step = TUTORIAL_STEPS[stepIdx]
	if not step then
		-- Tutorial abgeschlossen
		TweenService:Create(TutorialGui, TweenInfo.new(0.5), { BackgroundTransparency=1 }):Play()
		task.delay(0.6, function()
			if TutorialGui then TutorialGui.Visible = false end
		end)
		return
	end

	TutorialGui.Visible = true
	StepTitle.Text = step.title
	StepText.Text  = step.text
	updateDots()

	TweenService:Create(TutorialGui, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -160, 1, -120)
	}):Play()
end

-- Naechsten Schritt
local function advanceStep()
	currentStep = currentStep + 1
	if currentStep > #TUTORIAL_STEPS then
		-- Tutorial fertig → Server informieren
		local eventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if eventsFolder then
			local evt = eventsFolder:FindFirstChild(RE.TUTORIAL_COMPLETE)
			if evt then evt:FireServer() end
		end
		if TutorialGui then TutorialGui.Visible = false end
		tutorialActive = false
		return
	end
	showStep(currentStep)
end

-- Progress fuer aktuellen Schritt
local function progressStep(triggerType)
	if not tutorialActive then return end
	local step = TUTORIAL_STEPS[currentStep]
	if not step or step.trigger ~= triggerType then return end

	stepProgress[currentStep] = (stepProgress[currentStep] or 0) + 1
	if stepProgress[currentStep] >= step.goal then
		task.delay(0.5, advanceStep)
	end
end

-- Tutorial starten
local function startTutorial()
	tutorialActive = true
	currentStep    = 1
	showStep(1)
end

-- ========== Events abonnieren ==========
local function connectTutorialEvents(eventsFolder)
	-- Ore gemined
	local mineEvt = eventsFolder:FindFirstChild(RE.ORE_MINED)
	if mineEvt then
		mineEvt.OnClientEvent:Connect(function(oreId, resource)
			if resource then progressStep("mine") end
		end)
	end

	-- Ressourcen verkauft (indirekt: UPDATE_COINS nach Sell)
	local sellEvt = eventsFolder:FindFirstChild(RE.SELL_RESOURCES)
	-- Client-seitig: Sell-Button liefert kein direktes Event zurueck
	-- Wir nutzen UPDATE_INVENTORY als Proxy: wenn Inventar leer → sell passiert
	local invEvt = eventsFolder:FindFirstChild(RE.UPDATE_INVENTORY)
	if invEvt then
		invEvt.OnClientEvent:Connect(function(inventory)
			local empty = true
			for _, _ in pairs(inventory) do empty=false; break end
			if empty then progressStep("sell") end
		end)
	end

	-- Upgrade
	local upgradeEvt = eventsFolder:FindFirstChild(RE.UPGRADE_CONFIRMED)
	if upgradeEvt then
		upgradeEvt.OnClientEvent:Connect(function(upgradeType, newLevel)
			if newLevel and newLevel > 1 then progressStep("upgrade") end
		end)
	end

	-- Insel freigeschaltet
	local islandEvt = eventsFolder:FindFirstChild(RE.ISLAND_UNLOCKED)
	if islandEvt then
		islandEvt.OnClientEvent:Connect(function(islandIndex, unlockerName)
			if unlockerName == Players.LocalPlayer.DisplayName then
				progressStep("island")
			end
		end)
	end

	-- Spieler-Daten: pruefen ob Tutorial schon abgeschlossen
	local pdEvt = eventsFolder:FindFirstChild(RE.PLAYER_DATA_LOADED)
	if pdEvt then
		pdEvt.OnClientEvent:Connect(function(data)
			if not data.tutorialDone then
				task.delay(2, startTutorial)
			end
		end)
	end
end

-- ========== Initialisierung ==========
task.spawn(function()
	local eventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	if not eventsFolder then return end

	task.wait(2)
	createTutorialUI()
	connectTutorialEvents(eventsFolder)
end)
