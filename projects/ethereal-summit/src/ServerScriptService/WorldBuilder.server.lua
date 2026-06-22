-- Ethereal Summit – WorldBuilder
-- Generates all 10 islands, lighting, jump pads, and ore spawn positions.
-- Must run before GameManager reads _G.EtherealSpawnPositions.
local TweenService = game:GetService("TweenService")
local Lighting     = game:GetService("Lighting")
local IslandData   = require(game.ReplicatedStorage.Modules.IslandData)

math.randomseed(os.clock())

-- =============================================
-- ISLAND VISUAL SETTINGS
-- =============================================
local ISLAND_COLORS = {
	[1]  = Color3.fromRGB(120, 105,  90),  -- Ankunft: Sandstein
	[2]  = Color3.fromRGB( 80, 160, 200),  -- Kristallklippe: Eisblau
	[3]  = Color3.fromRGB(160, 160, 190),  -- Nebelgipfel: Grau
	[4]  = Color3.fromRGB(110,  80, 200),  -- Aetherfels: Violett
	[5]  = Color3.fromRGB(210, 225, 255),  -- Wolkenthron: Weissblau
	[6]  = Color3.fromRGB( 50,  70, 150),  -- Sturmpeak: Dunkelblau
	[7]  = Color3.fromRGB(160, 190, 255),  -- Himmelsveste: Hellblau
	[8]  = Color3.fromRGB(190, 160, 255),  -- Ewigkeitsgipfel: Lila
	[9]  = Color3.fromRGB(255, 200,  80),  -- Gottesthron: Gold
	[10] = Color3.fromRGB(220,  90, 255),  -- Etherealer Gipfel: Magenta
}
local ISLAND_MATERIALS = {
	[1]=Enum.Material.SmoothPlastic, [2]=Enum.Material.Neon,
	[3]=Enum.Material.Marble,        [4]=Enum.Material.Neon,
	[5]=Enum.Material.SmoothPlastic, [6]=Enum.Material.Slate,
	[7]=Enum.Material.Marble,        [8]=Enum.Material.Neon,
	[9]=Enum.Material.Neon,          [10]=Enum.Material.Neon,
}
local ISLAND_SIZES = {
	[1]=64, [2]=58, [3]=54, [4]=56, [5]=60,
	[6]=56, [7]=60, [8]=64, [9]=68, [10]=72,
}
local PLATFORM_THICKNESS = 10

-- =============================================
-- LIGHTING & ATMOSPHERE
-- =============================================
Lighting.Brightness         = 1.2
Lighting.ClockTime          = 20
Lighting.FogColor           = Color3.fromRGB(25, 15, 50)
Lighting.FogEnd             = 2200
Lighting.FogStart           = 900
Lighting.Ambient            = Color3.fromRGB(55, 35, 75)
Lighting.OutdoorAmbient     = Color3.fromRGB(35, 25, 65)
Lighting.ExposureCompensation = 0.3

local atmo = Instance.new("Atmosphere")
atmo.Density = 0.30
atmo.Offset  = 0.08
atmo.Color   = Color3.fromRGB(55, 35, 95)
atmo.Decay   = Color3.fromRGB(18,  8, 35)
atmo.Glare   = 0.25
atmo.Haze    = 1.2
atmo.Parent  = Lighting

local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.5
bloom.Size      = 20
bloom.Threshold = 0.90
bloom.Parent    = Lighting

local cc = Instance.new("ColorCorrectionEffect")
cc.Brightness  = 0.03
cc.Contrast    = 0.08
cc.Saturation  = 0.25
cc.TintColor   = Color3.fromRGB(145, 115, 200)
cc.Parent      = Lighting

-- =============================================
-- WORLD FOLDER
-- =============================================
local WorldFolder = Instance.new("Folder")
WorldFolder.Name  = "EtherealWorld"
WorldFolder.Parent = workspace

-- =============================================
-- HELPERS
-- =============================================
local function makePart(props)
	local p = Instance.new("Part")
	for k, v in pairs(props) do p[k] = v end
	p.TopSurface    = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow    = false
	return p
end

