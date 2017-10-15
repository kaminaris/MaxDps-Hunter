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
local _SerpentSting = 87935;
local _FocusingShot = 163485;
local _KillerCobra = 199532;

-- NEW
local _AMurderofCrows = 131894;
local _MarkedShot = 185901;
local _AimedShot = 19434;
local _Barrage = 120360;
local _BlackArrow = 194599;
local _ArcaneShot = 185358;
local _Sidewinders = 214579;
local _Trueshot = 193526;
local _TitansThunder = 207068;
local _DireFrenzy = 217200;
local _AspectoftheWild = 193530;
local _CobraShot = 193455;
local _Stampede = 201430;
local _Windburst = 204147;
local _MultiShot = 2643;
local _PatientSniper = 234588;
local _ExplosiveShot = 212431;
local _PiercingShot = 198670;
local _TrickShot = 199522;
local _Volley = 194386;
local _Precision = 246153;
local _CriticalAimed = 242243;
local _BurstingShot = 186387;
local _Sentinel = 206817;

-- AURAS
local _ThrillOfTheHunt = 34720;
local _SteadyFocus = 177668;
local _Frenzy = 19623;
local _Vulnerable = 187131;
local _MarkingTargets = 223138;
local _LockandLoad = 194595;
local _HuntersMark = 185987;
local _ParselsTongue = 248085;
local _BeastCleave = 118455;

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
local _CaltropsAura = 194279;
local _ImprovedTraps = 199518;
local _SteelTrap = 162488;
local _SpittingCobra = 194407;
local _ExpertTrapper = 199543;
local _AspectoftheBeast = 191384;
local _OnewiththePack = 199528;

-- costs
local _AimedShotCost = 50;

-- talents
local isMurderofcrows = false;
local isDireBeast = false;
local isDireFrenzy = false;
local isSteadyFocus = false;
local isBarrage = false;
local isSidewinders = false;
local isDragonsfireGrenade = false;
local isThrowingAxes = false;
local isPatientSniper = false;
local isExplosive = false;

local NHSetPieces = {138339, 138340, 138342, 138344, 138347, 138368};
local TombSetPieces = {147139, 147140, 147141, 147142, 147143, 147144};
local QaplaEredunWarOrder = 137227;
local CallOfTheWild = 137101;
local ConvergenceOfFates = 140806;
local ParselsTongue = 151805;
local FrizzosFingertrap = 137043;

local _PetBasics = {
	smack = 49966,
	claw = 16827,
	bite = 17253
}

-- Flags
local _AimedShotTime = false;
local _isT19_2Set = false;
local _isT19_4Set = false;
local _isT20_2Set = false;
local _isT20_4Set = false;
MaxDps.Hunter = {};

function MaxDps.Hunter.CheckTalents()
	isMurderofcrows = MaxDps:HasTalent(_AMurderofCrows) or MaxDps:HasTalent(_AMurderofCrowsSurvi);
	isDireFrenzy = MaxDps:HasTalent(_DireFrenzy);
	isSteadyFocus = MaxDps:HasTalent(_SteadyFocus);
	isBarrage = MaxDps:HasTalent(_Barrage);
	isDragonsfireGrenade = MaxDps:HasTalent(_DragonsfireGrenade);
	isThrowingAxes = MaxDps:HasTalent(_ThrowingAxes);
	isSidewinders = MaxDps:HasTalent(_Sidewinders);
	isPatientSniper = MaxDps:HasTalent(_PatientSniper);
	isExplosive = MaxDps:HasTalent(_ExplosiveShot);

--	_AimedShotCost = MaxDps:ExtractTooltip(_AimedShot, FOCUS_COST);
--	if not _AimedShotCost then
		_AimedShotCost = 50;
--	end
	_isT19_2Set = MaxDps:SetBonus(NHSetPieces) >= 2;
	_isT19_4Set = MaxDps:SetBonus(NHSetPieces) >= 4;
	_isT20_2Set = MaxDps:SetBonus(TombSetPieces) >= 2;
	_isT20_4Set = MaxDps:SetBonus(TombSetPieces) >= 4;
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

	self:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED');
	self.lastSpellTimestamp = 0;
	self.lastSpellId = 0;
end

-- Spell that break Tomb 2pc
local includedSpells = {
	[_AimedShot] = true,
	[_MarkedShot] = true,
	[_Sidewinders] = true,
	[_ArcaneShot] = true,
	[_MultiShot] = true,
	[_BurstingShot] = true,
};
function MaxDps:UNIT_SPELLCAST_SUCCEEDED(event, unitID, spell, rank, lineID, spellID)
	if unitID == 'player' and includedSpells[spellID] then
		self.lastSpellTimestamp = GetTime();
		self.lastSpellId = spellID;
	end
end

-- Requires a pet's basic ability to be on an action bar somewhere.
function MaxDps.Hunter.TargetsInPetRange()
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

