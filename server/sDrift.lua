class "sDrift"

function sDrift:__init()
	self:initVars()
	Events:Subscribe("ModuleLoad", self, self.onModuleLoad)
	Events:Subscribe("PostTick", self, self.onPostTick)
	Network:Subscribe("01", self, self.onDriftRecord)
end

function sDrift:initVars()
	self.timer = Timer()
	self.delay = 30000
end

-- Events
function sDrift:onModuleLoad()
	NetworkObject.Create("Drift")
end

function sDrift:onPostTick()
	if self.timer:GetMilliseconds() < self.delay then return end
	self.timer:Restart()
	local object = NetworkObject.GetByName("Drift") or NetworkObject.Create("Drift")
	if not object:GetValue("E") then return end
	local expire = object:GetValue("E") - 1
	if expire < 1 then
		object:SetNetworkValue("S", nil)
		object:SetNetworkValue("N", nil)
		object:SetNetworkValue("E", nil)
		return
	end
	object:SetNetworkValue("E", expire)
end

-- Network
function sDrift:onDriftRecord(score, player)
	local object = NetworkObject.GetByName("Drift") or NetworkObject.Create("Drift")
	if score < (object:GetValue("S") or 0) then return end
	object:SetNetworkValue("S", score)
	object:SetNetworkValue("N", player:GetName())
	object:SetNetworkValue("E", 10)
	self.timer:Restart()
end

sDrift = sDrift()
