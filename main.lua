ExtraFWMod = RegisterMod("ExtraFW", 1)
local modTable = {}
local Content = {}

function ExtraFWMod:getContent()
	return Content
end

local function makeReadOnlyTable(t)
	local p = {}
	local mt = {
		__index = t,
		__metatable = "protected metatable",
		__newindex = function(t,k,v)
			error("Tried to write to read-only table: " .. tostring(t))
		end,
	}
	setmetatable(p, mt)
	return p
end

local ExtraFWLoc = {
	addMod = function (self, mod)
		modTable[#modTable+1] = mod
		return makeReadOnlyTable(Content)
	end
}

ExtraFW = makeReadOnlyTable(ExtraFWLoc)

runExtraFW = runExtraFW or {}
for _, fn in pairs(runExtraFW) do
	fn()
end

require("ids")
Content.ENUMS = require("enums2")
Content.Pedestals = Content.ENUMS.Pedestals --shortcuts
Content.EnemySubTypes = Content.ENUMS.EnemySubTypes
Content.TearSubTypes = Content.ENUMS.TearSubTypes
Content.Callbacks = Content.ENUMS.Callbacks
Content.JumpVariant = Content.ENUMS.JumpVariant
Content.fnTypes = Content.ENUMS.fnTypes

Content.Classes = {}

--Systems
require("code/Systems/HelperFunctions")
require("code/Systems/RoomFairness")
--require("code/Systems/SaveData")
--require("code/Systems/CustomCallbacks")
--require("code/Systems/CustomPickups")
--require("code/Systems/CustomPedestals")
--require("code/Systems/CustomUnlocks")
--require("code/Systems/DelayedFunctions")
--require("code/Systems/SpriteRender")
--require("code/Systems/TearProjectiles")
require("code/Systems/CustomNPCs")

--Eternal list
local EternalsList = {}
function Content:AddEternal(Type,Variant,Name,Danger)
	if EternalsList[Type] == nil then
		EternalsList[Type] = {[Variant] = {name = Name, danger = Danger or 20}}
	else
		EternalsList[Type][Variant] = {name = Name, danger = Danger or 20}
	end
end

function Content:getEternalList()
	return EternalsList
end

function Content:HasEternalSubtype(Type,Variant)
	return EternalsList[Type] ~= nil and EternalsList[Type][Variant] ~= nil
end

function Content:IsEternal(Type,Variant,Subtype)
	return Content:HasEternalSubtype(Type,Variant) and Subtype == 15
end

function Content:IsEntityEternal(ent)
	return Content:HasEternalSubtype(ent.Type,ent.Variant) and ent.SubType == 15
end

function Content:getEternal(Type,Variant)
	if Content:HasEternalSubtype(Type,Variant) then
		return EternalsList[Type][Variant]
	end
	return nil
end 




--Debug
require("debug")
--Content END
ExtraFWMod.getContent = nil