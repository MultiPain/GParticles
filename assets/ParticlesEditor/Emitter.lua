--!NOEXEC
local SHAPES = {"Point", "Sphere", "Box"}
local BLEND_MODES = {"None", Sprite.ADD, Sprite.ALPHA, Sprite.MULTIPLY, Sprite.NO_ALPHA, Sprite.SCREEN}
local COLOR_PICKER_FLAGS = ImGui.ColorEditFlags_AlphaPreviewHalf | ImGui.ColorEditFlags_AlphaPreview
local ICONS = ParticlesEditor.ICONS

local random = math.random
local frandom = ParticlesEditor.frandom
local cos = math.cos
local sin = math.sin
local PI2 = math.pi * 2
local toDeg = 180 / math.pi

local default = {
	name = "",
	tmpName = "",
	
	image = nil,
	imageName = "",
	
	blendMode = 0,
	
	colorTransform = 0xffffff,
	colorTransformAlpha = 1,
	colors = {},
	
	spawnRate = 1,
	spawnFreq = 0, -- 0: every frame
	spawnTimer = 0,
	
	emmsionShape = 0,
	emmsionShapeType = 0,
	
	isPaused = false,
	visibleMarkers = true ,
	visible = true,
	delete = false,
	lockToDirection = true,
	faceToDirection = false,
	
	direction = 90,
	spread = 45,
	color = 0xffffff,
	alpha = 1,
	
	posX = 0,
	posY = 0,
	
	emissionRadius = 0,
	emissionW = 0,
	emissionH = 0,
	emmsionAX = 0.5,
	emmsionAY = 0.5,
	
	speed = 2.5,
	speed_min = 0,
	speed_max = 0,
	
	ttl = 40,
	ttl_min = 0,
	ttl_max = 0,
	
	size = 10,
	size_min = 0,
	size_max = 0,
	
	angle = 0,
	angle_min = 0,
	angle_max = 0,
	
	speedAngular = 0,
	speedAngular_min = 0,
	speedAngular_max = 0,
	
	speedGrowth = 0,
	speedGrowth_min = 0,
	speedGrowth_max = 0,
	
	decay = 1,
	decay_min = 0,
	decay_max = 0,

	decayAngular = 1,
	decayAngular_min = 0,
	decayAngular_max = 0,

	decayGrowth = 1,
	decayGrowth_min = 0,
	decayGrowth_max = 0,

	decayAlpha = 1,
	decayAlpha_min = 0,
	decayAlpha_max = 0,
}

Emitter = Core.class(Sprite)

function Emitter:init(scene, name)
	self.parent = scene
	self.ui = self.parent.ui
	self.io = self.ui:getIO()
	self.settings = self.parent.settings
	
	self.particles = Particles.new()
	self:addChild(self.particles)
	
	self.subEmitters = {} -- TODO
	
	self:load(default)
	
	self.name = name
	self.tmpName = name
	
	self.resetX, self.resetY = self:getPosition()
end
-- 
function Emitter:load(t, keepName)
	self:clear()
	
	local tmpName = self.name
	
	for k,v in pairs(t) do 
		self[k] = v
	end
	
	if (keepName) then 
		self.name = tmpName
		self.tmpName = tmpName
	end
	
	if (self.imageName == "") then 
		self:updateTexture(nil, "")
	else
		for i,v in ipairs(self.parent.images) do
			if (v.name == self.imageName) then 
				self:updateTexture(v.texture, v.name)
				break
			end
		end
	end
	self:updateBlendMode()
	self:updateColorTransform()
end
-- 
function Emitter:save()
	local t = {}
	for k,v in pairs(default) do 
		t[k] = self[k]
	end
	return t
end
-- 
function Emitter:clear()
	self.particles:removeParticles()
	for i,ps in ipairs(self.subEmitters) do 
		ps.particles:removeParticles()
	end
