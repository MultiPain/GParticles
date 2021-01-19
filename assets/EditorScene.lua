--!NOEXEC
local BLEND_MODES = {"None", Sprite.ADD, Sprite.ALPHA, Sprite.MULTIPLY, Sprite.NO_ALPHA, Sprite.SCREEN}
local ui = UI
local GameData = Game

local MAIN_WINDOW_FLAGS = ImGui.WindowFlags_NoTitleBar | ImGui.WindowFlags_NoCollapse | ImGui.WindowFlags_NoResize | ImGui.WindowFlags_NoMove | ImGui.WindowFlags_NoBringToFrontOnFocus | ImGui.WindowFlags_NoNavFocus | ImGui.WindowFlags_MenuBar

EditorScene = Core.class(Sprite)

function EditorScene:init()
	self.particleSystem = Particles.new()
	
	self.rtOriginW = GameData.W
	self.rtOriginH = GameData.H
	self.view = RenderTarget.new(GameData.W, GameData.H, true)
	self:addChild(ui)
	
	self:addEventListener("enterFrame", self.drawGUI, self)
	
	self.subParticles = {}
	
	self.activePS = nil
	
	self.showCombinedResult = true
	self.showLog = false
	self.showStyleEditor = false
	
	self.image = nil
	self.imageName = ""
	self.blendMode = 0
	
	
	self:loadImages("|R|gfx")
end
--
function EditorScene:loadImages(dir)
	self.images = {}
	
	for entry in lfs.dir(dir) do
		if (entry ~= "." and entry ~= "..") then
			local path = dir.."/"..entry
			local attributes = lfs.attributes(path)
			if (attributes.mode == "file") then 
				local ext = entry:match("(%.[^/]*)")
				if (ext == ".jpg" or ext == ".jpeg" or ext == ".png") then 
					self.images[#self.images + 1] = {
						texture = Texture.new(path, true),
						name = entry,
						path = path,
						ext = ext
					}
				end
			else
				self:loadImages(path)
			end
		end
	end
end
--
function EditorScene:drawGUI(e)
	ui:newFrame(e)
	local dockspace_id = ui:getID("root")
	
	if (not ui:dockBuilderCheckNode(dockspace_id)) then 
		self:createDock(ui, dockspace_id)
	end
	
	ui:pushStyleVar(ImGui.StyleVar_WindowPadding, 0, 0)
	if (ui:beginFullScreenWindow("DockSpace Demo", nil, MAIN_WINDOW_FLAGS)) then 
		ui:popStyleVar()
		
		ui:dockSpace(dockspace_id, 0, 0, ImGui.DockNodeFlags_NoWindowMenuButton | ImGui.DockNodeFlags_NoCloseButton)
		
		if (ui:beginMenuBar()) then 
			if (ui:beginMenu("File")) then 
				if (ui:menuItem("Open", "CTRL+O")) then 
					
				end
				if (ui:menuItem("Save", "CTRL+S")) then 
					
				end
				if (ui:menuItem("Save as", "CTRL+SHIFT+S")) then 
					
				end
				ui:endMenu()
			end 
			if (ui:beginMenu("Windows")) then 
				if (ui:menuItem("Log", nil, self.showLog)) then 
					self.showLog = not self.showLog
				end
				if (ui:menuItem("Style editor", nil, self.showStyleEditor)) then 
					self.showStyleEditor = not self.showStyleEditor
				end
				ui:endMenu()
			end
			ui:endMenuBar()
		end
	end
	
	ui:endWindow()
	
	if (ui:beginWindow("Particles", nil, ImGui.WindowFlags_NoBackground | ImGui.WindowFlags_NoMove | ImGui.WindowFlags_NoScrollbar)) then
		local w, h = ui:getContentRegionAvail()	
		if (self.showCombinedResult) then 		
			--self.particleSystem:addParticles{
			--	{x=math.random(4*64),y=math.random(5*256),size=math.random(1,30),color=0xD9B589,ttl=1*60,speedX=1,speedY=0},
			--	{x=math.random(2*64),y=math.random(5*256),size=math.random(1,30),color=0xffff00,ttl=30*6,speedX=10,speedY=0},
			--}
			
			for i,ps in ipairs(self.subParticles) do 
				if (ps.visible) then 
					addParticles(self.particleSystem, ps, self.rtOriginW, self.rtOriginH)
				end
			end
			
			self.view:clear(0, 0)
			self.view:draw(self.particleSystem)
			ui:scaledImage(self.view, w, h, nil, nil, 0, 1)
		elseif (self.activePS) then
			--self.view:clear(0, 0)
			--self.view:draw(self.particleSystem)
			--ui:scaledImage(self.view, w, h)
		end
	end
    ui:endWindow()
	
	if (self.showLog) then 
		self.showLog = ui:showLog("Log", self.showLog, ImGui.WindowFlags_NoMove)
	end
	
	if (ui:beginWindow("Emitters", nil, ImGui.WindowFlags_NoMove | ImGui.WindowFlags_NoResize)) then
		self:drawProperties()
	end
    ui:endWindow()
	
	if (self.showStyleEditor) then
		self.showStyleEditor = ui:showLuaStyleEditor("Style editor", self.showStyleEditor, ImGui.WindowFlags_NoMove)
	end
	
	--ui:showDemoWindow()
	
	ui:render()
	ui:endFrame()
