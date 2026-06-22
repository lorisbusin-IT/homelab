-- Ethereal Summit – UI-Manager (Client)
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService= game:GetService("MarketplaceService")

local RemoteEventsConfig = require(ReplicatedStorage.Modules.RemoteEvents)
local GameConfig         = require(ReplicatedStorage.Modules.GameConfig)
local IslandData         = require(ReplicatedStorage.Modules.IslandData)

local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")
local EventsFolder = nil

-- ====== UI-Aufbau ======

local ScreenGui        = Instance.new("ScreenGui")
ScreenGui.Name         = "EtherealSummitHUD"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent       = PlayerGui

-- Haupt-HUD (oben links)
local HUD              = Instance.new("Frame")
HUD.Name               = "HUD"
HUD.Size               = UDim2.new(0, 260, 0, 120)
HUD.Position           = UDim2.new(0, 10, 0, 10)
HUD.BackgroundColor3   = Color3.fromRGB(20, 20, 35)
HUD.BackgroundTransparency = 0.3
HUD.BorderSizePixel    = 0
HUD.Parent             = ScreenGui
Instance.new("UICorner", HUD).CornerRadius = UDim.new(0, 10)

local function makeLabel(parent, name, pos, size, text, color)
	local lbl              = Instance.new("TextLabel")
	lbl.Name               = name
	lbl.Position           = pos
	lbl.Size               = size
	lbl.Text               = text
	lbl.TextColor3         = color or Color3.fromRGB(255, 220, 80)
	lbl.BackgroundTransparency = 1
	lbl.Font               = Enum.Font.GothamBold
	lbl.TextSize           = 16
	lbl.TextXAlignment     = Enum.TextXAlignment.Left
	lbl.Parent             = parent
	return lbl
end

local CoinsLabel  = makeLabel(HUD, "CoinsLabel",  UDim2.new(0,10,0,8),   UDim2.new(1,-20,0,25), "Coins: 0",    Color3.fromRGB(255,220,80))
local GemsLabel   = makeLabel(HUD, "GemsLabel",   UDim2.new(0,10,0,36),  UDim2.new(1,-20,0,25), "Gems: 0",     Color3.fromRGB(100,200,255))
local IslandLabel = makeLabel(HUD, "IslandLabel", UDim2.new(0,10,0,64),  UDim2.new(1,-20,0,25), "Insel: 1",    Color3.fromRGB(180,255,180))
local InvLabel    = makeLabel(HUD, "InvLabel",    UDim2.new(0,10,0,92),  UDim2.new(1,-20,0,25), "Inv: 0/50",   Color3.fromRGB(200,200,200))

-- Shop-Button (oben rechts)
local ShopBtn              = Instance.new("TextButton")
ShopBtn.Name               = "ShopBtn"
ShopBtn.Size               = UDim2.new(0, 100, 0, 40)
ShopBtn.Position           = UDim2.new(1, -115, 0, 10)
ShopBtn.Text               = "Shop"
ShopBtn.TextColor3         = Color3.fromRGB(255,255,255)
ShopBtn.BackgroundColor3   = Color3.fromRGB(80, 40, 140)
ShopBtn.Font               = Enum.Font.GothamBold
ShopBtn.TextSize           = 18
ShopBtn.BorderSizePixel    = 0
ShopBtn.Parent             = ScreenGui
Instance.new("UICorner", ShopBtn).CornerRadius = UDim.new(0, 8)

-- Verkaufen-Button (unten mitte)
local SellBtn              = Instance.new("TextButton")
SellBtn.Name               = "SellBtn"
SellBtn.Size               = UDim2.new(0, 160, 0, 50)
SellBtn.Position           = UDim2.new(0.5, -80, 1, -70)
SellBtn.Text               = "Alles verkaufen"
SellBtn.TextColor3         = Color3.fromRGB(255,255,255)
SellBtn.BackgroundColor3   = Color3.fromRGB(40, 160, 60)
SellBtn.Font               = Enum.Font.GothamBold
SellBtn.TextSize           = 16
SellBtn.BorderSizePixel    = 0
SellBtn.Parent             = ScreenGui
Instance.new("UICorner", SellBtn).CornerRadius = UDim.new(0, 8)

-- Mobile Mine-Button
local MineBtn              = Instance.new("TextButton")
MineBtn.Name               = "MineBtn"
MineBtn.Size               = UDim2.new(0, 80, 0, 80)
MineBtn.Position           = UDim2.new(1, -100, 1, -100)
MineBtn.Text               = "E\nAbbauen"
MineBtn.TextColor3         = Color3.fromRGB(255,255,255)
MineBtn.BackgroundColor3   = Color3.fromRGB(180, 100, 20)
MineBtn.BackgroundTransparency = 0.2
MineBtn.Font               = Enum.Font.GothamBold
MineBtn.TextSize            = 14
MineBtn.BorderSizePixel    = 0
MineBtn.Parent             = ScreenGui
Instance.new("UICorner", MineBtn).CornerRadius = UDim.new(0, 40)

