-- SPELLS
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
local _AMurderofCrows = 131894;
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

-- Survi

local _FuryoftheEagle = 203415;
local _MongooseFury = 190931;
local _RaptorStrike = 186270;
local _WayoftheMokNathal = 201082;
local _ExplosiveTrap = 191433;
local _DragonsfireGrenade = 194855;
local _Lacerate = 185855;
local _MongooseBite = 190928;
local _AspectoftheEagle = 186289;
local _ThrowingAxes = 200163;
local _FlankingStrike = 202800;
local _SnakeHunter = 201078;
local _Butchery = 212436;
local _Carve = 187708;
local _SerpentSting = 87935;
local _AMurderofCrowsSurvi = 206505;
local _Growl = 6795;
local _Thunderstomp = 63900;
local _AnimalInstincts = 204315;
local _MokNathalTactics = 201081;
local _MortalWounds = 201075;
local _Caltrops = 194277;
local _ImprovedTraps = 199518;
local _SteelTrap = 162488;
local _SpittingCobra = 194407;
local _ExpertTrapper = 199543;
local _AspectoftheBeast = 191384;

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
local isDragonsfireGrenade = false;
local isThrowingAxes = false;

-- Flags
local _AimedShotTime = false;
MaxDps.Hunter = {};

function MaxDps.Hunter.CheckTalents()
	MaxDps:CheckTalents();
	isStampede = MaxDps:HasTalent(_Stampede);
	isMurderofcrows = MaxDps:HasTalent(_AMurderofCrows) or MaxDps:HasTalent(_AMurderofCrowsSurvi);
	isDireFrenzy = MaxDps:HasTalent(_DireFrenzy);
	isSteadyFocus = MaxDps:HasTalent(_SteadyFocus);
	isBarrage = MaxDps:HasTalent(_Barrage);
	isDragonsfireGrenade = MaxDps:HasTalent(_DragonsfireGrenade);
	isThrowingAxes = MaxDps:HasTalent(_ThrowingAxes);
	isSidewinders = MaxDps:HasTalent(_Sidewinders);

	_AimedShotTime = select(4, GetSpellInfo(_AimedShot));
	_AimedShotCost = MaxDps:ExtractTooltip(_AimedShot, FOCUS_COST);
	if not _AimedShotTime then
		_AimedShotTime = 2;
	else
		_AimedShotTime = _AimedShotTime / 1000;
	end
end

function MaxDps:EnableRotationModule(mode)
	mode = mode or 1;
	MaxDps.Description = 'Hunter [Beast Mastery, Marksmanship, Survial]';
	MaxDps.ModuleOnEnable = MaxDps.Hunter.CheckTalents;
	if mode == 1 then
		MaxDps.NextSpell = MaxDps.Hunter.BeastMastery;
	end;
	if mode == 2 then
		MaxDps.NextSpell = MaxDps.Hunter.Marksmanship;
	end;
	if mode == 3 then
		MaxDps.NextSpell = MaxDps.Hunter.Survival;
	end;
end

MaxDps.Hunter.BeastMastery = function()
	local timeShift, currentSpell, gcd = MaxDps:EndCast();
	local focus, focusMax = MaxDps.Hunter.Focus(0, timeShift);

	local amoc = MaxDps:SpellAvailable(_AMurderofCrows, timeShift);
	local db, dbCD = MaxDps:SpellAvailable(_DireBeast, timeShift);
	local df, dfCD = MaxDps:SpellAvailable(_DireFrenzy, timeShift);
	local kc, kcCD = MaxDps:SpellAvailable(_KillCommand, timeShift + 1);
	local bw = MaxDps:SpellAvailable(_BestialWrath, timeShift);
	local stamp = MaxDps:SpellAvailable(_Stampede, timeShift);
	local aotw = MaxDps:SpellAvailable(_AspectoftheWild, timeShift);

	MaxDps:GlowCooldown(_AMurderofCrows, isMurderofcrows and amoc);
	MaxDps:GlowCooldown(_Stampede, isStampede and stamp);
	MaxDps:GlowCooldown(_AspectoftheWild, aotw);
	MaxDps:GlowCooldown(_TitansThunder, MaxDps:SpellAvailable(_TitansThunder, timeShift));

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

