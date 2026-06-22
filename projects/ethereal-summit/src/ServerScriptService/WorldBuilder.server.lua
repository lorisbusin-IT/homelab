-- Ethereal Summit – WorldBuilder v2
-- Erstellt alle 10 Inseln mit Barrieren, Beleuchtung, Jump Pads und Erzpositionen.
local TweenService = game:GetService("TweenService")
local Lighting     = game:GetService("Lighting")
local IslandData   = require(game.ReplicatedStorage.Modules.IslandData)

math.randomseed(12345)

-- =============================================
-- ISLAND SETTINGS
-- =============================================
local ISLAND_COLORS = {
	[1]  = Color3.fromRGB(130, 110,  90),
	[2]  = Color3.fromRGB( 70, 150, 210),
	[3]  = Color3.fromRGB(150, 150, 185),
	[4]  = Color3.fromRGB(110,  75, 210),
	[5]  = Color3.fromRGB(200, 220, 255),
	[6]  = Color3.fromRGB( 45,  65, 155),
	[7]  = Color3.fromRGB(150, 185, 255),
	[8]  = Color3.fromRGB(185, 150, 255),
	[9]  = Color3.fromRGB(255, 195,  70),
	[10] = Color3.fromRGB(215,  80, 255),
}
local ISLAND_MATERIALS = {
	[1]=Enum.Material.SmoothPlastic, [2]=Enum.Material.Neon,
	[3]=Enum.Material.Marble,        [4]=Enum.Material.Neon,
	[5]=Enum.Material.SmoothPlastic, [6]=Enum.Material.Slate,
	[7]=Enum.Material.Marble,        [8]=Enum.Material.Neon,
	[9]=Enum.Material.Neon,          [10]=Enum.Material.Neon,
}
-- Groessere Inseln = mehr Platz zum Laufen
local ISLAND_SIZES = {
	[1]=90, [2]=80, [3]=75, [4]=78, [5]=85,
	[6]=80, [7]=85, [8]=90, [9]=95, [10]=100,
}
local PLATFORM_THICKNESS = 12
local BARRIER_HEIGHT      = 8   -- Unsichtbare Barriere am Rand

-- =============================================
-- LIGHTING
-- =============================================
Lighting.Brightness           = 1.0
Lighting.ClockTime            = 20
Lighting.FogColor             = Color3.fromRGB(20, 10, 45)
Lighting.FogEnd               = 2500
Lighting.FogStart             = 1000
Lighting.Ambient              = Color3.fromRGB(50, 30, 70)
Lighting.OutdoorAmbient       = Color3.fromRGB(30, 20, 60)
Lighting.ExposureCompensation = 0.2

local atmo = Instance.new("Atmosphere")
atmo.Density = 0.28
atmo.Offset  = 0.06
atmo.Color   = Color3.fromRGB(50, 30, 90)
atmo.Decay   = Color3.fromRGB(15,  6, 30)
atmo.Glare   = 0.20
atmo.Haze    = 1.0
atmo.Parent  = Lighting

local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.6
bloom.Size      = 22
bloom.Threshold = 0.88
bloom.Parent    = Lighting

local cc = Instance.new("ColorCorrectionEffect")
cc.Brightness  = 0.02
cc.Contrast    = 0.06
cc.Saturation  = 0.20
cc.TintColor   = Color3.fromRGB(140, 110, 195)
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

local function addGlow(parent, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color      = color
	l.Brightness = brightness
	l.Range      = range
	l.Parent     = parent
end

-- 16 Erzpositionen gleichmaessig auf der Inseloberflaeche verteilen
local function makeSpawnPositions(topY, size)
	local positions = {}
	local margin = 12
	local usable = size - margin * 2
	local rows, cols = 4, 4
	local stepX = usable / (cols - 1)
	local stepZ = usable / (rows - 1)
	local x0 = -(usable / 2)
	local z0 = -(usable / 2)
	local oreY = topY + 2

	for r = 0, rows - 1 do
		for c = 0, cols - 1 do
			local jx = (math.random() - 0.5) * 4
			local jz = (math.random() - 0.5) * 4
			table.insert(positions, Vector3.new(x0 + c * stepX + jx, oreY, z0 + r * stepZ + jz))
		end
	end
	return positions
end

-- Inselname + Kosten als schwebendes Schild
local function createSign(island, idx, topY, size)
	local anchor = makePart({
		Name = "Sign_" .. idx, Size = Vector3.new(1,1,1),
		Position = Vector3.new(0, topY + 12, -(size/2 + 3)),
		Anchored = true, Transparency = 1, CanCollide = false,
		Parent = WorldFolder,
	})
	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(0, 360, 0, 100)
	bg.AlwaysOnTop = false
	bg.Parent = anchor

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1,0,1,0)
	frame.BackgroundColor3 = Color3.fromRGB(10, 5, 22)
	frame.BackgroundTransparency = 0.2
	frame.Parent = bg
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1,-10,0.55,0)
	title.Position = UDim2.new(0,5,0.03,0)
	title.BackgroundTransparency = 1
	title.Text = "⛰ Insel " .. idx .. "  ·  " .. island.name
	title.TextColor3 = Color3.fromRGB(225, 205, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1,-10,0.38,0)
	sub.Position = UDim2.new(0,5,0.58,0)
	sub.BackgroundTransparency = 1
	sub.Text = idx == 1 and "Startinsel – kostenlos"
	           or ("💰 " .. island.unlockCost .. " Coins zum Freischalten")
	sub.TextColor3 = Color3.fromRGB(175, 150, 220)
	sub.TextScaled = true
	sub.Font = Enum.Font.Gotham
	sub.Parent = frame
