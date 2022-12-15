local Tests = WoWUnit and WoWUnit('Unfit', 'PLAYER_LOGIN', 'GET_ITEM_INFO_RECEIVED')
if not Tests then return end

local Replace, IsFalse, IsTrue = WoWUnit.Replace, WoWUnit.IsFalse, WoWUnit.IsTrue
local Unfit = LibStub('Unfit-1.0')

function Tests:Leather()
	Replace(Unfit.unusable[4], 2, true)
	IsFalse(Unfit:IsItemUnusable(2318)) -- light leather
	IsTrue(Unfit:IsItemUnusable(6085)) -- leather chest
end
