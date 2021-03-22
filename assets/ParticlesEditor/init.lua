--!NOEXEC
local PATH = (...):gsub('%.[^%.]+$', '')

if (not ImGui) then require "ImGui" end
if (not lfs) then require "lfs" end

local TABLE_FLAGS = ImGui.TableFlags_RowBg | ImGui.TableFlags_PadOuterX

local SAVE_FILE_NAME = "ParticlesEditor.json"

local defaultOptions = {
	previewSize = 64,
	overrideBgColor = false,
	bgColor = 0,
	bgAlpha = 0,
}

local ICONS = {
	PARTICLES = utf8.char(0xE3A5),
	TRASH = utf8.char(0xE872),
	PEN = utf8.char(0xE3C9),
	SAVE = utf8.char(0xE161),
	NEW = utf8.char(0xE05E),
	X = utf8.char(0xE14C),
	OFF = utf8.char(0xE8F5),
	ON = utf8.char(0xE8F4),
}

ParticlesEditor = Core.class(Sprite)
ParticlesEditor.GLOBAL_ID = 1
ParticlesEditor.ICONS = ICONS

require(PATH.."/utils")
require(PATH.."/Emitter")
require(PATH.."/ImGuiExt")

function ParticlesEditor:init(imgui, enableSaveSettings)
	self.ui = imgui
	self.io = self.ui:getIO()
	
	local fonts = self.io:getFonts()
	fonts:addFont(PATH.."/MaterialIcons-Regular.ttf", 16, {
		glyphs = {
			ranges = { { 0xE3A2, 0xE3A5, 0 } },
			chars = { 0xE872, 0xE8F4, 0xE8F5, 0xE3C9, 0xE161, 0xE05E, 0xE3A5, 0xE14C },
		},
		oversampleH = 2,
		oversampleV = 1,
		glyphOffsetX = -1,
		glyphOffsetY = 4,
		pixelSnapH = true,
		mergeMode = true,
	})
	fonts:build()
	
	self.dragEmitter = false
	self.dragType = "global" -- "local"
	self.enableSaveSettings = enableSaveSettings
	
	self.emitters = {}
	self.images = {}
	
	self:loadImages("|R|"..PATH.."/images")
	
	self.settings = {}
	
	self:loadSave()
	for key, value in pairs(defaultOptions) do 
		if (not self.settings[key]) then 
			self.settings[key] = value
		end
	end
	
	self:addEmitter()
end
--
function ParticlesEditor:loadSave()
	if (not json) then require "json" end
	
	local file = io.open("|D|"..SAVE_FILE_NAME, "r")
	if (file) then 
		local tString = file:read("*a")
		file:close()
		
		local t = json.decode(tString)
		if (t) then 
			self.settings = t
		end
	end
	
	self.tmpBgColor = application:getBackgroundColor()
	
	if (self.settings.overrideBgColor) then 
		application:setBackgroundColor(self.settings.bgColor)
	end
end
--
function ParticlesEditor:saveSettings()
	if (not self.enableSaveSettings) then return end
	if (not json) then require "json" end
	local file = io.open("|D|"..SAVE_FILE_NAME, "w")
	if (file) then 
		local tString = json.encode(self.settings)
		file:write(tString)
		file:close()
	end