function MaxDps.Hunter.PetAura(name, timeShift)
	timeShift = timeShift or 0.2;
	local spellName = GetSpellInfo(name) or name;
	local _, _, _, count, _, _, expirationTime = UnitAura("pet", spellName);

	if expirationTime ~= nil and (expirationTime - GetTime()) > timeShift then
		local cd = expirationTime - GetTime() - (timeShift or 0);
		return true, count, cd;
	end

	return false, 0, 0;
end

MaxDps.Hunter.BeastMastery = function(_, timeShift, currentSpell, gcd, talents)

	local targets = MaxDps.Hunter.TargetsInPetRange();

	local bw, bwCd = MaxDps:SpellAvailable(_BestialWrath, timeShift);
	local bwAura, _, bwAuraCd = MaxDps:Aura(_BestialWrath, timeShift);

	-- bestial_wrath,if=!buff.bestial_wrath.up
	MaxDps:GlowCooldown(_BestialWrath, bw and not bwAura);
	
	-- # With both AotW cdr sources and OwtP, there's no visible benefit if it's delayed, use it on cd. With only one or neither, pair it with Bestial Wrath. Also use it if the fight will end when the buff does.
	-- aspect_of_the_wild,if=(equipped.call_of_the_wild&equipped.convergence_of_fates&talent.one_with_the_pack.enabled)|buff.bestial_wrath.remains>7|target.time_to_die<12
	MaxDps:GlowCooldown(_AspectoftheWild, MaxDps:SpellAvailable(_AspectoftheWild, timeShift) and (IsEquippedItem(CallOfTheWild) and IsEquippedItem(ConvergenceOfFates) and talents[_OnewiththePack] or bwAuraCd > 7));

	-- a_murder_of_crows,if=cooldown.bestial_wrath.remains<3|cooldown.bestial_wrath.remains>30|target.time_to_die<16
	if talents[_AMurderofCrows] and MaxDps:SpellAvailable(_AMurderofCrows, timeShift) and (bwCd < 3 or bwCd > 30) then
		return _AMurderofCrows;
	end

	-- stampede,if=buff.bloodlust.up|buff.bestial_wrath.up|cooldown.bestial_wrath.remains<=2|target.time_to_die<=14
	if talents[_Stampede] and MaxDps:SpellAvailable(_Stampede, timeShift) and (bwAura or bwCd <= 2) then
		return _Stampede;
	end

	local kc, kcCd = MaxDps:SpellAvailable(_KillCommand, timeShift);

	-- kill_command,if=equipped.qapla_eredun_war_order
	if kc and IsEquippedItem(QaplaEredunWarOrder) then
		return _KillCommand;
	end

	local direAbility = _DireBeast;
	if talents[_DireFrenzy] then
		direAbility = _DireFrenzy;
	end

	local dbCd, dbCharges, dbMaxCharges = MaxDps:SpellCharges(direAbility, timeShift);
	local _, _, _, dbChargeDuration = GetSpellCharges(direAbility);
	local dbFullRecharge = (dbMaxCharges - dbCharges) * dbChargeDuration;
	local tt, ttCd = MaxDps:SpellAvailable(_TitansThunder, timeShift);

	-- # Hold charges of Dire Beast as long as possible to take advantage of T20 2pc unless T19 2pc is on.
	-- dire_beast,if=((!equipped.qapla_eredun_war_order|cooldown.kill_command.remains>=3)&(set_bonus.tier19_2pc|!buff.bestial_wrath.up))|full_recharge_time<gcd.max|cooldown.titans_thunder.up|spell_targets>1

	if dbCharges >= 1 and not talents[_DireFrenzy] and (((not IsEquippedItem(QaplaEredunWarOrder) or kcCd > 1) and (_isT19_2Set or not bwAura)) or dbFullRecharge < gcd or tt or targets > 1) then
		return _DireBeast;
	end

	local df, dfStack, dfCd = MaxDps.Hunter.PetAura(_DireFrenzy, timeShift)

	-- dire_frenzy,if=(pet.cat.buff.dire_frenzy.remains<=gcd.max*1.2)|full_recharge_time<gcd.max|target.time_to_die<9
	if talents[_DireFrenzy] and dbCharges >= 1 and (dfCd < 2 or dbFullRecharge < gcd) then
		return _DireFrenzy;
	end

	-- titans_thunder,if=(talent.dire_frenzy.enabled&(buff.bestial_wrath.up|cooldown.bestial_wrath.remains>35))|buff.bestial_wrath.up
	if tt and (talents[_DireFrenzy] and bwCd > 35 or bwAura) then
		return _TitansThunder;
	end

	local bc, _, bcCd = MaxDps.Hunter.PetAura(_BeastCleave, timeShift);

	-- multishot,if=spell_targets>4&(pet.cat.buff.beast_cleave.remains<gcd.max|pet.cat.buff.beast_cleave.down)
	if targets > 4 and (bcCd < gcd or not bc) then
		return _MultiShot;
	end
	
	-- kill_command
	if kc then
		return _KillCommand;
	end

	-- multishot,if=spell_targets>1&(pet.cat.buff.beast_cleave.remains<gcd.max|pet.cat.buff.beast_cleave.down)
	if targets > 1 and (bcCd < gcd or not bc) then
		return _MultiShot;
	end

	local focus, focusMax, focusRegen = MaxDps.Hunter.Focus(0, timeShift);

	-- chimaera_shot,if=focus<90
	if talents[_ChimaeraShot] and MaxDps:SpellAvailable(_ChimaeraShot, timeShift) and focus < 90 then
		return _ChimaeraShot;
	end

	local focusTimeToMax = (focusMax - focus) / focusRegen
	local parsels, parselsStack, parselsCd = MaxDps:Aura(_ParselsTongue, timeShift);
	
	-- cobra_shot,if=(cooldown.kill_command.remains>focus.time_to_max&cooldown.bestial_wrath.remains>focus.time_to_max)
	-- |(buff.bestial_wrath.up&(spell_targets.multishot=1|focus.regen*cooldown.kill_command.remains>action.kill_command.cost))
	-- |target.time_to_die<cooldown.kill_command.remains
	-- |(equipped.parsels_tongue&buff.parsels_tongue.remains<=gcd.max*2)
	if kcCd > focusTimeToMax and bwCd > focusTimeToMax or bwAura and (targets == 1 or focusRegen * kcCd > 30) or IsEquippedItem(ParselsTongue) and parselsCd < gcd * 2 then
		return _CobraShot;
	end

	-- dire_beast,if=buff.bestial_wrath.up
	if math.floor(dbCharges) >= 1 and not talents[_DireFrenzy] and bwAura then
		return _DireBeast;
	end
