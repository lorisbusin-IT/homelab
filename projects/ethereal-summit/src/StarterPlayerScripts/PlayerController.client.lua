-- Ethereal Summit – Spieler-Controller (Client)
local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")

local RemoteEventsConfig = require(ReplicatedStorage.Modules.RemoteEvents)
local ResourceData       = require(ReplicatedStorage.Modules.ResourceData)

local LocalPlayer  = Players.LocalPlayer
local EventsFolder = nil
local OreNodes     = {}   -- { [oreId] = { position, resource, part } }
local isMining     = false
local lastMineTime = 0
local MINE_COOLDOWN = 0.4  -- Sekunden zwischen Mine-Events (Client-seitig)

-- Warten bis RemoteEvents verfuegbar sind
local function waitForEvents()
	EventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	return EventsFolder ~= nil
end

local function getEvent(name)
	if not EventsFolder then return nil end
	return EventsFolder:FindFirstChild(name)
end

-- Naechsten abbaubaren Ore-Node in Reichweite finden
local function getNearestOre(maxDistance)
	local character = LocalPlayer.Character
	if not character then return nil, nil end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return nil, nil end

	local playerPos  = rootPart.Position
	local bestOreId  = nil
	local bestDist   = maxDistance

	for oreId, node in pairs(OreNodes) do
		if node.position then
			local dist = (node.position - playerPos).Magnitude
			if dist < bestDist then
				bestDist  = dist
				bestOreId = oreId
			end
		end
	end

	return bestOreId, bestDist
end

-- Mining-Event an Server senden
local function sendMineRequest(oreId)
	local now = os.clock()
	if now - lastMineTime < MINE_COOLDOWN then return end
	lastMineTime = now

	local evt = getEvent(RemoteEventsConfig.MINE_ORE)
	if evt then evt:FireServer(oreId) end
end

-- Visuelles Feedback beim Abbau (Partikel / Farbblitz am Ore-Part)
local function playMineEffect(oreId)
	local node = OreNodes[oreId]
	if not node or not node.part then return end

	-- Kurzes Blink-Feedback
	local originalColor = node.part.BrickColor
	node.part.BrickColor = BrickColor.new("Bright yellow")
	task.delay(0.1, function()
		if node.part and node.part.Parent then
			node.part.BrickColor = originalColor
		end
	end)
end

-- Tastendruck / Touch: Mining ausloesen
local function onMineInput()
	local oreId, dist = getNearestOre(12)
	if oreId then
		playMineEffect(oreId)
		sendMineRequest(oreId)
	end
end

-- Server: Neuer Ore-Node spawnen
local function onSpawnOre(oreId, islandIndex, position, resource, maxHp)
	OreNodes[oreId] = {
		position  = position,
		resource  = resource,
		islandIdx = islandIndex,
		hp        = maxHp,
		maxHp     = maxHp,
		part      = nil,
	}

	-- Part in der Welt finden (per Name im Workspace, gesetzt von IslandManager/Platzierung)
	-- Falls kein festes Part existiert, erstellen wir ein visuelles Client-Part
	local resData  = ResourceData[resource]
	if resData then
		local part         = Instance.new("Part")
		part.Name          = "Ore_" .. oreId
		part.Size          = Vector3.new(3, 3, 3)
		part.Position      = position
		part.Anchored      = true
		part.BrickColor    = BrickColor.new(resData.color)
		part.Material      = Enum.Material.SmoothPlastic
		part.CastShadow    = false
		part.Parent        = workspace

		-- ProximityPrompt fuer Mobile-Unterstuetzung
		local prompt           = Instance.new("ProximityPrompt")
		prompt.ActionText      = "Abbauen"
		prompt.ObjectText      = resource
		prompt.MaxActivationDistance = 12
		prompt.HoldDuration    = 0
		prompt.Parent          = part

		prompt.Triggered:Connect(function(triggeringPlayer)
			if triggeringPlayer == LocalPlayer then
				sendMineRequest(oreId)
			end
		end)

		OreNodes[oreId].part = part
	end
end

-- Server: Ore-Node entfernen
local function onRemoveOre(oreId)
	local node = OreNodes[oreId]
	if node then
		if node.part and node.part.Parent then
			-- Kurze Schrumpf-Animation
			local tween = game:GetService("TweenService"):Create(
				node.part,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Size = Vector3.new(0.1, 0.1, 0.1) }
			)
			tween:Play()
			tween.Completed:Connect(function()
				if node.part and node.part.Parent then
					node.part:Destroy()
				end
			end)
		end
		OreNodes[oreId] = nil
	end
end

-- Events verbinden
local function connectEvents()
	local spawnEvt  = getEvent(RemoteEventsConfig.SPAWN_ORE)
	local removeEvt = getEvent(RemoteEventsConfig.REMOVE_ORE)

	if spawnEvt  then spawnEvt.OnClientEvent:Connect(onSpawnOre)  end
	if removeEvt then removeEvt.OnClientEvent:Connect(onRemoveOre) end
end

-- Tastatureingabe
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.E or
	   input.KeyCode == Enum.KeyCode.F then
		onMineInput()
	end
end)

-- Mobile: Touch-Button wird von UIManager erstellt und ruft onMineInput auf
-- Diese Funktion wird global exportiert
_G.EtherealMineInput = onMineInput

-- Initialisierung
task.spawn(function()
	if not waitForEvents() then
		warn("[PlayerController] RemoteEvents nicht gefunden!")
		return
	end
	connectEvents()

	-- Server nach aktuellen Insel-Daten fragen
	local reqEvt = getEvent(RemoteEventsConfig.REQUEST_ISLAND_DATA)
	if reqEvt then reqEvt:FireServer() end
end)