-- Toast-Benachrichtigungs-Container
local ToastContainer       = Instance.new("Frame")
ToastContainer.Name        = "Toasts"
ToastContainer.Size        = UDim2.new(0, 300, 0, 200)
ToastContainer.Position    = UDim2.new(0.5, -150, 0, 10)
ToastContainer.BackgroundTransparency = 1
ToastContainer.Parent      = ScreenGui

-- Leaderboard-Frame (rechts)
local LBFrame              = Instance.new("Frame")
LBFrame.Name               = "Leaderboard"
LBFrame.Size               = UDim2.new(0, 220, 0, 300)
LBFrame.Position           = UDim2.new(1, -235, 0.5, -150)
LBFrame.BackgroundColor3   = Color3.fromRGB(15, 15, 30)
LBFrame.BackgroundTransparency = 0.2
LBFrame.BorderSizePixel    = 0
LBFrame.Visible            = false
LBFrame.Parent             = ScreenGui
Instance.new("UICorner", LBFrame).CornerRadius = UDim.new(0, 10)

-- ====== Zustand ======

local PlayerData  = nil
local ToastQueue  = {}
local isShowingToast = false

-- ====== Hilfsfunktionen ======

local function formatNumber(n)
	if n >= 1e9 then return string.format("%.1fMrd", n/1e9)
	elseif n >= 1e6 then return string.format("%.1fMio", n/1e6)
	elseif n >= 1e3 then return string.format("%.1fK", n/1e3)
	else return tostring(math.floor(n)) end
end

local function updateHUD(data)
	if not data then return end
	CoinsLabel.Text  = "Coins: " .. formatNumber(data.coins or 0)
	GemsLabel.Text   = "Gems: "  .. formatNumber(data.gems or 0)
	IslandLabel.Text = "Insel: " .. (data.highestIsland or 1) .. "/" .. GameConfig.MAX_ISLANDS

	local inv      = data.inventory or {}
	local total    = 0
	for _, qty in pairs(inv) do total = total + qty end
	local maxSlots = GameConfig.BACKPACK_CAPACITY[(data.upgrades and data.upgrades.backpack) or 1] or 50
	InvLabel.Text  = "Inv: " .. total .. "/" .. maxSlots
end

-- Toast-Benachrichtigung anzeigen
local TOAST_COLORS = {
	info    = Color3.fromRGB(50, 100, 200),
	success = Color3.fromRGB(40, 160, 60),
	warning = Color3.fromRGB(200, 140, 20),
	error   = Color3.fromRGB(200, 40, 40),
}