end

MaxDps.Hunter.Marksmanship = function(_, timeShift, currentSpell, gcd, talents)
	if talents[_PatientSniper] then
		return MaxDps.Hunter.PatientSniper(_, timeShift, currentSpell, gcd, talents);
	else
		return MaxDps.Hunter.NonPatientSniper(_, timeShift, currentSpell, gcd, talents);
	end
end

function MaxDps.Hunter.AimedCost(timeShift, lol, ts, talents, gcd)
	-- Baseline
	local aimedShotCost = _AimedShotCost;
	local aimedShotCastTime = 2.0 * MaxDps:AttackHaste();

	-- NH 4 set
	if _isT19_4Set and ts then
		aimedShotCost = aimedShotCost * 0.85;
	end

	-- Tomb 2 set
	local prec = MaxDps:Aura(_Precision, timeShift + aimedShotCastTime);
	if prec then
		aimedShotCost = aimedShotCost * 0.92;
		aimedShotCastTime = aimedShotCastTime * 0.92;
	end

	-- Volley error
	local aimedShotError = 0;
--	if not talents[_Volley] then
--		aimedShotError = 0;
--	else
--		aimedShotCost = aimedShotCost + 3; -- volley cost
--	end

	local origAimedShotCost = aimedShotCost;
	local origAimedShotCastTime = aimedShotCastTime;

	-- Lock and load proc
	if lol then
		aimedShotCost = 0;
		aimedShotCastTime = 0;
	end

	local aimedShotExecuteTime = math.max(aimedShotCastTime, gcd);

	return aimedShotCost, aimedShotCastTime, aimedShotExecuteTime, origAimedShotCost, origAimedShotTime, aimedShotError;
end

function MaxDps.Hunter.Cooldowns(timeShift, talents)
	MaxDps:GlowCooldown(_Trueshot, MaxDps:SpellAvailable(_Trueshot, timeShift));
end

