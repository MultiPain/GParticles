--!NOEXEC
local ui = UI
local toDeg = 180 / math.pi

SubParticleSystem = Core.class()

function SubParticleSystem:init(name, scene)
	self.name = name
	self.tmpName = name
	
	self.parent = scene
	
	self.visible = true
	self.delete = false
	self.localSpace = true
	self.showPreview = true
	self.growDown = false -- TODO
	self.fade = "" -- TODO
	
	self.direction = 0
	self.spread = 0
	
	self.color = 0xffffff
	self.alpha = 1
	
	self.xPos = 0.5			self.xPos_min = 0 			self.xPos_max = 0
	self.yPos = 0.5			self.yPos_min = 0 			self.yPos_max = 0
	self.size = 10			self.size_min = 0 			self.size_max = 0
	self.ttl = 30			self.ttl_min = 0 			self.ttl_max = 0
	self.speed = 0			self.speed_min = 0 			self.speed_max = 0
	self.angle = 0			self.angle_min = 0 			self.angle_max = 0
	self.speedAngular = 0	self.speedAngular_min = 0 	self.speedAngular_max = 0
	self.speedGrowth = 0	self.speedGrowth_min = 0 	self.speedGrowth_max = 0
	self.decay = 1			self.decay_min = 0 			self.decay_max = 0
	self.decayAngular = 1	self.decayAngular_min = 0 	self.decayAngular_max = 0
	self.decayGrowth = 1	self.decayGrowth_min = 0 	self.decayGrowth_max = 0
	self.decayAlpha = 1		self.decayAlpha_min = 0 	self.decayAlpha_max = 0
	
	self.xBound_max = 1
	self.xRndBound_min = -0.5	self.xRndBound_max =  0.5
	self.yBound_max = 1
	self.yRndBound_min = -0.5	self.yRndBound_max =  0.5
	
	self.particles = Particles.new()
	
	local previewSize = Options.PREVIEW_SIZE
	self.view = RenderTarget.new(previewSize, previewSize)
end
--
function SubParticleSystem:dragAndDrop(id)
	local CTRL = io:isKeyCtrl()
	if (ui:beginDragDropSource(ImGui.DragDropFlags_None)) then
		ui:setNumDragDropPayload("EMITTER", id)
		local mode = "Swap "
		if (CTRL) then 
			mode = "Copy "
		end
		ui:text(mode..self.name)
		ui:endDragDropSource()
	end
	
	if (UI:beginDragDropTarget()) then
		local payload = UI:acceptDragDropPayload("EMITTER")
		if (payload) then
			local payload_id = payload:getNumData()
			if (CTRL) then 
				return "copy", payload_id, id
			end
			return "swap", payload_id, id
		end
	end
end
--
function SubParticleSystem:copyFrom(other)
	self.growDown = other.growDown 
	self.fade = other.fade 
	
	self.direction = other.direction 
	self.spread = other.spread 
	
	self.color = other.color 
	self.alpha = other.alpha 
	
	self.xPos = other.xPos					self.xPos_min			= other.xPos_min  		 self.xPos_max			= other.xPos_max 
	self.yPos = other.yPos					self.yPos_min			= other.yPos_min  		 self.yPos_max			= other.yPos_max 
	self.size = other.size  				self.size_min			= other.size_min  		 self.size_max			= other.size_max 
	self.ttl = other.ttl  					self.ttl_min			= other.ttl_min  		 self.ttl_max			= other.ttl_max 
	self.speed = other.speed  				self.speed_min			= other.speed_min  		 self.speed_max			= other.speed_max 
	self.angle = other.angle  				self.angle_min			= other.angle_min  		 self.angle_max			= other.angle_max 
	self.speedAngular = other.speedAngular	self.speedAngular_min	= other.speedAngular_min self.speedAngular_max	= other.speedAngular_max 
	self.speedGrowth = other.speedGrowth	self.speedGrowth_min	= other.speedGrowth_min  self.speedGrowth_max	= other.speedGrowth_max 
	self.decay = other.decay				self.decay_min			= other.decay_min  		 self.decay_max			= other.decay_max 
	self.decayAngular = other.decayAngular  self.decayAngular_min	= other.decayAngular_min self.decayAngular_max	= other.decayAngular_max 
	self.decayGrowth = other.decayGrowth  	self.decayGrowth_min	= other.decayGrowth_min  self.decayGrowth_max	= other.decayGrowth_max 
	self.decayAlpha = other.decayAlpha  	self.decayAlpha_min		= other.decayAlpha_min   self.decayAlpha_max	= other.decayAlpha_max 
