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
	local r, g, b = ui:colorConvertHEXtoRGB(self.colorTransform)
	self.particles:setColorTransform(r, g, b, self.colorTransformAlpha)
	for i,ps in ipairs(self.particles) do 
		ps.particles:setColorTransform(r, g, b, self.colorTransformAlpha)
	end
end
--
function ParticlesEditor:draw()
	local ui = self.ui
	local io = self.io
	local saveSettings = false
	
	if (ui:beginCombo("Image##MAIN", self.imageName, ImGui.ComboFlags_NoArrowButton)) then 
		for i,v in ipairs(self.images) do 
			if (ui:scaledImageButtonWithText(v.texture, v.name .. "##MAIN", 20, 20)) then 
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
		
		local w = ui:getContentRegionAvail()
		ui:scaledImage(self.image, w, self.settings.previewSize)
	else
		local w = ui:getContentRegionAvail()
		ui:dummy(w, self.settings.previewSize)
	end
	
	local blendModeChanged = false
	self.blendMode, blendModeChanged = ui:combo("Blend mode##MAIN", self.blendMode, BLEND_MODES)
	
	if (blendModeChanged) then 
		self:updateBlendMode()
	end	
	ui:separator()
	
	self.spawnRate = ui:sliderInt("Spawn rate##MAIN", self.spawnRate, 1, 1000)	
	ui:separator()
	
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
	
	local colorChanged = false
	self.colorTransform, self.colorTransformAlpha, colorChanged = ui:colorEdit4("Color transform##MAIN", self.colorTransform, self.colorTransformAlpha)
	if (colorChanged) then 
		self:updateColorTransform()
	end
	ui:separator()
	
	if (saveSettings) then
		self:saveSettings()
	end
end