MaxDps.Hunter.Marksmanship = function()
	local timeShift, currentSpell, gcd = MaxDps:EndCast();

	local lol, lolCharges = MaxDps:Aura(_LockandLoad, timeShift);
	local ts = MaxDps:Aura(_Trueshot, timeShift);
	local mt = MaxDps:Aura(_MarkingTargets, timeShift);
	local hm = MaxDps:TargetAura(_HuntersMark, timeShift);
	local vul, vulCd = MaxDps:TargetAura('Vulnerable', timeShift);

	local sw, swCharges = MaxDps:SpellCharges(_Sidewinders, timeShift);

	local aimedShotCost = _AimedShotCost;
	if lol then
		aimedShotCost = 0;
	end

	local minusFocus = 0;
	if MaxDps:SameSpell(currentSpell, _AimedShot) then
		minusFocus = 50;
	end
	if MaxDps:SameSpell(currentSpell, _Windburst) then
		minusFocus = 20;
	end
	local focus, focusMax = MaxDps.Hunter.Focus(minusFocus, timeShift);

	MaxDps:GlowCooldown(_Trueshot, MaxDps:SpellAvailable(_Trueshot, timeShift));
	MaxDps:GlowCooldown(_AMurderofCrows, isMurderofcrows and MaxDps:SpellAvailable(_AMurderofCrows, timeShift));

	if hm and (((vul and vulCd < 3) or not vul) or focus >= 130) then
		return _MarkedShot;
	end

	if isSidewinders and mt and not hm and swCharges > 1 then
		return _Sidewinders;
	end

	if vul and (vulCd > 3 and lol) then
		return _AimedShot;
	end

	if MaxDps:SpellAvailable(_Windburst, timeShift) and MaxDps:SameSpell(currentSpell, _Windburst) then
		return _Windburst;
	end

	if focus <= aimedShotCost then
		return isSidewinders and _Sidewinders or _ArcaneShot;
	end

	if isBarrage and MaxDps:SpellAvailable(_Barrage, timeShift) then
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

local recenlyCapedBite = false;
MaxDps.Hunter.Survival = function()
	local timeShift, currentSpell, gcd = MaxDps:EndCast();

	local fote = MaxDps:SpellAvailable(_FuryoftheEagle, timeShift);
	local epxTrap = MaxDps:SpellAvailable(_ExplosiveTrap, timeShift);
	local dfg = MaxDps:SpellAvailable(_DragonsfireGrenade, timeShift);
	local lac = MaxDps:SpellAvailable(_Lacerate, timeShift);

	local fs = MaxDps:SpellAvailable(_FlankingStrike, timeShift);
	local aote, aoteCd = MaxDps:SpellAvailable(_AspectoftheEagle, timeShift);
	local mb, mbCharges = MaxDps:SpellCharges(_MongooseBite, timeShift);
	local ta, taCharges = MaxDps:SpellCharges(_ThrowingAxes, timeShift);

	local mf, mfCount = MaxDps:Aura(_MongooseFury, timeShift);
	local wotm, wotmCount, wotmExpires = MaxDps:Aura(_MokNathalTactics, timeShift);
	local lacAura = MaxDps:Aura(_Lacerate, timeShift + 3);

	local focus, focusMax = MaxDps.Hunter.Focus(0, timeShift);

	if mbCharges == 0 then
		recenlyCapedBite = false;
	end

	if fote and mfCount >= 6 then
		return _FuryoftheEagle;
	end

	if (wotmCount < 4) or (wotmExpires < 2.5) and focus > 22 then
		return _RaptorStrike;
	end

	if epxTrap then
		return _ExplosiveTrap;
	end

	if isDragonsfireGrenade and dfg then
		return _DragonsfireGrenade;
	end

	if lac and not lacAura and focus > 32 then
		return _Lacerate;
	end

	local aoteClose = not aote and aoteCd < 5;
	if (((mbCharges >= 3)
			or (recenlyCapedBite and mbCharges > 0))
			and not aoteClose) then
		recenlyCapedBite = true;
		return _MongooseBite;
	end

	if isThrowingAxes and taCharges > 0 and focus > 12 then
		return _ThrowingAxes;
	end

	if fs and focus > 46 then
		return _FlankingStrike;
	end

	return _RaptorStrike;
end

function MaxDps.Hunter.Focus(minus, timeShift)
	local _, casting = GetPowerRegen();
	local powerMax = UnitPowerMax('player', SPELL_POWER_FOCUS);
	local power = UnitPower('player', SPELL_POWER_FOCUS) - minus + (casting * timeShift);
	if power > powerMax then
		power = powerMax;
	end;
	return power, powerMax;
end

