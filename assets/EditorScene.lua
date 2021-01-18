--!NOEXEC
local ui = UI

local MAIN_WINDOW_FLAGS = ImGui.WindowFlags_NoTitleBar | ImGui.WindowFlags_NoCollapse | ImGui.WindowFlags_NoResize | ImGui.WindowFlags_NoMove | ImGui.WindowFlags_NoBringToFrontOnFocus | ImGui.WindowFlags_NoNavFocus | ImGui.WindowFlags_MenuBar

EditorScene = Core.class(Sprite)

function EditorScene:init()
	self.particleSystem = Particles.new()
	
	self.view = RenderTarget.new(Game.W, Game.H, true)
	self:addChild(ui)
	
	self:addEventListener("enterFrame", self.drawGUI, self)
	
	self.subParticles = {}
	
	self.activePS = nil
	
	self.showCombinedResult = true
	self.showLog = false
	self.showStyleEditor = false
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
		local x1, y1, x2, y2 = ui:getWindowBounds()
		local w = x2 - x1
		local h = y2 - y1		
		if (self.showCombinedResult) then 		
			self.particleSystem:addParticles{
				{x=math.random(4*64),y=math.random(5*256),size=math.random(1,30),color=0xD9B589,ttl=1*60,speedX=1,speedY=0},
				{x=math.random(2*64),y=math.random(5*256),size=math.random(1,30),color=0xffff00,ttl=30*6,speedX=10,speedY=0},
			}
			self.view:clear(0, 0)
			self.view:draw(self.particleSystem)
			ui:scaledImage(self.view, w, h)
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
	if (ui:button("+ add emitter", -1)) then 
		local sub = SubParticleSystem.new()
		local n = #self.subParticles + 1
		self.subParticles[n] = {
			name = "Emitter"..n,
			ps = sub,
		}
	end
	ui:separator()
	for i,t in ipairs(self.subParticles) do 
		ui:pushStyleColor(ImGui.Col_FrameBg, 0, 0)
		ui:pushID(i * GI_EMITTERS)
		t.name = ui:inputText("", t.name, 128)
		ui:popID()
		ui:popStyleColor()
		if (ui:treeNode(t.name)) then 
			t.ps:draw()
			ui:popTree()
		end
	end
	
end