local function addLight(parent, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color      = color
	l.Brightness = brightness
	l.Range      = range
	l.Parent     = parent
end

-- Generate 16 ore spawn positions spread across the island top surface
local function makeSpawnPositions(topY, size)
	local positions = {}
	local margin = 8
	local usable = size - margin * 2
	local rows, cols = 4, 4
	local stepX = usable / (cols - 1)
	local stepZ = usable / (rows - 1)
	local x0    = -(usable / 2)
	local z0    = -(usable / 2)
	local oreY  = topY + 2  -- ores sit on top of the surface

	for r = 0, rows - 1 do
		for c = 0, cols - 1 do
			local jx = (math.random() - 0.5) * 3.5
			local jz = (math.random() - 0.5) * 3.5
			table.insert(positions, Vector3.new(
				x0 + c * stepX + jx,
				oreY,
				z0 + r * stepZ + jz
			))
		end
	end
	return positions  -- 16 positions
end

-- Island name sign (BillboardGui above the platform edge)
local function createSign(island, idx, topY, size)
	local anchor = makePart({
		Name         = "SignAnchor_" .. idx,
		Size         = Vector3.new(1, 1, 1),
		Position     = Vector3.new(0, topY + 10, -(size / 2 + 2)),
		Anchored     = true,
		Transparency = 1,
		CanCollide   = false,
		Parent       = WorldFolder,
	})

	local bg = Instance.new("BillboardGui")
	bg.Size         = UDim2.new(0, 340, 0, 90)
	bg.StudsOffset  = Vector3.new(0, 0, 0)
	bg.AlwaysOnTop  = false
	bg.Parent       = anchor

	local frame = Instance.new("Frame")
	frame.Size                   = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3       = Color3.fromRGB(12, 6, 28)
	frame.BackgroundTransparency = 0.25
	frame.Parent                 = bg
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size                = UDim2.new(1, -8, 0.58, 0)
	title.Position            = UDim2.new(0, 4, 0.04, 0)
	title.BackgroundTransparency = 1
	title.Text                = "Insel " .. idx .. "  ·  " .. island.name
	title.TextColor3          = Color3.fromRGB(220, 200, 255)
	title.TextScaled          = true
	title.Font                = Enum.Font.GothamBold
	title.Parent              = frame

	local sub = Instance.new("TextLabel")
	sub.Size                  = UDim2.new(1, -8, 0.36, 0)
	sub.Position              = UDim2.new(0, 4, 0.62, 0)
	sub.BackgroundTransparency = 1
	sub.Text                  = idx == 1 and "Startinsel – kostenlos"
	                            or ("Freischalten: " .. island.unlockCost .. " Coins")
	sub.TextColor3            = Color3.fromRGB(170, 145, 215)
	sub.TextScaled            = true
	sub.Font                  = Enum.Font.Gotham
	sub.Parent                = frame
end

-- Jump pad that teleports the player up to the next island
local function createJumpPad(fromIdx, fromTopY, toTopY, fromSize)
	local padPos = Vector3.new(fromSize / 2 - 5, fromTopY + 0.5, 0)
	local pad = makePart({
		Name     = "JumpPad_" .. fromIdx,
		Size     = Vector3.new(8, 1, 8),
		Position = padPos,
		Anchored = true,
		Color    = Color3.fromRGB(80, 255, 140),
		Material = Enum.Material.Neon,
		Parent   = WorldFolder,
	})
	addLight(pad, Color3.fromRGB(80, 255, 140), 3, 22)

	local bg = Instance.new("BillboardGui")
	bg.Size        = UDim2.new(0, 200, 0, 50)
	bg.StudsOffset = Vector3.new(0, 5, 0)
	bg.Parent      = pad
	local lbl = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text                   = "⬆  Insel " .. (fromIdx + 1)
	lbl.TextColor3             = Color3.fromRGB(80, 255, 140)
	lbl.TextScaled             = true
	lbl.Font                   = Enum.Font.GothamBold
	lbl.Parent                 = bg

	-- Pulsing glow
	task.spawn(function()
		local light = pad:FindFirstChildOfClass("PointLight")
		if not light then return end
		local ti = TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		TweenService:Create(light, ti, { Brightness = 6 }):Play()
	end)

	-- Teleport on touch (debounced per character)
	local debounce = {}
	pad.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end
		local hrp      = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not hrp or not humanoid or humanoid.Health <= 0 then return end
		if debounce[character] then return end
		debounce[character] = true
		hrp.CFrame = CFrame.new(0, toTopY + 6, 0)
		task.delay(1.5, function() debounce[character] = nil end)
	end)
end

