--!NOEXEC
local BLEND_MODES = {"None", Sprite.ADD, Sprite.ALPHA, Sprite.MULTIPLY, Sprite.NO_ALPHA, Sprite.SCREEN}
local COLOR_PICKER_FLAGS = ImGui.ColorEditFlags_AlphaPreviewHalf | ImGui.ColorEditFlags_AlphaPreview

local ICO_ON = utf8.char(0xE8F4)
local ICO_OFF = utf8.char(0xE8F5)

local random = math.random
local function frandom(min, max)
	if (not max) then 
		max = min
		min = 0
	end
	return min + random() * (max - min)
end

local cos = math.cos
local sin = math.sin
--local PI2 = math.pi * 2
local toDeg = 180 / math.pi

Emitter = Core.class(Sprite)

function Emitter:init(scene, name)
	self.parent = scene
	self.ui = self.parent.ui
	self.io = self.ui:getIO()
	self.settings = self.parent.settings
	
	self.particles = Particles.new()
	self:addChild(self.particles)
	
	self.name = name
	self.tmpName = name
	
	self.image = nil
	self.imageName = ""
	self.blendMode = 0
	self.colorTransform = 0xffffff
	self.colorTransformAlpha = 1
	self.spawnRate = 1
	self.spawnFreq = 0 -- 0: every frame
	self.spawnTimer = 0
	self.isPaused = false	
	
	self.subEmitters = {} -- TODO
	
	self.visibleMarkers = true -- drag&drop circles
	self.visible = true
	self.delete = false
	self.localSpace = false
	self.lockToDirection = true
	self.faceToDirection = false
	
	self.direction = 90
	self.spread = 45
	
	self.color = 0xffffff
	self.alpha = 1
	
	self.posX = 0			self.posX_min = 0			self.posX_max = 0			self.posX_rMin = -960			self.posX_rMax = 960
	self.posY = 0			self.posY_min = 0			self.posY_max = 0			self.posY_rMin = -960			self.posY_rMax = 960
	self.speed = 2			self.speed_min = 0			self.speed_max = 0			self.speed_rMin = -128			self.speed_rMax = 128
	self.ttl = 20			self.ttl_min = 0			self.ttl_max = 0			self.ttl_rMin = 0				self.ttl_rMax = 60*120
	self.size = 10			self.size_min = 0			self.size_max = 0			self.size_rMin = 0				self.size_rMax = 2048
	self.angle = 0			self.angle_min = 0			self.angle_max = 0			self.angle_rMin = 0				self.angle_rMax = 360
end
-- 
function Emitter:updateTexture(texture, name)
	self.image = texture
	self.imageName = name
	if (texture) then 
		self.particles:setTexture(texture)
		for i,ps in ipairs(self.subEmitters) do 
			ps.particles:setTexture(texture)
		end
	else
		self.particles:clearTexture()
		for i,ps in ipairs(self.subEmitters) do 
			ps.particles:clearTexture()
		end
	end
end
--
function Emitter:updateBlendMode()
	if (self.blendMode == 0) then 
		self.particles:clearBlendMode()
		for i,ps in ipairs(self.subEmitters) do 
			ps.particles:clearBlendMode()
		end
	else
		self.particles:setBlendMode(BLEND_MODES[self.blendMode + 1])
		for i,ps in ipairs(self.subEmitters) do 
			ps.particles:setBlendMode(BLEND_MODES[self.blendMode + 1])
		end
	end
end
--
function Emitter:updateColorTransform()
	local r, g, b = self.ui:colorConvertHEXtoRGB(self.colorTransform)
	self.particles:setColorTransform(r, g, b, self.colorTransformAlpha)
	for i,ps in ipairs(self.subEmitters) do 
		ps.particles:setColorTransform(r, g, b, self.colorTransformAlpha)
	end
end
--
function Emitter:dragAndDrop(id)
	local ui = self.ui
	if (ui:beginDragDropSource(ImGui.DragDropFlags_None)) then
		ui:setNumDragDropPayload("EMITTER", id)
		local mode = "Swap "
		if (self.io:isKeyCtrl()) then 
			mode = "Copy "
		end
		ui:text(mode..self.name)
		ui:endDragDropSource()
	end
	
	if (ui:beginDragDropTarget()) then
		local payload = ui:acceptDragDropPayload("EMITTER")
		if (payload) then
			local payload_id = payload:getNumData()
			if (self.io:isKeyCtrl()) then 
				return "copy", payload_id, id
			end
			return "swap", payload_id, id
		end
	end
