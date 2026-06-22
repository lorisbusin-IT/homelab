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
local tabNames = {"Upgrades", "Inseln", "Pets", "Codes", "Robux"}
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

-- Pet-Daten (vom Server geladen)
local PetData = nil

local function renderPetsTab()
	clearScroll()

	-- Eier-Sektion
	local eggDefs = {
		{ key="common",    name="Normales Ei",    costStr="100 Coins",  color=Color3.fromRGB(160,160,160) },
		{ key="rare",      name="Seltenes Ei",    costStr="500 Gems",   color=Color3.fromRGB(40,100,200)  },
		{ key="legendary", name="Legendaeres Ei", costStr="999 Gems",   color=Color3.fromRGB(200,160,20)  },
	}

	for _, egg in ipairs(eggDefs) do
		makeShopItem(ScrollFrame, egg.name, "Oeffne fuer Pets!", egg.costStr, egg.color, function()
			local evt = getEvent(RemoteEventsConfig.OPEN_PET_EGG)
			if evt then evt:FireServer(egg.key) end
		end)
	end

	-- Eigene Pets anzeigen
	if PetData and PetData.owned then
		for _, pet in ipairs(PetData.owned) do
			local equipped = false
			if PetData.equipped then
				for _, eq in ipairs(PetData.equipped) do
					if eq == pet.id then equipped = true; break end
				end
			end

			local rColors = {
				common="Gewoehnlich", uncommon="Ungewoehnlich",
				rare="Selten", epic="Episch", legendary="LEGENDAER"
			}
			local subtitle = (rColors[pet.rarity] or "?") .. " " .. pet.name .. " – Lv." .. pet.level
			local btnText  = equipped and "Ausgeruestet" or "Equip (Slot 1)"
			local btnColor = equipped and Color3.fromRGB(40,140,60) or Color3.fromRGB(80,40,140)

			makeShopItem(ScrollFrame, pet.name, subtitle, btnText, btnColor, function()
				if not equipped then
					local evt = getEvent(RemoteEventsConfig.EQUIP_PET)
					if evt then evt:FireServer(pet.id, 1) end
				end
			end)
		end
	end

	-- Refresh Pet-Daten anfordern
	local reqEvt = getEvent(RemoteEventsConfig.REQUEST_PET_DATA)
	if reqEvt then reqEvt:FireServer() end
end

-- Code-Eingabe Tab
local codeInput = nil

