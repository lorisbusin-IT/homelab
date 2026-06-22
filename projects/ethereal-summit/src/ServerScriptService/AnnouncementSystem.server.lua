-- Ethereal Summit – Server-weite Ankuendigungen
local AnnouncementSystem = {}

local _eventsFolder = nil

function AnnouncementSystem.setEventsFolder(ef)
	_eventsFolder = ef
end

-- color: "gold" | "green" | "red" | "blue" | "purple"
function AnnouncementSystem.announce(message, color)
	if not _eventsFolder then return end
	local evt = _eventsFolder:FindFirstChild("ServerAnnouncement")
	if evt then
		evt:FireAllClients(message, color or "gold")
	end
end

return AnnouncementSystem