end
--
function SubParticleSystem:draw(id)
	local mode, id0, id1
	ui:pushID("emitterVisble"..id)
	--self.visible = ui:checkbox("", self.visible)
	if (ui:button(self.visible and ICO_ON or ICO_OFF)) then 
		self.visible = not self.visible
	end
	ui:popID()
	ui:sameLine()
	
	if (ui:collapsingHeader(self.name)) then 
		mode, id0, id1 = self:dragAndDrop(id)
		ui:pushID("emitterName"..id)
		local enterFlag = false
		self.tmpName, enterFlag = ui:inputTextWithHint("", self.name, "Name", 128, ImGui.InputTextFlags_EnterReturnsTrue)
		ui:popID()
		if (enterFlag) then 
			self.name = self.tmpName
		end
		ui:sameLine()
		
		ui:pushID("emitterDelete"..id)
		self.delete = ui:button("Delete", -1)
		ui:popID()
		
		self.showPreview = ui:checkbox("Show preview##"..id, self.showPreview)
		if (self.showPreview) then 
			local w = ui:getContentRegionAvail() - 5
			local SIZE = Options.PREVIEW_SIZE
			addParticles(self.particles, self, SIZE, SIZE, 0.2, self.parent.spawnRate, self.localSpace)
			self.view:clear(self.parent.bgColor, self.parent.bgAlpha)
			self.view:draw(self.particles)
			ui:scaledImage(self.view, w, SIZE, nil, nil, 0, 1)
		end
		
		self.color, self.alpha = ui:colorEdit4("Color##"..id, self.color, self.alpha, COLOR_PICKER_FLAGS)
		
		if (ui:treeNode("Position##"..id)) then
			local localSpaceChanged = false
			self.localSpace, localSpaceChanged = ui:checkbox("Local space##"..id, self.localSpace)
			if (localSpaceChanged) then 
				if (self.localSpace) then 
					self.xBound_max = 1
					self.yBound_max = 1
					
					self.xRndBound_min = -0.5
					self.xRndBound_max =  0.5
					self.yRndBound_min = -0.5
					self.yRndBound_max =  0.5
				else
					local SIZE = Options.PREVIEW_SIZE
					self.xBound_max = SIZE
					self.yBound_max = SIZE
					
					self.xRndBound_min = 0
					self.xRndBound_max = SIZE
					self.yRndBound_min = 0
					self.yRndBound_max = SIZE
				end
			end
			
			ui:text("> X")
			self.xPos = ui:sliderFloat("XPos##"..id, self.xPos, 0, self.xBound_max)
			self.xPos_min, self.xPos_max = ui:sliderFloat2("Randomize##XPos"..id, self.xPos_min, self.xPos_max, self.xRndBound_min, self.xRndBound_max)
			if (ui:button("Reset##XPos"..id, -1)) then
				self.xPos = 0.5
				self.xPos_min = 0
				self.xPos_max = 0
			end
			
			ui:text("> Y")
			self.yPos = ui:sliderFloat("YPos##"..id, self.yPos, 0, self.yBound_max)
			self.yPos_min, self.yPos_max = ui:sliderFloat2("Randomize##YPos"..id, self.yPos_min, self.yPos_max, self.yRndBound_min, self.yRndBound_max)
			if (ui:button("Reset##YPos"..id, -1)) then
				self.yPos = 0.5
				self.yPos_min = 0
				self.yPos_max = 0
			end
			ui:treePop()
		end
		
		if (ui:treeNode("Size##"..id)) then
			self.size = ui:sliderFloat("Size##"..id, self.size, 0, 256)
			self.size_min, self.size_max = ui:sliderFloat2("Randomize##Size"..id, self.size_min, self.size_max, 0, 128)
			if (ui:button("Reset##Size"..id, -1)) then
				self.size = 10
				self.size_min = 0
				self.size_max = 0
			end
			ui:treePop()
		end
		
		if (ui:treeNode("TTL##"..id)) then
			self.ttl = ui:sliderInt("Ttl##"..id, self.ttl, 0, 1800)
			self.ttl_min, self.ttl_max = ui:sliderFloat2("Randomize##Ttl"..id, self.ttl_min, self.ttl_max, 0, 900)
			if (ui:button("Reset##Ttl"..id, -1)) then
				self.ttl = 30
				self.ttl_min = 0
				self.ttl_max = 0
			end
			ui:treePop()
		end
		
		if (ui:treeNode("Speed##"..id)) then
			self.speed = ui:sliderFloat("Speed##"..id, self.speed, -8, 8)
			self.speed_min, self.speed_max = ui:sliderFloat2("Randomize##SpeedX"..id, self.speed_min, self.speed_max, -8, 8)
			if (ui:button("Reset##Speed"..id, -1)) then
				self.speed = 0
				self.speed_min = 0
				self.speed_max = 0
			end
			ui:treePop()
		end
		
		if (ui:treeNode("Direction##"..id)) then
			self.direction = ui:dial("##DirectionLabel"..id, self.direction, 64, toDeg, 360)
			ui:treePop()
		end
		
		if (ui:treeNode("Spread##"..id)) then
			self.spread = ui:spread("##SpreadLabel"..id, self.spread, 64, toDeg, 180, ^<self.direction)
			ui:treePop()
		end
		
		if (ui:treeNode("Angle##"..id)) then
			self.angle = ui:dial("##AngleLabel"..id, self.angle, 64, 1, PI2)
			--self.angle = ui:sliderFloat("Angle##"..id, self.angle, 0, 360)
			self.angle_min, self.angle_max = ui:sliderFloat2("Randomize##Angle"..id, self.angle_min, self.angle_max, 0, 360)
			if (ui:button("Reset##Angle"..id, -1)) then
				self.angle = 0
				self.angle_min = 0
				self.angle_max = 0
			end
			ui:treePop()
		end
		
		if (ui:treeNode("SpeedAngular##"..id)) then
			self.speedAngular = ui:sliderFloat("SpeedAngular##"..id, self.speedAngular, -2, 2)
			self.speedAngular_min, self.speedAngular_max = ui:sliderFloat2("Randomize##SpeedAngular"..id, self.speedAngular_min, self.speedAngular_max, -0.5, 0.5)
			if (ui:button("Reset##SpeedAngular"..id, -1)) then
				self.speedAngular = 0
				self.speedAngular_min = 0
				self.speedAngular_max = 0
			end
			ui:treePop()
		end
		
		if (ui:treeNode("SpeedGrowth##"..id)) then
			self.growDown = ui:checkbox("Grow down##"..id, self.growDown)
			if (not self.growDown) then 
				self.speedGrowth = ui:sliderFloat("SpeedGrowth##"..id, self.speedGrowth, -2, 2)
				self.speedGrowth_min, self.speedGrowth_max = ui:sliderFloat2("Randomize##SpeedGrowth"..id, self.speedGrowth_min, self.speedGrowth_max, -0.5, 0.5)
				if (ui:button("Reset##SpeedGrowth"..id, -1)) then
					self.speedGrowth = 0
					self.speedGrowth_min = 0
					self.speedGrowth_max = 0
				end
			end
			ui:treePop()
		end
		
		if (ui:treeNode("Decay##"..id)) then
			self.decay = ui:sliderFloat("Decay##"..id, self.decay, -2, 2)
			self.decay_min, self.decay_max = ui:sliderFloat2("Randomize##Decay"..id, self.decay_min, self.decay_max, -0.5, 0.5)
			if (ui:button("Reset##Decay"..id, -1)) then
				self.decay = 1
				self.decay_min = 0
				self.decay_max = 0
			end
			ui:treePop()
		end
		
		if (ui:treeNode("DecayAngular##"..id)) then
			self.decayAngular = ui:sliderFloat("DecayAngular##"..id, self.decayAngular, -2, 2)
			self.decayAngular_min, self.decayAngular_max = ui:sliderFloat2("Randomize##DecayAngular"..id, self.decayAngular_min, self.decayAngular_max, -0.5, 0.5)
			if (ui:button("Reset##DecayAngular"..id, -1)) then
				self.decayAngular = 1
				self.decayAngular_min = 0
				self.decayAngular_max = 0
			end
			ui:treePop()
		end
		
		if (ui:treeNode("DecayGrowth##"..id)) then
			self.decayGrowth = ui:sliderFloat("DecayGrowth##"..id, self.decayGrowth, -2, 2)
			self.decayGrowth_min, self.decayGrowth_max = ui:sliderFloat2("Randomize##DecayGrowth"..id, self.decayGrowth_min, self.decayGrowth_max, -0.5, 0.5)
			if (ui:button("Reset##DecayGrowth"..id, -1)) then
				self.decayGrowth = 1
				self.decayGrowth_min = 0
				self.decayGrowth_max = 0
			end
			ui:treePop()
		end
		
		if (ui:treeNode("DecayAlpha##"..id)) then
			if (ui:radioButton("No fade", self.fade == "")) then self.fade = "" end ui:sameLine()
			if (ui:radioButton("Fade IN", self.fade == "IN")) then self.fade = "IN" end ui:sameLine()
			if (ui:radioButton("Fade OUT", self.fade == "OUT")) then self.fade = "OUT" end
			
			if (self.fade == "") then 
				self.decayAlpha = ui:sliderFloat("DecayAlpha##"..id, self.decayAlpha, -2, 2)
				self.decayAlpha_min, self.decayAlpha_max = ui:sliderFloat2("Randomize##DecayAlpha"..id, self.decayAlpha_min, self.decayAlpha_max, -0.5, 0.5)
				if (ui:button("Reset##DecayAlpha"..id, -1)) then
					self.decayAlpha = 1
					self.decayAlpha_min = 0
					self.decayAlpha_max = 0
				end
			end
			ui:treePop()
		end
	else
		mode, id0, id1 = self:dragAndDrop(id)
	end
	
	return mode, id0, id1
end