-- Ethereal Summit – Shop-Client (Client)
local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local RemoteEventsConfig = require(ReplicatedStorage.Modules.RemoteEvents)
local GameConfig         = require(ReplicatedStorage.Modules.GameConfig)
local IslandData         = require(ReplicatedStorage.Modules.IslandData)

local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")
local EventsFolder = nil
local PlayerData   = nil

-- Auf HUD-ScreenGui warten
local ScreenGui = PlayerGui:WaitForChild("EtherealSummitHUD", 10)

-- ====== Shop-Frame erstellen ======

local ShopFrame            = Instance.new("Frame")
ShopFrame.Name             = "ShopFrame"
ShopFrame.Size             = UDim2.new(0, 420, 0, 500)
ShopFrame.Position         = UDim2.new(0.5, -210, 0.5, -250)
ShopFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
ShopFrame.BackgroundTransparency = 0.05
ShopFrame.BorderSizePixel  = 0
ShopFrame.Visible          = false
ShopFrame.ZIndex           = 10
ShopFrame.Parent           = ScreenGui
Instance.new("UICorner", ShopFrame).CornerRadius = UDim.new(0, 12)

-- Titel
local TitleLbl             = Instance.new("TextLabel")
TitleLbl.Size              = UDim2.new(1, -50, 0, 40)
TitleLbl.Position          = UDim2.new(0, 10, 0, 5)
TitleLbl.Text              = "Ethereal Summit – Shop"
TitleLbl.TextColor3        = Color3.fromRGB(255, 220, 80)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Font              = Enum.Font.GothamBold
TitleLbl.TextSize          = 20
TitleLbl.ZIndex            = 11
TitleLbl.Parent            = ShopFrame

-- Schliessen-Button
local CloseBtn             = Instance.new("TextButton")
CloseBtn.Size              = UDim2.new(0, 36, 0, 36)
CloseBtn.Position          = UDim2.new(1, -42, 0, 4)
CloseBtn.Text              = "X"
CloseBtn.TextColor3        = Color3.fromRGB(255, 100, 100)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Font              = Enum.Font.GothamBold
CloseBtn.TextSize          = 18
CloseBtn.ZIndex            = 11
CloseBtn.Parent            = ShopFrame

-- Tab-Buttons
local Tabs = {}
local tabNames = {"Upgrades", "Inseln", "Robux"}
local tabFrames = {}
local activeTab = "Upgrades"

local tabBar           = Instance.new("Frame")
tabBar.Size            = UDim2.new(1, -20, 0, 36)
tabBar.Position        = UDim2.new(0, 10, 0, 48)
tabBar.BackgroundTransparency = 1
tabBar.ZIndex          = 11
tabBar.Parent          = ShopFrame

for i, tabName in ipairs(tabNames) do
	local btn              = Instance.new("TextButton")
	btn.Name               = tabName
	btn.Size               = UDim2.new(0, 120, 1, 0)
	btn.Position           = UDim2.new(0, (i-1)*128, 0, 0)
	btn.Text               = tabName
	btn.TextColor3         = Color3.fromRGB(200, 200, 200)
	btn.BackgroundColor3   = Color3.fromRGB(30, 30, 50)
	btn.BorderSizePixel    = 0
	btn.Font               = Enum.Font.GothamBold
	btn.TextSize           = 14
	btn.ZIndex             = 11
	btn.Parent             = tabBar
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	Tabs[tabName] = btn
end

-- Scroll-Container fuer Shop-Inhalt
local ScrollFrame          = Instance.new("ScrollingFrame")
ScrollFrame.Size           = UDim2.new(1, -20, 1, -100)
ScrollFrame.Position       = UDim2.new(0, 10, 0, 92)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.ZIndex         = 11
ScrollFrame.Parent         = ShopFrame
Instance.new("UIListLayout", ScrollFrame).Padding = UDim.new(0, 8)

-- ====== Hilfsfunktionen ======

local function formatNumber(n)
	if n >= 1e6 then return string.format("%.1fMio", n/1e6)
	elseif n >= 1e3 then return string.format("%.1fK", n/1e3)
	else return tostring(math.floor(n)) end
end

local function getEvent(name)
	if not EventsFolder then return nil end
	return EventsFolder:FindFirstChild(name)
end

