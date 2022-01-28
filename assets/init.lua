function require2(module)
	if package.loaded[module] then return package.loaded[module] end
	local m
	if package.preload[module] then
		assert(type(package.preload[module])=="function","Module loader isn't a function")
		m=package.preload[module](module) or true
	else
		local paths={ "%s.lua", "_LuaPlugins_/%s.lua", "%s/init.lua", "_LuaPlugins_/%s/init.lua" } 
		local tp=1
		while not m and paths[tp] do
			local luafile = loadfile(paths[tp]:format(module))		
			if luafile and type(luafile)=="function" then 
				m = luafile(module) or true
			end		
			tp+=1
		end
	end
	assert(m,"Module "..module.." not found")
	package.loaded[module]=m or true
	return m
end