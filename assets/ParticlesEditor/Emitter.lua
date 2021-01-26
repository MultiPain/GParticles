--!NOEXEC

local function frandom(min, max)
	if (not max) then 
		max = min
		min = 0
	end
	return min + random() * (max - min)
end