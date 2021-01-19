require "ImGui_beta"
require "lfs"

local random = math.random
local cos = math.cos
local sin = math.sin

PI2 @ 6.28318530718

ICO_PARTICLES = utf8.char(0xE3A5)
ICO_TRASH = utf8.char(0xE872)
ICO_ON = utf8.char(0xE8F4)
ICO_OFF = utf8.char(0xE8F5)
ICO_PEN = utf8.char(0xE3C9)
ICO_SAVE = utf8.char(0xE161)
ICO_NEW = utf8.char(0xE05E)

Game = {
	-- Screen details
	Left = 0, 
	Right = 0,
	Top = 0,
	Bottom = 0,
	W = 0, H = 0,
	CX = 0, CY = 0,
	EmitterID = 0
}

-- Updates after program restarts
Options = {
	PREVIEW_SIZE = 128,
}

function math.clamp(v, min, max)
	return (v<>min)><max
end

function frandom(min, max)
	if (not max) then 
		max = min
		min = 0
	end
	return min + random() * (max - min)
end

function addParticles(particleSystem, subSystem, w, h, scale)
	scale = scale or 1
	local speed = subSystem.speed + random(subSystem.speed_min, subSystem.speed_max)
	local dir = subSystem.direction
	if (subSystem.spread > 0) then 
		dir += frandom(-subSystem.spread, subSystem.spread)
	end
	local theta = ^<dir
	local speedX = cos(theta) * speed
	local speedY = sin(theta) * speed
	particleSystem:addParticles{{
		x = (subSystem.xPos + frandom(subSystem.xPos_min, subSystem.xPos_max)) * w,
		y = (subSystem.yPos + frandom(subSystem.yPos_min, subSystem.yPos_max)) * h,
		size = (subSystem.size + random(subSystem.size_min, subSystem.size_max)) * scale,
		color = subSystem.color,
		alpha = subSystem.alpha,
		ttl = subSystem.ttl + random(subSystem.ttl_min, subSystem.ttl_max),
		speedX = speedX,
		speedY = speedY,
		
		angle = subSystem.angle + random(subSystem.angle_min, subSystem.angle_max),
		speedAngular = subSystem.speedAngular + random(subSystem.speedAngular_min, subSystem.speedAngular_max),
		speedGrowth = subSystem.speedGrowth + random(subSystem.speedGrowth_min, subSystem.speedGrowth_max),
		decay = subSystem.decay + random(subSystem.decay_min, subSystem.decay_max),
		decayAngular = subSystem.decayAngular + random(subSystem.decayAngular_min, subSystem.decayAngular_max),
		decayGrowth = subSystem.decayGrowth + random(subSystem.decayGrowth_min, subSystem.decayGrowth_max),
		decayAlpha = subSystem.decayAlpha + random(subSystem.decayAlpha_min, subSystem.decayAlpha_max),
	}}
end

