--ids here

--Constants Updater
local enumsToUpdate = {
	CollectibleType,
	PillEffect,
	TrinketType,
	Card,
	PlayerType,
	NullItemID,
}
local boosterConsts = { --nicalis forgot to update their enums with the new things added in the booster pack
	0,
	0,
	0,
	3,
	0,
	0,
}
for _, enum in pairs(enumsToUpdate) do
	local count = 0
	local constName = nil
	for name, id in pairs(enum) do
		if name:sub(1,4) ~= "NUM_"  and name ~= "CARD_RANDOM" and name ~= "PILLEFFECT_NULL" then --have to exclude CARD_RANDOM and PILLEFFECT_NULL because they don't count
			count = count + 1
		elseif name:sub(1,4) == "NUM_" then
			constName = name
		end
	end
	enum[constName] = count + boosterConsts[_]
end