end

-- Unsichtbare Barriere rundum – verhindert Runterfallen
local function createBarriers(topY, size, parent)
	local halfSize = size / 2
	local centerY  = topY + BARRIER_HEIGHT / 2

	local walls = {
		{ pos = Vector3.new(0, centerY, -(halfSize + 1)),  sz = Vector3.new(size + 4, BARRIER_HEIGHT, 2) },
		{ pos = Vector3.new(0, centerY,  (halfSize + 1)),  sz = Vector3.new(size + 4, BARRIER_HEIGHT, 2) },
		{ pos = Vector3.new(-(halfSize + 1), centerY, 0), sz = Vector3.new(2, BARRIER_HEIGHT, size + 4) },
		{ pos = Vector3.new( (halfSize + 1), centerY, 0), sz = Vector3.new(2, BARRIER_HEIGHT, size + 4) },
	}
	for _, w in ipairs(walls) do
		makePart({
			Name = "Barrier", Size = w.sz, Position = w.pos,
			Anchored = true, Transparency = 1, CanCollide = true,
			Parent = parent,
		})
	end
end

-- Sichtbare Gelaender (dekorativ) als niedrige Mauern
local function createRailing(topY, size, color, parent)
	local halfSize = size / 2
	local railY    = topY + 1.5
	local railH    = 3
	local railW    = 2

	local sides = {
		{ pos = Vector3.new(0, railY, -(halfSize - railW/2)),  sz = Vector3.new(size, railH, railW) },
		{ pos = Vector3.new(0, railY,  (halfSize - railW/2)),  sz = Vector3.new(size, railH, railW) },
		{ pos = Vector3.new(-(halfSize - railW/2), railY, 0), sz = Vector3.new(railW, railH, size) },
		{ pos = Vector3.new( (halfSize - railW/2), railY, 0), sz = Vector3.new(railW, railH, size) },
	}
	local railColor = color:Lerp(Color3.new(0,0,0), 0.5)
	for _, s in ipairs(sides) do
		local rail = makePart({
			Name = "Railing", Size = s.sz, Position = s.pos,
			Anchored = true, Color = railColor,
			Material = Enum.Material.Neon,
			Transparency = 0.5, CanCollide = true,
			Parent = parent,
		})
		addGlow(rail, color, 0.4, 15)
	end
end

-- Leuchtendes Jump Pad am Rand der Insel
local function createJumpPad(fromIdx, fromTopY, toTopY, fromSize)
	local padPos = Vector3.new(0, fromTopY + 1.5, fromSize/2 - 6)
	local pad = makePart({
		Name = "JumpPad_" .. fromIdx,
		Size = Vector3.new(10, 1, 10),
		Position = padPos,
		Anchored = true,
		Color = Color3.fromRGB(80, 255, 140),
		Material = Enum.Material.Neon,
		Parent = WorldFolder,
	})
	addGlow(pad, Color3.fromRGB(80, 255, 140), 4, 28)

	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(0, 220, 0, 55)
	bg.StudsOffset = Vector3.new(0, 6, 0)
	bg.Parent = pad
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1,0,1,0)
	lbl.BackgroundTransparency = 1
	lbl.Text = "⬆  Insel " .. (fromIdx + 1)
	lbl.TextColor3 = Color3.fromRGB(80, 255, 140)
	lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBold
	lbl.Parent = bg

	-- Pulsierender Glow
	task.spawn(function()
		local light = pad:FindFirstChildOfClass("PointLight")
		if not light then return end
		local ti = TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		TweenService:Create(light, ti, { Brightness = 8 }):Play()
	end)

	-- Teleport (Debounce pro Charakter)
	local debounce = {}
	pad.Touched:Connect(function(hit)
		local char = hit.Parent
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then return end
		if debounce[char] then return end
		debounce[char] = true
		-- Zur Mitte der naechsten Insel teleportieren
		hrp.CFrame = CFrame.new(0, toTopY + 8, 0)
		task.delay(1.8, function() debounce[char] = nil end)
	end)
