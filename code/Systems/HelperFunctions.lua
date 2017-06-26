local Content = ExtraFWMod:getContent()

function Content:IsPosInRoom(pos)
	local room = Game():GetRoom()
	if room:IsLShapedRoom() then
		--TODO: Add support for L-shaped rooms
		local tl = room:GetTopLeftPos()
		local br = room:GetBottomRightPos()
		return pos.X > tl.X and pos.X < br.X and pos.Y > tl.Y and pos.Y < br.Y
	else
		local tl = room:GetTopLeftPos()
		local br = room:GetBottomRightPos()
		return pos.X > tl.X and pos.X < br.X and pos.Y > tl.Y and pos.Y < br.Y
	end
end

--Caclulates DamagePerSecond for current Isaac-stats
--Doesn't account for tear-effects like burn, double shot
function Content:calcDPS(player)
	return (player.Damage / player.MaxFireDelay) * 30.0
end

--Caclulates DamagePerFrame for current Isaac-stats
--Doesn't account for tear-effects like burn, double shot
function Content:calcDPF(player)
	return player.Damage / player.MaxFireDelay
end

--Calculates the velocity a tear needs to have to hit a target Position
function Content:calcTearVel(sourcePos, targetPos, multiplier)
	return (targetPos - sourcePos):Normalized() * multiplier;
end

--returns the nearest Enemy
function Content:getNearestEnemy(sourceEnt, whiteList, blackList)
	whiteList = whiteList or {0}
	blackList = blackList or {}
	local entities = Isaac.GetRoomEntities();
	local smallestDist = nil;
	local nearestEnt = nil;
	
	::redo::
	if blackList.mode == "only_same_ent" then
		local tmp = {}
		for i=1, #entities do
			if entities[i].Type == sourceEnt.Type and entities[i].Variant == sourceEnt.Variant and entities[i].SubType == sourceEnt.SubType then
				table.insert(tmp, 1, entities[i])
			end
		end
		entities = tmp
	elseif blackList.mode == "only_whitelist" then
		local tmp = {}
		for i=1, #entities do
			for j=1, #whiteList do
				if entities[i].Type == whiteList[j] then
					table.insert(tmp, 1, entities[i])
				end
			end
		end
		entities = tmp
	elseif blackList.mode == nil then
		for i=1, #blackList do
			local tmp = {}
			for j=1, #entities do
				if entities[j].Type ~= blackList[i] then
					 table.insert(tmp, 1, entities[j])
				end
			end
			entities = tmp
		end
	else
		blackList.mode = nil
		goto redo
	end
	
	for i = 1, #entities do
		for j = 1, #whiteList do
			if (entities[i].Index ~= sourceEnt.Index and (entities[i]:IsVulnerableEnemy() or entities[i].Type == whiteList[j])) then
				if (smallestDist == nil or sourceEnt.Position:Distance(entities[i].Position) < smallestDist) then
					smallestDist = sourceEnt.Position:Distance(entities[i].Position);
					nearestEnt = entities[i];
				end
			end
		end
	end
	
	if (nearestEnt == nil) then
		return sourceEnt;
	else	
		return nearestEnt;
	end
end

--returns the furthest enemy
function Content:getFurthestEnemy(sourceEnt, whiteList, blackList)
	whiteList = whiteList or {0}
	blackList = blackList or {}
	local entities = Isaac.GetRoomEntities();
	local largestDist = nil;
	local furthestEnt = nil;
	
	::redo::
	if blackList.mode == "only_same_ent" then
		local tmp = {}
		for i=1, #entities do
			if entities[i].Type == sourceEnt.Type and entities[i].Variant == sourceEnt.Variant and entities[i].SubType == sourceEnt.SubType then
				table.insert(tmp, 1, entities[i])
			end
		end
		entities = tmp
	elseif blackList.mode == "only_whitelist" then
		local tmp = {}
		for i=1, #entities do
			for j=1, #whiteList do
				if entities[i].Type == whiteList[j] then
					table.insert(tmp, 1, entities[i])
				end
			end
		end
		entities = tmp
	elseif blackList.mode == nil then
		for i=1, #blackList do
			local tmp = {}
			for j=1, #entities do
				if entities[j].Type ~= blackList[i] then
					 table.insert(tmp, 1, entities[j])
				end
			end
			entities = tmp
		end
	else
		blackList.mode = nil
		goto redo
	end
	
	for i = 1, #entities do
		for j=1, #whiteList do
			if entities[i].Index ~= sourceEnt.Index and (entities[i]:IsVulnerableEnemy() or entities[i].Type == whiteList[j]) then
				if (largestDist == nil or sourceEnt.Position:Distance(entities[i].Position) > largestDist) then
					largestDist = sourceEnt.Position:Distance(entities[i].Position);
					furthestEnt = entities[i];
				end
			end
		end
	end
	
	if (furthestEnt == nil) then
		return sourceEnt;
	else	
		return furthestEnt;
	end
