application:setBackgroundColor(0x323232)
require "ImGui"
require "ParticlesEditor"

Window = {}

local ui = ImGui.new() 
ui:setAutoUpdateCursor(true)

local IO = ui:getIO()
local showEditor = true
local showDemo = false

local function loadStyles(imgui)
	local style = imgui:getStyle()
	
	--style:setColor(ImGui.Col_DockingEmptyBg, 0x333333, 1.00)
	--style:setColor(ImGui.Col_DockingPreview, 0x4296f9, 0.70)
	
	style:setColor(ImGui.Col_TabHovered, 0x54575b, 0.83)
	style:setColor(ImGui.Col_NavWindowingHighlight, 0xffffff, 0.70)
	style:setColor(ImGui.Col_FrameBgActive, 0xababaa, 0.39)
	style:setColor(ImGui.Col_PopupBg, 0x212426, 1.00)
	style:setColor(ImGui.Col_DragDropTarget, 0x1ca3ea, 1.00)
	style:setColor(ImGui.Col_FrameBgHovered, 0x616160, 1.00)
	style:setColor(ImGui.Col_ScrollbarBg, 0x050505, 0.53)
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
	style:setColor(ImGui.Col_TableRowBgAlt, 0x00ff00, 1)
	
	style:setWindowRounding(0)
	style:setChildRounding(0)
	style:setPopupRounding(3)
	style:setFrameRounding(3)
	style:setScrollbarRounding(0)
	style:setGrabRounding(3)
	style:setTabRounding(0)
end

local function onWindowResize()
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
		ui:setNextWindowPos(Window.Right - 450, Window.Y, ImGui.Always)
		ui:setNextWindowSize(450, Window.H, ImGui.Always)
		showEditor, drawEditor = ui:beginWindow("Particles editor v0.5", showEditor)
		if (drawEditor) then 
			if (ui:button("DEMO")) then 
				showDemo = true
			end
			editor:draw()
		end
		ui:endWindow()
	end
	
	if (showDemo) then 
		showDemo = ui:showDemoWindow(showDemo)
	end
	
	ui:render()
	ui:endFrame()
end

stage:addChild(editor)
stage:addChild(ui)

stage:addEventListener("applicationResize", onWindowResize)
stage:addEventListener("enterFrame", onDrawGui)