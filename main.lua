-- Author      : Kaminari
-- Create Date : 10/27/2014 6:47:46 PM

-- SPELLS
local _AMurderOfCrows = 131894;
local _ArcaneShot = 3044;
local _ChimaeraShot = 53209;
local _KillShot = 53351;
local _KillShotMM = 157708;
local _AimedShot = 19434;
local _GlaiveToss = 117050;
local _Barrage = 120360;
local _SteadyShot = 56641;
local _CobraShot = 77767;
local _DireBeast = 120679;
local _KillCommand = 34026;
local _BestialWrath = 19574;
local _FocusFire = 82692;
local _Stampede = 121818;
local _RapidFire = 3045;
local _ExplosiveShot = 53301;
local _BlackArrow = 3674;
local _SerpentSting = 87935;
local _FocusingShot = 163485;

-- AURAS
local _ThrillOfTheHunt = 34720;
local _SteadyFocus = 177668;
local _Frenzy = 19623;
-- local _BestialWrathAura = 19574; the same as spell id

-- costs
local _ChimaeraShotCost = 35;
local _AMurderOfCrowsCost = 30;
local _AimedShotCost = 30;
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
local isSteadyFocus = false;
local isBarrage = false;
local isFocusingShot = false;

-- Flags
local shouldGainSf = false;
local _FlagStamp = false;
local _SteadyShotTime = false;

----------------------------------------------
-- Pre enable, checking talents
----------------------------------------------
TDDps_Hunter_CheckTalents = function()
	isStampede = TD_TalentEnabled('Stampede');
	isMurderofcrows = TD_TalentEnabled('A Murder of Crows');
	isDireBeast = TD_TalentEnabled('Dire Beast');
	isSteadyFocus = TD_TalentEnabled('Steady Focus');
	isBarrage = TD_TalentEnabled('Barrage');
	isFocusingShot = TD_TalentEnabled('Focusing Shot');
	_SteadyShotTime = select(4, GetSpellInfo(_SteadyShot));
	if not _SteadyShotTime then
		_SteadyShotTime = 2;
	else
		_SteadyShotTime = _SteadyShotTime / 1000;
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
	local timeShift, spellName = TD_EndCast();

	local focus = TDDps_Hunter_Focus(0, timeShift);
	if spellName == 'Cobra Shot' then
		focus = focus + 14;
	end

	local toh = TD_Aura(_ThrillOfTheHunt);
	local sf = TD_Aura(_SteadyFocus);
	local sf3 = TD_Aura(_SteadyFocus, 3 + timeShift);
	local bw = TD_Aura(_BestialWrath, timeShift);
	local frenzy = TDDps_Hunter_PetFrenzy();
	local stamp, stampCD = TD_SpellAvailable(_Stampede, timeShift);
	local ff = TD_Aura(_FocusFire);
	local kk = TD_SpellAvailable(_KillCommand, timeShift + 2);
	local bwCd = TD_SpellAvailable(_BestialWrath, timeShift);
	local ks = TD_SpellAvailable(_KillShot, timeShift);

	if isStampede then
		TDButton_GlowCooldown(_Stampede, stamp);
	end

	if isStampede and stampCD > 265 and frenzy >= 1 and not ff then
		return _FocusFire;
	end;

	if not sf and shouldGainSf then
		shouldGainSf = false;
		return _CobraShot;
	end

	if frenzy == 5 and not ff then
		return _FocusFire;
	end;

	if bw and kk and not ff and frenzy >= 1 then
		return _FocusFire;
	end

	if isMurderofcrows and focus >= _AMurderOfCrowsCost and TD_SpellAvailable(_AMurderOfCrows) then
		return _AMurderOfCrows;
	end

	if bwCd and not bw and kk then
		return _BestialWrath;
	end

	if focus >= _KillCommandCost and TD_SpellAvailable(_KillCommand, timeShift) then
		return _KillCommand;
	end

	local targetPH = TD_TargetPercentHealth();
	if targetPH < 0.2 and ks then
		return _KillShot;
	end

	if isDireBeast and focus >= _DireBeastCost and TD_SpellAvailable(_DireBeast, timeShift) then
		return _DireBeast;
	end

	-- 6. Barrage
	if isBarrage and focus >= _BarrageCost and TD_SpellAvailable(_Barrage, timeShift) then
		return _Barrage;
	end

	if not sf and focus < 80 then
		shouldGainSf = true;
		return _CobraShot;
	end

	-- 6. Barrage
	if focus >= 80 then
		return _ArcaneShot;
	end

	return _CobraShot;
end