-- Small decorative crystal spike
local function spawnCrystal(parent, x, topY, z, color, scl)
	local c = makePart({
		Name     = "Deco",
		Size     = Vector3.new(scl, scl * 2.8, scl),
		CFrame   = CFrame.new(x, topY + scl * 1.4, z) * CFrame.Angles(0, math.random() * math.pi * 2, 0),
		Anchored = true,
		Color    = color,
		Material = Enum.Material.Neon,
		Parent   = parent,
	})
	addLight(c, color, 0.7, scl * 7)
end

-- =============================================
-- BUILD ISLANDS
-- =============================================
_G.EtherealSpawnPositions = {}

for i = 1, 10 do
	local island  = IslandData[i]
	local topY    = island.height
	local size    = ISLAND_SIZES[i]
	local color   = ISLAND_COLORS[i]
	local mat     = ISLAND_MATERIALS[i]
	local centerY = topY - PLATFORM_THICKNESS / 2

	local folder = Instance.new("Folder")
	folder.Name  = "Island_" .. i
	folder.Parent = WorldFolder

	-- Main platform
	local platform = makePart({
		Name     = "Platform_" .. i,
		Size     = Vector3.new(size, PLATFORM_THICKNESS, size),
		Position = Vector3.new(0, centerY, 0),
		Anchored = true,
		Color    = color,
		Material = mat,
		Parent   = folder,
	})
	addLight(platform, color, 1.8, 90)

	-- Slightly darker border ring
	makePart({
		Name     = "PlatformBorder_" .. i,
		Size     = Vector3.new(size + 5, 2.5, size + 5),
		Position = Vector3.new(0, topY - PLATFORM_THICKNESS + 1.25, 0),
		Anchored = true,
		Color    = color:Lerp(Color3.new(0, 0, 0), 0.35),
		Material = mat,
		Parent   = folder,
	})

	-- Stalactites (underside decoration)
	for s = 1, 5 do
		local sx  = (math.random() - 0.5) * (size - 10)
		local sz  = (math.random() - 0.5) * (size - 10)
		local sh  = math.random(10, 22)
		local sw  = math.random(3, 6)
		makePart({
			Name     = "Stalactite",
			Size     = Vector3.new(sw, sh, sw),
			Position = Vector3.new(sx, centerY - PLATFORM_THICKNESS / 2 - sh / 2, sz),
			Anchored = true,
			Color    = color:Lerp(Color3.new(0, 0, 0), 0.45),
			Material = mat,
			Parent   = folder,
		})
	end

	-- Decorative crystal spikes on surface
	local crystalColor = color:Lerp(Color3.fromRGB(200, 170, 255), 0.55)
	for d = 1, math.random(4, 7) do
		local cx = (math.random() - 0.5) * (size - 14)
		local cz = (math.random() - 0.5) * (size - 14)
		spawnCrystal(folder, cx, topY, cz, crystalColor, math.random(1, 2))
	end

	-- Island name sign
	createSign(island, i, topY, size)

	-- SpawnLocation on Island 1
	if i == 1 then
		local sp = Instance.new("SpawnLocation")
		sp.Name      = "SpawnLocation"
		sp.Size      = Vector3.new(6, 1, 6)
		sp.Position  = Vector3.new(-16, topY + 0.5, 0)
		sp.Anchored  = true
		sp.Duration  = 0
		sp.Neutral   = true
		sp.Parent    = WorldFolder
	end

	-- Jump pad to next island (not on last island)
	if i < 10 then
		createJumpPad(i, topY, IslandData[i + 1].height, size)
	end

	-- Ore spawn positions
	_G.EtherealSpawnPositions[i] = makeSpawnPositions(topY, size)

	print(string.format("[WorldBuilder] Island %d (%s) @ Y=%d  size=%d", i, island.name, topY, size))
end

-- =============================================
-- VOID KILL FLOOR
-- =============================================
local killFloor = makePart({
	Name        = "VoidFloor",
	Size        = Vector3.new(4000, 4, 4000),
	Position    = Vector3.new(0, -80, 0),
	Anchored    = true,
	Transparency = 1,
	CanCollide  = true,
	Parent      = WorldFolder,
})
killFloor.Touched:Connect(function(hit)
	local h = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
	if h then h.Health = 0 end
end)

-- Hide or keep default Baseplate
local bp = workspace:FindFirstChild("Baseplate")
if bp then
	bp.Transparency = 1
	bp.CanCollide   = false
end

-- =============================================
-- SIGNAL READY
-- =============================================
_G.EtherealWorldReady = true
print("[WorldBuilder] Done – 10 islands generated, spawn positions ready.")