end
--
function ParticlesEditor:loadImages(dir)
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
function ParticlesEditor:addEmitter()
	local name = "Emitter" .. ParticlesEditor.GLOBAL_ID
    local emitter = Emitter.new(self, name)
	emitter:setPosition(Window.CX - 200, Window.CY)
	self:addChild(emitter)
	self.emitters[#self.emitters + 1] = emitter
	ParticlesEditor.GLOBAL_ID += 1
	return emitter
end
--
function ParticlesEditor:save()
	local data = {}
	for i,emitter in ipairs(self.emitters) do 
		local t = emitter:save()
		data[i] = t
	end
	local str = json.encode(data)
	local file = io.open("|D|test.json", "w")
	if (file) then 
		file:write(str)
		file:close()
	end
end
--
function ParticlesEditor:load()
	local file = io.open("|D|test.json", "r")
	if (file) then 
		local str = file:read("*a")
		file:close()
		
		local data = json.decode(str)
		for i = #self.emitters, 1, -1 do
			self:removeChild(self.emitters[i])
			self.emitters[i] = nil
		end
		for i,t in ipairs(data) do 
			local emitter = self:addEmitter()
			emitter:load(t)
		end
	end
end
--
function ParticlesEditor:draw()
	local ui = self.ui
	local io = self.io
	
	if (ui:button("Save")) then 
		self:save()
	end
	ui:sameLine()
	if (ui:button("Load")) then 
		self:load()
	end
	
	if (ui:beginTabBar("TabBar")) then 
		if (ui:beginTabItem("Emitters")) then 
			local w, h = ImGui:getContentRegionAvail()
			
			if (ui:button("+ emitter", -1)) then 
				self:addEmitter()
			end
			ui:separator()
			
			local i = 1
			local len = #self.emitters
			if (len > 0) then
				local list = ui:getBackgroundDrawList()				
				local mx, my = ui:getMousePos()
				while (i <= len) do 
					local ps = self.emitters[i]
					
					local mode, id0, id1 = ps:draw(i)
					
					if (ps.delete) then 
						local child = table.remove(self.emitters, i)
						self:removeChild(child)
						len -= 1
					else
						local x, y = ps:getPosition()
						
						if (ps.visibleMarkers) then
							list:addCircle(x, y, 32, 0, 1, nil, 2)
							list:addCircle(x + ps.posX, y + ps.posY, 20, 0x00ff00, 1, nil, 2)
						end
						
						if (not self.dragEmitter) then 
							local dist1 = math.distance(mx, my, x, y)
							local dist2 = math.distance(mx, my, x + ps.posX, y + ps.posY)
							if (ps.drag or (ui:isMouseClicked(KeyCode.MOUSE_LEFT) and dist1 < 32)) then 
								self.dragEmitter = ps
								self.dragType = "global"
							elseif (ps.drag or (ui:isMouseClicked(KeyCode.MOUSE_RIGHT) and dist2 < 20)) then 
								self.dragEmitter = ps
								self.dragType = "local"
							end
						end
						
						
						if (mode == "copy") then 
							self.emitters[id1]:copyFrom(self.emitters[id0])
						elseif (mode == "swap") then 
							self:swapChildren(self.emitters[id0], self.emitters[id1])
							self.emitters[id0], self.emitters[id1] = self.emitters[id1], self.emitters[id0]
						end
						i += 1
					end
				end	
				
				if (self.dragEmitter) then 
					local dx, dy = self.io:getMouseDelta()
					local x, y = self.dragEmitter:getPosition()
					x += dx
					y += dy
					
					if (self.dragType == "global") then 
						self.dragEmitter:setPosition(x, y)
					else
						self.dragEmitter.posX += dx
						self.dragEmitter.posY += dy
					end
					
					if (ui:isMouseReleased(KeyCode.MOUSE_LEFT) or ui:isMouseReleased(KeyCode.MOUSE_RIGHT)) then 
						self.dragEmitter = false
					end
				end
			end	
			
			ui:endTabItem()
		end
		if (ui:beginTabItem("Settings")) then 
			
			self:drawSettings()
			
			ui:endTabItem()
		end
	end
	ui:endTabBar()
end
--
function ParticlesEditor:drawSettings()
	local ui = self.ui
	
	local saveSettings = false
	
	local bgBoxChanged = false
	self.settings.overrideBgColor, bgBoxChanged = ui:checkbox("Override BG color##MAIN", self.settings.overrideBgColor)
	if (bgBoxChanged) then 
		application:setBackgroundColor(self.tmpBgColor)
		saveSettings = true
	end
	
	if (self.settings.overrideBgColor) then 
		local bgColorChanged = false
		self.settings.bgColor, bgColorChanged = ui:colorEdit3("BG color##MAIN", self.settings.bgColor, COLOR_PICKER_FLAGS)
		
		if (bgColorChanged or bgBoxChanged) then 
			application:setBackgroundColor(self.settings.bgColor)
			saveSettings = true
		end
	end
	
	if (saveSettings) then
		self:saveSettings()
	end
end