end

-- Dekoratives Kristall auf der Inseloberflaeche
local function spawnCrystal(parent, x, topY, z, color, scl)
	local c = makePart({
		Name = "Deco", Size = Vector3.new(scl, scl * 3, scl),
		CFrame = CFrame.new(x, topY + scl * 1.5, z) * CFrame.Angles(0, math.random() * math.pi * 2, 0.1),
		Anchored = true, Color = color, Material = Enum.Material.Neon,
		Parent = parent,
	})
	addGlow(c, color, 0.6, scl * 7)
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

	-- Hauptplattform (Oberflaeche bei topY)
	local platform = makePart({
		Name = "Platform_" .. i,
		Size = Vector3.new(size, PLATFORM_THICKNESS, size),
		Position = Vector3.new(0, centerY, 0),
		Anchored = true, Color = color, Material = mat,
		Parent = folder,
	})
	addGlow(platform, color, 2.0, 100)

	-- Dunklerer Rand
	makePart({
		Name = "PlatformEdge",
		Size = Vector3.new(size + 6, 3, size + 6),
		Position = Vector3.new(0, topY - PLATFORM_THICKNESS + 1.5, 0),
		Anchored = true,
		Color = color:Lerp(Color3.new(0,0,0), 0.4),
		Material = mat,
		Parent = folder,
	})

	-- Unterseite: Stalaktiten
	for s = 1, 6 do
		local sx = (math.random() - 0.5) * (size - 10)
		local sz = (math.random() - 0.5) * (size - 10)
		local sh = math.random(12, 28)
		local sw = math.random(3, 7)
		makePart({
			Name = "Stalactite",
			Size = Vector3.new(sw, sh, sw),
			Position = Vector3.new(sx, centerY - PLATFORM_THICKNESS/2 - sh/2, sz),
			Anchored = true,
			Color = color:Lerp(Color3.new(0,0,0), 0.50),
			Material = mat,
			Parent = folder,
		})
	end

	-- Barrieren (unsichtbar, verhindert Runterfallen)
	createBarriers(topY, size, folder)

	-- Gelaender (sichtbar, dekorativ)
	createRailing(topY, size, color, folder)

	-- Kristalle
	local crystalColor = color:Lerp(Color3.fromRGB(200, 160, 255), 0.6)
	for d = 1, math.random(5, 8) do
		local margin = 14
		local cx = (math.random() - 0.5) * (size - margin * 2)
		local cz = (math.random() - 0.5) * (size - margin * 2)
		spawnCrystal(folder, cx, topY, cz, crystalColor, math.random(1, 2))
	end

	-- Inselschild
	createSign(island, i, topY, size)

	-- SpawnLocation genau in der Mitte von Insel 1
	if i == 1 then
		local sp = Instance.new("SpawnLocation")
		sp.Name     = "SpawnLocation"
		sp.Size     = Vector3.new(8, 1, 8)
		sp.Position = Vector3.new(0, topY + 0.5, 0)
		sp.Anchored = true
		sp.Duration = 0
		sp.Neutral  = true
		sp.Parent   = WorldFolder
	end

	-- Jump Pad zur naechsten Insel
	if i < 10 then
		createJumpPad(i, topY, IslandData[i+1].height, size)
	end

	-- Erzpositionen speichern
	_G.EtherealSpawnPositions[i] = makeSpawnPositions(topY, size)

	print(string.format("[WorldBuilder] Island %d (%s) @ Y=%d  size=%d", i, island.name, topY, size))
end

-- =============================================
-- KILL-FLOOR (Void)
-- =============================================
local kf = makePart({
	Name = "VoidFloor", Size = Vector3.new(5000, 4, 5000),
	Position = Vector3.new(0, -100, 0),
	Anchored = true, Transparency = 1, CanCollide = true,
	Parent = WorldFolder,
})
kf.Touched:Connect(function(hit)
	local h = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
	if h then h.Health = 0 end
end)

-- Baseplate ausblenden falls vorhanden
local bp = workspace:FindFirstChild("Baseplate")
if bp then
	bp.Transparency = 1
	bp.CanCollide   = false
end

-- =============================================
-- FERTIG
-- =============================================
_G.EtherealWorldReady = true
print("[WorldBuilder] Fertig – 10 Inseln generiert!")
