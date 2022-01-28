--!NOEXEC
local function frandom(min, max)
	if (not max) then 
		max = min
		min = 0
	end
	return min + math.random() * (max - min)
end

local function clamp(v, min, max)
	return (v<>min)><max
end

local function map(value, istart, istop, ostart, ostop)
    return ostart + (ostop - ostart) * ((value - istart) / (istop - istart))
end

local function cmap(value, istart, istop, ostart, ostop)
	return clamp(map(value, istart, istop, ostart, ostop), ostart, ostop)
end

ParticlesEditor.split = string.split
ParticlesEditor.frandom = frandom
ParticlesEditor.split = split
ParticlesEditor.clamp = clamp
ParticlesEditor.map = map
ParticlesEditor.cmap = cmap