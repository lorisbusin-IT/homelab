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

local CoinsLabel   = makeLabel(HUD, "CoinsLabel",   UDim2.new(0,10,0,8),   UDim2.new(1,-20,0,25), "Coins: 0",    Color3.fromRGB(255,220,80))
local GemsLabel    = makeLabel(HUD, "GemsLabel",    UDim2.new(0,10,0,36),  UDim2.new(1,-20,0,25), "Gems: 0",     Color3.fromRGB(100,200,255))
local RebirthLabel = makeLabel(HUD, "RebirthLabel", UDim2.new(0,10,0,150), UDim2.new(1,-20,0,20), "",            Color3.fromRGB(255,100,255))
local IslandLabel = makeLabel(HUD, "IslandLabel", UDim2.new(0,10,0,64),  UDim2.new(1,-20,0,25), "Insel: 1",    Color3.fromRGB(180,255,180))
local InvLabel    = makeLabel(HUD, "InvLabel",    UDim2.new(0,10,0,92),  UDim2.new(1,-20,0,25), "Inv: 0/50",   Color3.fromRGB(200,200,200))

-- Daily-Reward-Button (oben rechts, neben Shop)
local DailyBtn             = Instance.new("TextButton")
DailyBtn.Name              = "DailyBtn"
DailyBtn.Size              = UDim2.new(0, 90, 0, 40)
DailyBtn.Position          = UDim2.new(1, -220, 0, 10)
DailyBtn.Text              = "Taegl."
DailyBtn.TextColor3        = Color3.fromRGB(255,255,255)
DailyBtn.BackgroundColor3  = Color3.fromRGB(180, 120, 20)
DailyBtn.Font              = Enum.Font.GothamBold
DailyBtn.TextSize          = 15
DailyBtn.BorderSizePixel   = 0
DailyBtn.Parent            = ScreenGui
Instance.new("UICorner", DailyBtn).CornerRadius = UDim.new(0, 8)

-- Quest-Button
local QuestBtn             = Instance.new("TextButton")
QuestBtn.Name              = "QuestBtn"
QuestBtn.Size              = UDim2.new(0, 90, 0, 40)
QuestBtn.Position          = UDim2.new(1, -220, 0, 58)
QuestBtn.Text              = "Quests"
QuestBtn.TextColor3        = Color3.fromRGB(255,255,255)
QuestBtn.BackgroundColor3  = Color3.fromRGB(20, 120, 180)
QuestBtn.Font              = Enum.Font.GothamBold
QuestBtn.TextSize          = 15
QuestBtn.BorderSizePixel   = 0
QuestBtn.Parent            = ScreenGui
Instance.new("UICorner", QuestBtn).CornerRadius = UDim.new(0, 8)