function loadStyles(imgui)
	local style = imgui:getStyle()
	
	style:setColor(ImGui.Col_TabHovered, 0x54575b, 0.83)
	style:setColor(ImGui.Col_NavWindowingHighlight, 0xffffff, 0.70)
	style:setColor(ImGui.Col_FrameBgActive, 0xababaa, 0.39)
	style:setColor(ImGui.Col_PopupBg, 0x212426, 1.00)
	style:setColor(ImGui.Col_DragDropTarget, 0x1ca3ea, 1.00)
	style:setColor(ImGui.Col_FrameBgHovered, 0x616160, 1.00)
	style:setColor(ImGui.Col_ScrollbarBg, 0x050505, 0.53)
	style:setColor(ImGui.Col_DockingEmptyBg, 0x333333, 1.00)
	style:setColor(ImGui.Col_ResizeGripActive, 0x4296f9, 0.95)
	style:setColor(ImGui.Col_FrameBg, 0x40403f, 1.00)
	style:setColor(ImGui.Col_Separator, 0x6e6e7f, 0.50)
	style:setColor(ImGui.Col_Button, 0x40403f, 1.00)
	style:setColor(ImGui.Col_Header, 0x383838, 1.00)
	style:setColor(ImGui.Col_ScrollbarGrabActive, 0x828282, 1.00)
	style:setColor(ImGui.Col_ModalWindowDimBg, 0xcccccc, 0.35)
	style:setColor(ImGui.Col_NavWindowingDimBg, 0xcccccc, 0.20)
	style:setColor(ImGui.Col_TabUnfocused, 0x141416, 1.00)
	style:setColor(ImGui.Col_HeaderHovered, 0x40403f, 1.00)
	style:setColor(ImGui.Col_BorderShadow, 0x000000, 0.00)
	style:setColor(ImGui.Col_Border, 0x6e6e7f, 0.50)
	style:setColor(ImGui.Col_HeaderActive, 0xababaa, 0.39)
	style:setColor(ImGui.Col_NavHighlight, 0x4296f9, 1.00)
	style:setColor(ImGui.Col_ChildBg, 0x212426, 1.00)
	style:setColor(ImGui.Col_TextSelectedBg, 0x4296f9, 0.35)
	style:setColor(ImGui.Col_TitleBg, 0x141416, 1.00)
	style:setColor(ImGui.Col_PlotHistogramHovered, 0xff9900, 1.00)
	style:setColor(ImGui.Col_PlotHistogram, 0xe6b200, 1.00)
	style:setColor(ImGui.Col_ScrollbarGrab, 0x4f4f4f, 1.00)
	style:setColor(ImGui.Col_CheckMark, 0x1ca3ea, 1.00)
	style:setColor(ImGui.Col_ButtonActive, 0xababaa, 0.39)
	style:setColor(ImGui.Col_PlotLines, 0x9c9c9b, 1.00)
	style:setColor(ImGui.Col_TextDisabled, 0x80807f, 1.00)
	style:setColor(ImGui.Col_ScrollbarGrabHovered, 0x696968, 1.00)
	style:setColor(ImGui.Col_Text, 0xffffff, 1.00)
	style:setColor(ImGui.Col_DockingPreview, 0x4296f9, 0.70)
	style:setColor(ImGui.Col_TitleBgActive, 0x141416, 1.00)
	style:setColor(ImGui.Col_TabUnfocusedActive, 0x212426, 1.00)
	style:setColor(ImGui.Col_SliderGrabActive, 0x1480b7, 1.00)
	style:setColor(ImGui.Col_ResizeGrip, 0x000000, 0.00)
	style:setColor(ImGui.Col_Tab, 0x141416, 0.83)
	style:setColor(ImGui.Col_TitleBgCollapsed, 0x000000, 0.51)
	style:setColor(ImGui.Col_ResizeGripHovered, 0x4a4c4f, 0.67)
	style:setColor(ImGui.Col_TabActive, 0x3b3b3d, 1.00)
	style:setColor(ImGui.Col_WindowBg, 0x212426, 1.00)
	style:setColor(ImGui.Col_SeparatorActive, 0x4296f9, 0.95)
	style:setColor(ImGui.Col_SeparatorHovered, 0x696b70, 1.00)
	style:setColor(ImGui.Col_PlotLinesHovered, 0xff6e59, 1.00)
	style:setColor(ImGui.Col_SliderGrab, 0x1ca3ea, 1.00)
	style:setColor(ImGui.Col_ButtonHovered, 0x616160, 1.00)
	style:setColor(ImGui.Col_MenuBarBg, 0x242423, 1.00)
	
	style:setWindowRounding(0)
	style:setChildRounding(0)
	style:setPopupRounding(3)
	style:setFrameRounding(3)
	style:setScrollbarRounding(0)
	style:setGrabRounding(3)
	style:setTabRounding(0)
end