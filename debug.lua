local Content = ExtraFWMod:getContent()
local debugScript = {
	show_debug = true, --TODO[ ] Set to false on release
	entities_mode = 0, -- 0 = Room list, 1 = Entity data, 2 = Show GridFairnessDebug(In RoomFairness.lua)
	toggle_pressed = false
}

debug_text = "I like debugging - Hide with 0 - Change modes with 1-3"
debug_tbl1 = {one_no = "entries"}
debug_tbl2 = {two_no = "entries"}
debug_entity = nil

function debugScript:displayEntities()
	if not debugScript.show_debug then return end
	
	local entList = Isaac.GetRoomEntities()
	if debugScript.entities_mode == 0 then
		for i = 1, #entList, 1 do
			Isaac.RenderText(tostring(entList[i].Type) .. " " .. tostring(entList[i].Variant) .. " " .. tostring(entList[i].SubType), 40, 10 + (10*i), 255, 0, 0, 255)
		end
		
	elseif debugScript.entities_mode == 1 then
		local room = Game():GetRoom()
		for i = 1, #entList, 1 do
			local e = entList[i]
			local p = Isaac.WorldToRenderPosition(e.Position,true) + room:GetRenderScrollOffset()
			local str = tostring(e.Index) .. ": " .. tostring(e.Type) .. "." .. tostring(e.Variant) .. "." .. tostring(e.SubType)
			local str2 = ""
			if e.HitPoints > 0 then
				str2 = tostring(e.HitPoints) .. "\\" .. tostring(e.MaxHitPoints) .. " HP"
			end
			if e:ToNPC() ~= nil then
				local npc = e:ToNPC()
				str = str.."-"..tostring(npc.State)..":"..tostring(npc.StateFrame)
			end
			--Isaac.RenderText(tostring(e.Type) .. " " .. tostring(e.Variant) .. " " .. tostring(e.SubType), p.X, p.Y, 255, 0, 0, 0.5)
			Isaac.RenderScaledText(str, p.X-str:len()*1.5, p.Y, 0.5, 0.5, 4, 0, 0, 0.75)
			Isaac.RenderScaledText(str2, p.X-str2:len()*1.5, p.Y+5, 0.5, 0.5, 1, 1, 255, 0.75)
			if e.Type == EntityType.ENTITY_PLAYER then
				local posstr = tostring(e.Position.X).." - "..tostring(e.Position.Y)
				Isaac.RenderScaledText(posstr, p.X-posstr:len()*1.5, p.Y+10, 0.5, 0.5, 1, 1, 1, 0.75)
			end
		end
		
	elseif debugScript.entities_mode == 2 then
		--Inside RoomFairness.lua
		Content:RenderGridFairnessDebug()
	end
end
 
function debugScript:universalDebugText()
	if not debugScript.show_debug then return end
	
	local room = Game():GetRoom():GetType()
	local stage = Game():GetLevel():GetStage()

	Isaac.RenderText(tostring(debug_text), 40, 250, 255, 255, 0, 255);
	--if debug_entity ~= nil then
	--	Isaac.RenderText(tostring(debug_entity.State), 10, 250, 255, 255, 255, 255);
	--end
	local str = "Stage: " .. tostring(stage) .. " RoomType: " .. tostring(room)
	Isaac.RenderText(str, 420-str:len()*6, 10, 0, 10, 200, 255)
end

function debugScript:universalTableParser()
	if not debugScript.show_debug then return end
	
	local count = 0
	local count2 = 0
	for a,b in pairs(debug_tbl1) do
		local str = tostring(a).. ": " .. tostring(b)
		Isaac.RenderScaledText(str, 470-str:len()*3, 80 + count*5, 0.5, 0.5, 0, 255, 0, 255)
		count = count + 1
	end
	for a,b in pairs(debug_tbl2) do
		local str = tostring(a).. ": " .. tostring(b)
		Isaac.RenderScaledText(str, 470-str:len()*3, 80 + count2*5 + count*5, 0.5, 0.5, 255, 0, 255, 255)
		count2 = count2 + 1
	end
end

function debugScript:stateReader(ent)
	debug_entity = ent
end

function debugScript:checkToggle()
	if Input.IsButtonPressed(Keyboard.KEY_0,0) then
		if debugScript.toggle_pressed ~= true then
			debugScript.toggle_pressed = true
			debugScript.show_debug = not debugScript.show_debug
		end
	else
		debugScript.toggle_pressed = false
	end
	
	if Input.IsButtonPressed(49,0) then --Key1
		debugScript.entities_mode = 0
	elseif Input.IsButtonPressed(50,0) then --Key2
		debugScript.entities_mode = 1
	elseif Input.IsButtonPressed(51,0) then --Key3
		debugScript.entities_mode = 2
	end
end

ExtraFWMod:AddCallback(ModCallbacks.MC_POST_RENDER, debugScript.displayEntities)
ExtraFWMod:AddCallback(ModCallbacks.MC_POST_RENDER, debugScript.universalDebugText)
ExtraFWMod:AddCallback(ModCallbacks.MC_POST_RENDER, debugScript.universalTableParser)
--CoupMod:AddCallback(ModCallbacks.MC_NPC_UPDATE, debugScript.stateReader, EntityType.ENTITY_POOTER)
ExtraFWMod:AddCallback(ModCallbacks.MC_POST_UPDATE, debugScript.checkToggle)