function MaxDps.Hunter.NonPatientSniper(_, timeShift, currentSpell, gcd, talents)
	MaxDps.Hunter.Cooldowns(timeShift, talents);
	MaxDps.debug = {};

	-- This is unreliable for determining how many targets will actually be hit by Multishot, Piercing Shot, etc.
	-- MaxDps:TargetsInRange(_ArcaneShot);
	local targets = 1;

	-- explosive_shot
	if talents[_ExplosiveShot] and MaxDps:SpellAvailable(_ExplosiveShot, timeShift) then
		return _ExplosiveShot;
	end

	local vul, vulCd = MaxDps:TargetAura(_Vulnerable, timeShift);
	local ts = MaxDps:Aura(_Trueshot, timeShift);
	local lnl = MaxDps:Aura(_LockandLoad, timeShift);
	local aimedShotCost, aimedShotCastTime, aimedShotExecuteTime, origAimedShotCost, origAimedShotTime, aimedShotError = MaxDps.Hunter.AimedCost(timeShift, lnl, ts, talents, gcd);
	local minusFocus = 0;
	
	if MaxDps:SameSpell(currentSpell, _AimedShot) then
		minusFocus = aimedShotCost;
	end

	if MaxDps:SameSpell(currentSpell, _Windburst) then
		minusFocus = 20;
		vul = true;
		vulCd = 7;
	end

	local focus, focusMax, focusRegen = MaxDps.Hunter.Focus(minusFocus, timeShift);
	local aimedShotCastRegen = aimedShotExecuteTime * focusRegen;
	local gcdRegen = gcd * focusRegen;

	local piercing, piercingCd = MaxDps:SpellAvailable(_PiercingShot, timeShift);

	-- piercing_shot,if=lowest_vuln_within.5>0&focus>100
	if talents[_PiercingShot] and piercing and targets == 1 and vul and focus > 100 then
		return _PiercingShot
	end

	local hm = MaxDps:TargetAura(_HuntersMark, timeShift);

	-- actions.non_patient_sniper+=/sentinel,if=!debuff.hunters_mark.up
	if talents[_Sentinel] and MaxDps:SpellAvailable(_Sentinel, timeShift) and not hm then
		return _Sentinel;
	end

	-- black_arrow
	if talents[_BlackArrow] and MaxDps:SpellAvailable(_BlackArrow, timeShift) then
		return _BlackArrow;
	end

	-- a_murder_of_crows
	if talents[_AMurderofCrows] and MaxDps:SpellAvailable(_AMurderofCrows, timeShift) then
		return _AMurderofCrows;
	end

	-- windburst
	if MaxDps:SpellAvailable(_Windburst, timeShift) and not MaxDps:SameSpell(currentSpell, _Windburst) then
		return _Windburst;
	end

	-- marked_shot,if=buff.marking_targets.up|buff.trueshot.up
	local mt = MaxDps:Aura(_MarkingTargets, timeShift);
	if hm and (mt or ts) then
		return _MarkedShot;
	end

	local sw, swCharges = MaxDps:SpellCharges(_Sidewinders, timeShift);

	-- sidewinders,if=(debuff.hunters_mark.down|(buff.trueshot.down&buff.marking_targets.down))&((buff.marking_targets.up|buff.trueshot.up)|charges_fractional>1.8)&(focus.deficit>cast_regen)
	if talents[_Sidewinders] and (not hm or (not ts and not mt)) and ((mt or ts) or swCharges > 1.8) and (focusMax - focus > gcdRegen + 45) then
		return _Sidewinders;
	end

	-- aimed_shot,if=talent.sidewinders.enabled&debuff.vulnerability.remains>cast_time
	if talents[_Sidewinders] and vulCd > aimedShotCastTime then
		return _AimedShot;
	end

	-- # Start being conservative with focus if expecting a Piercing Shot at the end of the current Vulnerable debuff. The expression lowest_vuln_within.<range> is used to check the lowest Vulnerable debuff duration on all enemies within the specified range from the target.
	-- variable,name=pooling_for_piercing,value=talent.piercing_shot.enabled&cooldown.piercing_shot.remains<5&lowest_vuln_within.5>0&lowest_vuln_within.5>cooldown.piercing_shot.remains&(buff.trueshot.down|spell_targets=1)
	local poolingForPiercing = talents[_PiercingShot] and piercingCd < 5 and vul and vulCd > piercingCd and not ts

	-- aimed_shot,if=!talent.sidewinders.enabled&debuff.vulnerability.remains>cast_time&(!variable.pooling_for_piercing|(buff.lock_and_load.up&lowest_vuln_within.5>gcd.max))&(talent.trick_shot.enabled)
	if not talents[_Sidewinders] and vulCd > aimedShotCastTime and (not poolingForPiercing or (lnl and vulCd > gcd)) and talents[_TrickShot] then
		return _AimedShot;
	end

	-- marked_shot
	if hm then
		return _MarkedShot;
	end

	-- aimed_shot,if=focus+cast_regen>focus.max
	if focus + aimedShotCastRegen >= focusMax then
		return _AimedShot;
	end

	local filler = _ArcaneShot;
	if targets > 1 then
		filler = _MultiShot;
	end

	-- arcane_shot
	if not talents[_Sidewinders] then
		return filler;
	end
end