-- Rebirth-Button (leuchtet wenn verfuegbar)
local RebirthBtn           = Instance.new("TextButton")
RebirthBtn.Name            = "RebirthBtn"
RebirthBtn.Size            = UDim2.new(0, 90, 0, 40)
RebirthBtn.Position        = UDim2.new(1, -220, 0, 106)
RebirthBtn.Text            = "Rebirth"
RebirthBtn.TextColor3      = Color3.fromRGB(255,255,255)
RebirthBtn.BackgroundColor3= Color3.fromRGB(60, 60, 80)
RebirthBtn.Font            = Enum.Font.GothamBold
RebirthBtn.TextSize        = 15
RebirthBtn.BorderSizePixel = 0
RebirthBtn.Parent          = ScreenGui
Instance.new("UICorner", RebirthBtn).CornerRadius = UDim.new(0, 8)

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

	-- Rebirth-Label
	local rebirths = data.rebirths or 0
	if rebirths > 0 then
		RebirthLabel.Text    = "Rebirth " .. rebirths .. "x | +" .. math.floor(rebirths * 25) .. "% Coins"
		RebirthLabel.Visible = true
	else
		RebirthLabel.Visible = false
	end

	-- Rebirth-Button Farbe: leuchtet wenn bereit
	if data.unlockedIslands and data.unlockedIslands[GameConfig.MAX_ISLANDS] then
		RebirthBtn.BackgroundColor3 = Color3.fromRGB(160, 30, 200)
	else
		RebirthBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	end

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
				showToast("Coin Boost x3 aktiv! 1 Stunde!", "success")
			elseif productType == "coin_boost5" then
				showToast("Coin Boost x5 aktiv! 3 Stunden!", "success")
			elseif productType == "gem_small" then
				showToast("+100 Gems erhalten!", "success")
			elseif productType == "gem_large" then
				showToast("+500 Gems erhalten!", "success")
			elseif productType == "gem_xl" then
				showToast("+1200 Gems erhalten!", "success")
			end
		end)
	end

	-- Rebirth-Ergebnis
	local rebirthEvt = getEvent(RemoteEventsConfig.REBIRTH_RESULT)
	if rebirthEvt then
		rebirthEvt.OnClientEvent:Connect(function(success, rebirthsOrMsg, newMult)
			if success and PlayerData then
				PlayerData.rebirths   = rebirthsOrMsg
				PlayerData.rebirthMult= newMult
				updateHUD(PlayerData)
			end
		end)
	end

	-- Daily Reward Daten
	local dailyDataEvt = getEvent(RemoteEventsConfig.DAILY_DATA_RESPONSE)
	if dailyDataEvt then
		dailyDataEvt.OnClientEvent:Connect(function(dailyData)
			-- Wenn claimbar: Button hervorheben
			if dailyData.canClaim then
				DailyBtn.BackgroundColor3 = Color3.fromRGB(220, 160, 20)
				DailyBtn.Text = "Taegl. !"
			else
				DailyBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
				DailyBtn.Text = "Taegl. " .. (dailyData.streak or 0)
			end
		end)
	end

	-- Daily Reward erhalten
	local dailyGrantEvt = getEvent(RemoteEventsConfig.DAILY_REWARD_GRANTED)
	if dailyGrantEvt then
		dailyGrantEvt.OnClientEvent:Connect(function(success, reward, newStreak)
			if success and reward then
				local txt = reward.type == "coins" and ("+" .. reward.amount .. " Coins!")
					or reward.type == "gems"  and ("+" .. reward.amount .. " Gems!")
					or "Coin Boost aktiviert!"
				showToast("Tag " .. newStreak .. ": " .. txt, "success")
				DailyBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
				DailyBtn.Text = "Taegl. " .. newStreak
			end
		end)
	end

	-- Achievement erhalten
	local achievEvt = getEvent(RemoteEventsConfig.ACHIEVEMENT_UNLOCKED)
	if achievEvt then
		achievEvt.OnClientEvent:Connect(function(achievId, display, reward)
			local rewardTxt = reward.coins and ("+" .. reward.coins .. " Coins")
				or reward.gems and ("+" .. reward.gems .. " Gems") or ""
			showToast("Achievement: " .. display .. "! " .. rewardTxt, "success")
		end)
	end

	-- Pet erhalten
	local petEggEvt = getEvent(RemoteEventsConfig.PET_EGG_RESULT)
	if petEggEvt then
		petEggEvt.OnClientEvent:Connect(function(success, petData, msg)
			if success and petData then
				local rarityColors = {
					common="Gewoehnlich", uncommon="Ungewoehnlich",
					rare="Selten", epic="Episch", legendary="LEGENDAER"
				}
				showToast("Pet erhalten: " .. (rarityColors[petData.rarity] or "?") .. " " .. petData.name, "success")
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

DailyBtn.MouseButton1Click:Connect(function()
	local evt = getEvent(RemoteEventsConfig.CLAIM_DAILY_REWARD)
	if evt then evt:FireServer() end
end)

QuestBtn.MouseButton1Click:Connect(function()
	if _G.EtherealToggleQuests then _G.EtherealToggleQuests() end
end)

RebirthBtn.MouseButton1Click:Connect(function()
	local evt = getEvent(RemoteEventsConfig.REBIRTH_REQUEST)
	if evt then evt:FireServer() end
end)

ShopBtn.MouseButton1Click:Connect(function()
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