local function makeShopItem(parent, title, subtitle, btnText, btnColor, onClickFn)
	local row              = Instance.new("Frame")
	row.Size               = UDim2.new(1, -10, 0, 64)
	row.BackgroundColor3   = Color3.fromRGB(25, 25, 45)
	row.BorderSizePixel    = 0
	row.ZIndex             = 12
	row.Parent             = parent
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

	local titleLbl         = Instance.new("TextLabel")
	titleLbl.Size          = UDim2.new(0.6, 0, 0.5, 0)
	titleLbl.Position      = UDim2.new(0, 8, 0, 4)
	titleLbl.Text          = title
	titleLbl.TextColor3    = Color3.fromRGB(255, 255, 255)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font          = Enum.Font.GothamBold
	titleLbl.TextSize      = 14
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.ZIndex        = 13
	titleLbl.Parent        = row

	local subLbl           = Instance.new("TextLabel")
	subLbl.Size            = UDim2.new(0.6, 0, 0.5, 0)
	subLbl.Position        = UDim2.new(0, 8, 0.5, 0)
	subLbl.Text            = subtitle
	subLbl.TextColor3      = Color3.fromRGB(160, 160, 180)
	subLbl.BackgroundTransparency = 1
	subLbl.Font            = Enum.Font.Gotham
	subLbl.TextSize        = 12
	subLbl.TextXAlignment  = Enum.TextXAlignment.Left
	subLbl.ZIndex          = 13
	subLbl.Parent          = row

	local btn              = Instance.new("TextButton")
	btn.Size               = UDim2.new(0, 110, 0, 36)
	btn.Position           = UDim2.new(1, -118, 0.5, -18)
	btn.Text               = btnText
	btn.TextColor3         = Color3.fromRGB(255, 255, 255)
	btn.BackgroundColor3   = btnColor or Color3.fromRGB(80, 40, 140)
	btn.Font               = Enum.Font.GothamBold
	btn.TextSize           = 13
	btn.BorderSizePixel    = 0
	btn.ZIndex             = 13
	btn.Parent             = row
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

	btn.MouseButton1Click:Connect(onClickFn)
	return row
end

-- ====== Tab-Inhalte rendern ======

local function clearScroll()
	for _, child in ipairs(ScrollFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
end

local upgradeNames = {
	{ key="pickaxe",   display="Spitzhacke",   desc="Schnelleres Abbauen" },
	{ key="backpack",  display="Rucksack",      desc="Mehr Inventarplatz" },
	{ key="autoMiner", display="Auto-Miner",    desc="Automatisches Abbauen" },
	{ key="sellBoost", display="Verkaufs-Boost",desc="Mehr Coins beim Verkauf" },
}

local function renderUpgradesTab()
	clearScroll()
	if not PlayerData then return end

	for _, upg in ipairs(upgradeNames) do
		local currentLevel = PlayerData.upgrades and PlayerData.upgrades[upg.key] or 1
		local costs        = GameConfig.UPGRADE_COSTS[upg.key] or {}
		local nextLevel    = currentLevel + 1
		local cost         = costs[currentLevel]  -- costs[1] = Preis fuer Stufe 2, etc.
		local maxed        = cost == nil

		local subtitle     = upg.desc .. " (Stufe " .. currentLevel .. ")"
		local btnText      = maxed and "Max" or (formatNumber(cost) .. " Coins")
		local btnColor     = maxed and Color3.fromRGB(60,60,60) or Color3.fromRGB(80,40,140)

		makeShopItem(ScrollFrame, upg.display, subtitle, btnText, btnColor, function()
			if maxed then return end
			local evt = getEvent(RemoteEventsConfig.UPGRADE_PURCHASE)
			if evt then evt:FireServer(upg.key, nextLevel) end
		end)
	end
end

local function renderIslandsTab()
	clearScroll()
	if not PlayerData then return end

	for i = 2, GameConfig.MAX_ISLANDS do
		local island    = IslandData[i]
		local unlocked  = PlayerData.unlockedIslands and PlayerData.unlockedIslands[i]
		local subtitle  = island.description
		local btnText   = unlocked and "Freigeschaltet" or (formatNumber(island.unlockCost) .. " Coins")
		local btnColor  = unlocked and Color3.fromRGB(40,140,60) or Color3.fromRGB(140,80,20)

		makeShopItem(ScrollFrame, island.name, subtitle, btnText, btnColor, function()
			if unlocked then return end
			local evt = getEvent(RemoteEventsConfig.UNLOCK_ISLAND)
			if evt then evt:FireServer(i) end
		end)
	end
end

local function renderRobuxTab()
	clearScroll()

	-- Game Passes
	makeShopItem(ScrollFrame, "VIP Pass", "2x Ressourcen + Gold-Spitzhacke", "299 Robux",
		Color3.fromRGB(200,160,20), function()
			if GameConfig.GAME_PASSES.VIP ~= 0 then
				MarketplaceService:PromptGamePassPurchase(LocalPlayer, GameConfig.GAME_PASSES.VIP)
			end
		end)

	makeShopItem(ScrollFrame, "Auto-Mine Pass", "AFK-Mining ohne aktives Spielen", "499 Robux",
		Color3.fromRGB(20,140,180), function()
			if GameConfig.GAME_PASSES.AUTO_MINE ~= 0 then
				MarketplaceService:PromptGamePassPurchase(LocalPlayer, GameConfig.GAME_PASSES.AUTO_MINE)
			end
		end)

	makeShopItem(ScrollFrame, "Pet Companion", "+15% Glueck bei seltenen Erzen", "199 Robux",
		Color3.fromRGB(160,40,160), function()
			if GameConfig.GAME_PASSES.PET ~= 0 then
				MarketplaceService:PromptGamePassPurchase(LocalPlayer, GameConfig.GAME_PASSES.PET)
			end
		end)

	-- Developer Products
	makeShopItem(ScrollFrame, "Gem Pack S", "100 Edelsteine – Boost deine Zukunft", "50 Robux",
		Color3.fromRGB(40,100,200), function()
			if GameConfig.DEV_PRODUCTS.GEM_SMALL ~= 0 then
				MarketplaceService:PromptProductPurchase(LocalPlayer, GameConfig.DEV_PRODUCTS.GEM_SMALL)
			end
		end)

	makeShopItem(ScrollFrame, "Gem Pack L", "500 Edelsteine – Bester Wert!", "200 Robux",
		Color3.fromRGB(20,60,180), function()
			if GameConfig.DEV_PRODUCTS.GEM_LARGE ~= 0 then
				MarketplaceService:PromptProductPurchase(LocalPlayer, GameConfig.DEV_PRODUCTS.GEM_LARGE)
			end
		end)

	makeShopItem(ScrollFrame, "Coin Boost x3", "3-fache Coins fuer 1 Stunde", "75 Robux",
		Color3.fromRGB(180,120,20), function()
			if GameConfig.DEV_PRODUCTS.COIN_BOOST ~= 0 then
				MarketplaceService:PromptProductPurchase(LocalPlayer, GameConfig.DEV_PRODUCTS.COIN_BOOST)
			end
		end)

	-- Gems gegen Coins tauschen
	makeShopItem(ScrollFrame, "Gems tauschen", "1 Gem = " .. GameConfig.GEM_TO_COIN_RATE .. " Coins", "100 Gems → Coins",
		Color3.fromRGB(60,160,80), function()
			local evt = getEvent(RemoteEventsConfig.USE_GEMS)
			if evt then evt:FireServer("gem_to_coins", 100) end
		end)
end

-- Tab wechseln
local function switchTab(tabName)
	activeTab = tabName
	for name, btn in pairs(Tabs) do
		btn.BackgroundColor3 = name == tabName
			and Color3.fromRGB(80, 40, 140)
			or  Color3.fromRGB(30, 30, 50)
		btn.TextColor3 = name == tabName
			and Color3.fromRGB(255,255,255)
			or  Color3.fromRGB(180,180,180)
	end
	if tabName == "Upgrades" then renderUpgradesTab()
	elseif tabName == "Inseln" then renderIslandsTab()
	elseif tabName == "Robux" then renderRobuxTab()
	end
end

for _, tabName in ipairs(tabNames) do
	Tabs[tabName].MouseButton1Click:Connect(function()
		switchTab(tabName)
	end)
end

-- Shop oeffnen/schliessen
local function toggleShop()
	local visible = not ShopFrame.Visible
	ShopFrame.Visible = visible
	if visible then
		switchTab(activeTab)
		ShopFrame.Size = UDim2.new(0, 0, 0, 0)
		ShopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		TweenService:Create(ShopFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size     = UDim2.new(0, 420, 0, 500),
			Position = UDim2.new(0.5, -210, 0.5, -250),
		}):Play()
	end
