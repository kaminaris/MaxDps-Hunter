--- @type MaxDps
if not MaxDps then
	return;
end

local Hunter = MaxDps:NewModule('Hunter');

-- MM

-- Spells
local _Trueshot = 193526;
local _Barrage = 120360;
local _SteadyShot = 56641;
local _RapidFire = 257044;
local _AimedShot = 19434;
local _MultiShot = 257620;
local _ArcaneShot = 185358;
local _Barrage = 120361;
local _SerpentSting = 271788;

-- Player Auras
local _PreciseShots = 260242;
local _SteadyFocus = 193534;
local _LoneWolf = 164273;
local _TrickShots = 257622;
local _LockandLoad = 194594;
local _MasterMarksman = 269576;

-- BM

-- Spells
local _SpittingCobra = 194407;
local _MultiShotBM = 2643;
local _CounterShot = 147362;
local _AspectoftheWild = 193530;
local _DireBeast = 120679;
local _AutoShot = 75;
local _Stampede = 201430;
local _ChimaeraShot = 53209;
local _AMurderofCrows = 131894;
local _BestialWrath = 19574;
local _CobraShot = 193455;
local _KillCommand = 34026;
local _BarbedShot = 217200;

-- Player Auras
local _BestialWrathAura = 186254;
local _LoadedDieMastery = 267326;
--local _BestialWrath = 19574;
local _BeastCleave = 268877;
--local _BarbedShot = 246152;
local _Pathfinding = 264656;
--local _DireBeast = 281036;
--local _BarbedShot = 246852;

-- Pet Auras
local _Frenzy = 272790;

-- Target Auras
local _BarbedShotAura = 217200;
--local _AMurderofCrows = 131894;


local _PetBasics = {
	smack = 49966,
	claw = 16827,
	bite = 17253
}


function Hunter:Enable()
	MaxDps:Print(MaxDps.Colors.Info .. 'Hunter [Beast Mastery, Marksmanship, Survial]');

	if MaxDps.Spec == 1 then
		MaxDps.NextSpell = Hunter.BeastMastery;
	elseif MaxDps.Spec == 2 then
		MaxDps.NextSpell = Hunter.Marksmanship;
	elseif MaxDps.Spec == 3 then
		MaxDps.NextSpell = Hunter.Survival;
	end;

	return true;
end

function Hunter:BeastMastery(timeShift, currentSpell, gcd, talents)
	local minus = 0;
	local focus, focusMax, focusRegen = Hunter:Focus(minus, timeShift);

	-- Cooldowns

	local bw, bwCd = MaxDps:SpellAvailable(_BestialWrath, timeShift);
	MaxDps:GlowCooldown(_AspectoftheWild, MaxDps:SpellAvailable(_AspectoftheWild, timeShift) and (bw or bwCd > 82));

	if talents[_SpittingCobra] then
		MaxDps:GlowCooldown(_SpittingCobra, MaxDps:SpellAvailable(_SpittingCobra, timeShift));
	end

	if  talents[_Stampede] then
		MaxDps:GlowCooldown(_Stampede, MaxDps:SpellAvailable(_Stampede, timeShift));
	end

	if talents[_Barrage] then
		MaxDps:GlowCooldown(_Barrage, MaxDps:SpellAvailable(_Barrage, timeShift));
	end

	-- Auras

	local bwAura = MaxDps:Aura(_BestialWrathAura, timeShift);

	local bs, bsCharges = MaxDps:SpellCharges(_BarbedShot, timeShift);
	local frenzyAura, frenzyCount, frenzyCd = MaxDps:UnitAura(_Frenzy, timeShift, 'pet');

	-- Rotation start
	if frenzyAura and bsCharges >= 1 and frenzyCd < 2 then
		return _BarbedShot;
	end

	if talents[_AMurderofCrows] and MaxDps:SpellAvailable(_AMurderofCrows, timeShift) then
		return _AMurderofCrows;
	end

	if bsCharges >= 1.8 then
		return _BarbedShot;
	end

	if bw then
		return _BestialWrath;
	end

	if talents[_ChimaeraShot] and MaxDps:SpellAvailable(_ChimaeraShot, timeShift) then
		return _ChimaeraShot;
	end

	local kc, kcCd = MaxDps:SpellAvailable(_KillCommand, timeShift + 0.5);
	if kc then
		return _KillCommand;
	end

	if talents[_DireBeast] and MaxDps:SpellAvailable(_DireBeast, timeShift) then
		return _DireBeast;
	end

	if focus > 60 and kcCd > 2 then
		return _CobraShot;
	else
		return nil;
	end
end

function Hunter:Marksmanship(timeShift, currentSpell, gcd, talents)
	local minus = 0;

	local focus, focusMax, focusRegen = Hunter:Focus(minus, timeShift);
	local as, asCharges = MaxDps:SpellCharges(_AimedShot, timeShift);


	if currentSpell == _AimedShot then
		asCharges = asCharges - 1;
		minus = 30;
	end

	if currentSpell == _SteadyShot then
		minus = -10;
	end

	MaxDps:GlowCooldown(_Trueshot, MaxDps:SpellAvailable(_Trueshot, timeShift));

	if currentSpell == _AimedShot then
		return _ArcaneShot;
	end

	if focus >= 30 and asCharges >= 1.7	then
		return _AimedShot;
	end

	if MaxDps:SpellAvailable(_RapidFire, timeShift) then -- focusMax - focus > 40 and
		return _RapidFire;
	end

	local ss, _, ssCd = MaxDps:TargetAura(_SerpentSting, timeShift);
	if talents[_SerpentSting] and focus >= 10 and ssCd < 3 then
		return _SerpentSting;
	end

	local ps, psCount, psCd = MaxDps:Aura(_PreciseShots, timeShift);
	if currentSpell == _AimedShot or psCount >= 1 then
		return _ArcaneShot;
	end

	if focus >= 60 and asCharges >= 1 then
		return _AimedShot;
	end

	if focus > 80 then
		return _ArcaneShot;
	end

	return _SteadyShot;
end

function Hunter:Survival(timeShift, currentSpell, gcd, talents)

end

function Hunter:Focus(minus, timeShift)
	local casting = GetPowerRegen();
	local powerMax = UnitPowerMax('player', Enum.PowerType.Focus);
	local power = UnitPower('player', Enum.PowerType.Focus) + (casting * timeShift);
	if power > powerMax then
		power = powerMax;
	end;
	power = power - minus;
	return power, powerMax, casting;
end

-- Requires a pet's basic ability to be on an action bar somewhere.
function Hunter:TargetsInPetRange()
	local button
	for _, id in pairs (_PetBasics) do
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