end
--
function Emitter:drawBody(id)
	local ui = self.ui
	
	ui:pushID("EMITTER_NAME_"..id)
	local enterFlag = false
	self.tmpName, enterFlag = ui:inputTextWithHint("Name", self.name, "Name", 128, ImGui.InputTextFlags_EnterReturnsTrue)
	ui:popID()
	if (enterFlag) then 
		self.name = self.tmpName
	end
	
	local blendModeChanged = false
	self.blendMode, blendModeChanged = ui:combo("##EMITTER_BLEND_"..id, self.blendMode, BLEND_MODES)
	
	if (blendModeChanged) then 
		self:updateBlendMode()
	end	
	
	local colorChanged = false
	self.colorTransform, self.colorTransformAlpha, colorChanged = ui:colorEdit4("##EMITTER_COLOR_"..id, self.colorTransform, self.colorTransformAlpha)
	if (colorChanged) then 
		self:updateColorTransform()
	end
	
	if (ui:treeNode("Spawn##EMITTER_"..id)) then 
		self.spawnRate = ui:sliderInt("Rate##EMITTER_RATE_"..id, self.spawnRate, 1, 100)
		self.spawnFreq = ui:sliderFloat("Frequency##EMITTER_FREQ_"..id, self.spawnFreq, 0, 30)
		ui:treePop()
	end
	
	if (ui:treeNode("Texture##EMITTER_TEXTURE_"..id)) then 
		local previewSize = self.settings.previewSize
		ui:pushItemWidth(-1)
		ui:pushStyleVar(ImGui.StyleVar_FramePadding, 5, previewSize / 2)
		
		local combo_x, combo_y = ui:getCursorScreenPos()
		if (ui:beginCombo("##EMITTER_IMG_"..id, "", ImGui.ComboFlags_HeightLargest | ImGui.ComboFlags_NoArrowButton)) then 
			ui:popStyleVar()
			
			for i,v in ipairs(self.parent.images) do 
				if (ui:scaledImageButton(v.texture, previewSize, previewSize, 4)) then 
					self:updateTexture(v.texture, v.name)
				end
				
				if (i % 5 ~= 0) then 
					ui:sameLine()
				end
			end
			ui:endCombo()
		else
			ui:popStyleVar()
		end
		
		if (self.image) then 
			
			local backup_x, backup_y = ui:getCursorScreenPos()
			local style = ui:getStyle()
			local fpx, fpy = style:getFramePadding()
			
			ui:setCursorScreenPos(combo_x + fpx, combo_y + 8)
			ui:scaledImage(self.image, previewSize, previewSize, self.colorTransform, self.colorTransformAlpha)
			ui:setCursorScreenPos(combo_x + fpx + previewSize, combo_y + previewSize / 2)
			--ui:sameLine()
			ui:text(self.imageName)
			ui:setCursorScreenPos(backup_x, backup_y)
			
			if (ui:button("Clear##EMITTER_DEL_IMG_"..id, -1)) then 
				self:updateTexture(nil, "")
			end
		end
		ui:popItemWidth()
		ui:treePop()
	end
	
	
	
	if (ui:treeNode("Position##EMITTER_"..id)) then 
		self.localSpace = ui:checkbox("Local space##"..id, self.localSpace)
		
		self.posX = ui:sliderFloat("X##POSITION_X" .. id, self.posX, self.posX_rMin, self.posX_rMax)
		self.posX_min, self.posX_max = ui:sliderFloat2("Random##X" .. id, self.posX_min, self.posX_max, self.posX_rMin, self.posX_rMax)

		self.posY = ui:sliderFloat("Y##POSITION_Y" .. id, self.posY, self.posY_rMin, self.posY_rMax)
		self.posY_min, self.posY_max = ui:sliderFloat2("Random##Y" .. id, self.posY_min, self.posY_max, self.posY_rMin, self.posX_rMax)

		if (ui:button("Reset##EMITTER_RES_POS_"..id, -1)) then 
			self:setPosition(Window.CX - 200, Window.CY)
			self.posX = 0
			self.posY = 0
		end
		ui:treePop()
	end
	
	if (ui:treeNode("Size##EMITTER_"..id)) then 
		self.size = ui:sliderFloat("##" .. id, self.size, self.size_rMin, self.size_rMax)
		self.size_min, self.size_max = ui:sliderFloat2("Random##TTL" .. id, self.size_min, self.size_max, self.size_rMin, self.size_rMax)
		ui:treePop()
	end
	
	if (ui:treeNode("Speed##EMITTER_"..id)) then 
		self.speed = ui:sliderFloat("##" .. id, self.speed, self.speed_rMin, self.speed_rMax)
		self.speed_min, self.speed_max = ui:sliderFloat2("Random##SPEED" .. id, self.speed_min, self.speed_max, self.speed_rMin, self.speed_rMax)
		ui:treePop()
	end
	
	if (ui:treeNode("Direction##EMITTER_"..id)) then 
		self.direction = ui:dial("##DirectionLabel"..id, self.direction, 64, toDeg, 360)
		ui:treePop()
	end
	
	if (ui:treeNode("Spread##EMITTER_"..id)) then 
		self.lockToDirection = ui:checkbox("Align with direction", self.lockToDirection)
		if (self.lockToDirection) then 
			self.spread = ui:spread("##SpreadLabel"..id, self.spread, 64, toDeg, 180, ^<self.direction)
		else
			self.spread = ui:spread("##SpreadLabel"..id, self.spread, 64, toDeg, 180, 0)
		end
		ui:treePop()
	end
	
	if (ui:treeNode("Angle##EMITTER_"..id)) then 
		self.faceToDirection = ui:checkbox("Align with direction##FACE_TO_"..id, self.faceToDirection)
		self.angle = ui:dial("##AngleLabel"..id, self.angle, 64, toDeg, 360)
		if (not self.faceToDirection) then 
			self.angle_min, self.angle_max = ui:sliderFloat2("Random##Angle"..id, self.angle_min, self.angle_max, self.angle_rMin, self.angle_rMax)
		end
		ui:treePop()
	end
	
	if (ui:treeNode("TTL##EMITTER_"..id)) then 
		self.ttl = ui:sliderFloat("##" .. id, self.ttl, self.ttl_rMin, self.ttl_rMax)
		self.ttl_min, self.ttl_max = ui:sliderFloat2("Random##TTL" .. id, self.ttl_min, self.ttl_max, self.ttl_rMin, self.ttl_rMax)
		ui:treePop()
	end
	
	ui:separator()
	if (ui:button("Force clear##EMITTER_CLEAR_"..id, -1)) then 
		self.particles:removeParticles()
		for i,ps in ipairs(self.subEmitters) do 
			ps.particles:removeParticles()
		end
	end
	self.delete = ui:button("Delete##EMITTER_DEL_"..id, -1)
