-- Author      : Kaminari
-- Create Date : 10/27/2014 6:47:46 PM

-- SPELLS
local _AMurderOfCrows = 131894;

local _ChimaeraShot = 53209;
local _KillShot = 53351;
local _KillShotMM = 157708;

local _GlaiveToss = 117050;

local _SteadyShot = 56641;
local _DireBeast = 120679;
local _KillCommand = 34026;
local _BestialWrath = 19574;
local _FocusFire = 82692;
local _RapidFire = 3045;
local _ExplosiveShot = 53301;
local _BlackArrow = 3674;
local _SerpentSting = 87935;
local _FocusingShot = 163485;

-- NEW
local _MarkedShot = 185901;
local _AimedShot = 19434;
local _Barrage = 120360;
local _ArcaneShot = 185358;
local _Sidewinders = 214579;
local _Trueshot = 193526;
local _TitansThunder = 207097;
local _DireFrenzy = 217200;
local _AspectoftheWild = 193530;
local _CobraShot = 193455;
local _Stampede = 201430;
local _Windburst = 204147;

-- AURAS
local _ThrillOfTheHunt = 34720;
local _SteadyFocus = 177668;
local _Frenzy = 19623;
local _Vulnerable = 198925;
local _MarkingTargets = 223138;
local _LockandLoad = 194595;
local _HuntersMark = 185987;
-- local _BestialWrathAura = 19574; the same as spell id

-- costs
local _ChimaeraShotCost = 35;
local _AMurderOfCrowsCost = 30;
local _AimedShotCost = 50;
local _GlaiveTossCost = 15;
local _BarrageCost = 60;
local _DireBeastCost = 0;
local _KillCommandCost = 40;
local _ExplosiveShotCost = 15;
local _BlackArrowCost = 35;
local _ArcaneShotCost = 30;

-- talents
local isStampede = false;
local isMurderofcrows = false;
local isDireBeast = false;
local isDireFrenzy = false;
local isSteadyFocus = false;
local isBarrage = false;
local isSidewinders = false;

-- Flags
local _AimedShotTime = false;

----------------------------------------------
-- Pre enable, checking talents
----------------------------------------------
TDDps_Hunter_CheckTalents = function()
	isStampede = TD_TalentEnabled('Stampede');
	isMurderofcrows = TD_TalentEnabled('A Murder of Crows');
	isDireFrenzy = TD_TalentEnabled('Dire Frenzy');
	isSteadyFocus = TD_TalentEnabled('Steady Focus');
	isBarrage = TD_TalentEnabled('Barrage');
	isSidewinders = TD_TalentEnabled('Sidewinders');
	_AimedShotTime = select(4, GetSpellInfo(_AimedShot));
	_AimedShotCost = TD_ExtractTooltip(_AimedShot, FOCUS_COST);
	if not _AimedShotTime then
		_AimedShotTime = 2;
	else
		_AimedShotTime = _AimedShotTime / 1000;
	end
end

----------------------------------------------
-- Enabling Addon
----------------------------------------------
function TDDps_Hunter_EnableAddon(mode)
	mode = mode or 1;
	_TD['DPS_Description'] = 'TD Hunter DPS supports: Beast Mastery, Marksmanship, (Survial is here but no longer maintained)';
	_TD['DPS_OnEnable'] = TDDps_Hunter_CheckTalents;
	if mode == 1 then
		_TD['DPS_NextSpell'] = TDDps_Hunter_BeastMastery;
	end;
	if mode == 2 then
		_TD['DPS_NextSpell'] = TDDps_Hunter_Marksmanship;
	end;
	if mode == 3 then
		_TD['DPS_NextSpell'] = TDDps_Hunter_Survival;
	end;
	TDDps_EnableAddon();
end

