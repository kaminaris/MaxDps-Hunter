local addonName, addonTable = ...;
_G[addonName] = addonTable;

--- @type MaxDps
if not MaxDps then return end
local MaxDps = MaxDps;

local Hunter = MaxDps:NewModule('Hunter');
addonTable.Hunter = Hunter;

Hunter.spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!');
	end
}

local _PetBasics = {
	smack = 49966,
	claw  = 16827,
	bite  = 17253
}

function Hunter:Enable()
	MaxDps:Print(MaxDps.Colors.Info .. 'Hunter [Beast Mastery, Marksmanship, Survival]');
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
	local powerMax = UnitPowerMax('player', Enum.PowerType.Focus);
	local power = UnitPower('player', Enum.PowerType.Focus); -- + (casting * timeShift)
	if power > powerMax then
		power = powerMax;
	end ;
	power = power - minus;
	return power, powerMax, casting;
end

function Hunter:FocusTimeToMax()
	local regen = GetPowerRegen();
	local focusMax = UnitPowerMax('player', Enum.PowerType.Focus);
	local focus = UnitPower('player', Enum.PowerType.Focus);

	local ttm = (focusMax - focus) / regen;
	if ttm < 0 then
		ttm = 0;
	end

	return ttm;
end

-- Requires a pet's basic ability to be on an action bar somewhere.
function Hunter:TargetsInPetRange()
	local button
	for _, id in pairs(_PetBasics) do
		for i = 1, 72 do
			if select(2, GetActionInfo(i)) == id then
				button = i
				break
			end
		end
	end

	if button == nil then
		return 1
	end

	local count = 0;
	for i, frame in pairs(C_NamePlate.GetNamePlates()) do
		local inRange = IsActionInRange(button, frame.UnitFrame.unit)
		if frame:IsVisible() and inRange then
			count = count + 1;
		end
	end

	return count
end