end
--
function Emitter:draw(id)
	local ui = self.ui
	local mode, id1, id2
	
	ui:pushID("emitterVisble"..id)
	if (ui:button(self.visible and ICO_ON or ICO_OFF)) then 
		self.visible = not self.visible
		self.particles:setVisible(self.visible)
	end
	ui:popID()
	ui:sameLine()
	
	if (ui:collapsingHeader(self.name)) then 
		mode, id1, id2 = self:dragAndDrop(id)	
		self:drawBody(id)
	else
		mode, id1, id2 = self:dragAndDrop(id)
	end
	
	if (self.visible) then
		if (self.spawnFreq == 0) then 
			self:spawn()
		else
			self.spawnTimer += self.io:getDeltaTime()
			
			if (self.spawnTimer >= self.spawnFreq) then 
				self:spawn()
				self.spawnTimer = 0
			end
		end
	end
	
	return mode, id1, id2
end
--
function Emitter:spawn()
	for i = 1, self.spawnRate do 
		
		local speed = self.speed + frandom(self.speed_min, self.speed_max)
		local dir = self.direction
		if (self.spread > 0) then 
			dir += frandom(-self.spread, self.spread)
		end
		local theta = ^<dir
		local speedX = cos(theta) * speed
		local speedY = sin(theta) * speed
		
		local angle = self.angle - dir 
		if (not self.faceToDirection) then 
			angle = self.angle + frandom(self.angle_min, self.angle_max)
		end
		
		self.particles:addParticles{
			{
				x = self.posX + frandom(self.posX_min, self.posX_max),
				y = self.posY + frandom(self.posY_min, self.posY_max),
				speedX = speedX,
				speedY = speedY,
				size = self.size + frandom(self.size_min, self.size_max),
				ttl = self.ttl + frandom(self.ttl_min, self.ttl_max),
				angle = angle
				
			}
		}
	end
end
--