----------------------------------------------
-- Main rotation: Beast Mastery
----------------------------------------------
TDDps_Hunter_BeastMastery = function()
	local timeShift, currentSpell, gcd = TD_EndCast();
	local focus, focusMax = TDDps_Hunter_Focus(0, timeShift);

	local tt = TD_SpellAvailable(_TitansThunder, timeShift);
	local amoc = TD_SpellAvailable(_AMurderOfCrows, timeShift);
	local db, dbCD = TD_SpellAvailable(_DireBeast, timeShift);
	local df, dfCD = TD_SpellAvailable(_DireFrenzy, timeShift);
	local kc, kcCD = TD_SpellAvailable(_KillCommand, timeShift + 1);
	local bw = TD_SpellAvailable(_BestialWrath, timeShift);
	local stamp = TD_SpellAvailable(_Stampede, timeShift);
	local aotw = TD_SpellAvailable(_AspectoftheWild, timeShift);

	TDButton_GlowCooldown(_AMurderOfCrows, isMurderofcrows and amoc);
	TDButton_GlowCooldown(_Stampede, isStampede and stamp);
	TDButton_GlowCooldown(_AspectoftheWild, aotw);
	TDButton_GlowCooldown(_TitansThunder, tt);

	if bw then
		return _BestialWrath;
	end

	if not isDireFrenzy and (db or (dbCD < kcCD and focus < 80 and dbCD < 2)) then
		return _DireBeast;
	end

	if isDireFrenzy and (df or (dfCD < kcCD and focus < 80 and dfCD < 2)) then
		return _DireFrenzy;
	end

	if kcCD < 1 then
		return _KillCommand;
	end

	if focus > 80 then
		return _CobraShot;
	else
		return nil;
	end
end

----------------------------------------------
-- Main rotation: Marksmanship
----------------------------------------------
TDDps_Hunter_Marksmanship = function()
	local timeShift, currentSpell, gcd = TD_EndCast();

	local lol, lolCharges = TD_Aura(_LockandLoad, timeShift);
	local ts = TD_Aura(_Trueshot, timeShift);
	local hm = TD_TargetAura(_HuntersMark, timeShift);
	local vul, vulCd = TD_TargetAura('Vulnerable', timeShift);

	local amoc = TD_SpellAvailable(_AMurderOfCrows, timeShift);
	local tsCd = TD_SpellAvailable(_Trueshot, timeShift);
	local wb = TD_SpellAvailable(_Windburst, timeShift);
	local barr = TD_SpellAvailable(_Barrage, timeShift);

	local aimedShotCost = _AimedShotCost;
	if lol then
		aimedShotCost = 0;
	end

	local minusFocus = 0;
	if currentSpell == 'Aimed Shot' then
		minusFocus = 50;
	end
	if currentSpell == 'Windburst' then
		minusFocus = 20;
	end
	local focus, focusMax = TDDps_Hunter_Focus(minusFocus, timeShift);

	TDButton_GlowCooldown(_Trueshot, tsCd);
	TDButton_GlowCooldown(_AMurderOfCrows, isMurderofcrows and amoc);

	if hm and ((vul and vulCd < 2) or not vul) then
		return _MarkedShot;
	end

	if vul and (vulCd > 2 and lol) then
		return _AimedShot;
	end

	if wb and currentSpell ~= 'Windburst' then
		return _Windburst;
	end

	if focus <= aimedShotCost then
		return isSidewinders and _Sidewinders or _ArcaneShot;
	end

	if barr then
		return _Barrage;
	end

	if vul and (vulCd > 2 or not hm) and focus > 40 then
		return _AimedShot;
	end

	-- Aimed Shot to dump Focus.
	if focus >= focusMax - 10 then
		return _AimedShot;
	end

	if focus <= _AimedShotCost - 10 then
		return isSidewinders and _Sidewinders or _ArcaneShot;
	end

	-- If nothing else, Steady Shot
	return isSidewinders and _Sidewinders or _ArcaneShot;
end

----------------------------------------------
-- Main rotation: Survival
----------------------------------------------
TDDps_Hunter_Survival = function()
	return nil;
end
----------------------------------------------
-- Current or Future Focus
----------------------------------------------
function TDDps_Hunter_Focus(minus, timeShift)
	local _, casting = GetPowerRegen();
	local powerMax = UnitPowerMax('player', SPELL_POWER_FOCUS);
	local power = UnitPower('player', SPELL_POWER_FOCUS) - minus + (casting * timeShift);
	if power > powerMax then
		power = powerMax;
	end;
	return power, powerMax;
end