local function showToast(message, style)
	local color = TOAST_COLORS[style] or TOAST_COLORS.info

	local toast              = Instance.new("Frame")
	toast.Size               = UDim2.new(1, 0, 0, 36)
	toast.BackgroundColor3   = color
	toast.BackgroundTransparency = 0.2
	toast.BorderSizePixel    = 0
	toast.Parent             = ToastContainer
	Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 8)

	local lbl              = Instance.new("TextLabel")
	lbl.Size               = UDim2.new(1, -10, 1, 0)
	lbl.Position           = UDim2.new(0, 5, 0, 0)
	lbl.Text               = message
	lbl.TextColor3         = Color3.fromRGB(255, 255, 255)
	lbl.BackgroundTransparency = 1
	lbl.Font               = Enum.Font.Gotham
	lbl.TextSize           = 14
	lbl.TextXAlignment     = Enum.TextXAlignment.Center
	lbl.Parent             = toast

	-- Einblenden
	toast.Position = UDim2.new(0, 0, 0, -40)
	TweenService:Create(toast, TweenInfo.new(0.3), { Position = UDim2.new(0,0,0,0) }):Play()

	-- Nach 2.5 Sekunden ausblenden und entfernen
	task.delay(2.5, function()
		local tween = TweenService:Create(toast, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
		TweenService:Create(lbl,   TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
		tween.Completed:Connect(function() toast:Destroy() end)
		tween:Play()
	end)
end

-- Leaderboard-Daten rendern
local function renderLeaderboard(data)
	-- Alte Eintraege loeschen
	for _, child in ipairs(LBFrame:GetChildren()) do
		if child:IsA("TextLabel") or child:IsA("Frame") then
			child:Destroy()
		end
	end

	local titleLbl      = Instance.new("TextLabel")
	titleLbl.Size       = UDim2.new(1, 0, 0, 30)
	titleLbl.Position   = UDim2.new(0, 0, 0, 5)
	titleLbl.Text       = "Top Spieler"
	titleLbl.TextColor3 = Color3.fromRGB(255, 220, 80)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font       = Enum.Font.GothamBold
	titleLbl.TextSize   = 16
	titleLbl.Parent     = LBFrame

	local topCoins = data.topCoins or {}
	for i, entry in ipairs(topCoins) do
		if i > 5 then break end
		local lbl          = Instance.new("TextLabel")
		lbl.Size           = UDim2.new(1, -10, 0, 24)
		lbl.Position       = UDim2.new(0, 5, 0, 28 + (i-1)*26)
		lbl.Text           = i .. ". " .. entry.name .. "  " .. formatNumber(entry.value)
		lbl.TextColor3     = Color3.fromRGB(220, 220, 220)
		lbl.BackgroundTransparency = 1
		lbl.Font           = Enum.Font.Gotham
		lbl.TextSize       = 13
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent         = LBFrame
	end
end

-- ====== Event-Verbindungen ======

local function getEvent(name)
	if not EventsFolder then return nil end
	return EventsFolder:FindFirstChild(name)
end

local function connectEvents()
	-- Spieler-Daten geladen
	local pdEvt = getEvent(RemoteEventsConfig.PLAYER_DATA_LOADED)
	if pdEvt then
		pdEvt.OnClientEvent:Connect(function(data)
			PlayerData = data
			updateHUD(data)
		end)
	end

	-- Coins / Gems aktualisiert
	local coinsEvt = getEvent(RemoteEventsConfig.UPDATE_COINS)
	if coinsEvt then
		coinsEvt.OnClientEvent:Connect(function(coins, gems)
			if PlayerData then
				PlayerData.coins = coins
				PlayerData.gems  = gems
				updateHUD(PlayerData)
			end
		end)
	end

	-- Inventar aktualisiert
	local invEvt = getEvent(RemoteEventsConfig.UPDATE_INVENTORY)
	if invEvt then
		invEvt.OnClientEvent:Connect(function(inventory)
			if PlayerData then
				PlayerData.inventory = inventory
				updateHUD(PlayerData)
			end
		end)
	end

	-- Benachrichtigung
	local notifEvt = getEvent(RemoteEventsConfig.SHOW_NOTIFICATION)
	if notifEvt then
		notifEvt.OnClientEvent:Connect(function(message, style)
			showToast(message, style)
		end)
	end

	-- Insel freigeschaltet
	local islandEvt = getEvent(RemoteEventsConfig.ISLAND_UNLOCKED)
	if islandEvt then
		islandEvt.OnClientEvent:Connect(function(islandIndex, unlockerName)
			local island = IslandData[islandIndex]
			if island then
				showToast(unlockerName .. " hat '" .. island.name .. "' freigeschaltet!", "success")
			end
		end)
	end

	-- Upgrade bestaetigt
	local upgradeEvt = getEvent(RemoteEventsConfig.UPGRADE_CONFIRMED)
	if upgradeEvt then
		upgradeEvt.OnClientEvent:Connect(function(upgradeType, newLevel, newCoins)
			if PlayerData then
				if not PlayerData.upgrades then PlayerData.upgrades = {} end
				PlayerData.upgrades[upgradeType] = newLevel
				PlayerData.coins = newCoins
				updateHUD(PlayerData)
			end
		end)
	end

	-- Auto-Mine Tick
	local autoEvt = getEvent(RemoteEventsConfig.AUTO_MINE_TICK)
	if autoEvt then
		autoEvt.OnClientEvent:Connect(function(resource, amount, coinsGained)
			if resource and coinsGained > 0 then
				showToast("[Auto] +" .. coinsGained .. " Coins", "info")
			end
		end)
	end

	-- Leaderboard
	local lbEvt = getEvent(RemoteEventsConfig.UPDATE_LEADERBOARD)
	if lbEvt then
		lbEvt.OnClientEvent:Connect(function(data)
			renderLeaderboard(data)
		end)
	end

	-- Kauf bestaetigt
	local purchaseEvt = getEvent(RemoteEventsConfig.PURCHASE_CONFIRMED)
	if purchaseEvt then
		purchaseEvt.OnClientEvent:Connect(function(productType, newBalance)
			if PlayerData then
				PlayerData.coins = newBalance.coins
				PlayerData.gems  = newBalance.gems
				updateHUD(PlayerData)
			end
			if productType == "coin_boost" then
				showToast("Coin Boost aktiv! 3x fuer 1 Stunde!", "success")
			elseif productType == "gem_small" then
				showToast("+100 Gems erhalten!", "success")
			elseif productType == "gem_large" then
				showToast("+500 Gems erhalten!", "success")
			end
		end)
	end
end

-- Button-Callbacks
SellBtn.MouseButton1Click:Connect(function()
	local evt = getEvent(RemoteEventsConfig.SELL_RESOURCES)
	if evt then evt:FireServer("", 0) end
end)

MineBtn.MouseButton1Click:Connect(function()
	if _G.EtherealMineInput then _G.EtherealMineInput() end
end)

ShopBtn.MouseButton1Click:Connect(function()
	-- ShopClient oeffnen/schliessen
	if _G.EtherealToggleShop then _G.EtherealToggleShop() end
end)

-- Leaderboard-Toggle mit Tab-Taste
game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Tab then
		LBFrame.Visible = not LBFrame.Visible
	end
end)

-- Initialisierung
task.spawn(function()
	EventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	if not EventsFolder then
		warn("[UIManager] RemoteEvents nicht gefunden!")
		return
	end
	connectEvents()
	showToast("Willkommen bei Ethereal Summit!", "success")
end)
