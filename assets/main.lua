IO = io

local ui = ImGui.new() 
ui:setAutoUpdateCursor(true)
io = ui:getIO()
io:setIniFilename(nil) -- disable INI file (new API)
io:addConfigFlags(ImGui.ConfigFlags_DockingEnable)
loadStyles(ui)
UI = ui

local function onWindowResize()	
	local minX, minY, maxX, maxY = application:getLogicalBounds()
	local W, H = maxX - minX, maxY - minY
	
	ui:setPosition(minX, minY)
	io:setDisplaySize(W, H)
	
	Game.Left = minX
	Game.Right = maxX
	Game.Top = minY
	Game.Bottom = maxY
	Game.W = W
	Game.H = H
	Game.CX = minX + W / 2
	Game.CY = minY + H / 2
end

onWindowResize()
stage:addEventListener("applicationResize", onWindowResize)

require "EditorScene"
require "SubParticleSystem"
stage:addChild(EditorScene.new())

--[[
local data = {
	-- slider, name, initValue, initMin, initMax, valueMin, valueMax, randomMin, randomMax
	{"Float", "xPos", 0.5, 0, 0, 0, 1, -0.5, 0.5},
	{"Float", "yPos", 0.5, 0, 0, 0, 1, -0.5, 0.5},
	{"Float", "size", 10, 0, 0, 0, 256, 0, 128},
	{"Int", "ttl", 30, 0, 0, 0, 30*60, 0, 30*30},
	{"Float", "speedX", 0, 0, 0, -8, 8, -8, 8},
	{"Float", "speedY", 0, 0, 0, -8, 8, -8, 8},
	{"Float", "angle", 0, 0, 0, 0, 360, 0, 360},
	{"Float", "speedAngular", 0, 0, 0, -2, 2, -0.5, 0.5},
	{"Float", "speedGrowth", 0, 0, 0, -2, 2, -0.5, 0.5},
	{"Float", "decay", 1, 0, 0, -2, 2, -0.5, 0.5},
	{"Float", "decayAngular", 1, 0, 0, -2, 2, -0.5, 0.5},
	{"Float", "decayGrowth", 1, 0, 0, -2, 2, -0.5, 0.5},
	{"Float", "decayAlpha", 1, 0, 0, -2, 2, -0.5, 0.5},
}
local str =  "\t\tif (ui:treeNode(\"%s##\"..id)) then\n"
str = str .. "\t\t\tself.%s = ui:slider%s(\"%s##\"..id, self.%s, %s, %s)\n"
str = str .. "\t\t\tself.%s_min, self.%s_max = ui:sliderFloat2(\"Randomize##%s\"..id, self.%s_min, self.%s_max, %s, %s)\n"
str = str .. "\t\t\tif (ui:button(\"Reset##%s\"..id, -1)) then\n"
str = str .. "\t\t\t\tself.%s = %s\n"
str = str .. "\t\t\t\tself.%s_min = %s\n"
str = str .. "\t\t\t\tself.%s_max = %s\n"
str = str .. "\t\t\tend\n"
str = str .. "\t\t\tui:treePop()\n"
str = str .. "\t\tend"
function fup(s) return s:sub(1,1):upper()..s:sub(2) end
for i,t in ipairs(data) do
	local sliderTP = t[1]
	local v = t[2]
	local f = fup(v)
	print(str:format(f,v,sliderTP,f,v,tostring(t[6]),tostring(t[7]),v,v,f,v,v,tostring(t[8]),tostring(t[9]),f,v,tostring(t[3]),v,tostring(t[4]),v,tostring(t[5]) ))
end
--]]