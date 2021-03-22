--!NOEXEC
-- ImGui custom widgets

local sin = math.sin
local cos = math.cos
local atan2 = math.atan2
local pi = math.pi
local acos = math.acos
local sqrt = math.sqrt
local length = math.length
local clamp = ParticlesEditor.clamp
local map = ParticlesEditor.map
local cmap = ParticlesEditor.cmap
--
function ImGui:helpMarker(desc)
	self:textDisabled("(?)")
	if (self:isItemHovered()) then
		self:beginTooltip()
		self:pushTextWrapPos(self:getFontSize() * 35)
		self:text(desc)
		self:popTextWrapPos()
		self:endTooltip()
	end
end
--
function ImGui:point(label, size, vx, vy, minX, minY, maxX, maxY)
	minX = minX or -1
	minY = minY or -1
	maxX = maxX or 1
	maxY = maxY or 1
	local offset = 4
	local spacing = 8
	local px, py = self:getCursorScreenPos()
	
	self:invisibleButton("##"..label, size, size)
	
	if (self:isItemActive()) then 
		local mx, my = self:getMousePos()
		
		vx = cmap(mx, px, px + size, minX, maxX)
		vy = cmap(my, py, py + size, minY, maxY)
	end
	
	local backupX, backupY = self:getCursorScreenPos()
	self:sameLine()
	local npx, npy = self:getCursorScreenPos()
	
	local changedX = false
	local changedY = false
	
	self:pushItemWidth(100)
	vx = self:dragFloat("X: "..label, vx, 0.01, minX, maxX)
	local w, h = self:getItemRectSize()	
	self:setCursorScreenPos(npx, npy + h + offset)
	vy = self:dragFloat("Y: "..label, vy, 0.01, minY, maxY)
	self:setCursorScreenPos(backupX, backupY)
	self:popItemWidth()
	
	local draw_list = self:getWindowDrawList()
	local style = self:getStyle()
	local colLn = style:getColor(ImGui.Col_Text)
	
	local cx = map(vx, minX, maxX, px + offset, px + size - offset)
	local cy = map(vy, minY, maxY, py + offset, py + size - offset)
	
	draw_list:addRect(px, py, px + size, py + size, colLn, 1, offset, nil, 1)
	--draw_list:addLine(px + offset, cy, px + size - offset, cy, colLn, 1)
	--draw_list:addLine(cx, py + offset, cx, py + size - offset, colLn, 1)
	
	draw_list:addLine(px + offset, cy, clamp(cx - spacing, px + offset, px + size - offset), cy, colLn, 1)
	draw_list:addLine(cx, py + offset, cx, clamp(cy - spacing, py + offset, py + size - offset), colLn, 1)
	
	draw_list:addLine(clamp(cx + spacing, px, px + size - offset), cy, px + size - offset, cy, colLn, 1)
	draw_list:addLine(cx, clamp(cy + spacing, py, py + size - offset), cx, py + size - offset, colLn, 1)
	
	draw_list:addCircle(cx, cy, spacing / 2, colLn, 1)
	
	return vx, vy
end
--
function ImGui:dial(label, value, size, fac, max_v, offset)
	size = size or 36
	fac = fac or pi * 2
	offset = offset or 5
	local style = self:getStyle()
	
	local px, py = self:getCursorScreenPos()

	local radio =  size*0.5
	local centerx, centery = px + radio, py + radio
	
	self:invisibleButton(label.."t", size, size)
	local is_active = self:isItemActive()
	local is_hovered = self:isItemHovered()
	
	local touched = false
	local io = self:getIO()
	if is_active then 
		touched = true
		local mx, my = self:getMousePos()
		local mdx, mdy = io:getMouseDelta()
		if mdx == 0 and mdy == 0 then touched = false end
		local mpx, mpy = mx - mdx, my - mdy
		local ax = mpx - centerx
		local ay = mpy - centery
		local bx = mx - centerx
		local by = my - centery
		local ma = length(ax, ay)
		local mb = length(bx, by)
		local ab  = ax * bx + ay * by
		local vet = ax * by - bx * ay
		ab = ab / (ma * mb)
		if not (ma == 0 or mb == 0 or ab < -1 or ab > 1) then
			if (vet>0) then
				value += acos(ab) * fac
			else 
				value -= acos(ab) * fac
			end
			value = value % max_v
		end
	end
	
	local col32idx = is_active and ImGui.Col_FrameBgActive or (is_hovered and ImGui.Col_FrameBgHovered or ImGui.Col_FrameBg)
	local col32 = style:getColor(col32idx) 
	local col32line = style:getColor(ImGui.Col_Text) 
	local draw_list = self:getWindowDrawList()
	draw_list:addCircleFilled( centerx, centery, radio, col32, 1 )
	
	local theta = value / fac
	local x2 = cos(theta) * (radio - offset) + centerx
	local y2 = sin(theta) * (radio - offset) + centery
	draw_list:addLine( centerx, centery, x2, y2, col32line, 1, 2 )
	self:sameLine()
	self:pushItemWidth(50)
	value, touched = self:inputFloat(label, value, 0.0, 0.1)
	self:popItemWidth()
	return value, touched
