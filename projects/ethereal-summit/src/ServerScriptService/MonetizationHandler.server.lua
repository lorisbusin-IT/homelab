-- Ethereal Summit – Monetarisierung (Server)
-- Dieser Script muss VOR GameManager geladen werden (wird von ihm required)
local MarketplaceService = game:GetService("MarketplaceService")
local Players            = game:GetService("Players")
local GameConfig         = require(game.ReplicatedStorage.Modules.GameConfig)
local DataStoreManager   = require(script.Parent.DataStoreManager)

local MonetizationHandler = {}

-- Sessions-Referenz wird von GameManager gesetzt
local Sessions = nil
function MonetizationHandler.setSessions(s) Sessions = s end

-- Gibt true zurueck wenn Spieler einen bestimmten Game Pass besitzt
function MonetizationHandler.checkGamePass(player, passId)
	if passId == 0 then return false end  -- Noch nicht konfiguriert
	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)
	return success and owns or false
end

-- Alle Passes beim Join pruefen und in der Session speichern
function MonetizationHandler.loadPassesForPlayer(player, session)
	session.passes = {
		vip      = MonetizationHandler.checkGamePass(player, GameConfig.GAME_PASSES.VIP),
		autoMine = MonetizationHandler.checkGamePass(player, GameConfig.GAME_PASSES.AUTO_MINE),
		pet      = MonetizationHandler.checkGamePass(player, GameConfig.GAME_PASSES.PET),
	}
	session.isPremium = player.MembershipType == Enum.MembershipType.Premium

	-- Persistente Passes in den Spieler-Daten speichern
	if session.data then
		session.data.passes = session.passes
	end
end

-- Gesamtmultiplikator fuer einen Spieler berechnen
function MonetizationHandler.getCoinMultiplier(session)
	local mult = 1.0
	if session.passes and session.passes.vip    then mult = mult * GameConfig.VIP_MULTIPLIER     end
	if session.isPremium                         then mult = mult * GameConfig.PREMIUM_MULTIPLIER end

	-- Zeitlicher Boost aktiv?
	if session.data and session.data.boosts then
		if os.time() < session.data.boosts.coinBoostExpiry then
			mult = mult * session.data.boosts.coinBoostMult
		end
	end

	-- Verkauf-Boost Upgrade
	if session.data and session.data.upgrades then
		local lvl = session.data.upgrades.sellBoost or 1
		mult = mult * (GameConfig.SELL_BOOST_MULT[lvl] or 1.0)
	end

	return mult
end

-- Gluecksmultiplikator (beinflusst seltene Erze)
function MonetizationHandler.getLuckBonus(session)
	if session.passes and session.passes.pet then
		return GameConfig.PET_LUCK_BONUS
	end
	return 0
end

-- Receipt-Verarbeitung: Wird von Roblox aufgerufen wenn Kauf abgeschlossen
MarketplaceService.ProcessReceipt = function(receiptInfo)
	-- Doppel-Grant verhindern
	if DataStoreManager.IsReceiptProcessed(tostring(receiptInfo.PurchaseId)) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Spieler hat das Spiel verlassen – spaeter verarbeiten (Roblox retry)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if not Sessions then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local session = Sessions[player.UserId]
	if not session or not session.data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local data       = session.data
	local productId  = receiptInfo.ProductId
	local granted    = false
	local productType = ""

	if productId == GameConfig.DEV_PRODUCTS.GEM_SMALL then
		data.gems = data.gems + GameConfig.GEM_AMOUNTS.GEM_SMALL
		granted    = true
		productType = "gem_small"
	elseif productId == GameConfig.DEV_PRODUCTS.GEM_LARGE then
		data.gems = data.gems + GameConfig.GEM_AMOUNTS.GEM_LARGE
		granted    = true
		productType = "gem_large"
	elseif productId == GameConfig.DEV_PRODUCTS.COIN_BOOST then
		data.boosts.coinBoostExpiry = os.time() + GameConfig.COIN_BOOST_DURATION
		data.boosts.coinBoostMult   = GameConfig.COIN_BOOST_MULT
		granted    = true
		productType = "coin_boost"
	end

	if not granted then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Speichern und Client informieren
	DataStoreManager.MarkReceiptProcessed(tostring(receiptInfo.PurchaseId))
	DataStoreManager.SaveData(player, data)

	-- Dem Client Bestaetigung schicken (RemoteEvents bereits von GameManager erstellt)
	local eventsFolder = game.ReplicatedStorage:FindFirstChild("RemoteEvents")
	if eventsFolder then
		local evt = eventsFolder:FindFirstChild("PurchaseConfirmed")
		if evt then
			evt:FireClient(player, productType, { coins=data.coins, gems=data.gems })
		end
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

return MonetizationHandler
