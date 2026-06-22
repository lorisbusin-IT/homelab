-- Ethereal Summit – PlayerController v3
-- Zuverlaessige Ore-Synchronisierung: Client fragt Erze aktiv an (REQUEST_ORES).
local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local RE           = require(ReplicatedStorage.Modules.RemoteEvents)
local ResourceData = require(ReplicatedStorage.Modules.ResourceData)

local LocalPlayer   = Players.LocalPlayer
local EventsFolder  = nil
local OreNodes      = {}   -- { [oreId] = { position, resource, part, hpLabel } }
local lastMineTime  = 0
local MINE_COOLDOWN = 0.4

-- =============================================
-- WARTEN BIS REMOTEEVENTS DA SIND
-- =============================================
EventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 30)
if not EventsFolder then
	warn("[PlayerController] RemoteEvents nicht gefunden!")
	return
end

local function getEv(name)
	return EventsFolder:FindFirstChild(name)
end

-- =============================================
-- ORE PART ERSTELLEN (gluehend, gross, sichtbar)
-- =============================================
local function makeOrePart(oreId, position, resource, isLucky, isBoss)
	local resData = ResourceData[resource]
	if not resData then return nil end

	-- Groesse basierend auf Typ
	local baseSize = isBoss and 5 or isLucky and 4 or 3.5
	local part = Instance.new("Part")
	part.Name     = "Ore_" .. oreId
	part.Size     = Vector3.new(baseSize, baseSize, baseSize)
	part.Position = position
	part.Anchored = true
	part.CastShadow = false
	part.Material = isBoss and Enum.Material.Neon
	             or isLucky and Enum.Material.Neon
	             or Enum.Material.SmoothPlastic

	-- Farbe
	if isBoss then
		part.Color = Color3.fromRGB(180, 0, 255)
	elseif isLucky then
		part.Color = Color3.fromRGB(255, 215, 0)
	else
		local ok, bc = pcall(BrickColor.new, resData.color)
		part.BrickColor = ok and bc or BrickColor.new("Medium stone grey")
	end

	-- Leuchten (PointLight)
	local light = Instance.new("PointLight")
	light.Brightness = isBoss and 4 or isLucky and 3 or 1.2
	light.Range      = isBoss and 20 or isLucky and 16 or 10
	light.Color      = part.Color
	light.Parent     = part

	-- HP-Anzeige (BillboardGui)
	local bg = Instance.new("BillboardGui")
	bg.Name        = "OreHPGui"
	bg.Size        = UDim2.new(0, 80, 0, 14)
	bg.StudsOffset = Vector3.new(0, baseSize / 2 + 1.5, 0)
	bg.AlwaysOnTop = false
	bg.Parent      = part

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1,0,1,0)
	barBg.BackgroundColor3 = Color3.fromRGB(30,30,30)
	barBg.BorderSizePixel = 0
	barBg.Parent = bg
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = barBg

	local bar = Instance.new("Frame")
	bar.Name = "HPBar"
	bar.Size = UDim2.new(1,0,1,0)
	bar.BackgroundColor3 = isBoss and Color3.fromRGB(180,0,255)
	                    or isLucky and Color3.fromRGB(255,200,0)
	                    or Color3.fromRGB(80,220,80)
	bar.BorderSizePixel = 0
	bar.Parent = barBg
	local corner2 = Instance.new("UICorner")
	corner2.CornerRadius = UDim.new(1, 0)
	corner2.Parent = bar

	-- Ressourcenname
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 100, 0, 16)
	label.Position = UDim2.new(0.5, -50, 1, 3)
	label.BackgroundTransparency = 1
	label.Text = (isLucky and "⭐ " or "") .. resource
	label.TextColor3 = Color3.fromRGB(255,255,255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.4
	label.Parent = bg

	-- ProximityPrompt (Mobile + Hinweis)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Abbauen"
	prompt.ObjectText = (isBoss and "👑 Boss" or isLucky and "⭐ Lucky" or "") .. " " .. resource
	prompt.MaxActivationDistance = 14
	prompt.HoldDuration = 0
	prompt.Parent = part
	prompt.Triggered:Connect(function(triggeringPlayer)
		if triggeringPlayer == LocalPlayer then
			local ev = getEv(RE.MINE_ORE)
			if ev then ev:FireServer(oreId) end
		end
	end)

	part.Parent = workspace
	return part, bar
end

-- =============================================
-- ORE REGISTRIEREN
-- =============================================
local function registerOre(oreId, islandIndex, position, resource, maxHp, isLucky, isBoss)
	if OreNodes[oreId] then return end  -- bereits bekannt

	local part, hpBar = makeOrePart(oreId, position, resource, isLucky, isBoss)
	OreNodes[oreId] = {
		position   = position,
		resource   = resource,
		islandIdx  = islandIndex,
		hp         = maxHp,
		maxHp      = maxHp,
		part       = part,
		hpBar      = hpBar,
	}
end

-- =============================================
-- ORE ENTFERNEN (Animation)
-- =============================================
local function removeOre(oreId)
	local node = OreNodes[oreId]
	if not node then return end
	OreNodes[oreId] = nil
	if node.part and node.part.Parent then
		local t = TweenService:Create(
			node.part,
			TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Size = Vector3.new(0.05,0.05,0.05), Transparency = 1 }
		)
		t:Play()
		t.Completed:Connect(function()
			if node.part and node.part.Parent then node.part:Destroy() end
		end)
	end