end
--
function ImGui:spread(label, value, size, fac, max_v, adjust, offset)
	size = size or 36
	fac = fac or pi * 2
	offset = offset or 5
	adjust = adjust or 0
	local style = self:getStyle()
	
	local px, py = self:getCursorScreenPos()

	local radio =  size * 0.5
	local centerx, centery = px + radio, py + radio
	
	self:invisibleButton(label.."t", size, size)
	
	local is_active = self:isItemActive()
	local is_hovered = self:isItemHovered()
	
	local touched = false
	local io = self:getIO()
	if is_active then 
		touched = true
		local mx, my = self:getMousePos()
		local mdx, mdy = io:getMouseDelta()
		if mdx == 0 and mdy == 0 then touched = false end
		local mpx, mpy = mx - mdx, my - mdy
		local ax = mpx - centerx
		local ay = mpy - centery
		local bx = mx - centerx
		local by = my - centery
		local ma = length(ax, ay)
		local mb = length(bx, by)
		local ab  = ax * bx + ay * by
		local vet = ax * by - bx * ay
		ab = ab / (ma * mb)
		if not (ma == 0 or mb == 0 or ab < -1 or ab > 1) then
			if (vet>0) then
				value += acos(ab) * fac
			else 
				value -= acos(ab) * fac
			end
			value = clamp(value, 0, max_v)
		end
	end
	
	local col32idx = is_active and ImGui.Col_FrameBgActive or (is_hovered and ImGui.Col_FrameBgHovered or ImGui.Col_FrameBg)
	local col32 = style:getColor(col32idx) 
	local col32line = style:getColor(ImGui.Col_Text) 
	local draw_list = self:getWindowDrawList()
	draw_list:addCircleFilled( centerx, centery, radio, col32, 1)
	
	local theta = value / fac
	local x2 = cos(theta + adjust) * (radio - offset) + centerx
	local y2 = sin(theta + adjust) * (radio - offset) + centery
	draw_list:addLine( centerx, centery, x2, y2, col32line, 1, 2)
	
	x2 = cos(adjust - theta) * (radio - offset) + centerx
	y2 = sin(adjust - theta) * (radio - offset) + centery
	draw_list:addLine( centerx, centery, x2, y2, col32line, 1, 2)
	
	draw_list:pathClear()
	draw_list:pathLineTo(centerx, centery)
	draw_list:pathArcTo(centerx, centery, radio - 5, adjust + theta, adjust - theta)
	draw_list:pathStroke(col32line, 1, 1, 2)
	
	self:sameLine()
	self:pushItemWidth(50)
	value, touched = self:inputFloat(label, value, 0.0, 0.1)
	self:popItemWidth()
	return value, touched
end
--
-- draws separator like that:  ---- label -----------------------
function ImGui:separatorText(label, offset)
	offset = offset or 10
	
	local x, y = self:getWindowPos()
	local w, h = self:getWindowSize()
	local cx, cy = self:getCursorPos()
	local sx = self:getScrollX()
	local sy = self:getScrollY()
	
	local style = self:getStyle()
	local indent = 0 --RRstyle:getIndentSpacing()
	local color, alpha = style:getColor(ImGui.Col_Separator)
	local px, py = style:getWindowPadding()
	local fx, fy = style:getItemSpacing()
	local hfy = fy // 2
	
	self:setCursorPos(px + indent, cy + hfy)
	self:text(label)
	
	local tw, th = self:calcTextSize(label)
	local thh = th // 2 + hfy
	local list = self:getWindowDrawList()
	local ly = y + cy + thh - sy
	local x1 = px + x - sx
	local x2 = x1 + indent - offset
	
	list:addLine(x1, ly, x2, ly, color, alpha)
	list:addLine(x1 + indent + tw + offset, ly, x1 + w, ly, color, alpha)
	
	self:setCursorPos(cx, cy + fy + th)
end