local function renderCodesTab()
	clearScroll()

	-- Code-Eingabefeld
	local inputFrame           = Instance.new("Frame")
	inputFrame.Size            = UDim2.new(1, -10, 0, 80)
	inputFrame.BackgroundColor3= Color3.fromRGB(25,25,45)
	inputFrame.BorderSizePixel = 0
	inputFrame.ZIndex          = 12
	inputFrame.Parent          = ScrollFrame
	Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0, 8)

	local lbl                  = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(1, -10, 0, 24)
	lbl.Position               = UDim2.new(0, 8, 0, 6)
	lbl.Text                   = "Promo-Code eingeben:"
	lbl.TextColor3             = Color3.fromRGB(200,200,200)
	lbl.BackgroundTransparency = 1
	lbl.Font                   = Enum.Font.Gotham
	lbl.TextSize               = 14
	lbl.TextXAlignment         = Enum.TextXAlignment.Left
	lbl.ZIndex                 = 13
	lbl.Parent                 = inputFrame

	codeInput                  = Instance.new("TextBox")
	codeInput.Size             = UDim2.new(0.65, -5, 0, 30)
	codeInput.Position         = UDim2.new(0, 8, 0, 34)
	codeInput.Text             = ""
	codeInput.PlaceholderText  = "z.B. ETHEREAL100"
	codeInput.TextColor3       = Color3.fromRGB(255,255,255)
	codeInput.BackgroundColor3 = Color3.fromRGB(40,40,60)
	codeInput.Font             = Enum.Font.GothamBold
	codeInput.TextSize         = 15
	codeInput.BorderSizePixel  = 0
	codeInput.ZIndex           = 13
	codeInput.Parent           = inputFrame
	Instance.new("UICorner", codeInput).CornerRadius = UDim.new(0, 6)

	local redeemBtn            = Instance.new("TextButton")
	redeemBtn.Size             = UDim2.new(0.33, -5, 0, 30)
	redeemBtn.Position         = UDim2.new(0.67, 0, 0, 34)
	redeemBtn.Text             = "Einloesen"
	redeemBtn.TextColor3       = Color3.fromRGB(255,255,255)
	redeemBtn.BackgroundColor3 = Color3.fromRGB(40,140,60)
	redeemBtn.Font             = Enum.Font.GothamBold
	redeemBtn.TextSize         = 14
	redeemBtn.BorderSizePixel  = 0
	redeemBtn.ZIndex           = 13
	redeemBtn.Parent           = inputFrame
	Instance.new("UICorner", redeemBtn).CornerRadius = UDim.new(0, 6)

	redeemBtn.MouseButton1Click:Connect(function()
		local code = codeInput.Text
		if #code < 3 then return end
		local evt = getEvent(RemoteEventsConfig.REDEEM_CODE)
		if evt then evt:FireServer(code) end
		codeInput.Text = ""
	end)

	-- Bekannte Codes als Hinweis
	local hintLbl              = Instance.new("TextLabel")
	hintLbl.Size               = UDim2.new(1, -10, 0, 40)
	hintLbl.BackgroundTransparency = 1
	hintLbl.Text               = "Tipp: Folge uns auf Social Media\nfuer exklusive Codes!"
	hintLbl.TextColor3         = Color3.fromRGB(140,140,160)
	hintLbl.Font               = Enum.Font.Gotham
	hintLbl.TextSize           = 13
	hintLbl.TextXAlignment     = Enum.TextXAlignment.Left
	hintLbl.ZIndex             = 12
	hintLbl.Parent             = ScrollFrame
	Instance.new("UICorner", hintLbl)
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
	elseif tabName == "Pets"   then renderPetsTab()
	elseif tabName == "Codes"  then renderCodesTab()
	elseif tabName == "Robux"  then renderRobuxTab()
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

	-- Pet-Daten empfangen und Pets-Tab aktualisieren
	local petDataEvt = EventsFolder:FindFirstChild(RemoteEventsConfig.PET_DATA_RESPONSE)
	if petDataEvt then
		petDataEvt.OnClientEvent:Connect(function(data)
			PetData = data
			if ShopFrame.Visible and activeTab == "Pets" then
				renderPetsTab()
			end
		end)
	end

	-- Pet equipped: Pets-Tab neu rendern
	local petEquippedEvt = EventsFolder:FindFirstChild(RemoteEventsConfig.PET_EQUIPPED)
	if petEquippedEvt then
		petEquippedEvt.OnClientEvent:Connect(function(slot, petId, petInfo)
			if PetData then
				if not PetData.equipped then PetData.equipped = {} end
				PetData.equipped[slot] = petId
			end
			if ShopFrame.Visible and activeTab == "Pets" then
				renderPetsTab()
			end
		end)
	end

	-- Code-Ergebnis: Toast anzeigen
	local codeResultEvt = EventsFolder:FindFirstChild(RemoteEventsConfig.CODE_RESULT)
	if codeResultEvt then
		codeResultEvt.OnClientEvent:Connect(function(success, message)
			local toast        = Instance.new("TextLabel")
			toast.Size         = UDim2.new(0, 280, 0, 44)
			toast.Position     = UDim2.new(0.5, -140, 0, 80)
			toast.Text         = message or (success and "Code eingeloest!" or "Ungültiger Code")
			toast.TextColor3   = Color3.fromRGB(255, 255, 255)
			toast.BackgroundColor3 = success
				and Color3.fromRGB(30, 140, 60)
				or  Color3.fromRGB(160, 40, 40)
			toast.BackgroundTransparency = 0.1
			toast.Font         = Enum.Font.GothamBold
			toast.TextSize     = 15
			toast.BorderSizePixel = 0
			toast.ZIndex       = 30
			toast.Parent       = ScreenGui
			Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 8)

			TweenService:Create(toast, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
				0, false, 2.0), { TextTransparency=1, BackgroundTransparency=1 }):Play()
			task.delay(2.6, function() if toast.Parent then toast:Destroy() end end)
		end)
	end

	-- Quest-Panel (einfache Overlay-Liste)
	local QuestPanel       = Instance.new("Frame")
	QuestPanel.Name        = "QuestPanel"
	QuestPanel.Size        = UDim2.new(0, 340, 0, 420)
	QuestPanel.Position    = UDim2.new(0, 10, 0.5, -210)
	QuestPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
	QuestPanel.BackgroundTransparency = 0.05
	QuestPanel.BorderSizePixel = 0
	QuestPanel.Visible     = false
	QuestPanel.ZIndex      = 10
	QuestPanel.Parent      = ScreenGui
	Instance.new("UICorner", QuestPanel).CornerRadius = UDim.new(0, 12)

	local qTitle           = Instance.new("TextLabel")
	qTitle.Size            = UDim2.new(1, -44, 0, 36)
	qTitle.Position        = UDim2.new(0, 10, 0, 4)
	qTitle.Text            = "Quests"
	qTitle.TextColor3      = Color3.fromRGB(255, 220, 80)
	qTitle.BackgroundTransparency = 1
	qTitle.Font            = Enum.Font.GothamBold
	qTitle.TextSize        = 18
	qTitle.ZIndex          = 11
	qTitle.Parent          = QuestPanel

	local qClose           = Instance.new("TextButton")
	qClose.Size            = UDim2.new(0, 36, 0, 36)
	qClose.Position        = UDim2.new(1, -40, 0, 2)
	qClose.Text            = "X"
	qClose.TextColor3      = Color3.fromRGB(255, 100, 100)
	qClose.BackgroundTransparency = 1
	qClose.Font            = Enum.Font.GothamBold
	qClose.TextSize        = 16
	qClose.ZIndex          = 11
	qClose.Parent          = QuestPanel
	qClose.MouseButton1Click:Connect(function() QuestPanel.Visible = false end)

	local qScroll          = Instance.new("ScrollingFrame")
	qScroll.Size           = UDim2.new(1, -16, 1, -48)
	qScroll.Position       = UDim2.new(0, 8, 0, 44)
	qScroll.BackgroundTransparency = 1
	qScroll.BorderSizePixel = 0
	qScroll.ScrollBarThickness = 4
	qScroll.ZIndex         = 11
	qScroll.Parent         = QuestPanel
	local qLayout          = Instance.new("UIListLayout", qScroll)
	qLayout.Padding        = UDim.new(0, 6)

	local QuestData        = nil

	local function renderQuests()
		for _, c in ipairs(qScroll:GetChildren()) do
			if c:IsA("Frame") then c:Destroy() end
		end
		if not QuestData then return end

		local function makeQuestRow(quest)
			local row              = Instance.new("Frame")
			row.Size               = UDim2.new(1, -6, 0, 72)
			row.BackgroundColor3   = Color3.fromRGB(25, 25, 45)
			row.BorderSizePixel    = 0
			row.ZIndex             = 12
			row.Parent             = qScroll
			Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

			local ql               = Instance.new("TextLabel")
			ql.Size                = UDim2.new(0.65, 0, 0.5, 0)
			ql.Position            = UDim2.new(0, 8, 0, 4)
			ql.Text                = quest.display or quest.id
			ql.TextColor3          = Color3.fromRGB(230, 230, 230)
			ql.BackgroundTransparency = 1
			ql.Font                = Enum.Font.GothamBold
			ql.TextSize            = 13
			ql.TextXAlignment      = Enum.TextXAlignment.Left
			ql.ZIndex              = 13
			ql.Parent              = row

			local prog             = quest.goal and quest.goal > 0
				and tostring(math.min(quest.progress or 0, quest.goal)) .. "/" .. quest.goal
				or "Abgeschlossen"
			local qs               = Instance.new("TextLabel")
			qs.Size                = UDim2.new(0.65, 0, 0.5, 0)
			qs.Position            = UDim2.new(0, 8, 0.5, 0)
			qs.Text                = "Fortschritt: " .. prog
			qs.TextColor3          = Color3.fromRGB(140, 160, 140)
			qs.BackgroundTransparency = 1
			qs.Font                = Enum.Font.Gotham
			qs.TextSize            = 12
			qs.TextXAlignment      = Enum.TextXAlignment.Left
			qs.ZIndex              = 13
			qs.Parent              = row

			local done   = quest.done
			local claimed= quest.claimed
			local claimBtn = Instance.new("TextButton")
			claimBtn.Size  = UDim2.new(0, 90, 0, 30)
			claimBtn.Position = UDim2.new(1, -96, 0.5, -15)
			claimBtn.Text  = claimed and "Erhalten" or (done and "Einloesen" or "Aktiv")
			claimBtn.TextColor3 = Color3.fromRGB(255,255,255)
			claimBtn.BackgroundColor3 = claimed
				and Color3.fromRGB(60,60,60)
				or (done and Color3.fromRGB(40,140,60) or Color3.fromRGB(60,40,100))
			claimBtn.Font  = Enum.Font.GothamBold
			claimBtn.TextSize = 12
			claimBtn.BorderSizePixel = 0
			claimBtn.ZIndex = 13
			claimBtn.Parent = row
			Instance.new("UICorner", claimBtn).CornerRadius = UDim.new(0, 6)

			if done and not claimed then
				claimBtn.MouseButton1Click:Connect(function()
					local evt = EventsFolder and EventsFolder:FindFirstChild(RemoteEventsConfig.CLAIM_QUEST_REWARD)
					if evt then evt:FireServer(quest.id) end
				end)
			end
		end

		local secLbl       = Instance.new("TextLabel")
		secLbl.Size        = UDim2.new(1, 0, 0, 22)
		secLbl.Text        = "Tagesquests"
		secLbl.TextColor3  = Color3.fromRGB(255, 200, 60)
		secLbl.BackgroundTransparency = 1
		secLbl.Font        = Enum.Font.GothamBold
		secLbl.TextSize    = 13
		secLbl.ZIndex      = 12
		secLbl.Parent      = qScroll

		if QuestData.daily then
			for _, q in ipairs(QuestData.daily) do makeQuestRow(q) end
		end

		local secLbl2      = Instance.new("TextLabel")
		secLbl2.Size       = UDim2.new(1, 0, 0, 22)
		secLbl2.Text       = "Wochenquest"
		secLbl2.TextColor3 = Color3.fromRGB(100, 200, 255)
		secLbl2.BackgroundTransparency = 1
		secLbl2.Font       = Enum.Font.GothamBold
		secLbl2.TextSize   = 13
		secLbl2.ZIndex     = 12
		secLbl2.Parent     = qScroll

		if QuestData.weekly then makeQuestRow(QuestData.weekly) end

		qScroll.CanvasSize = UDim2.new(0, 0, 0, qLayout.AbsoluteContentSize.Y + 10)
	end

	-- Quest-Daten empfangen
	local questDataEvt = EventsFolder:FindFirstChild(RemoteEventsConfig.QUEST_DATA_RESPONSE)
	if questDataEvt then
		questDataEvt.OnClientEvent:Connect(function(data)
			QuestData = data
			if QuestPanel.Visible then renderQuests() end
		end)
	end

	-- Quest-Fortschritt live aktualisieren
	local questProgressEvt = EventsFolder:FindFirstChild(RemoteEventsConfig.QUEST_PROGRESS_UPDATE)
	if questProgressEvt then
		questProgressEvt.OnClientEvent:Connect(function(questId, progress, done)
			if not QuestData then return end
			if QuestData.daily then
				for _, q in ipairs(QuestData.daily) do
					if q.id == questId then q.progress = progress; q.done = done; break end
				end
			end
			if QuestData.weekly and QuestData.weekly.id == questId then
				QuestData.weekly.progress = progress
				QuestData.weekly.done = done
			end
			if QuestPanel.Visible then renderQuests() end
		end)
	end

	_G.EtherealToggleQuests = function()
		QuestPanel.Visible = not QuestPanel.Visible
		if QuestPanel.Visible then
			local reqEvt = EventsFolder:FindFirstChild(RemoteEventsConfig.REQUEST_QUEST_DATA)
			if reqEvt then reqEvt:FireServer() end
			renderQuests()
		end
	end
end)
