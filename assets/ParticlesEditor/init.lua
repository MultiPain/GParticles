--!NOEXEC
local PATH = (...):gsub('%.[^%.]+$', '')

if (not ImGui) then require "ImGui_beta" end
if (not lfs) then require "lfs" end

require(PATH.."/Emitter")
require(PATH.."/ImGuiExt")

local SAVE_FILE_NAME = "ParticlesEditor.json"

local BLEND_MODES = {"None", Sprite.ADD, Sprite.ALPHA, Sprite.MULTIPLY, Sprite.NO_ALPHA, Sprite.SCREEN}
local COLOR_PICKER_FLAGS = ImGui.ColorEditFlags_AlphaPreviewHalf | ImGui.ColorEditFlags_AlphaPreview

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
--
local function clamp(v, min, max)
	return (v<>min)><max
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
	
	self.particles = Particles.new()
	self:addChild(self.particles)
	
	self.emitters = {}
	self.images = {}
	
	self.image = nil
	self.imageName = ""
	self.blendMode = 0
	self.colorTransform = 0xffffff
	self.colorTransformAlpha = 1
	self.spawnRate = 1
	self.isPaused = false
	
	self:loadImages("|R|"..PATH.."/images")
	
	self.settings = {}
	
	self:loadSave()
	for key, value in pairs(defaultOptions) do 
		if (not self.settings[key]) then 
			self.settings[key] = value
		end
	end
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
	self.emitters[#self.emitters + 1] = Emitter.new()
end
--
function ParticlesEditor:updateTexture(texture, name)
	self.image = texture
	self.imageName = name
	if (texture) then 
		self.particles:setTexture(texture)
		for i,ps in ipairs(self.particles) do 
			ps.particles:setTexture(texture)
		end
	else
		self.particles:clearTexture()
		for i,ps in ipairs(self.particles) do 
			ps.particles:clearTexture()
		end
	end
end
--
function ParticlesEditor:updateBlendMode()
	if (self.blendMode == 0) then 
		self.particles:clearBlendMode()
		for i,ps in ipairs(self.particles) do 
			ps.particles:clearBlendMode()
		end
	else
		self.particles:setBlendMode(BLEND_MODES[self.blendMode + 1])
		for i,ps in ipairs(self.particles) do 
			ps.particles:setBlendMode(BLEND_MODES[self.blendMode + 1])
		end
	end
end
--
function ParticlesEditor:updateColorTransform()
	local r, g, b = self.ui:colorConvertHEXtoRGB(self.colorTransform)
	self.particles:setColorTransform(r, g, b, self.colorTransformAlpha)
	for i,ps in ipairs(self.particles) do 
		ps.particles:setColorTransform(r, g, b, self.colorTransformAlpha)
	end
end
--
function ParticlesEditor:drawEmitters()
	local ui = self.ui
	ui:separatorText("Texture")
	
	ui:pushItemWidth(-1)
	if (ui:beginCombo("##MAIN_IMAGE", self.imageName, ImGui.ComboFlags_NoArrowButton)) then 
		for i,v in ipairs(self.images) do 
			if (ui:scaledImageButtonWithText(v.texture, v.name .. "##MAIN_IMAGE", 20, 20, 4)) then 
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
		if (ui:button("X##MAIN_DELETE_IMAGE")) then 
			self:updateTexture(nil, "")
		end
		ui:text("Preview:")
		local w = ui:getContentRegionAvail()
		ui:scaledImage(self.image, w, self.settings.previewSize)
	else
		ui:text("Preview:")
		local w = ui:getContentRegionAvail()
		ui:dummy(w, self.settings.previewSize)
	end
	
	ui:separatorText("Blend mode")
	local blendModeChanged = false
	self.blendMode, blendModeChanged = ui:combo("##MAIN_BLEND_MODE", self.blendMode, BLEND_MODES)
	
	if (blendModeChanged) then 
		self:updateBlendMode()
	end	
	
	ui:separatorText("Spawn rate")
	self.spawnRate = ui:sliderInt("##MAIN_SPAWN_RATE", self.spawnRate, 1, 1000)	
	
	ui:separatorText("Color transform")	
	local colorChanged = false
	self.colorTransform, self.colorTransformAlpha, colorChanged = ui:colorEdit4("##MAIN_COLOR_TRANSFORM", self.colorTransform, self.colorTransformAlpha)
	if (colorChanged) then 
		self:updateColorTransform()
	end
	ui:separatorText("IDK")	
	
	ui:popItemWidth(w)
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
--
local flags = ImGui.TableFlags_Borders | ImGui.TableFlags_RowBg
function ParticlesEditor:PushStyleCompact()
    local style = self.ui:getStyle()
	local fx, fy = style:getFramePadding()
	local ix, iy = style:getItemSpacing()
    self.ui:pushStyleVar(ImGui.StyleVar_FramePadding, fx, fy * 0.6)
    self.ui:pushStyleVar(ImGui.StyleVar_ItemSpacing, ix, iy * 0.6)
end
--
function ParticlesEditor:draw()
	local ui = self.ui
	local io = self.io
	
	self.showDemoWindow = ui:checkbox("Show demo", self.showDemoWindow)
	
	if (self.showDemoWindow) then 
		self.showDemoWindow = ui:showDemoWindow(self.showDemoWindow)
	end
	
	if (ui:treeNode("Borders, background")) then
	
	self:PushStyleCompact()
    flags = ui:checkboxFlags("ImGuiTableFlags_RowBg", flags, ImGui.TableFlags_RowBg)
    flags = ui:checkboxFlags("ImGuiTableFlags_Borders", flags, ImGui.TableFlags_Borders)
    ui:indent()
	
	flags = ui:checkboxFlags("ImGuiTableFlags_BordersH", flags, ImGui.TableFlags_BordersH)
    ui:indent()
    
	flags = ui:checkboxFlags("ImGuiTableFlags_BordersOuterH", flags, ImGui.TableFlags_BordersOuterH)
    flags = ui:checkboxFlags("ImGuiTableFlags_BordersInnerH", flags, ImGui.TableFlags_BordersInnerH)
	ui:unindent()
	
    flags = ui:checkboxFlags("ImGuiTableFlags_BordersV", flags, ImGui.TableFlags_BordersV)
    ui:indent()
    flags = ui:checkboxFlags("ImGuiTableFlags_BordersOuterV", flags, ImGui.TableFlags_BordersOuterV)
    flags = ui:checkboxFlags("ImGuiTableFlags_BordersInnerV", flags, ImGui.TableFlags_BordersInnerV)
    ui:unindent()

    flags = ui:checkboxFlags("ImGuiTableFlags_BordersOuter", flags, ImGui.TableFlags_BordersOuter)
    flags = ui:checkboxFlags("ImGuiTableFlags_BordersInner", flags, ImGui.TableFlags_BordersInner)
    ui:unindent()
	ui:popStyleVar(2)
	
	ui:treePop()
	end
	
	if (ui:beginTabBar("TabBar")) then 
		if (ui:beginTabItem("Emitters")) then 
			
			self:drawEmitters()
			
			ui:endTabItem()
		end
		if (ui:beginTabItem("Settings")) then 
			
			self:drawSettings()
			
			ui:endTabItem()
		end
	end
	ui:endTabBar()
end

