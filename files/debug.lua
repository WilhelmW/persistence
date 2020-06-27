function str(var)
	if type(var) == 'table' then
		local s = '{\n'
		for k,v in pairs(var) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			s = s .. '\t['..k..'] = ' .. string.gsub(str(v), "\n", "\n\t") .. ',\n'
		end
		return s .. '}'
	end
	return tostring(var)
end


function debug_entity(e)
	local parent = EntityGetParent(e)
	local children = EntityGetAllChildren(e)
	local comps = EntityGetAllComponents(e)

	print("--- ENTITY DATA ---")
	print("Parent: ["..parent.."] " .. (EntityGetName(parent) or "nil"))

	print(" Entity: ["..tostring(e).."] " .. (EntityGetName(e) or "nil"))
	print("  Tags: " .. (EntityGetTags(e) or "nil"))
	if (comps ~= nil) then
		for _, comp in ipairs(comps) do
			print("  Comp: ["..comp.."] " .. (ComponentGetTypeName(comp) or "nil"))
			if comp ~= nil then
				for member_key, member_val in pairs(ComponentGetMembers(comp)) do
					--[[if member_val == "" then
						print("   [" .. member_key .. "]:")
						for object_key, object_val in pairs(ComponentObjectGetMembers(comp, member_key)) do
							print("    [" .. object_key .. "]: " .. (object_val or "nil"))
						end
					else]]--
						print("   [" .. member_key .. "]: " .. (member_val or "nil"))
					--end
				end
			end
		end
	end

	if children == nil then return end

	for _, child in ipairs(children) do
		local comps = EntityGetAllComponents(child)
		print("  Child: ["..child.."] " .. EntityGetName(child))
		for _, comp in ipairs(comps) do
			print("   Comp: ["..comp.."] " .. (ComponentGetTypeName(comp) or "nil"))
			if comp ~= nil then
				for member_key, member_val in pairs(ComponentGetMembers(comp)) do
					--[[if member_val == "" then
						print("   [" .. member_key .. "]:")
						for object_key, object_val in pairs(ComponentObjectGetMembers(comp, member_key)) do
							print("    [" .. object_key .. "]: " .. (object_val or "nil"))
						end
					else]]--
						print("   [" .. member_key .. "]: " .. (member_val or "nil"))
					--end
				end
			end
		end
	end
	print("--- END ENTITY DATA ---")
end