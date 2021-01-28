application:setBackgroundColor(0x323232)
require "ImGui_beta"
require "ParticlesEditor"

Window = {}

local ui = ImGui.new() 
ui:setAutoUpdateCursor(true)

local IO = ui:getIO()
local showEditor = true

function onWindowResize()
	local minX, minY, maxX, maxY = application:getLogicalBounds()
	local W, H = maxX - minX, maxY - minY
	
	ui:setPosition(minX, minY)
	IO:setDisplaySize(W, H)
	
	Window.X = minX
	Window.Y = minY
	Window.Right = maxX
	Window.Bottom = maxY
	Window.W = W
	Window.H = H
	Window.CX = minX + W / 2
	Window.CY = minY + H / 2
end

loadStyles(ui)
onWindowResize()

local editor = ParticlesEditor.new(ui, false)

local function onDrawGui(e)
	ui:newFrame(e)

	if (showEditor) then 
		local drawEditor = false
		ui:setNextWindowPos(Window.Right - 400, Window.Y, ImGui.Always)
		ui:setNextWindowSize(400, Window.H, ImGui.Always)
		showEditor, drawEditor = ui:beginWindow("Particles editor v1.0", showEditor, ImGui.WindowFlags_NoResize)
		if (drawEditor) then 
			editor:draw()			
		end
		ui:endWindow()
	end
	
	ui:render()
	ui:endFrame()
end

stage:addChild(editor)
stage:addChild(ui)

stage:addEventListener("applicationResize", onWindowResize)
stage:addEventListener("enterFrame", onDrawGui)