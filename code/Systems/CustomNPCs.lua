local npcTree = {}
local Content = ExtraFWMod:getContent()
local CustomNPCs = {}

Content.Classes.AI = {
	new = function (self, obj) --creates a new member of the class. attributes in obj override defaults, except for the four function tables
		obj = obj or {}
		for _,tbl in pairs(Content.fnTypes) do --clone all tables containing functions from class, add entries given in obj
			local origTbl = self.clone(self[tbl])
			if obj[tbl] ~= nil then
				for k,v in pairs(obj[tbl]) do
					origTbl[k] = v
				end
			end
			obj[tbl] = origTbl
		end
		local mt = {
			__index = self,
			__metatable = "protected metatable",
		}
		setmetatable(obj, mt)
		return obj
	end,
	clone = function (self) --clones tables and tables's tables
		local ret = {}
		for k,v in pairs(self) do
			if type(v) == "table" then
				v = Content.Classes.AI.clone(v)
			end
			ret[k] = v
		end
		local mt = {__index = self}
		if getmetatable(self) ~= nil and type(getmetatable(self)) ~= "table" then
			mt.__metatable = "protected metatable"
		end
		setmetatable(ret, mt)
		return ret
	end,
	addFn = function (self, fnType, fn, i) --add a function easily
		local tbl = nil
		if fnType == Content.fnTypes.EVENT then
			tbl = self.eventFns
		elseif fnType == Content.fnTypes.UPDATE then
			tbl = self.updateFns
		elseif fnType == Content.fnTypes.ANIM then
			tbl = self.animFns
		elseif fnType == Content.fnTypes.INIT then
			tbl = self.initFns
		else
			error("No such functiontype as \"" .. tostring(fnType) .. "\"")
			return
		end

		if i == nil then
			i = #tbl+1
		else
			i = tostring(i)
		end
		tbl[i] = fn
	end,
	removeFn = function (self, fnType, i) --remove a function easily
		local tbl = nil
		if fnType == Content.fnTypes.EVENT then
			tbl = self.eventFns
		elseif fnType == Content.fnTypes.UPDATE then
			tbl = self.updateFns
		elseif fnType == Content.fnTypes.ANIM then
			tbl = self.animFns
		elseif fnType == Content.fnTypes.INIT then
			tbl = self.initFns
		else
			error("No such functiontype as \"" .. tostring(fnType) .. "\"")
			return
		end

		tbl[i] = nil
	end,
	setState = function (self, state) --state switching helper func 
		self.ent.StateFrame = 0
		self.ent.State = state
	end,
	_incStateFrame = function (self) --increases state frame, always running after init
		self.ent.StateFrame = self.ent.StateFrame + 1
	end,
	_init = function (self, data)
		for k,v in pairs(self.initData) do
			data[k] = v
		end
	end,
	initFns = {},
	animFns = {},
	updateFns = {},
	eventFns = {},
	preDmgFn = function (ent, dmg, dmgFlags, src, dmgCntDown, ai)
		return
	end,
	preDeathFn = function (ent, dmg, dmgFlags, src, dmgCntDown, ai)
		return
	end,

	initData = {}, --data put into entityData by init()
	defState = NpcState.STATE_IDLE, --state init() inits to
	defOverlayAnim = nil, --anim can also play an overlay anim by default

	ent = nil, --Entity that has the ai
	isAI = true, --to check if this is an ai and not a table
}


local mtAI = getmetatable(Content.Classes.AI) or {}
mtAI.__call= function(self, o)
	return self:new(o)
end
setmetatable(Content.Classes.AI, mtAI)


Content.Classes.BasicStickAI = Content.Classes.AI({
	initFns = {
		function (ent, state, data) --called on init
			ent.V1 = ent.Position
		end,
	},
	animFns = {
		function (ent, state, rng, data, sprite, ai) --always running
			if state == ai.defState then
				sprite:Play(sprite:GetDefaultAnimationName())
				if ai.defOverlayAnim ~= nil then
					sprite:PlayOverlay(tostring(ai.defOverlayAnim))
				end
			elseif state == NpcState.STATE_INIT then
				if ai.appearOverlay ~= nil then
					sprite:PlayOverlay(tostring(ai.appearOverlay))
				end
			end
		end,
	},
	updateFns = { --running after init
		function (ent, state, rng, data, ai) --stick to floor
			if state == ai.defState then
				ent.Velocity = ent.V1 - ent.Position
			end
		end,
	},
	eventFns = {}, --running if key of table entry is triggered as an event
})

