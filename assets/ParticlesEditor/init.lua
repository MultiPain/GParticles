--!NOEXEC
local PATH = (...):gsub('%.[^%.]+$', '')

if (not ImGui) then require "ImGui_beta" end
if (not lfs) then require "lfs" end

require(PATH.."/Emitter")
require(PATH.."/ImGuiExt")

local SAVE_FILE_NAME = "ParticlesEditor.json"

local ICO_PARTICLES = utf8.char(0xE3A5)
local ICO_TRASH = utf8.char(0xE872)
local ICO_ON = utf8.char(0xE8F4)
local ICO_OFF = utf8.char(0xE8F5)
local ICO_PEN = utf8.char(0xE3C9)
local ICO_SAVE = utf8.char(0xE161)
local ICO_NEW = utf8.char(0xE05E)
local ICO_X = utf8.char(0xE14C)

local defaultOptions = {
	previewSize = 64,
	overrideBgColor = false,
	bgColor = 0,
	bgAlpha = 0,
}

ParticlesEditor = Core.class(Sprite)
ParticlesEditor.GLOBAL_ID = 1
--
local function clamp(v, min, max)
	return (v<>min)><max
end
--
local function frandom(min, max)
	if (not max) then 
		max = min
		min = 0
	end
	return min + random() * (max - min)
end
--
local function split(inputstr, sep)
	local t = {}
	local pattern = "([^"..sep.."]+)"
	
	for str in inputstr:gmatch(pattern) do
		table.insert(t, str)
	end
	return t
end
--
function ParticlesEditor:init(imgui, enableSaveSettings)
	self.ui = imgui
	self.io = self.ui:getIO()
	
	if (ImGui.ConfigFlags_DockingEnable) then 
		self.dockingEnabled = true
		self.io:addConfigFlags(ImGui.ConfigFlags_DockingEnable)
	end
	
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
	
	self.showDemoWindow = false
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
	self:addChild(emitter)
	self.emitters[#self.emitters + 1] = emitter
	ParticlesEditor.GLOBAL_ID += 1
end
--
function ParticlesEditor:draw()
	local ui = self.ui
	local io = self.io
	
	self.showDemoWindow = ui:checkbox("Show demo", self.showDemoWindow)
	
	if (self.showDemoWindow) then 
		self.showDemoWindow = ui:showDemoWindow(self.showDemoWindow)
	end
	
	if (ui:beginTabBar("TabBar")) then 
		if (ui:beginTabItem("Emitters")) then 
		
			local w, h = ImGui:getContentRegionAvail()
			
			ui:beginChild(1, w, h - 50)
			
			if (ui:button("+ emitter", -1)) then 
				self:addEmitter()
			end
			ui:separator()
			
			local i = 1
			local len = #self.emitters
			
			while (i <= len) do 
				local ps = self.emitters[i]
				
				local mode, id0, id1 = ps:draw(i)
				if (ps.delete) then 
					table.remove(self.subParticles, i)
					len -= 1
				else
					if (mode == "copy") then 
						--self.emitters[id1]:copyFrom(self.subParticles[id0])
					elseif (mode == "swap") then 
						self.emitters[id0], self.emitters[id1] = self.emitters[id1], self.emitters[id0]
					end
					i += 1
				end
			end	
			
			ui:endChild()
			
			ui:button(ICO_TRASH, -1, -1)
			if (ui:isItemHovered()) then 
				ui:beginTooltip()
				ui:text("Drag & drop emitter here")
				ui:endTooltip()
			end
			if (ui:beginDragDropTarget()) then
				local payload = ui:acceptDragDropPayload("EMITTER")
				if (payload) then
					local id = payload:getNumData()
					table.remove(self.emitters, id)
				else
					payload = ui:acceptDragDropPayload("SUB_EMITTER")
					
					if (payload) then
						local str = payload:getStrData()
						local t = split(str, ";")
						table.remove(self.emitters[t[1]].subEmitters, t[2])
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