end
-- 
function Emitter:copyFrom(other)
	local options = other:save()
	self:load(options, true)
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
	local r, g, b = ImGui.colorConvertHEXtoRGB(self.colorTransform)
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
	
	local enterFlag = false
	self.tmpName, enterFlag = ui:inputTextWithHint("Name##EMITTER_NAME_"..id, self.name, "Name", 128, ImGui.InputTextFlags_EnterReturnsTrue)
	if (enterFlag) then 
		self.name = self.tmpName
	end
	
	local blendModeChanged = false
	self.blendMode, blendModeChanged = ui:combo("Blend mode##EMITTER_BLEND_"..id, self.blendMode, BLEND_MODES)
	
	if (blendModeChanged) then 
		self:updateBlendMode()
	end	
	
	self.visibleMarkers  = ui:checkbox("Markes##EMITTER_MARKERS_"..id, self.visibleMarkers)
	
	if (ui:treeNode("Colors##EMITTER_COLORS_"..id)) then
		local colorChanged = false
		self.colorTransform, self.colorTransformAlpha, colorChanged = ui:colorEdit4("Transform##EMITTER_COLOR_TRANS_"..id, self.colorTransform, self.colorTransformAlpha)
		if (colorChanged) then 
			self:updateColorTransform()
		end
		
		self.color, self.alpha = ui:colorEdit4("Color##EMITTER_COLOR_"..id, self.color, self.alpha)
		
		if (ui:treeNode("Random colors##EMITTER_RANDOM_COLORS_"..id)) then
			local ID = "##EMITTER_COLOR_"..id
			if (ui:button("ADD"..ID, -1)) then 
				self.colors[#self.colors + 1] = {
					hex = 0, a = 1
				}
			end
			
			local len = #self.colors
			local i = 1
			while (i <= len) do
				if (ui:button("-"..ID..i)) then 
					len -= 1
					table.remove(self.colors, i)
					i -= 1
					if (len == 0) then break end
				end
				local color = self.colors[i]
				ui:sameLine()
				color.hex, color.a = ui:colorEdit4("#"..i..ID, color.hex, color.a)
				i += 1
			end
			ui:treePop()
		end
		ui:treePop()
	end
	
	if (ui:treeNode("Spawn##EMITTER_"..id)) then 
		self.spawnRate = ui:dragInt("Rate##EMITTER_RATE_"..id, self.spawnRate, 1, 1, 100)
		self.spawnFreq = ui:dragFloat("Frequency##EMITTER_FREQ_"..id, self.spawnFreq, 0.01, 0, 100000)
		ui:treePop()
	end
	
	if (ui:treeNode("Texture##EMITTER_TEXTURE_"..id)) then 
		self.faceToDirection = ui:checkbox("Align with direction##FACE_TO_"..id, self.faceToDirection)
		ui:sameLine() ui:helpMarker("Adjust angle with \"Angle\" knob")
		
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
		ui:text("Local position")
		self.posX = ui:dragFloat("X##LPOSITION_X" .. id, self.posX)
		self.posY = ui:dragFloat("Y##LPOSITION_Y" .. id, self.posY)
		if (ui:button("Reset##LEMITTER_RES_POS_"..id, -1)) then 
			self.posX = 0
			self.posY = 0
		end
		
		local x, y = self:getPosition()
		ui:text("Global position")
		x = ui:dragFloat("X##GPOSITION_X" .. id, x)
		y = ui:dragFloat("Y##GPOSITION_Y" .. id, y)
		
		if (ui:button("Reset##GEMITTER_RES_POS_"..id, -1)) then 
			x = Window.CX - 200 --self.resetX
			y = Window.CY --self.resetY
		end
		self:setPosition(x, y)
		ui:treePop()
	end
	
	if (ui:treeNode("Emission shape##EMITTER_"..id)) then
		local valueChanged = false
		self.emmsionShape = ui:combo("##EMITTER_SHAPE_"..id, self.emmsionShape, "Point\0Sphere\0Box\0", 3)
		if (self.emmsionShape == 1) then
			self.emissionRadius = ui:dragFloat("Radius##EMITTER_ERADIUS"..id, self.emissionRadius, 0.1)
			
			local list = ui:getBackgroundDrawList()
			local x, y = self:getPosition()
			list:addCircle(x + self.posX, y + self.posY, self.emissionRadius, 0xff0000, 1, nil, 2)
		elseif (self.emmsionShape == 2) then
			self.emmsionAX, self.emmsionAY = ui:point("Anchor##EMITTER_ANCHOR"..id, 100, self.emmsionAX, self.emmsionAY, 0, 0, 1, 1)
			self.emissionW, self.emissionH = ui:dragFloat2("Size##EMITTER_ESIZE_"..id, self.emissionW, self.emissionH, 0.1, 0, 1000000)
			--self.emmsionAX, self.emmsionAY = ui:dragFloat2("Anchor##EMITTER_EANCHOR"..id, self.emmsionAX, self.emmsionAY, 0.01, 0, 1)
	
			
			local list = ui:getBackgroundDrawList()
			local x, y = self:getPosition()
			x += self.posX - self.emissionW * self.emmsionAX
			y += self.posY - self.emissionH * self.emmsionAY
			list:addRect(x, y, x + self.emissionW, y + self.emissionH, 0xff0000, 1, nil, nil, 2)
		end
		ui:treePop()
	end
	
	if (ui:treeNode("Size##EMITTER_"..id)) then 
		self.size = ui:dragInt("##EMITTER_SIZE_" .. id, self.size, nil, 0, 4096)
		self.size_min, self.size_max = ui:dragFloat2("Random##EMITTER_RANDOM_SIZE_" .. id, self.size_min, self.size_max)
		ui:treePop()
	end
	
	if (ui:treeNode("Speed##EMITTER_" .. id)) then 
		self.speed = ui:dragFloat("##EMITTER_SPEED_" .. id, self.speed, 0.1)
		self.speed_min, self.speed_max = ui:dragFloat2("Random##EMITTER_RANDOM_SPEED_" .. id, self.speed_min, self.speed_max, 0.1)
		ui:treePop()
	end
	
	if (ui:treeNode("Direction##EMITTER_"..id)) then 
		self.direction = ui:dial("##EMITTER_DIR_"..id, self.direction, 64, toDeg, 360)
		ui:treePop()
	end
	
	if (ui:treeNode("Spread##EMITTER_"..id)) then 
		self.lockToDirection = ui:checkbox("Align with direction##EMITTER_LOCK_SPREAD_"..id, self.lockToDirection)
		if (self.lockToDirection) then 
			self.spread = ui:spread("##EMITTER_SPREAD_"..id, self.spread, 64, toDeg, 180, ^<self.direction)
		else
			self.spread = ui:spread("##EMITTER_SPREAD_"..id, self.spread, 64, toDeg, 180, 0)
		end
		ui:treePop()
	end
	
	if (ui:treeNode("Angle##EMITTER_"..id)) then 
		self.angle = ui:dial("##EMITTER_Angle_"..id, self.angle, 64, toDeg, 360)
		if (not self.faceToDirection) then 
			self.angle_min, self.angle_max = ui:sliderFloat2("Random##EMITTER_Angle_"..id, self.angle_min, self.angle_max, -360, 360)
		end
		ui:treePop()
	end
	
	if (ui:treeNode("TTL##EMITTER_"..id)) then 
		self.ttl = ui:dragInt("##EMITTER_TTL_" .. id, self.ttl, 1)
		self.ttl_min, self.ttl_max = ui:dragInt2("Random##EMITTER_TTL_" .. id, self.ttl_min, self.ttl_max, 1, 0, 7200)
		ui:treePop()
	end
	
	if (ui:treeNode("Angular speed##EMITTER_"..id)) then
		self.speedAngular = ui:dragFloat("##EMITTER_SPEED_ANGULAR_"..id, self.speedAngular, 0.001)
		self.speedAngular_min, self.speedAngular_max = ui:dragFloat2("Random##EMITTER_RANDOM_SPA_" .. id, self.speedAngular_min, self.speedAngular_max, 0.001, -128, 128)
		ui:treePop() 
	end
	if (ui:treeNode("Growth speed##EMITTER_"..id)) then
		self.speedGrowth = ui:dragFloat("##EMITTER_SPEED_GROWTH_"..id, self.speedGrowth, 0.001)
		self.speedGrowth_min, self.speedGrowth_max = ui:dragFloat2("Random##EMITTER_RANDOM_SGR_" .. id, self.speedGrowth_min, self.speedGrowth_max, 0.001, -128, 128)
		ui:treePop() 
	end
	if (ui:treeNode("Decay##EMITTER_"..id)) then
		self.decay = ui:dragFloat("##EMITTER_DECAY_"..id, self.decay, 0.001)
		self.decay_min, self.decay_max = ui:dragFloat2("Random##EMITTER_RANDOM_SD_" .. id, self.decay_min, self.decay_max, 0.001, -128, 128)
		ui:treePop() 
	end
	if (ui:treeNode("Angular decay##EMITTER_"..id)) then
		self.decayAngular = ui:dragFloat("##EMITTER_DECAY_ANGULAR_"..id, self.decayAngular, 0.001)
		self.decayAngular_min, self.decayAngular_max = ui:dragFloat2("Random##EMITTER_RANDOM_SDA_" .. id, self.decayAngular_min, self.decayAngular_max, 0.001, -128, 128)
		ui:treePop() 
	end
	if (ui:treeNode("Growth decay##EMITTER_"..id)) then
		self.decayGrowth = ui:dragFloat("##EMITTER_DECAY_GROWTH_"..id, self.decayGrowth, 0.001)
		self.decayGrowth_min, self.decayGrowth_max = ui:dragFloat2("Random##EMITTER_RANDOM_SGA_" .. id, self.decayGrowth_min, self.decayGrowth_max, 0.001, -128, 128)
		ui:treePop() 
	end
	if (ui:treeNode("Alpha decay##EMITTER_"..id)) then
		self.decayAlpha = ui:dragFloat("##EMITTER_DECAY_ALPHA_"..id, self.decayAlpha, 0.001)
		self.decayAlpha_min, self.decayAlpha_max = ui:dragFloat2("Random##EMITTER_RANDOM_SAA_" .. id, self.decayAlpha_min, self.decayAlpha_max, 0.001, -128, 128)
		ui:treePop() 
	end
	
	if (ui:button("Force clear##EMITTER_CLEAR_"..id, -1)) then 
		self:clear()
	end
	
	if (ui:button("Reset##EMITTER_RESET_"..id, -1)) then 
		ui:openPopup("Confirm##EMITTER_CRESET_"..id)
	end
	
	if (ui:beginPopupModal("Confirm##EMITTER_CRESET_"..id)) then 
		ui:text("This will reset all the setting.\nAre you sure you want to reset?")
		if (ui:button("Yes##EMITTER_CRY_"..id)) then 
			-- keep name
			self:load(default, true, id)
			ui:closeCurrentPopup()
		end
		if (ui:button("No##EMITTER_CRY_"..id)) then 
			ui:closeCurrentPopup()
		end
		ui:endPopup()
	end
