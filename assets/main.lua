require "ParticlesEditor"


local ui = ImGui.new() 
ui:setAutoUpdateCursor(true)
local IO = ui:getIO()
--
function onWindowResize()
	local minX, minY, maxX, maxY = application:getLogicalBounds()
	local W, H = maxX - minX, maxY - minY
	
	ui:setPosition(minX, minY)
	IO:setDisplaySize(W, H)
end

loadStyles(ui)
onWindowResize()
stage:addEventListener("applicationResize", onWindowResize)
stage:addChild(ui)

local editor = ParticlesEditor.new(ui, false)

local showEditor = true
local function onDrawGui(e)
	ui:newFrame(e)
	
	if (showEditor) then 
		local drawEditor = false
		showEditor, drawEditor = ui:beginWindow("Particles editor v1.0", showEditor)
		if (drawEditor) then 
			editor:draw()
		end
		ui:endWindow()
	end
	
	ui:render()
	ui:endFrame()
end

stage:addEventListener("enterFrame", onDrawGui)