end

--Display Giant Book anim take 2
function Content:AnimGiantBook(bookSprite, animName, customAnm2)
	customAnm2 = customAnm2 or "giantbook.anm2"

	local pos = Vector((640-128-48)/2, (460-128-48)/2)
	local rS = {
		[0] = "gfx/ui/giantbook/" .. tostring(bookSprite),
	}
	local aQ = {
		{
			Name = tostring(animName),
			Loops = 1
		},
		--[[ some testing stuff for the rewritten addToRender()
		{
			Name = "Idle",
			Loops = 3,
			killLoop = 10
		},
		{
			Name = "Shake",
			Loops = -1,
			killLoop = 120
		}]]
	}
	Content:addToRender("gfx/ui/giantbook/" .. tostring(customAnm2), aQ, pos, 30, rS)
end

function Content:dataCopy(originData,targetData)
	for k, v in pairs(originData) do
		targetData[k] = v
	end
end

--returns the items the player currently has
--a list of items can be specified to check if the player has any of these
function Content:getCurrentItems(pool)
	local itemCfg = Isaac.GetItemConfig()
	local numCol = #(itemCfg:GetCollectibles())
	if type(numCol) ~= "number" then
		numCol = 9999 --Mac seems to have trouble with this number thing
	end
	pool = pool or {}
	local currList = {}
	local player = Isaac.GetPlayer(0)
	for id=1, numCol do
		if itemCfg:GetCollectible(id) ~= nil then
			if #pool == 0 then
				if player:HasCollectible(id) then
					table.insert(currList, id)
				end
			else
				for _, poolId in pairs(pool) do
					if id == poolId and player:HasCollectible(id) then
						table.insert(currList, id)
					end
				end
			end
		end
	end
	--debug_tbl1 = currList
	return currList
end

--these are some Flag manipulation functions, they are similar to the EntityFlags functions
function Content:AddFlags(flagSource, flags)
	return flagSource | flags
end

function Content:HasFlags(flagSource, flags)
	return (flagSource & flags) ~= 0
end

function Content:ClearFlags(flagSource, flags)
	return flagSource & (~flags)
end

--gets the sprite path of a collectible
function Content:getItemGfxFromId(id)
	--id = tonumber(id) or 1
	local item = Isaac.GetItemConfig():GetCollectible(id)
	return item.GfxFileName
end

--returns a velocity an entity must have to get closer to target
--this differs from calcTearVel() by adding small normalized vectors to an existing velocity and normalizing the result instead of just calculating a vector pointing from ent to target
--better suited for enemies because that way knockback has an effect on the enemy
function Content:calcEntVel(ent, target, speed)
	if ent:HasEntityFlags(EntityFlag.FLAG_FEAR) then
		return (ent.Velocity*0.8 + -(target - ent.Position):Resized(speed * 3.5)*0.2)
	elseif ent:HasEntityFlags(EntityFlag.FLAG_CONFUSION) then
		local rng = ent:GetDropRNG()
		return (ent.Velocity*0.9 + Vector.FromAngle(rng:RandomInt(360)):Resized(speed * 3.5)*0.1)
	else
		return (ent.Velocity*0.8 + (target - ent.Position):Resized(speed * 3.5)*0.2)
	end
end

function Content:makeSplat(pos, var, size, ent)
	if size > 1 then
		local num = 2^(2+size) - 8 --calculate number of spawns
		local power = 1 --used to know which ring we're on
		for i=1, num do
			local sub = 2^(2+power) - 8 --need to clean i of the previous ring's numbers for incPowerTrig
			local cleanI = i-sub-1

			local splatNum = 2^(2+power) --how many splats the current ring contains

			if cleanI == splatNum then --start new ring
				power = power+1
			end

			local step = math.pi*(i/(2+2^power)) --input of sin and cos
			Isaac.Spawn(EntityType.ENTITY_EFFECT, var, 0, pos:__add(Vector(power*16*math.sin(step),power*16*math.cos(step))), Vector(0,0), ent)
		end
	else
		Isaac.Spawn(EntityType.ENTITY_EFFECT, var, 0, pos, Vector(0,0), ent)
	end
end

function Content:getItemNameFromID(id)
	--debug_text = tostring(Isaac.GetItemConfig():GetCollectible(id).Name)
	if id > 0 then
		return tostring(Isaac.GetItemConfig():GetCollectible(id).Name)
	else
		return "zero"
	end
end