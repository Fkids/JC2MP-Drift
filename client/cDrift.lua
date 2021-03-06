class "cDrift"

function cDrift:__init()
	Events:Subscribe("Render", self, self.onRender)
	Network:Subscribe("03", self, self.onDriftAttempt)
end

-- Events
function cDrift:onRender()
	local object = NetworkObject.GetByName("Drift")
	if object then
		local record = object:GetValue("S")
		local text = "Best Drift!"
		local position = Vector2(20, Render.Height * 0.4)
		Render:DrawText(position + Vector2.One, text, Color(0, 0, 0, 100), 16)
		Render:DrawText(position, text, Color(255, 255, 255), 16)
		Render:DrawText(position + Vector2(Render:GetTextWidth("Best ", 16), 0), "Drift!", Color(255, 150, 0), 16)
		local height = Render:GetTextHeight("A") * 1.2
		position.y = position.y + height
		local record = object:GetValue("S")
		if record then
			text = tostring(record) .. " I " .. object:GetValue("N")
			Render:DrawText(position + Vector2.One, text, Color(0, 0, 0, 100), 16)
			Render:DrawText(position, text, Color(255, 255, 255), 16)
			text = tostring(record)
			Render:DrawText(position + Vector2.One, text, Color(0, 0, 0, 100), 16)
			Render:DrawText(position, text, Color(0, 150, 255), 16)
			text = ""
			for i = 1, object:GetValue("E") do text = text .. "`" end
			position.y = position.y + height * 0.95
			Render:DrawText(position + Vector2.One, text, Color(0, 0, 0, 100), 16)
			Render:DrawText(position, text, Color(255, 255, 255), 16)
			Render:DrawLine(position + Vector2(3, 2), position + Vector2(Render:GetTextWidth(text, 16) + 1, 2), Color(200, 200, 200, 150))
			if self.attempt then
				local player = Player.GetById(self.attempt[2] - 1)
				if player then
					position.y = position.y + height * 0.42
					local alpha = math.min(self.attempt[3], 1)
					text = tostring(self.attempt[1]) .. " I " .. player:GetName()
					Render:DrawText(position + Vector2.One, text, Color(0, 0, 0, 100 * alpha), 16)
					Render:DrawText(position, text, Color(255, 255, 255, 255 * alpha), 16)
					text = tostring(self.attempt[1])
					Render:DrawText(position + Vector2.One, text, Color(0, 0, 0, 100 * alpha), 16)
					Render:DrawText(position, text, Color(240, 220, 70, 255 * alpha), 16)
					self.attempt[3] = self.attempt[3] - 0.02
					if self.attempt[3] < 0.02 then self.attempt = nil end
				end
			end
		else
			text = "–"
			Render:DrawText(position + Vector2.One, text, Color(0, 0, 0, 100), 16)
			Render:DrawText(position, text, Color(200, 200, 200), 16)
		end
	end
	if self.score and not self.timer and self.score >= 200 then
		self.slide = self.slide + 1
		if self.slide == 1 then
			local object = NetworkObject.GetByName("Drift")
			if not object or self.score > (object:GetValue("S") or 0) then
				Network:Send("01", self.score)
			elseif self.score > ((object:GetValue("S") or 0) * 0.6) and (object:GetValue("N") or "None") ~= LocalPlayer:GetName() then
				Network:Send("02", self.score)
			end
			local shared = SharedObject.Create("Drift")
			if self.score > (shared:GetValue("Record") or 0) then
				shared:SetValue("Record", self.score)
			end
		end
		local text = "Drift! " .. tostring(self.score)
		local textSize = Render:GetTextSize(text, 36)
		local alpha = 1 - self.slide / 255
		local position = Vector2(Render.Width / 2, Render.Height * 0.3 * alpha) - textSize / 2
		Render:DrawText(position + Vector2.One, text, Color(0, 0, 0, 100 * alpha), 36)
		Render:DrawText(position, text, Color(255, 150, 0, 255 * alpha), 36)
		Render:DrawText(position + Vector2(Render:GetTextWidth("Drift! ", 36), 0), tostring(self.score), Color(255, 255, 255, 255 * alpha), 36)
		if self.slide == 255 then
			self.slide = nil
			self.score = nil
		end
	end
	if LocalPlayer:GetState() ~= PlayerState.InVehicle then self.timer = nil; return end
	local vehicle = LocalPlayer:GetVehicle()
	if not IsValid(vehicle) then self.timer = nil; return end
	if vehicle:GetClass() ~= VehicleClass.Land then self.timer = nil; return end
	local velocity = vehicle:GetLinearVelocity()
	if velocity:Length() < 20 then self.timer = nil; return end
	local dot = Angle.Dot(Angle(Angle.FromVectors(velocity, Vector3.Forward).yaw, 0, 0), Angle(-vehicle:GetAngle().yaw, 0, 0))
	if dot < 0.7 or dot > 0.99 then self.timer = nil; return end
	local raycast = Physics:Raycast(vehicle:GetPosition() + Vector3(0, 0.5, 0), Vector3.Down, 0, 10, true)
	if raycast.distance > 1 then self.timer = nil; return end
	if not self.timer then
		self.timer = Timer()
		self.quality = 0
	end
	self.quality = math.max(math.lerp(self.quality, -45 * math.pow(dot - 0.85, 2) + 1, 0.1), self.quality)
	score = math.ceil(self.timer:GetMilliseconds() * self.quality)
	if score < 200 then return end
	self.score = score
	self.slide = 0
	local text = "Drift! " .. tostring(self.score)
	local textSize = Render:GetTextSize(text, 36)
	local position = Vector2(Render.Width / 2, Render.Height * 0.3) - textSize / 2
	Render:DrawText(position + Vector2.One, text, Color(0, 0, 0, 100), 36)
	Render:DrawText(position, text, Color(255, 150, 0), 36)
	Render:DrawText(position + Vector2(Render:GetTextWidth("Drift! ", 36), 0), tostring(self.score), Color(255, 255, 255), 36)
end

-- Network
function cDrift:onDriftAttempt(data)
	self.attempt = data
	self.attempt[3] = 4
end

cDrift = cDrift()
