--!NOEXEC
local BLEND_MODES = {"None", Sprite.ADD, Sprite.ALPHA, Sprite.MULTIPLY, Sprite.NO_ALPHA, Sprite.SCREEN}
local COLOR_PICKER_FLAGS = ImGui.ColorEditFlags_AlphaPreviewHalf | ImGui.ColorEditFlags_AlphaPreview


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
	self.isPaused = false
	
	self.subEmitters = {}
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
	ui:separatorText("Name")
	ui:pushID("EMITTER_NAME_"..id)
	local enterFlag = false
	self.tmpName, enterFlag = ui:inputTextWithHint("", self.name, "Name", 128, ImGui.InputTextFlags_EnterReturnsTrue)
	ui:popID()
	if (enterFlag) then 
		self.name = self.tmpName
	end
	
	self.delete = ui:button("Delete##EMITTER_DEL_"..id, -1)
	
	ui:separatorText("Texture")
	
	ui:pushItemWidth(-1)
	
	if (ui:beginCombo("##EMITTER_IMG_"..id, self.imageName, ImGui.ComboFlags_NoArrowButton)) then 
		for i,v in ipairs(self.parent.images) do 
			if (ui:scaledImageButtonWithText(v.texture, v.name .. "##EMITTER_IMG_SELECTOR_"..id, 20, 20, 4)) then 
				self:updateTexture(v.texture, v.name)
			end
			if (ui:isItemHovered()) then
				ui:beginTooltip()
				ui:scaledImage(v.texture, self.settings.previewSize, self.settings.previewSize)
				ui:endTooltip()
			end
		end
		ui:endCombo()
	end
	if (self.image) then 
		ui:sameLine()
		if (ui:button("X##EMITTER_DEL_IMG_"..id)) then 
			self:updateTexture(nil, "")
		end
		ui:text("Preview:")
		local w = ui:getContentRegionAvail()
		ui:scaledImage(self.image, w, self.settings.previewSize, self.colorTransform, self.colorTransformAlpha)
	else
		ui:text("Preview:")
		local w = ui:getContentRegionAvail()
		ui:dummy(w, self.settings.previewSize)
	end
	
	ui:separatorText("Blend mode")
	local blendModeChanged = false
	self.blendMode, blendModeChanged = ui:combo("##EMITTER_BLEND_"..id, self.blendMode, BLEND_MODES)
	
	if (blendModeChanged) then 
		self:updateBlendMode()
	end	
	
	ui:separatorText("Spawn rate")
	self.spawnRate = ui:sliderInt("##EMITTER_RATE_"..id, self.spawnRate, 1, 1000)	
	
	ui:separatorText("Color transform")	
	local colorChanged = false
	self.colorTransform, self.colorTransformAlpha, colorChanged = ui:colorEdit4("##EMITTER_COLOR_"..id, self.colorTransform, self.colorTransformAlpha)
	if (colorChanged) then 
		self:updateColorTransform()
	end
	
	ui:popItemWidth()
end
--
function Emitter:draw(id)
	local ui = self.ui
	local mode, id1, id2
	if (ui:collapsingHeader(self.name)) then 
		mode, id1, id2 = self:dragAndDrop(id)
		ui:indent()
		
		self:drawBody(id)
		
		ui:unindent()
	else
		mode, id1, id2 = self:dragAndDrop(id)
	end
	
	return mode, id1, id2
end
--