Content.Classes.BasicWalkAI = Content.Classes.AI({
	speed = 1,
	speedThreshold = 0.1,
	updateFns = {
		function (ent, state, rng, data, ai)
			if state == NpcState.STATE_MOVE then
				local target = ent:GetPlayerTarget()
				if ent:CollidesWithGrid() or data.gridCountdown > 0 then
					ent.Pathfinder:FindGridPath(target.Position, ai.speed/2, 1, false)
					if data.gridCountdown <= 0 then
						data.gridCountdown = 24
					else
						data.gridCountdown = data.gridCountdown - 1
					end
				else
					ent.Velocity = Content:calcEntVel(ent, target.Position, ai.speed)
				end 
			end
		end,
	},
	animFns = {
		function (ent, state, rng, data, sprite, ai)
			if ai.defOverlayAnim ~= nil then
				sprite:PlayOverlay(tostring(ai.defOverlayAnim))
			end
			ent:AnimWalkFrame("WalkHori", "WalkVert", ai.speedThreshold)
		end,
	},
	initData = {
		gridCountdown = 0
	},
	defState = NpcState.STATE_MOVE
})




function Content:addNPC(ai, type, var, sub)
	ai = ai:clone()
	if npcTree[type] == nil then
		if var ~= nil then
    		npcTree[type] = {}
    	else
    		npcTree[type] = ai
    	end
  	end

  	if var ~= nil and npcTree[type][var] == nil then
  		if sub ~= nil then
    		npcTree[type][var] = {}
    	else
    		npcTree[type][var] = ai
    	end
  	end
  	
  	if var ~= nil and sub ~= nil then
  		npcTree[type][var][sub] = ai
  	end
end

function CustomNPCs:updateNPCs(ent)
	local data = ent:GetData()
	if data.Content == nil then
		data.Content = {}
	end

	if ent.State == NpcState.STATE_INIT then
		local vars = npcTree[ent.Type]
		if vars ~= nil and not vars.isAI then
			local subs = vars[ent.Variant]
			if subs ~= nil and not subs.isAI then
				local ai = subs[ent.SubType]
				ai.ent = ent
				data.Content.ai = ai
			elseif subs ~= nil and subs.isAI then
				subs.ent = ent
				data.Content.ai = subs
			end
		elseif vars ~= nil and vars.isAI then
			vars.ent = ent
			data.Content.ai = vars
		end
	end

	local ai = data.Content.ai
	if ai ~= nil and ai.isAI and ai.ent ~= nil and ai.ent.Type == ent.Type and ai.ent.Variant == ent.Variant and ai.ent.SubType == ent.SubType then
		--debug_text = "ai detected"

		local sprite = ent:GetSprite()
		local state = ent.State
		local rng = ent:GetDropRNG()
		local data = ent:GetData()	

		if state == NpcState.STATE_INIT then
			ai:_init(data)
			for _, initFn in pairs(ai.initFns) do
				initFn(ai, ent, state, data)
			end
			ai:setState(ai.defState)
		else
			ai:_incStateFrame()

			for _,fn in pairs(ai.updateFns) do
				fn(ent, state, rng, data, ai)
			end

			for event, fn in pairs(ai.eventFns) do
				if sprite:IsEventTriggered(tostring(event)) then
					fn(ent, state, rng, data, ai)	
				end
			end
		end

		for _, animFn in pairs(ai.animFns) do
			animFn(ent, state, rng, data, sprite, ai)
		end
	end
end

function CustomNPCs:preNPCDmg(ent, dmg, dmgFlags, src, dmgCntDown)
	local data = ent:GetData()
	if data.Content ~= nil and data.Content.ai ~= nil and data.Content.ai.isAI and not ent:IsDead() then
		local ai = data.Content.ai
		if ai.ent ~= nil and ai.ent.Type == ent.Type and ai.ent.Variant == ent.Variant and ai.ent.SubType == ent.SubType then
			if ent.HitPoints < dmg and ai.preDeathFn ~= nil then
				ai:preDeathFn(ent, dmg, dmgFlags, src, dmgCntDown, ai)
			elseif ai.preDmgFn ~= nil then
				ai:preDmgFn(ent, dmg, dmgFlags, src, dmgCntDown, ai)
			end
		end
	end
end

ExtraFWMod:AddCallback(ModCallbacks.MC_NPC_UPDATE, CustomNPCs.updateNPCs)
ExtraFWMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, CustomNPCs.preNPCDmg)