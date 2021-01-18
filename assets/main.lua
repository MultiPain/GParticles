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