----------------------------------------------
-- Main rotation: Marksmanship
----------------------------------------------
TDDps_Hunter_Marksmanship = function()
	local timeShift, spellName = TD_EndCast();
	local gcd = TD_GlobalCooldown();

	local toh, tothCharges = TD_Aura(_ThrillOfTheHunt, timeShift);
	local rf = TD_Aura(_RapidFire, timeShift);

	local stamp = TD_SpellAvailable(_Stampede, timeShift);
	local chimaera, chimaeraCD = TD_SpellAvailable(_ChimaeraShot, timeShift);
	local ks = TD_SpellAvailable(_KillShotMM, timeShift);
	local rfCd = TD_SpellAvailable(_RapidFire, timeShift);
	local barr = TD_SpellAvailable(_Barrage, timeShift);

	local targetPH = TD_TargetPercentHealth();
	local careful = rf or targetPH > 0.8;
	local aimedShotCost = toh and _AimedShotCost or (_AimedShotCost - 20);

	local minusFocus = 0;
	if spellName == 'Aimed Shot' then
		if careful then
			-- almost certainly a crit, will refund a focus
			minusFocus = aimedShotCost - 20;
		else
			minusFocus = aimedShotCost;
		end
	end
	if spellName == 'Steady Shot' then
		minusFocus = -14;
	end
	if spellName == 'Focusing Shot' then
		minusFocus = -50;
	end

	local focus, focusMax = TDDps_Hunter_Focus(minusFocus, timeShift);

	if isStampede then
		TDButton_GlowCooldown(_Stampede, stamp);
	end

	if isBarrage then
		TDButton_GlowCooldown(_Barrage, barr);
	end

	TDButton_GlowCooldown(_RapidFire, rfCd);

	-- Chimaera Shot on cooldown.
	if chimaeraCD < gcd / 2 then
		if focus < _ChimaeraShotCost then
			return _SteadyShot;
		else
			return _ChimaeraShot;
		end
	end

	-- Kill Shot on cooldown if target below 35%
	if targetPH < 0.35 and ks then
		return _KillShotMM;
	end

	if careful and tothCharges > 0 and (focus >= aimedShotCost) then
		return _AimedShot;
	end

	-- Aimed Shot to dump Focus.
	if focus >= focusMax - 40 then
		return _AimedShot;
	end

	-- If nothing else, Steady Shot
	return _SteadyShot;
end

----------------------------------------------
-- Main rotation: Survival
----------------------------------------------
TDDps_Hunter_Survival = function()

	local timeShift, spellName = TD_EndCast();

	local focus = TDDps_Hunter_Focus(0, timeShift);
	if spellName == 'Cobra Shot' then
		focus = focus + 14;
	end

	local _, focusRegen = GetPowerRegen();
	local toh = TD_Aura(_ThrillOfTheHunt);

	local stamp, stampCD = TD_SpellAvailable(_Stampede, timeShift);
	local ss = TD_TargetAura(_SerpentSting, timeShift + 3);
	local arcaneShotCost = toh and _ArcaneShotCost or (_ArcaneShotCost - 20);

	-- 0. Stampede
	if isStampede then
		TDButton_GlowCooldown(_Stampede, stamp);
	end

	-- 0. A Murder of Crows
	--	if  focus >= _AMurderOfCrowsCost and TD_SpellAvailable(_AMurderOfCrows) then
	--		return _AMurderOfCrows;
	--	end

	-- 1. Explosive Shot
	if focus >= _ExplosiveShotCost and TD_SpellAvailable(_ExplosiveShot, timeShift + 1) then
		return _ExplosiveShot;
	end

	-- 2. Black Arrow
	if TD_SpellAvailable(_BlackArrow, timeShift + 1) then
		return _BlackArrow;
	end

	-- 3. Arcane Shot
	if focus >= arcaneShotCost and not ss then
		return _ArcaneShot;
	end

	-- 4. Barrage
	if focus >= _BarrageCost and TD_SpellAvailable(_Barrage, timeShift + 1) then
		return _Barrage;
	end

	-- 5. Barrage
	if focus >= 70 then
		return _ArcaneShot;
	end

	return _CobraShot;
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

----------------------------------------------
-- Is Rapid Fire Available
----------------------------------------------
function TDDps_Hunter_RapidFire()
	local _, _, _, _, _, _, expirationTime = UnitAura('player', 'Rapid Fire');
	if expirationTime ~= nil and (expirationTime - GetTime()) > 0.2 then
		return true;
	end
	return false;
end


----------------------------------------------
-- Is Steady Focus Available
----------------------------------------------
function TDDps_Hunter_SteadyFocus()
	local _, _, _, _, _, _, expirationTime = UnitAura('player', 'Steady Focus');
	if expirationTime ~= nil and (expirationTime - GetTime()) > 0.2 then
		return true;
	end
	return false;
end

----------------------------------------------
-- Pet frenzy stacks count
----------------------------------------------
function TDDps_Hunter_PetFrenzy()
	local _, _, _, count = UnitAura('pet', 'Frenzy')
	return count or 0;
end

