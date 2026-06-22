-- Ethereal Summit – Leaderboard-System (Server)
local DataStoreService = game:GetService("DataStoreService")
local GameConfig       = require(game.ReplicatedStorage.Modules.GameConfig)

local LeaderboardSystem = {}

local Boards = {
	topCoins  = DataStoreService:GetOrderedDataStore("EtherealSummit_TopCoins_v1"),
	topIsland = DataStoreService:GetOrderedDataStore("EtherealSummit_TopIsland_v1"),
	topOres   = DataStoreService:GetOrderedDataStore("EtherealSummit_TopOres_v1"),
}

local PlayerNames = {}  -- { [userId] = displayName }

-- Spieler-Score in allen Boards aktualisieren
function LeaderboardSystem.updatePlayer(player, data)
	if not data or not data.stats then return end

	PlayerNames[player.UserId] = player.DisplayName

	pcall(function()
		Boards.topCoins:SetAsync(tostring(player.UserId), data.stats.totalCoinsEarned or 0)
	end)
	pcall(function()
		Boards.topIsland:SetAsync(tostring(player.UserId), data.highestIsland or 1)
	end)
	pcall(function()
		Boards.topOres:SetAsync(tostring(player.UserId), data.stats.totalOresMined or 0)
	end)
end

-- Top-N Eintraege aus einem Board lesen
local function getTopEntries(board, count)
	local success, pages = pcall(function()
		return board:GetSortedAsync(false, count)
	end)

	if not success then return {} end

	local entries = {}
	local ok, data = pcall(function()
		return pages:GetCurrentPage()
	end)

	if ok and data then
		for _, entry in ipairs(data) do
			table.insert(entries, {
				userId = entry.key,
				name   = PlayerNames[tonumber(entry.key)] or "Spieler",
				value  = entry.value,
			})
		end
	end

	return entries
end

-- Leaderboard-Daten zusammenstellen und an alle Clients senden
function LeaderboardSystem.broadcastLeaderboard(eventsFolder)
	local leaderboardData = {
		topCoins  = getTopEntries(Boards.topCoins,  GameConfig.LEADERBOARD_TOP_COUNT),
		topIsland = getTopEntries(Boards.topIsland, GameConfig.LEADERBOARD_TOP_COUNT),
		topOres   = getTopEntries(Boards.topOres,   GameConfig.LEADERBOARD_TOP_COUNT),
	}

	if eventsFolder then
		local evt = eventsFolder:FindFirstChild("UpdateLeaderboard")
		if evt then
			evt:FireAllClients(leaderboardData)
		end
	end
end

-- Spieler-Namen fuer bekannte UserIds vorausfuellen
function LeaderboardSystem.cachePlayerName(player)
	PlayerNames[player.UserId] = player.DisplayName
end

return LeaderboardSystem