function MaxDps.Hunter.PatientSniper(_, timeShift, currentSpell, gcd, talents)
	MaxDps.Hunter.Cooldowns(timeShift, talents);
	MaxDps.debug = {};

	--[[
		Ignored for MM since it is unreliable for checking how many targets will actually be hit by Multishot, Piercing Shot, etc. 
		For example on Trushot Lodge dummies, multiple spread out dummies are in range of MM abilities but multitarget 
		relies on them being within the Multishot radius and I don't know if there's a reliable way to calculate that unless 
		you are not talented for Lone Wolf and can use the pet's basic ability range like BM apl does.
	]]
	local targets = MaxDps:TargetsInRange(_ArcaneShot);

	local vul, vulCd = MaxDps:TargetAura(_Vulnerable, timeShift);
	local piercing, piercingCd = MaxDps:SpellAvailable(_PiercingShot, timeShift);

	-- piercing_shot,if=cooldown.piercing_shot.up&spell_targets=1&lowest_vuln_within.5>0&lowest_vuln_within.5<1
	if talents[_PiercingShot] and piercing and vul and vulCd < 1 then
		return _PiercingShot
	end

	local sw, swCharges, swMaxCharges = MaxDps:SpellCharges(_Sidewinders, timeShift);
	local _, _, _, swChargeDuration = GetSpellCharges(_Sidewinders);
	local swFullRecharge = (swMaxCharges - swCharges) * swChargeDuration;

	-- # Sidewinders charges could cap sooner than the Vulnerable debuff ends, so clip the current window to the recharge time if it will.
	-- variable,name=vuln_window,op=setif,value=cooldown.sidewinders.full_recharge_time,value_else=debuff.vulnerability.remains,condition=talent.sidewinders.enabled&cooldown.sidewinders.full_recharge_time<variable.vuln_window
	if talents[_Sidewinders] then
		vulCd = math.min(vulCd, swFullRecharge)
	end

	local ts = MaxDps:Aura(_Trueshot, timeShift);
	local lnl = MaxDps:Aura(_LockandLoad, timeShift);
	local aimedShotCost, aimedShotCastTime, aimedShotExecuteTime, origAimedShotCost, origAimedShotTime, aimedShotError = MaxDps.Hunter.AimedCost(timeShift, lnl, ts, talents, gcd);
	local minusFocus = 0;
	
	if MaxDps:SameSpell(currentSpell, _AimedShot) then
		minusFocus = aimedShotCost;
	end

	if MaxDps:SameSpell(currentSpell, _Windburst) then
		minusFocus = 20;
		vul = true;
		vulCd = 7;
	end

	local focus, focusMax, focusRegen = MaxDps.Hunter.Focus(minusFocus, timeShift);
	local aimedShotCastRegen = aimedShotExecuteTime * focusRegen;
	local gcdRegen = gcd * focusRegen;

	-- variable,name=vuln_aim_casts,op=set,value=floor(variable.vuln_window%action.aimed_shot.execute_time)
	-- variable,name=vuln_aim_casts,op=set,value=floor((focus+action.aimed_shot.cast_regen*(variable.vuln_aim_casts-1))%action.aimed_shot.cost),if=variable.vuln_aim_casts>0&variable.vuln_aim_casts>floor((focus+action.aimed_shot.cast_regen*(variable.vuln_aim_casts-1))%action.aimed_shot.cost)
	local vulnAimedCasts = math.floor(vulCd / aimedShotExecuteTime);
	local vulnAimedCasts2 = math.floor((focus + aimedShotCastRegen * (vulnAimedCasts - 1)) / aimedShotCost);
	vulnAimedCasts = min(vulnAimedCasts, vulnAimedCasts2);

	-- # Start being conservative with focus if expecting a Piercing Shot at the end of the current Vulnerable debuff. The expression lowest_vuln_within.<range> is used to check the lowest Vulnerable debuff duration on all enemies within the specified range from the target.
	-- variable,name=pooling_for_piercing,value=talent.piercing_shot.enabled&cooldown.piercing_shot.remains<5&lowest_vuln_within.5>0&lowest_vuln_within.5>cooldown.piercing_shot.remains&(buff.trueshot.down|spell_targets=1)
	local poolingForPiercing = talents[_PiercingShot] and piercingCd < 5 and vul and vulCd > piercingCd and not ts

	local canWindburst = MaxDps:SpellAvailable(_Windburst, timeShift) and not MaxDps:SameSpell(currentSpell, _Windburst);
	
	-- windburst,if=variable.vuln_aim_casts<1&!variable.pooling_for_piercing
	if canWindburst and vulnAimedCasts < 1 and not poolingForPiercing then
		return _Windburst;
	end

	-- variable,name=can_gcd,value=variable.vuln_window<action.aimed_shot.cast_time|variable.vuln_window>variable.vuln_aim_casts*action.aimed_shot.execute_time+gcd.max+0.1
	local canGcd = (vulCd < aimedShotCastTime) or (vulCd > vulnAimedCasts * aimedShotExecuteTime + gcd + 0.1);

	-- black_arrow,if=variable.can_gcd&(!variable.pooling_for_piercing|(lowest_vuln_within.5>gcd.max&focus>85))
	if talents[_BlackArrow] and MaxDps:SpellAvailable(_BlackArrow, timeShift) and canGcd and (not poolingForPiercing or (vulCd > gcd and focus > 85)) then
		return _BlackArrow;
	end
	
	-- a_murder_of_crows,if=(!variable.pooling_for_piercing|lowest_vuln_within.5>gcd.max)&(target.time_to_die>=cooldown+duration|target.health.pct<20|target.time_to_die<16)&variable.vuln_aim_casts=0
	-- and (MaxDps:TimeToDie() >= 75 or MaxDps:TargetPercentHealth() < 0.2 or MaxDps:TimeToDie() < 16) 
	if talents[_AMurderofCrows] and MaxDps:SpellAvailable(_AMurderofCrows, timeShift) and (not poolingForPiercing or vulCd > gcd) and vulnAimedCasts == 0 then
		return _AMurderofCrows;
	end

	-- aimed_shot,if=debuff.vulnerability.up&buff.lock_and_load.up&(!variable.pooling_for_piercing|lowest_vuln_within.5>gcd.max)
	if vul and lnl and (not poolingForPiercing or vulCd > gcd ) then
		return _AimedShot;
	end

	local filler = _ArcaneShot;
	local focusR = 8;
	if not talents[_Sidewinders] and targets > 1 then
		filler = _MultiShot;
		focusR = targets * 3;
	end

	local critAimed, critAimedStack, critAimedCd = MaxDps:Aura(_CriticalAimed, timeShift)

	-- arcane_shot,if=(!set_bonus.tier20_2pc|!action.aimed_shot.in_flight|buff.t20_2p_critical_aimed_damage.remains>action.aimed_shot.execute_time+gcd.max)
	-- &variable.vuln_aim_casts>0&variable.can_gcd&focus+cast_regen+action.aimed_shot.cast_regen<focus.max&(!variable.pooling_for_piercing|lowest_vuln_within.5>gcd.max)
	if not talents[_Sidewinders] and (not _isT20_2Set or not MaxDps:SameSpell(currentSpell, _AimedShot) or critAimedCd > aimedShotExecuteTime + gcd)
		and vulnAimedCasts > 0 and canGcd and focus + focusR + gcdRegen + aimedShotCastRegen < focusMax and (not poolingForPiercing or vulCd > gcd)
	then
		return filler
	end

	-- aimed_shot,if=talent.sidewinders.enabled&(debuff.vulnerability.remains>cast_time|(buff.lock_and_load.down&action.windburst.in_flight))
	-- &(variable.vuln_window-(execute_time*variable.vuln_aim_casts)<1|focus.deficit<25|buff.trueshot.up)&(spell_targets.multishot=1|focus>100)
	if talents[_Sidewinders] and (vulCd > aimedShotCastTime or (not lnl and MaxDps:SameSpell(currentSpell, _Windburst))) and (vulCd - (aimedShotExecuteTime * vulnAimedCasts) < 1 or focusMax - focus < 25 or ts) then
		return _AimedShot;
	end

	-- aimed_shot,!talent.sidewinders.enabled&debuff.vulnerability.remains>cast_time&(!variable.pooling_for_piercing|(focus>100&lowest_vuln_within.5>(execute_time+gcd.max)))
	if not talents[_Sidewinders] and focus >= 50 and vulCd > aimedShotCastTime and (not poolingForPiercing or (focus > 100 and vulCd > (aimedShotExecuteTime + gcd))) then
		return _AimedShot;
	end

	local hm = MaxDps:TargetAura(_HuntersMark, timeShift);

	-- marked_shot,if=!talent.sidewinders.enabled&!variable.pooling_for_piercing&!action.windburst.in_flight&(focus>65|buff.trueshot.up|(1%attack_haste)>1.171)
	-- 1 / 1.171 = .854
	if hm and not talents[_Sidewinders] and not poolingForPiercing and not MaxDps:SameSpell(currentSpell, _Windburst) and (focus > 65 or ts or (_isT20_4Set and MaxDps:AttackHaste() < 0.854)) then
		return _MarkedShot;
	end

	-- marked_shot,if=talent.sidewinders.enabled&(variable.vuln_aim_casts<1|buff.trueshot.up|variable.vuln_window<action.aimed_shot.cast_time)
	if hm and talents[_Sidewinders] and (vulnAimedCasts < 1 or ts or vulCd < aimedShotCastTime) then
		return _MarkedShot;
	end

	-- aimed_shot,if=focus+cast_regen>focus.max
	if focus + aimedShotCastRegen >= focusMax then
		return _AimedShot;
	end

	local mt = MaxDps:Aura(_MarkingTargets, timeShift);

	-- sidewinders,if=(!debuff.hunters_mark.up|(!buff.marking_targets.up&!buff.trueshot.up))&((buff.marking_targets.up&variable.vuln_aim_casts<1)|buff.trueshot.up|charges_fractional>1.9)
	if talents[_Sidewinders] and math.floor(swCharges) >= 1 and (not hm or (not mt and not ts)) and ((mt and vulnAimedCasts < 1) or ts or swCharges > 1.9) then
		return _Sidewinders;
	end

	-- arcane_shot,if=!variable.pooling_for_piercing|lowest_vuln_within.5>gcd.max
	if not talents[_Sidewinders] and (not poolingForPiercing or vulCd > gcd) then
		return filler;
	end
