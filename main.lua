local addonName, addonTable = ...;
_G[addonName] = addonTable;

--- @type MaxDps
if not MaxDps then return end
local MaxDps = MaxDps;
local IsActionInRange = IsActionInRange;
local GetPowerRegen = GetPowerRegen;
local UnitPowerMax = UnitPowerMax;
local UnitPower = UnitPower;
local GetActionInfo = GetActionInfo;
local TableContains = tContains;
local PowerTypeFocus = Enum.PowerType.Focus;
local ipairs = ipairs;
local select = select;

local Hunter = MaxDps:NewModule('Hunter');
addonTable.Hunter = Hunter;

Hunter.spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!');
	end
}

local _PetBasics = {
	49966, -- Smack
	16827, -- Claw
	17253 -- Bite
}

function Hunter:Enable()
	MaxDps:Print(MaxDps.Colors.Info .. 'Hunter [Beast Mastery, Marksmanship, Survival]');
	Hunter:InitializeDatabase();
	Hunter:CreateConfig();

	if MaxDps.Spec == 1 then
		MaxDps.NextSpell = Hunter.BeastMastery;
	elseif MaxDps.Spec == 2 then
		MaxDps.NextSpell = Hunter.Marksmanship;
	elseif MaxDps.Spec == 3 then
		MaxDps.NextSpell = Hunter.Survival;
	end ;

	return true;
end

function Hunter:Focus(minus, timeShift)
	local casting = GetPowerRegen();
	local powerMax = UnitPowerMax('player', PowerTypeFocus);
	local power = UnitPower('player', PowerTypeFocus); -- + (casting * timeShift)
	if power > powerMax then
		power = powerMax;
	end ;
	power = power - minus;
	return power, powerMax, casting;
end

function Hunter:FocusTimeToMax()
	local regen = GetPowerRegen();
	local focusMax = UnitPowerMax('player', PowerTypeFocus);
	local focus = UnitPower('player', PowerTypeFocus);

	local ttm = (focusMax - focus) / regen;
	if ttm < 0 then
		ttm = 0;
	end

	return ttm;
end

local function isHunterPetBasic(slot)
	local id = select(2, GetActionInfo(slot));
	return TableContains(_PetBasics, id);
end

function Hunter:FindPetBasicSlot()
	if self.PetBasicSlot and isHunterPetBasic(self.PetBasicSlot) then
		return self.PetBasicSlot;
	end

	for slot = 1, 120 do
		if isHunterPetBasic(slot) then
			self.PetBasicSlot = slot;
			return slot;
		end
	end

	return nil;
end

-- Requires a pet's basic ability to be on an action bar somewhere.
function Hunter:TargetsInPetRange()
	local slot = self:FindPetBasicSlot();

	if slot == nil then
		MaxDps:Print(MaxDps.Colors.Error .. 'Pet basic ability needs to be on YOUR action bar (Smack, Claw, Bite)');
		return 1;
	end

	local count = 0;
	for i, unit in ipairs(MaxDps.visibleNameplates) do
		if IsActionInRange(slot, unit) then
			count = count + 1;
		end
	end

	return count;
end