end

-- =============================================
-- HP BAR UPDATEN (beim Treffer blinken)
-- =============================================
local function updateOreHP(oreId, hpFraction)
	local node = OreNodes[oreId]
	if not node or not node.hpBar then return end
	TweenService:Create(node.hpBar, TweenInfo.new(0.1), { Size = UDim2.new(hpFraction,0,1,0) }):Play()
	-- Part kurz aufblitzen
	if node.part then
		node.part.Transparency = 0.4
		task.delay(0.08, function()
			if node.part and node.part.Parent then node.part.Transparency = 0 end
		end)
	end
end

-- =============================================
-- NÄCHSTES ERZ FINDEN
-- =============================================
local function getNearestOre()
	local char = LocalPlayer.Character
	if not char then return nil end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local pos = root.Position
	local bestId, bestDist = nil, 14

	for oreId, node in pairs(OreNodes) do
		if node.position then
			local d = (node.position - pos).Magnitude
			if d < bestDist then bestDist = d; bestId = oreId end
		end
	end
	return bestId
end

-- =============================================
-- MINE INPUT
-- =============================================
local function onMineInput()
	local now = os.clock()
	if now - lastMineTime < MINE_COOLDOWN then return end
	local oreId = getNearestOre()
	if not oreId then return end
	lastMineTime = now
	-- Blink-Feedback
	local node = OreNodes[oreId]
	if node and node.part then
		node.part.Transparency = 0.5
		task.delay(0.08, function()
			if node.part and node.part.Parent then node.part.Transparency = 0 end
		end)
	end
	local ev = getEv(RE.MINE_ORE)
	if ev then ev:FireServer(oreId) end
end

_G.EtherealMineInput = onMineInput

-- =============================================
-- EVENTS VERBINDEN
-- =============================================
local spawnEvt  = getEv(RE.SPAWN_ORE)
local removeEvt = getEv(RE.REMOVE_ORE)
local oresDataEvt = getEv(RE.ORES_DATA)
local oreMined  = getEv(RE.ORE_MINED)

if spawnEvt then
	spawnEvt.OnClientEvent:Connect(function(oreId, islandIndex, position, resource, maxHp, isLucky, isBoss)
		registerOre(oreId, islandIndex, position, resource, maxHp, isLucky or false, isBoss or false)
	end)
end

if removeEvt then
	removeEvt.OnClientEvent:Connect(removeOre)
end

-- ORE_MINED: HP-Bar updaten wenn Ore getroffen aber nicht zerstoert
if oreMined then
	oreMined.OnClientEvent:Connect(function(oreId, resource, amount, coinsGained)
		local node = OreNodes[oreId]
		if node and node.hp then
			node.hp = math.max(0, node.hp - 1)
			updateOreHP(oreId, node.hp / node.maxHp)
		end
	end)
end

-- ORES_DATA: Server antwortet auf REQUEST_ORES mit allen aktiven Erzen
if oresDataEvt then
	oresDataEvt.OnClientEvent:Connect(function(ores)
		for oreId, node in pairs(ores) do
			registerOre(oreId, node.islandIndex, node.position, node.resource,
				node.maxHp, node.isLucky, node.isBoss)
		end
		print("[PlayerController] " .. (function() local n=0; for _ in pairs(ores) do n=n+1 end; return n end)() .. " Erze geladen.")
	end)
end

-- =============================================
-- INITIALISIERUNG: Erze vom Server anfordern
-- =============================================
task.spawn(function()
	-- Warten bis Character geladen ist
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	char:WaitForChild("HumanoidRootPart", 10)
	task.wait(1.0)  -- Kurz warten damit Server-Initialisierung fertig ist

	-- Erze anfordern (zuverlässiger als auf Server-Push zu warten)
	local reqEvt = getEv(RE.REQUEST_ORES)
	if reqEvt then
		reqEvt:FireServer()
		print("[PlayerController] Erze angefordert...")
	end

	-- Insel-Daten anfordern
	local islandReq = getEv(RE.REQUEST_ISLAND_DATA)
	if islandReq then islandReq:FireServer() end

	-- Spieler-Daten anfordern
	local pdReq = getEv(RE.REQUEST_PLAYER_DATA)
	if pdReq then pdReq:FireServer() end
end)

-- Erze neu anfordern wenn Character respawnt
LocalPlayer.CharacterAdded:Connect(function(char)
	char:WaitForChild("HumanoidRootPart", 10)
	task.wait(0.5)
	-- Alte Ore-Parts aus vorherigem Leben aufraumen (werden neu geladen)
	OreNodes = {}
	local reqEvt = getEv(RE.REQUEST_ORES)
	if reqEvt then reqEvt:FireServer() end
end)

-- =============================================
-- TASTATUR INPUT
-- =============================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.F then
		onMineInput()
	end
end)
