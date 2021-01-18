function ImGui:anhorPoint(id, w, h, minX, maxX, minY, maxY)
	minX = minX or 0
	maxX = maxX or 1
	minY = minY or 0
	maxY = maxY or 1
	
	self:pushID(id)
	
	self:popID()
end