end
--
function Emitter:draw(id)
	local ui = self.ui
	local mode, id1, id2
	local flag = false
	
	if (ui:beginTable("##EMITTER_TBL_"..id, 3)) then 
		ui:tableSetupColumn("Visbility", ImGui.TableColumnFlags_WidthFixed, 22)
		ui:tableSetupColumn("Emitter", ImGui.TableColumnFlags_WidthStretch)
		ui:tableSetupColumn("Delete", ImGui.TableColumnFlags_WidthFixed, 24)
		
		ui:tableNextColumn()
		ui:pushID("emitterVisble"..id)
		if (ui:button(self.visible and ICONS.ON or ICONS.OFF)) then 
			self.visible = not self.visible
			self.particles:setVisible(self.visible)
		end
		ui:popID()
		ui:tableNextColumn()
		
		flag = ui:collapsingHeader(self.name)
		mode, id1, id2 = self:dragAndDrop(id)
		
		ui:tableNextColumn()
		self.delete = ui:button(ICONS.TRASH .. "##EMITTER_DEL_"..id, -1)
	end	
	ui:endTable()
	
	if (flag) then 
		self:drawBody(id)
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
		
		local cosa = cos(theta)
		local sina = sin(theta)
		
		local speedX = cosa * speed
		local speedY = sina * speed
		
		local angle = self.angle - dir 
		if (not self.faceToDirection) then 
			angle = self.angle + frandom(self.angle_min, self.angle_max)
		end
		local rx = 0
		local ry = 0
		
		if (self.emmsionShape == 1) then
			local radius = frandom(self.emissionRadius)
			rx = cosa * radius
			ry = sina * radius
		elseif (self.emmsionShape == 2) then
			local w = self.emissionW
			local h = self.emissionH
			rx = w * random() - w * self.emmsionAX
			ry = h * random() - h * self.emmsionAY
		end
		
		local color = self.color
		local alpha = self.alpha
		local rColors = #self.colors
		
		if (rColors > 0) then 
			local newColor = self.colors[random(rColors)]
			color, alpha = newColor.hex, newColor.a
		end
		
		self.particles:addParticles{
			{
				x = self.posX + rx,
				y = self.posY + ry,
				speedX = speedX,
				speedY = speedY,
				size = self.size + frandom(self.size_min, self.size_max),
				ttl = self.ttl + frandom(self.ttl_min, self.ttl_max),
				angle = angle,
				color = color,
				alpha = alpha,
				
				speedAngular = self.speedAngular + frandom(self.speedAngular_min, self.speedAngular_max),
				speedGrowth = self.speedGrowth + frandom(self.speedGrowth_min, self.speedGrowth_max),
				decay = self.decay + frandom(self.decay_min, self.decay_max),
				decayAngular = self.decayAngular + frandom(self.decayAngular_min, self.decayAngular_max),
				decayGrowth = self.decayGrowth + frandom(self.decayGrowth_min, self.decayGrowth_max),
				decayAlpha = self.decayAlpha + frandom(self.decayAlpha_min, self.decayAlpha_max),
			}
		}
	end
end
--