end

CloseBtn.MouseButton1Click:Connect(function() ShopFrame.Visible = false end)
_G.EtherealToggleShop = toggleShop

-- Spieler-Daten aus UIManager uebernehmen (polling via Shared)
task.spawn(function()
	EventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	if not EventsFolder then return end

	local pdEvt = EventsFolder:WaitForChild(RemoteEventsConfig.PLAYER_DATA_LOADED, 10)
	if pdEvt then
		pdEvt.OnClientEvent:Connect(function(data)
			PlayerData = data
		end)
	end

	-- Upgrade-Bestaetigung aktualisiert lokale Daten
	local upgradeEvt = EventsFolder:FindFirstChild(RemoteEventsConfig.UPGRADE_CONFIRMED)
	if upgradeEvt then
		upgradeEvt.OnClientEvent:Connect(function(upgradeType, newLevel, newCoins)
			if PlayerData then
				if not PlayerData.upgrades then PlayerData.upgrades = {} end
				PlayerData.upgrades[upgradeType] = newLevel
				PlayerData.coins = newCoins
				if ShopFrame.Visible and activeTab == "Upgrades" then
					renderUpgradesTab()
				end
			end
		end)
	end

	-- Insel-Unlock aktualisiert lokale Daten
	local islandEvt = EventsFolder:FindFirstChild(RemoteEventsConfig.ISLAND_UNLOCKED)
	if islandEvt then
		islandEvt.OnClientEvent:Connect(function(islandIndex, _)
			if PlayerData then
				if not PlayerData.unlockedIslands then PlayerData.unlockedIslands = {} end
				PlayerData.unlockedIslands[islandIndex] = true
				if ShopFrame.Visible and activeTab == "Inseln" then
					renderIslandsTab()
				end
			end
		end)
	end
end)