end

MaxDps.Hunter.Survival = function(_, timeShift, currentSpell, gcd, talents)

	local targets = MaxDps:TargetsInRange(_MongooseBite);

	local mok, mokStack, mokCd = MaxDps:Aura(_MokNathalTactics, timeShift);

	-- call_action_list,name=mokMaintain,if=talent.way_of_the_moknathal.enabled
	-- raptor_strike,if=(buff.moknathal_tactics.remains<gcd)|(buff.moknathal_tactics.stack<2)
	MaxDps:GlowCooldown(_RaptorStrike, talents[_WayoftheMokNathal] and (mokCd < 3 or mokStack < 2));

	local mb, mbCharges, mbMaxCharges = MaxDps:SpellCharges(_MongooseBite, timeShift);
	local mf, mfStack, mfCd = MaxDps:Aura(_MongooseFury, timeShift);
	local aote, _, aoteCd = MaxDps:Aura(_AspectoftheEagle, timeShift);
	
	-- call_action_list,name=CDs
	-- snake_hunter,if=cooldown.mongoose_bite.charges=0&buff.mongoose_fury.remains>3*gcd&buff.aspect_of_the_eagle.down
	if talents[_SnakeHunter] then
		MaxDps:GlowCooldown(_SnakeHunter, MaxDps:SpellAvailable(_SnakeHunter, timeShift) and mbCharges == 0 and mfCd > 3 * gcd and not aote);
	end

	-- aspect_of_the_eagle,if=buff.mongoose_fury.stack>=2&buff.mongoose_fury.remains>3*gcd
	MaxDps:GlowCooldown(_AspectoftheEagle, MaxDps:SpellAvailable(_AspectoftheEagle, timeShift) and mfStack >= 2 and mfCd > 3 * gcd);

	local fs, fsCd = MaxDps:SpellAvailable(_FlankingStrike, timeShift);
	local ss, ssCd = MaxDps:TargetAura(_SerpentSting, timeShift);
	local lac, lacCd = MaxDps:TargetAura(_Lacerate, timeShift);
	local cal, calCd = MaxDps:SpellAvailable(_Caltrops, timeShift);
	local calDot = MaxDps:TargetAura(_CaltropsAura, timeShift);
	local butch, butchCharges, butchMaxCharegs = MaxDps:SpellCharges(_Butchery, timeShift);

	-- call_action_list,name=preBitePhase,if=!buff.mongoose_fury.up
	if not mf then
		
		-- flanking_strike,if=cooldown.mongoose_bite.charges<3
		if fs and mbCharges < 3 then
			return _FlankingStrike;
		end

		-- spitting_cobra
		if talents[_SpittingCobra] and MaxDps:SpellAvailable(_SpittingCobra, timeShift) then
			return _SpittingCobra;
		end

		-- dragonsfire_grenade
		if talents[_DragonsfireGrenade] and MaxDps:SpellAvailable(_DragonsfireGrenade, timeShift) then
			return _DragonsfireGrenade;
		end

		-- raptor_strike,if=active_enemies=1&talent.serpent_sting.enabled&dot.serpent_sting.refreshable
		if targets == 1 and talents[_SerpentSting] and not ss then
			return _RaptorStrike;
		end

		-- steel_trap
		if talents[_SteelTrap] and MaxDps:SpellAvailable(_SteelTrap, timeShift) then
			return _SteelTrap;
		end

		-- a_murder_of_crows
		if talents[_AMurderofCrowsSurvi] and MaxDps:SpellAvailable(_AMurderofCrowsSurvi, timeShift) then
			return _AMurderofCrowsSurvi;
		end

		-- explosive_trap
		if MaxDps:SpellAvailable(_ExplosiveTrap, timeShift) then
			return _ExplosiveTrap;
		end

		-- lacerate,if=refreshable
		if not lac then
			return _Lacerate;
		end

		-- butchery,if=equipped.frizzos_fingertrap&dot.lacerate.refreshable
		if talents[_Butchery] and IsEquippedItem(FrizzosFingertrap) and butchCharges >= 1 and not lac then
			return _Butchery;
		end

		-- carve,if=equipped.frizzos_fingertrap&dot.lacerate.refreshable
		if not talents[_Butchery] and IsEquippedItem(FrizzosFingertrap) and not lac then
			return _Carve;
		end

		-- mongoose_bite,if=charges=3&cooldown.flanking_strike.remains>=gcd
		if mbCharges == 3 and fsCd > gcd then
			return _MongooseBite;
		end

		-- caltrops,if=!ticking
		if talents[_Caltrops] and cal and not calDot then
			return _Caltrops
		end

		-- flanking_strike
		if fs then
			return _FlankingStrike;
		end

		if lacCd < 14 and _isT20_2Set then
			return _Lacerate;
		end	
	end

	-- call_action_list,name=aoe,if=active_enemies>=3
	if targets >= 3 then

		-- butchery
		if talents[_Butchery] and butchCharges >= 1 then
			return _Butchery;
		end

		-- caltrops,if=!ticking
		if talents[_Caltrops] and cal and not calDot then
			return _Caltrops
		end

		-- explosive_trap
		if MaxDps:SpellAvailable(_ExplosiveTrap, timeShift) then
			return _ExplosiveTrap;
		end

		-- carve,if=(talent.serpent_sting.enabled&dot.serpent_sting.refreshable)|(active_enemies>5)
		if talents[_SerpentSting] and not ss or targets > 5 then
			return _Carve;
		end
	end

	-- call_action_list,name=bitePhase
	-- fury_of_the_eagle,if=(!talent.way_of_the_moknathal.enabled|buff.moknathal_tactics.remains>(gcd*(8%3)))&buff.mongoose_fury.stack>3&cooldown.mongoose_bite.charges<1&!buff.aspect_of_the_eagle.up
	if MaxDps:SpellAvailable(_FuryoftheEagle, timeShift) and (not talents[_WayoftheMokNathal] or mokCd > (gcd * (8/3))) and mfStack > 3 and mbCharges < 1 and not aote then
		return _FuryoftheEagle;
	end

	-- lacerate,if=!dot.lacerate.ticking&set_bonus.tier20_4pc&buff.mongoose_fury.duration>cooldown.mongoose_bite.charges*gcd
	if not lac and tier20_4pc and mfCd > mbCharges * gcd then
		return _Lacerate;
	end

	-- mongoose_bite,if=charges>=2&cooldown.mongoose_bite.remains<gcd*2
	if mbCharges >= 2 and mb < gcd * 2 then
		return _MongooseBite;
	end

	-- flanking_strike,if=((buff.mongoose_fury.remains>(gcd*(cooldown.mongoose_bite.charges+2)))&cooldown.mongoose_bite.charges<=1)&(!set_bonus.tier19_4pc|(set_bonus.tier19_4pc&!buff.aspect_of_the_eagle.up))
	if fs and ((mfCd > (gcd * (math.floor(mbCharges) + 2))) and mbCharges <= 1) and (not tier19_4pc or (tier19_4pc and not aote)) then
		return _FlankingStrike;
	end

	-- mongoose_bite,if=buff.mongoose_fury.up
	if mbCharges >= 1 and mf then
		return _MongooseBite;
	end

	-- actions.bitePhase+=/flanking_strike
	if fs then
		return _FlankingStrike;
	end

	-- call_action_list,name=biteFill

	-- actions.biteFill=spitting_cobra
	if talents[_SpittingCobra] and MaxDps:SpellAvailable(_SpittingCobra, timeShift) then
		return _SpittingCobra;
	end

	-- butchery,if=equipped.frizzos_fingertrap&dot.lacerate.refreshable
	if talents[_Butchery] and IsEquippedItem(FrizzosFingertrap) and not lac then
		return _Butchery;
	end

	-- carve,if=equipped.frizzos_fingertrap&dot.lacerate.refreshable
	if not talents[_Butchery] and IsEquippedItem(FrizzosFingertrap) and not lac then
		return _Carve;
	end

	-- lacerate,if=refreshable
	if not lac then
		return _Lacerate;
	end

	-- raptor_strike,if=active_enemies=1&talent.serpent_sting.enabled&dot.serpent_sting.refreshable
	if talents[_SerpentSting] and targets == 1 and not ss then
		return _RaptorStrike;
	end

	-- steel_trap
	if talents[_SteelTrap] and MaxDps:SpellAvailable(_SteelTrap, timeShift) then
		return _SteelTrap;
	end

	-- a_murder_of_crows
	if talents[_AMurderofCrowsSurvi] and MaxDps:SpellAvailable(_AMurderofCrowsSurvi, timeShift) then
		return _AMurderofCrowsSurvi;
	end

	-- dragonsfire_grenade
	if talents[_DragonsfireGrenade] and MaxDps:SpellAvailable(_DragonsfireGrenade, timeShift) then
		return _DragonsfireGrenade;
	end

	-- explosive_trap
	if MaxDps:SpellAvailable(_ExplosiveTrap, timeShift) then
		return _ExplosiveTrap;
	end

	-- caltrops,if=!ticking
	if talents[_Caltrops] and not calDot then
		return _Caltrops
	end
	
	-- call_action_list,name=fillers
	-- carve,if=active_enemies>1&talent.serpent_sting.enabled&dot.serpent_sting.refreshable
	if not talents[_Butchery] and targets > 1 and talents[_SerpentSting] and not ss then
		return _Carve;
	end

	local ta, taCharges, taMaxCharges = MaxDps:SpellCharges(_ThrowingAxes, timeShift);

	-- throwing_axes
	if talents[_ThrowingAxes] and taCharges >= 1 then
		return _ThrowingAxes;
	end

	-- carve,if=active_enemies>2
	if not talents[_Butchery] and targets > 2 then
		return _Carve;
	end

	local focus, focusMax, focusRegen = MaxDps.Hunter.Focus(0, timeShift);

	-- raptor_strike,if=(talent.way_of_the_moknathal.enabled&buff.moknathal_tactics.remains<gcd*4)|(focus>((25-focus.regen*gcd)+55))
	if talents[_WayoftheMokNathal] and mokCd < gcd * 4 or focus > (25 - focusRegen * gcd) + 55 then
		return _RaptorStrike;
	end
end

function MaxDps.Hunter.Focus(minus, timeShift)
	local casting = GetPowerRegen();
	local powerMax = UnitPowerMax('player', SPELL_POWER_FOCUS);
	local power = UnitPower('player', SPELL_POWER_FOCUS) + (casting * timeShift);
	if power > powerMax then
		power = powerMax;
	end;
	power = power - minus;
	return power, powerMax, casting;
end
