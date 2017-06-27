local tearTable = {}
local Content = ExtraFWMod:getContent()
local TearProj = {}

function Content:TearConf()
	local t = {}
	t.TearFlags = 0
	t.SpawnerEntity = nil
	t.Height = -23
	t.FallingAcceleration = 0
	t.FallingSpeed = 0
	t.Color = Color(1,1,1,1,0,0,0)
	t.Data = {}
	t.Scale = 1 --goes in 1/6 steps for the bigger tearsprite
	t.Functions = {} --supported functions are onDeath, onUpdate and onHit

	return t
end

function TearProj:updateTears()
	for i, tearObj in pairs(tearTable) do
		local tear = tearObj[1]
		local func = tearObj[2]

		local player = Game():GetNearestPlayer(tear.Position)
		local tData = tear:GetData()

		if not tear:Exists() then
			--run onDeath when the tear doesn't exist
			if func ~= nil and func.onDeath ~= nil then
				func:onDeath(tear.Position, tear.Velocity, tear.SpawnerEntity, tear)
			end
			tearTable[i] = nil
		elseif player.Position:Distance(tear.Position) <= player.Size + tear.Size + 8 and tear.Height >= -30 then
			player:TakeDamage(1, 0, EntityRef(tear), 0)
			--run onHit when tear hits the player
			if func ~= nil and func.onHit ~= nil then
				func:onHit(tear)
			end
			--don't remove the tear if piercing
			if not Content:HasFlags(tear.TearFlags, TearFlags.TEAR_PIERCING) then
				tear:Die()
			end
		elseif tData.ExtraFW ~= nil and tData.ExtraFW.homing then
			tear.Velocity = Content:calcTearVel(tear.Position, player.Position, tear.Velocity:Length())
		end

		--run onUpdate on every frame of existance
		if tear:Exists() and func ~= nil and func.onUpdate ~= nil then
			func:onUpdate(tear)
		end
	end
end

function TearProj:deleteTears()
	tearTable = {}
end

function Content:fireTearProj(var, sub, pos, vel, tearConf)
	tearConf = tearConf or {}

	local t = Isaac.Spawn(EntityType.ENTITY_TEAR, var, sub, pos, vel, tearConf.SpawnerEntity):ToTear()
	t.SpawnerEntity = tearConf.SpawnerEntity
	if tearConf.SpawnerEntity ~= nil then
		t.SpawnerType = tearConf.SpawnerEntity.Type
		t.SpawnerVariant = tearConf.SpawnerEntity.Variant
	end
	t.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
	t.TearFlags = tearConf.TearFlags or t.TearFlags
	t.Height = tearConf.Height or -23
	t.FallingAcceleration = tearConf.FallingAcceleration or 0
	t.FallingSpeed = tearConf.FallingSpeed or 0
	t.Color = tearConf.Color or t.Color
	t.Scale = tearConf.Scale or 1

	if tearConf.Data ~= nil then
		Content:dataCopy(tearConf.Data, t:GetData())
	end

	table.insert(tearTable, {t, tearConf.Functions})
end

function Content:fireMonstroTearProj(var, sub, pos, vel, tearConf, num, rng, overrideConf)
	overrideConf = overrideConf or {}
	for i = 1, num do
		local deg = rng:RandomInt(21)-10 -- -10 to 10
		local speed = vel:Length() * (1+((rng:RandomInt(8)+1)/10))
		
		--Monstro shot standards
		tearConf.FallingAcceleration = overrideConf.FallingAcceleration or 0.5
		tearConf.FallingSpeed = overrideConf.FallingSpeed or (-5 - rng:RandomInt(11)) -- -15 to -5
		tearConf.Scale = overrideConf.Scale or (1 + (rng:RandomInt(5)-2)/6) -- 4/6 to 8/6

		Content:fireTearProj(var, sub, pos, vel:Normalized():Rotated(deg) * speed, tearConf)
	end
end

--Kinda like Ministro. Not fully.
function Content:fireMinistroTearProj(var, sub, pos, vel, tearConf, num, rng, overrideConf)
	overrideConf = overrideConf or {}
	for i = 1, num do
		local deg = rng:RandomInt(32)-15 -- -10 to 10
		local speed = vel:Length() * (rng:RandomFloat()+0.5)
		
		--Monstro shot standards
		tearConf.FallingAcceleration = overrideConf.FallingAcceleration or 0.8
		tearConf.FallingSpeed = overrideConf.FallingSpeed or (-7 - rng:RandomInt(10))
		tearConf.Scale = overrideConf.Scale or (1 + (rng:RandomInt(4)-2)/8)

		Content:fireTearProj(var, sub, pos, vel:Normalized():Rotated(deg) * speed, tearConf)
	end
end

function Content:fireIpecacTearProj(var, sub, pos, vel, tearConf, overrideConf)
	overrideConf = overrideConf or {}

	tearConf.TearFlags = tearConf.TearFlags or 0
	if not Content:HasFlags(tearConf.TearFlags, TearFlags.TEAR_EXPLOSIVE) then
		tearConf.TearFlags = Content:AddFlags(tearConf.TearFlags, TearFlags.TEAR_EXPLOSIVE)
	end

	--Ipecec tear standards
	tearConf.Color = overrideConf.Color or Color(0.5, 1, 0.5, 1, 0, 0, 0)
	tearConf.Height = overrideConf.Height or -35
	tearConf.FallingAcceleration = overrideConf.FallingAcceleration or 0.6
	tearConf.FallingSpeed = overrideConf.FallingSpeed or -10
	tearConf.Scale = overrideConf.Scale or 1
	tearConf.Scale = tearConf.Scale * (1 + 1/3)


	Content:fireTearProj(var, sub, pos, vel, tearConf)
end

function Content:fireHomingTearProj(var, sub, pos, vel, tearConf, overrideConf)
	overrideConf = overrideConf or {}
	--Homing tear standards
	tearConf.Color = overrideConf.Color or Color(1, 0.5, 1, 1, 0, 0, 0)
	tearConf.Data.ExtraFW = tearConf.Data.ExtraFW or {}
	tearConf.Data.ExtraFW.homing = true
	
	Content:fireTearProj(var, sub, pos, vel, tearConf)
end

function Content:fireMeatballTearProj(var, sub, pos, vel, tearConf, num, rng, overrideConf)
	overrideConf = overrideConf or {}
	for i=1, num do
		local speed = vel:Length() * (1 + rng:RandomInt(8)/10)
		local dir = Vector.FromAngle(rng:RandomInt(360))
			
		tearConf.FallingAcceleration = overrideConf.FallingAcceleration or 0.75
		tearConf.FallingSpeed = overrideConf.FallingSpeed or (-10 - rng:RandomInt(13))
		tearConf.Scale = overrideConf.Scale or 1
		tearConf.Scale = tearConf.Scale * (1 + (rng:RandomInt(5)-2)/6)

		Content:fireTearProj(var, sub, pos, dir * speed, tearConf)
	end
end

function Content:getTearTable()
	return tearTable
end

ExtraFWMod:AddCallback(ModCallbacks.MC_POST_UPDATE, TearProj.updateTears)
ExtraFWMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, TearProj.deleteTears)