end
--
function EditorScene:createDock(ui, dockspace_id)
	ui:dockBuilderRemoveNode(dockspace_id)
	ui:dockBuilderAddNode(dockspace_id)
	
	-- split main node into 2 (left and right node), return left panel id AND modified dockspace id
	local dock_id_left,_,dockspace_id= ui:dockBuilderSplitNode(dockspace_id, ImGui.Dir_Left, 0.2, nil, dockspace_id)
	local dock_id_right,_,dockspace_id= ui:dockBuilderSplitNode(dockspace_id, ImGui.Dir_Right, 0.5, nil, dockspace_id)
	
	-- split right node into 2, return bottom panel id
	local dock_id_bottom = ui:dockBuilderSplitNode(dockspace_id, ImGui.Dir_Down, 0.2, nil, dockspace_id)
	
	-- split right node into 2 (but in different direction), return top panel id
	local dock_id_top = ui:dockBuilderSplitNode(dockspace_id, ImGui.Dir_Up, 0.7, nil, dockspace_id)

	ui:dockBuilderDockWindow("Particles", dock_id_top)
	ui:dockBuilderDockWindow("Log", dock_id_bottom)
	ui:dockBuilderDockWindow("Emitters", dock_id_left)
	ui:dockBuilderDockWindow("Style editor", dock_id_right)
	ui:dockBuilderFinish(dockspace_id)
end
--
function EditorScene:drawProperties()
	if (self.image) then 
		ui:scaledImage(self.image, 32, 32)
	end
	
	if (ui:beginCombo("Image##MAIN", self.imageName)) then 
		for i,v in ipairs(self.images) do 
			if (ui:scaledImageButtonWithText(v.texture, v.name .. "##MAIN", 20, 20)) then 
				self.image = v.texture
				self.imageName = v.name
				
				self.particleSystem:setTexture(v.texture)
			end
		end
		ui:endCombo()
	end
	
	local blendModeChanged = false
	self.blendMode, blendModeChanged = ui:combo("Blend mode##MAIN", self.blendMode, BLEND_MODES)
	
	if (blendModeChanged) then 
		if (self.blendMode == 0) then 
			self.particleSystem:clearBlendMode()
		else
			self.particleSystem:setBlendMode(BLEND_MODES[self.blendMode + 1])
		end
	end
	
	if (ui:button("+ add emitter", -1)) then 
		GameData.EmitterID += 1
		local sub = SubParticleSystem.new("Emitter"..GameData.EmitterID, self.images)
		self.subParticles[#self.subParticles + 1] = sub
	end
	ui:separator()
	
	local w, h = ImGui:getContentRegionAvail()
	
	ui:beginChild(1, w, h - 50)
	
	
	local i = 1
	local len = #self.subParticles
	
	while (i <= len) do 
		local ps = self.subParticles[i]
		
		local mode, id0, id1 = ps:draw(i)
		if (ps.delete) then 
			table.remove(self.subParticles, i)
			len -= 1
		else
			if (mode == "copy") then 
				self.subParticles[id1]:copyFrom(self.subParticles[id0])
			elseif (mode == "swap") then 
				self.subParticles[id0], self.subParticles[id1] = self.subParticles[id1], self.subParticles[id0]
			end
			i += 1
		end
	end	
	
	ui:endChild()
	ui:button("Delete", -1, -1)
	if (ui:isItemHovered()) then 
		ui:beginTooltip()
		ui:text("Drag and drop emitter here")
		ui:endTooltip()
	end
	if (UI:beginDragDropTarget()) then
		local payload = UI:acceptDragDropPayload("EMITTER")
		if (payload) then
			local id = payload:getNumData()
			table.remove(self.subParticles, id)
		end
	end
end
