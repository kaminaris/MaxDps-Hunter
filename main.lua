--- @type MaxDps
if not MaxDps then
	return ;
end

local MaxDps = MaxDps;
local IsSpellInRange = IsSpellInRange;
local GetSpellInfo = GetSpellInfo;

local Hunter = MaxDps:NewModule('Hunter');

-- MM
local MM = {
	Trueshot       = 193526,
	Barrage        = 120360,
	SteadyShot     = 56641,
	RapidFire      = 257044,
	AimedShot      = 19434,
	MultiShot      = 257620,
	ArcaneShot     = 185358,
	Barrage        = 120361,
	SerpentSting   = 271788,
	PreciseShots   = 260242,
	SteadyFocus    = 193534,
	LoneWolf       = 164273,
	TrickShots     = 257622,
	LockAndLoad    = 194594,
	MasterMarksman = 269576,
}

-- BM
local BM = {
	SpittingCobra    = 194407,
	MultiShot        = 2643,
	CounterShot      = 147362,
	AspectOfTheWild  = 193530,
	DireBeast        = 120679,
	AutoShot         = 75,
	Stampede         = 201430,
	ChimaeraShot     = 53209,
	AMurderOfCrows   = 131894,
	BestialWrath     = 19574,
	CobraShot        = 193455,
	KillCommand      = 34026,
	BarbedShot       = 217200,
	Barrage          = 120360,
	PrimalInstincts  = 279810,

	-- Player Auras
	BestialWrathAura = 186254,
	LoadedDieMastery = 267326,
	BeastCleave      = 268877,
	Pathfinding      = 264656,
	Frenzy           = 272790,
	--BestialWrath   = 19574,
	--BarbedShot     = 246152,
	--DireBeast      = 281036,
	--BarbedShot     = 246852,

	-- Pet Auras

	-- Target Auras
	BarbedShotAura   = 217200,
	--AMurderofCrows = 131894,
}

local SV = {
	SteelTrap          = 162488,
	Harpoon            = 190925,
	WildfireInfusion   = 271014,
	AlphaPredator      = 269737,
	MongooseBite       = 259387,
	MongooseFury       = 259388,
	CoordinatedAssault = 266779,
	AspectOfTheEagle   = 186289,
	AMurderOfCrows     = 131894,
	Carve              = 187708,
	WildfireBomb       = 259495,
	GuerrillaTactics   = 264332,
	Chakrams           = 259391,
	KillCommand        = 259489,
	Butchery           = 212436,
	FlankingStrike     = 269751,
	SerpentSting       = 259491,
	VipersVenom        = 268501,
	TermsOfEngagement  = 265895,
	TipOfTheSpear      = 260285,
	RaptorStrike       = 186270,
	BirdsOfPrey        = 260331,
	LatentPoison       = 273283,

	PheromoneBomb      = 270323,
	ShrapnelBomb       = 270335,
	VolatileBomb       = 271045,

	InternalBleeding   = 270343,
};

local A = {
	UpCloseAndPersonal = 278533,
	LatentPoison       = 273283,
	VenomousFangs      = 274590,
	WildernessSurvival = 278532,
	BlurOfTalons       = 277653,
	PrimalInstincts    = 279806,
};

local spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!');
	end
}

setmetatable(SV, spellMeta);
setmetatable(MM, spellMeta);
setmetatable(BM, spellMeta);
setmetatable(A, spellMeta);

local _PetBasics = {
	smack = 49966,
	claw  = 16827,
	bite  = 17253
}

function Hunter:Enable()
	MaxDps:Print(MaxDps.Colors.Info .. 'Hunter [Beast Mastery, Marksmanship, Survival]');

	if MaxDps.Spec == 1 then
		MaxDps.NextSpell = Hunter.BeastMastery;
	elseif MaxDps.Spec == 2 then
		MaxDps.NextSpell = Hunter.Marksmanship;
	elseif MaxDps.Spec == 3 then
		MaxDps.NextSpell = Hunter.Survival;
	end ;

	return true;
end

--local BM = {
--	AspectOfTheWild = 193530,
--	BestialWrath = 19574,
--	BarbedShot = 217200,
--	Multishot = 2643,
--	Stampede = 201430,
--	ChimaeraShot = 53209,
--	AMurderOfCrows = 131894,
--	Barrage = 120360,
--	KillCommand = 34026,
--	DireBeast = 120679,
--	CobraShot = 193455,
--	SpittingCobra = 194407,
--};

local auraMetaTable = {
	__index = function()
		return {
			up          = false,
			count       = 0,
			remains     = 0,
			duration    = 0,
			refreshable = true,
		};
	end
};

function Hunter:BeastMastery()
	local fd = MaxDps.FrameData;
	local targets = MaxDps:SmartAoe();
	local timeShift = fd.timeShift;
	local cooldown = fd.cooldown;
	local talents = fd.talents;
	local buff = fd.buff;
	local bw, bwCd = cooldown[BM.BestialWrath].ready, cooldown[BM.BestialWrath].remains;

	if not fd.pet then
		fd.pet = {};
		setmetatable(fd.pet, auraMetaTable);
	end
	MaxDps:CollectAura('pet', timeShift, fd.pet);

	fd.targets = targets;
	local focus, focusMax, focusRegen = Hunter:Focus(0, timeShift);
	fd.focus = focus;
	fd.focusRegen = focusRegen;

	MaxDps:GlowCooldown(BM.AspectOfTheWild, cooldown[BM.AspectOfTheWild].ready);

	-- stampede,if=buff.aspect_of_the_wild.up&buff.bestial_wrath.up|target.time_to_die<15;
	if talents[BM.Stampede] then
		MaxDps:GlowCooldown(BM.Stampede, cooldown[BM.Stampede].ready and (buff[BM.AspectOfTheWild].up and buff[BM.BestialWrath].up));
	end

	-- call_action_list,name=cleave,if=active_enemies>1;
	if targets > 1 then
		return Hunter:BeastMasteryCleave();
	else
		return Hunter:BeastMasterySt();
	end
end

function Hunter:BeastMasteryCleave()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local azerite = fd.azerite;
	local buff = fd.buff;
	local talents = fd.talents;
	local timeShift = fd.timeShift;
	local gcd = fd.gcd;
	local pet = fd.pet;
	local focus = fd.focus;
	local focusTimeToMax = Hunter:FocusTimeToMax();

	local realFrenzyRemains = pet[BM.Frenzy].remains + timeShift;

	-- just in case we know its going to be in time
	if realFrenzyRemains < 2 and cooldown[BM.BarbedShot].remains <= pet[BM.Frenzy].remains then
		return BM.BarbedShot;
	end

	-- barbed_shot,if=pet.cat.buff.frenzy.up&pet.cat.buff.frenzy.remains<=gcd.max;
	--print(pet[BM.Frenzy].remains);
	if pet[BM.Frenzy].up and pet[BM.Frenzy].remains <= gcd
		and cooldown[BM.BarbedShot].remains <= gcd
	then
		return BM.BarbedShot;
	end

	-- multishot,if=gcd.max-pet.cat.buff.beast_cleave.remains>0.25;
	if gcd - buff[BM.BeastCleave].remains > 0.25 then
		return BM.MultiShot;
	end

	-- barbed_shot,if=full_recharge_time<gcd.max&cooldown.bestial_wrath.remains;
	if cooldown[BM.BarbedShot].fullRecharge < gcd and not cooldown[BM.BestialWrath].ready then
		return BM.BarbedShot;
	end

	-- bestial_wrath,if=cooldown.aspect_of_the_wild.remains>20|target.time_to_die<15;
	if cooldown[BM.BestialWrath].ready and (cooldown[BM.AspectOfTheWild].remains > 20 or cooldown[BM.AspectOfTheWild].ready) then
		return BM.BestialWrath;
	end

	-- chimaera_shot;
	if cooldown[BM.ChimaeraShot].ready then
		return BM.ChimaeraShot;
	end

	-- a_murder_of_crows;
	if talents[BM.AMurderOfCrows] and cooldown[BM.AMurderOfCrows].ready and focus >= 30 then
		return BM.AMurderOfCrows;
	end

	-- barrage;
	if talents[BM.Barrage] and cooldown[BM.Barrage].ready and focus >= 60 then
		return BM.Barrage;
	end

	-- kill_command;
	if cooldown[BM.KillCommand].ready and focus >= 30 then
		return BM.KillCommand;
	end

	-- dire_beast;
	if talents[BM.DireBeast] and cooldown[BM.DireBeast].ready and focus >= 25 then
		return BM.DireBeast;
	end

	if cooldown[BM.BarbedShot].fullRecharge < gcd then
		return BM.BarbedShot;
	end

	-- barbed_shot,if=pet.cat.buff.frenzy.down&(charges_fractional>1.8|buff.bestial_wrath.up)|cooldown.aspect_of_the_wild.remains<pet.cat.buff.frenzy.duration-gcd&azerite.primal_instincts.enabled|target.time_to_die<9;
	if not pet[BM.Frenzy].up and (cooldown[BM.BarbedShot].charges > 1.8 or buff[BM.BestialWrath].up) --or
		--cooldown[BM.AspectOfTheWild].remains < pet[BM.Frenzy].duration - gcd and azerite[A.PrimalInstincts] > 0
	then
		return BM.BarbedShot;
	end

	-- cobra_shot,if=cooldown.kill_command.remains>focus.time_to_max;
	if focus >= 35 and (cooldown[BM.KillCommand].remains > focusTimeToMax) then
		return BM.CobraShot;
	end

	-- spitting_cobra;
	if talents[BM.SpittingCobra] and cooldown[BM.SpittingCobra].ready then
		return BM.SpittingCobra;
	end
end

function Hunter:BeastMasterySt()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local azerite = fd.azerite;
	local buff = fd.buff;
	local talents = fd.talents;
	local timeShift = fd.timeShift;
	local gcd = fd.gcd;
	local focus = fd.focus;
	local pet = fd.pet;
	local timeToDie = fd.timeToDie;
	local focusRegen = fd.focusRegen;

	local realFrenzyRemains = pet[BM.Frenzy].remains + timeShift;

	-- just in case we know its going to be in time
	if realFrenzyRemains < 2 and cooldown[BM.BarbedShot].remains < pet[BM.Frenzy].remains then
		return BM.BarbedShot;
	end

	-- barbed_shot,if=pet.cat.buff.frenzy.up&pet.cat.buff.frenzy.remains<=gcd.max|full_recharge_time<gcd.max&cooldown.bestial_wrath.remains|azerite.primal_instincts.enabled&cooldown.aspect_of_the_wild.remains<gcd;

	if pet[BM.Frenzy].up and pet[BM.Frenzy].remains <= gcd or
		cooldown[BM.BarbedShot].fullRecharge < gcd and not cooldown[BM.BestialWrath].ready --or
		--azerite[A.PrimalInstincts] > 0 and cooldown[BM.AspectOfTheWild].remains < gcd
	then
		return BM.BarbedShot;
	end

	-- a_murder_of_crows;
	if talents[BM.AMurderOfCrows] and cooldown[BM.AMurderOfCrows].ready and focus >= 30 then
		return BM.AMurderOfCrows;
	end


	-- bestial_wrath,if=cooldown.aspect_of_the_wild.remains>20|target.time_to_die<15;
	if cooldown[BM.BestialWrath].ready and (cooldown[BM.AspectOfTheWild].remains > 20 or cooldown[BM.AspectOfTheWild].ready) then
		return BM.BestialWrath;
	end

	-- kill_command;
	if cooldown[BM.KillCommand].ready and focus >= 30 then
		return BM.KillCommand;
	end

	-- chimaera_shot;
	if cooldown[BM.ChimaeraShot].ready then
		return BM.ChimaeraShot;
	end

	-- dire_beast;
	if talents[BM.DireBeast] and cooldown[BM.DireBeast].ready and focus >= 25 then
		return BM.DireBeast;
	end

	-- barbed_shot,if=pet.cat.buff.frenzy.down&(charges_fractional>1.8|buff.bestial_wrath.up)|cooldown.aspect_of_the_wild.remains<pet.cat.buff.frenzy.duration-gcd&azerite.primal_instincts.enabled|target.time_to_die<9;
	if not pet[BM.Frenzy].up and (cooldown[BM.BarbedShot].charges > 1.8 or buff[BM.BestialWrath].up) -- or
		--cooldown[BM.AspectOfTheWild].remains < pet[BM.Frenzy].duration - gcd and azerite[A.PrimalInstincts] > 0
	then
		return BM.BarbedShot;
	end

	-- barrage;
	if talents[BM.Barrage] and cooldown[BM.Barrage].ready and focus >= 60 then
		return BM.Barrage;
	end

	local CobraShotCost = 35;
	local KillCommandCost = 30;
	-- cobra_shot,if=(focus-cost+focus.regen*(cooldown.kill_command.remains-1)>action.kill_command.cost|cooldown.kill_command.remains>1+gcd)&cooldown.kill_command.remains>1;
	if (
		focus - CobraShotCost + focusRegen * ( cooldown[BM.KillCommand].remains - 1 ) > KillCommandCost or
		cooldown[BM.KillCommand].remains > 1 + gcd
	) and cooldown[BM.KillCommand].remains > 1
	then
		return BM.CobraShot;
	end

	-- spitting_cobra;
	if talents[BM.SpittingCobra] and cooldown[BM.SpittingCobra].ready then
		return BM.SpittingCobra;
	end
end

--[[
function Hunter:BeastMastery()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, timeShift, talents, azerite, currentSpell =
		fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, fd.currentSpell;

	local minus = 0;
	local focus, focusMax, focusRegen = Hunter:Focus(minus, timeShift);

	-- Cooldowns

	local bw, bwCd = cooldown[BM.BestialWrath].ready, cooldown[BM.BestialWrath].remains;

	MaxDps:GlowCooldown(BM.AspectOfTheWild, cooldown[BM.AspectOfTheWild].ready and (bw or bwCd > 82));

	if talents[BM.SpittingCobra] then
		MaxDps:GlowCooldown(BM.SpittingCobra, cooldown[BM.SpittingCobra].ready);
	end

	if talents[BM.Stampede] then
		MaxDps:GlowCooldown(BM.Stampede, cooldown[BM.Stampede].ready);
	end

	if talents[BM.Barrage] then
		MaxDps:GlowCooldown(BM.Barrage, cooldown[BM.Barrage].ready);
	end

	-- Auras

	local bwAura = buff[BM.BestialWrathAura].up;

	local frenzyAura, frenzyCount, frenzyCd = MaxDps:UnitAura(BM.Frenzy, timeShift, 'pet');

	-- Rotation start
	if frenzyAura and cooldown[BM.BarbedShot].charges >= 1 and frenzyCd < 2 then
		return BM.BarbedShot;
	end

	if talents[BM.AMurderOfCrows] and cooldown[BM.AMurderOfCrows].ready then
		return BM.AMurderOfCrows;
	end

	if cooldown[BM.BarbedShot].charges >= 1.8 then
		return BM.BarbedShot;
	end

	if bw then
		return BM.BestialWrath;
	end

	if talents[BM.ChimaeraShot] and cooldown[BM.ChimaeraShot].ready then
		return BM.ChimaeraShot;
	end

	if cooldown[BM.KillCommand].remains < 0.5 then
		return BM.KillCommand;
	end

	if talents[BM.DireBeast] and cooldown[BM.DireBeast].ready then
		return BM.DireBeast;
	end

	if focus > 50 and cooldown[BM.KillCommand].remains > 2 then
		return BM.CobraShot;
	else
		return nil;
	end
end
]]--
function Hunter:Marksmanship()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, timeShift, talents, azerite, currentSpell =
		fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, fd.currentSpell;

	local minus = 0;

	local focus, focusMax, focusRegen = Hunter:Focus(minus, timeShift);
	local asCharges = cooldown[MM.AimedShot].charges;

	if currentSpell == MM.AimedShot then
		asCharges = asCharges - 1;
		minus = 30;
	end

	if currentSpell == MM.SteadyShot then
		minus = -10;
	end

	MaxDps:GlowCooldown(MM.Trueshot, cooldown[MM.Trueshot].ready);

	if currentSpell == MM.AimedShot then
		return MM.ArcaneShot;
	end

	if focus >= 30 and asCharges >= 1.7 then
		return MM.AimedShot;
	end

	if cooldown[MM.RapidFire].ready then
		-- focusMax - focus > 40 and
		return MM.RapidFire;
	end

	if talents[MM.SerpentSting] and focus >= 10 and debuff[MM.SerpentSting].remains < 3 then
		return MM.SerpentSting;
	end

	if currentSpell == MM.AimedShot or buff[MM.PreciseShots].count >= 1 then
		return MM.ArcaneShot;
	end

	if focus >= 60 and asCharges >= 1 then
		return MM.AimedShot;
	end

	if focus > 80 then
		return MM.ArcaneShot;
	end

	return MM.SteadyShot;
end

function Hunter:Survival()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, timeShift, talents, azerite, currentSpell =
		fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, fd.currentSpell;

	local minus = 0;
	fd.focus, fd.focusMax, fd.focusRegen = Hunter:Focus(minus, timeShift);

	Hunter:Cds();

	fd.targets = MaxDps:SmartAoe();

	if fd.targets < 3 and talents[SV.WildfireInfusion] and talents[SV.AlphaPredator] and talents[SV.MongooseBite] then
		return Hunter:SurvivalMbApWfiSt();
	end

	if fd.targets < 3 and talents[SV.WildfireInfusion] then
		return Hunter:SurvivalWfiSt();
	end

	if fd.targets < 2 then
		return Hunter:SurvivalSingleTarget();
	end

	if fd.targets > 1 then
		return Hunter:SurvivalCleave();
	end
end

function Hunter:Cds()
	local cooldown = MaxDps.FrameData.cooldown;

	MaxDps:GlowCooldown(SV.CoordinatedAssault, cooldown[SV.CoordinatedAssault].ready);

	MaxDps:GlowCooldown(
		SV.AspectOfTheEagle,
		cooldown[SV.AspectOfTheEagle].ready and not IsSpellInRange(SV.RaptorStrike, 'target')
	);
end

function Hunter:SurvivalCleave()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell, targets, focus, focusMax, focusRegen, gcd, timeShift =
	fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell, fd.targets, fd.focus, fd.focusMax, fd.focusRegen, fd.gcd, fd.timeShift;

	local BombSpell = self:SurvivalBombId();
	local castRegen = focusRegen * timeShift;
	local focusWithRegen = focus + castRegen;
	local mongooseBiteCost = 30;

	local carveCdr = targets;
	local MongooseBite = MaxDps:FindSpell(265888) and 265888 or SV.MongooseBite;
	local RaptorStrike = MaxDps:FindSpell(265189) and 265189 or SV.RaptorStrike;
	local canCarve = not talents[SV.Butchery] and cooldown[SV.Carve].ready and focusWithRegen >= 35;

	-- a_murder_of_crows;
	if talents[SV.AMurderOfCrows] and focusWithRegen >= 30 and cooldown[SV.AMurderOfCrows].ready then
		return SV.AMurderOfCrows;
	end

	-- carve,if=dot.shrapnel_bomb.ticking;
	if canCarve and debuff[SV.ShrapnelBomb].up then
		return SV.Carve;
	end

	-- wildfire_bomb,if=!talent.guerrilla_tactics.enabled|full_recharge_time<gcd;
	if (cooldown[SV.WildfireBomb].ready and not talents[SV.GuerrillaTactics]) or cooldown[SV.WildfireBomb].fullRecharge < gcd then
		return BombSpell;
	end

	-- mongoose_bite,target_if=max:debuff.latent_poison.stack,if=debuff.latent_poison.stack=10;
	if debuff[SV.LatentPoison].count >= 10 then
		return MongooseBite;
	end

	-- chakrams;
	if talents[SV.Chakrams] and cooldown[SV.Chakrams].ready and focusWithRegen >= 30 then
		return SV.Chakrams;
	end

	-- kill_command,target_if=min:bloodseeker.remains,if=focus+cast_regen<focus.max;
	if cooldown[SV.KillCommand].ready and focusWithRegen + 15 < focusMax then
		return SV.KillCommand;
	end

	-- butchery,if=full_recharge_time<gcd|!talent.wildfire_infusion.enabled|dot.shrapnel_bomb.ticking&dot.internal_bleeding.stack<3;
	if talents[SV.Butchery] and cooldown[SV.Butchery].charges >= 1 and (
		cooldown[SV.Butchery].fullRecharge < gcd or
		not talents[SV.WildfireInfusion] or
		debuff[SV.ShrapnelBomb].up and debuff[SV.InternalBleeding].count < 3
	) then
		return SV.Butchery;
	end

	-- carve,if=talent.guerrilla_tactics.enabled;
	if canCarve and talents[SV.GuerrillaTactics] then
		return SV.Carve;
	end

	-- flanking_strike,if=focus+cast_regen<focus.max;
	if talents[SV.FlankingStrike] and cooldown[SV.FlankingStrike].ready and focusWithRegen + 30 < focusMax then
		return SV.FlankingStrike;
	end

	-- wildfire_bomb,if=dot.wildfire_bomb.refreshable|talent.wildfire_infusion.enabled;
	if cooldown[SV.WildfireBomb].ready and (debuff[SV.WildfireBomb].refreshable or talents[SV.WildfireInfusion]) then
		return BombSpell;
	end

	-- serpent_sting,target_if=min:remains,if=buff.vipers_venom.up;
	if focusWithRegen >= 20 and buff[SV.VipersVenom].up then
		return SV.SerpentSting;
	end

	-- carve,if=cooldown.wildfire_bomb.remains>variable.carve_cdr%2;
	if canCarve and cooldown[SV.WildfireBomb].remains > carveCdr % 2 then
		return SV.Carve;
	end

	-- steel_trap;
	if talents[SV.SteelTrap] and cooldown[SV.SteelTrap].ready then
		return SV.SteelTrap;
	end

	-- harpoon,if=talent.terms_of_engagement.enabled;
	if cooldown[SV.Harpoon].ready and talents[SV.TermsOfEngagement] then
		return SV.Harpoon;
	end

	-- serpent_sting,target_if=min:remains,if=refreshable&buff.tip_of_the_spear.stack<3;
	if focusWithRegen >= 20 and debuff[SV.SerpentSting].refreshable and buff[SV.TipOfTheSpear].count < 3 then
		return SV.SerpentSting;
	end

	-- mongoose_bite,target_if=max:debuff.latent_poison.stack;
	if talents[SV.MongooseBite] and focusWithRegen > mongooseBiteCost then
		return MongooseBite;
	end

	-- raptor_strike,target_if=max:debuff.latent_poison.stack;
	return RaptorStrike;
end

function Hunter:SurvivalMbApWfiSt()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell, targets, focus, focusMax, focusRegen, gcd, timeShift =
		fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell, fd.targets, fd.focus, fd.focusMax, fd.focusRegen, fd.gcd, fd.timeShift;

	local BombSpell = self:SurvivalBombId();
	local nextWiBomb = select(7, GetSpellInfo(GetSpellInfo(259495)));
	local castRegen = focusRegen * timeShift;
	local focusWithRegen = focus + castRegen;
	local gcdRegen = focusRegen * gcd;
	local mongooseBiteCost = 30;
	local MongooseBite = MaxDps:FindSpell(265888) and 265888 or SV.MongooseBite;

	-- serpent_sting,if=!dot.serpent_sting.ticking;
	if focus >= 20 and not debuff[SV.SerpentSting].up then
		return SV.SerpentSting;
	end

	-- wildfire_bomb,if=full_recharge_time<gcd|(focus+cast_regen<focus.max)&(next_wi_bomb.volatile&dot.serpent_sting.ticking&dot.serpent_sting.refreshable|next_wi_bomb.pheromone&!buff.mongoose_fury.up&focus+cast_regen<focus.max-action.kill_command.cast_regen*3);
	if cooldown[SV.WildfireBomb].fullRecharge < gcd or cooldown[SV.WildfireBomb].charges >= 1 and (focusWithRegen < focusMax) and
		(
			(nextWiBomb == SV.VolatileBomb and debuff[SV.SerpentSting].up and debuff[SV.SerpentSting].refreshable) or
			(nextWiBomb == SV.PheromoneBomb and not buff[SV.MongooseFury].up and focusWithRegen < focusMax - gcdRegen * 3)
		)
	then
		return BombSpell;
	end

	-- a_murder_of_crows;
	if talents[SV.AMurderOfCrows] and focus >= 30 and cooldown[SV.AMurderOfCrows].ready then
		return SV.AMurderOfCrows;
	end

	-- steel_trap;
	if talents[SV.SteelTrap] and cooldown[SV.SteelTrap].ready then
		return SV.SteelTrap;
	end

	-- mongoose_bite,if=buff.mongoose_fury.remains&next_wi_bomb.pheromone;
	if focus >= 27 and buff[SV.MongooseFury].up and nextWiBomb == SV.PheromoneBomb then
		return MongooseBite;
	end

	-- kill_command,if=focus+cast_regen<focus.max&(buff.mongoose_fury.stack<5|focus<action.mongoose_bite.cost);
	if cooldown[SV.KillCommand].ready and (focusWithRegen + 15 < focusMax) and (buff[SV.MongooseFury].count < 5 or focus < mongooseBiteCost) then
		return SV.KillCommand;
	end

	-- wildfire_bomb,if=next_wi_bomb.shrapnel&focus>60&dot.serpent_sting.remains>3*gcd;
	if cooldown[SV.WildfireBomb].charges >= 1 and nextWiBomb == SV.ShrapnelBomb and
		focus > 60 and debuff[SV.SerpentSting].remains > 3 * gcd
	then
		return BombSpell;
	end

	-- serpent_sting,if=buff.vipers_venom.up|refreshable&(!talent.mongoose_bite.enabled|!talent.vipers_venom.enabled|next_wi_bomb.volatile&!dot.shrapnel_bomb.ticking|azerite.latent_poison.enabled|azerite.venomous_fangs.enabled);
	if focus >= 20 and
		(buff[SV.VipersVenom].up or debuff[SV.SerpentSting].refreshable and
			(
				not talents[SV.MongooseBite] or
				not talents[SV.VipersVenom] or
				(nextWiBomb == SV.VolatileBomb and not debuff[SV.ShrapnelBomb].up) or
				azerite[A.LatentPoison] > 0 or
				azerite[A.VenomousFangs] > 0
			)
		)
	then
		return SV.SerpentSting;
	end

	-- mongoose_bite,if=buff.mongoose_fury.up|focus>60|dot.shrapnel_bomb.ticking;
	if focus >= 27 and
		(buff[SV.MongooseFury].up or focus > 60 or debuff[SV.ShrapnelBomb].up)
	then
		return MongooseBite;
	end

	-- serpent_sting,if=refreshable;
	if focus >= 20 and debuff[SV.SerpentSting].refreshable then
		return SV.SerpentSting;
	end

	-- wildfire_bomb,if=next_wi_bomb.volatile&dot.serpent_sting.ticking|next_wi_bomb.pheromone|next_wi_bomb.shrapnel&focus>50;
	if cooldown[SV.WildfireBomb].ready and
		(
			nextWiBomb == SV.VolatileBomb and debuff[SV.SerpentSting].up or
			nextWiBomb == SV.PheromoneBomb or
			nextWiBomb == SV.ShrapnelBomb and focus > 50
		)
	then
		return BombSpell;
	end
end

function Hunter:SurvivalSingleTarget()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell, targets, focus, focusMax, focusRegen, gcd, timeShift =
	fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell, fd.targets, fd.focus, fd.focusMax, fd.focusRegen, fd.gcd, fd.timeShift;

	local castRegen = focusRegen * timeShift;
	local focusWithRegen = focus + castRegen;
	local mongooseBiteCost = 30;
	local MongooseBite = MaxDps:FindSpell(265888) and 265888 or SV.MongooseBite;
	local RaptorStrike = MaxDps:FindSpell(265189) and 265189 or SV.RaptorStrike;


	-- a_murder_of_crows;
	if talents[SV.AMurderOfCrows] and focusWithRegen >= 30 and cooldown[SV.AMurderOfCrows].ready then
		return SV.AMurderOfCrows;
	end

	-- mongoose_bite,if=talent.birds_of_prey.enabled&buff.coordinated_assault.up&(buff.coordinated_assault.remains<gcd|buff.blur_of_talons.up&buff.blur_of_talons.remains<gcd);
	if talents[SV.BirdsOfPrey] and buff[SV.CoordinatedAssault].up and (
		buff[SV.CoordinatedAssault].remains < gcd or
		buff[A.BlurOfTalons].up and buff[A.BlurOfTalons].remains < gcd
	) then
		return MongooseBite;
	end

	-- raptor_strike,if=talent.birds_of_prey.enabled&buff.coordinated_assault.up&(buff.coordinated_assault.remains<gcd|buff.blur_of_talons.up&buff.blur_of_talons.remains<gcd);
	if talents[SV.BirdsOfPrey] and buff[SV.CoordinatedAssault].up and (
		buff[SV.CoordinatedAssault].remains < gcd or
		buff[A.BlurOfTalons].up and buff[A.BlurOfTalons].remains < gcd
	) then
		return RaptorStrike;
	end

	-- serpent_sting,if=buff.vipers_venom.up&buff.vipers_venom.remains<gcd;
	if buff[SV.VipersVenom].up and buff[SV.VipersVenom].remains < gcd then
		return SV.SerpentSting;
	end

	-- kill_command,if=focus+cast_regen<focus.max&(!talent.alpha_predator.enabled|full_recharge_time<gcd);
	if cooldown[SV.KillCommand].ready and focusWithRegen + 15 < focusMax and (
		not talents[SV.AlphaPredator] or
		cooldown[SV.KillCommand].fullRecharge < gcd
	) then
		return SV.KillCommand;
	end

	-- wildfire_bomb,if=focus+cast_regen<focus.max&(full_recharge_time<gcd|!dot.wildfire_bomb.ticking&(buff.mongoose_fury.down|full_recharge_time<4.5*gcd));
	if cooldown[SV.WildfireBomb].ready and focusWithRegen < focusMax and (
		cooldown[SV.WildfireBomb].fullRecharge < gcd or
		not debuff[SV.WildfireBomb].up and (
			not buff[SV.MongooseFury].up or
			cooldown[SV.WildfireBomb].remains < 4.5 * gcd
		)
	) then
		return SV.WildfireBomb;
	end

	-- serpent_sting,if=buff.vipers_venom.react&dot.serpent_sting.remains<4*gcd|!talent.vipers_venom.enabled&!dot.serpent_sting.ticking&!buff.coordinated_assault.up
	if buff[SV.VipersVenom].up and debuff[SV.SerpentSting].remains < 4 * gcd or
		not talents[SV.VipersVenom] and not debuff[SV.SerpentSting].up and not buff[SV.CoordinatedAssault].up
	then
		return SV.SerpentSting;
	end

	-- serpent_sting,if=refreshable&(azerite.latent_poison.rank>2|azerite.latent_poison.enabled&azerite.venomous_fangs.enabled|(azerite.latent_poison.enabled|azerite.venomous_fangs.enabled)&(!azerite.blur_of_talons.enabled|!talent.birds_of_prey.enabled|!buff.coordinated_assault.up))
	if debuff[SV.SerpentSting].refreshable and (
		azerite[A.LatentPoison] > 2 or
		azerite[A.LatentPoison] > 0 and azerite[A.VenomousFangs] > 0 or
		(azerite[A.LatentPoison] > 0 or azerite[A.VenomousFangs] > 0) and (
			azerite[A.BlurOfTalons] == 0 or not talents[SV.BirdsOfPrey] or not buff[SV.CoordinatedAssault].up
		)
	) then
		return SV.SerpentSting;
	end

	-- steel_trap;
	if talents[SV.SteelTrap] and cooldown[SV.SteelTrap].ready then
		return SV.SteelTrap;
	end

	-- harpoon,if=talent.terms_of_engagement.enabled|azerite.up_close_and_personal.enabled;
	if talents[SV.TermsOfEngagement] or azerite[A.UpCloseAndPersonal] > 0 then
		return SV.Harpoon;
	end

	-- chakrams;
	if talents[SV.Chakrams] and cooldown[SV.Chakrams].ready and focusWithRegen >= 30 then
		return SV.Chakrams;
	end

	-- flanking_strike,if=focus+cast_regen<focus.max;
	if talents[SV.FlankingStrike] and cooldown[SV.FlankingStrike].ready and focusWithRegen + 30 < focusMax then
		return SV.FlankingStrike;
	end

	-- kill_command,if=focus+cast_regen<focus.max&(buff.mongoose_fury.stack<4|focus<action.mongoose_bite.cost);
	if cooldown[SV.KillCommand].ready and focusWithRegen + 15 < focusMax and (
		buff[SV.MongooseFury].count < 4 or
			focus < mongooseBiteCost
	) then
		return SV.KillCommand;
	end

	-- mongoose_bite,if=buff.mongoose_fury.up|focus>60;
	if talents[SV.MongooseBite] and focusWithRegen >= 30 and (buff[SV.MongooseFury].up or focus > 60) then
		return MongooseBite;
	end

	-- raptor_strike;
	if not talents[SV.MongooseBite] and focus >= 30 then
		return RaptorStrike;
	end

	-- serpent_sting,if=dot.serpent_sting.refreshable&!buff.coordinated_assault.up;
	if focusWithRegen >= 20 and debuff[SV.SerpentSting].refreshable and not buff[SV.CoordinatedAssault].up then
		return SV.SerpentSting;
	end

	-- wildfire_bomb,if=dot.wildfire_bomb.refreshable;
	if cooldown[SV.WildfireBomb].ready and debuff[SV.WildfireBomb].refreshable then
		return SV.WildfireBomb;
	end
end

function Hunter:SurvivalWfiSt()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell, targets, focus, focusMax, focusRegen, gcd, timeShift =
	fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell, fd.targets, fd.focus, fd.focusMax, fd.focusRegen, fd.gcd, fd.timeShift;

	local BombSpell = self:SurvivalBombId();
	local nextWiBomb = select(7, GetSpellInfo(GetSpellInfo(259495)));
	local castRegen = focusRegen * timeShift;
	local focusWithRegen = focus + castRegen;
	local gcdRegen = focusRegen * gcd;
	local mongooseBiteCost = 30;
	local MongooseBite = MaxDps:FindSpell(265888) and 265888 or SV.MongooseBite;
	local RaptorStrike = MaxDps:FindSpell(265189) and 265189 or SV.RaptorStrike;

	-- a_murder_of_crows;
	if talents[SV.AMurderOfCrows] and focus >= 30 and cooldown[SV.AMurderOfCrows].ready then
		return SV.AMurderOfCrows;
	end

	-- mongoose_bite,if=azerite.wilderness_survival.enabled&next_wi_bomb.volatile&dot.serpent_sting.remains>2.1*gcd&dot.serpent_sting.remains<3.5*gcd&cooldown.wildfire_bomb.remains>2.5*gcd;
	if talents[SV.MongooseBite] and azerite[A.WildernessSurvival] > 0 and nextWiBomb == SV.VolatileBomb and
		debuff[SV.SerpentSting].remains > 2.1 * gcd and debuff[SV.SerpentSting].remains < 3.5 * gcd
		and cooldown[SV.WildfireBomb].remains > 2.5 * gcd
	then
		return MongooseBite;
	end

	-- wildfire_bomb,if=full_recharge_time<gcd|(focus+cast_regen<focus.max)&(next_wi_bomb.volatile&dot.serpent_sting.ticking&dot.serpent_sting.refreshable|next_wi_bomb.pheromone&!buff.mongoose_fury.up&focus+cast_regen<focus.max-action.kill_command.cast_regen*3);
	if cooldown[SV.WildfireBomb].fullRecharge < gcd or cooldown[SV.WildfireBomb].ready and (focusWithRegen < focusMax) and
		(
			nextWiBomb == SV.VolatileBomb and debuff[SV.SerpentSting].up and debuff[SV.SerpentSting].refreshable or
			nextWiBomb == SV.PheromoneBomb and not buff[SV.MongooseFury].up and focusWithRegen < focusMax - gcdRegen * 3
		)
	then
		return BombSpell;
	end

	-- kill_command,if=focus+cast_regen<focus.max&buff.tip_of_the_spear.stack<3&(!talent.alpha_predator.enabled|buff.mongoose_fury.stack<5|focus<action.mongoose_bite.cost);
	if cooldown[SV.KillCommand].ready and focusWithRegen + 15 < focusMax and buff[SV.TipOfTheSpear].count < 3 and (
		not talents[SV.AlphaPredator] or buff[SV.MongooseFury].count < 5 or focus < mongooseBiteCost
	) then
		return SV.KillCommand;
	end

	-- raptor_strike,if=dot.internal_bleeding.stack<3&dot.shrapnel_bomb.ticking&!talent.mongoose_bite.enabled;
	if focus >= 30 and debuff[SV.InternalBleeding].count < 3 and debuff[SV.ShrapnelBomb].up and not talents[SV.MongooseBite] then
		return RaptorStrike;
	end

	-- wildfire_bomb,if=next_wi_bomb.shrapnel&buff.mongoose_fury.down&(cooldown.kill_command.remains>gcd|focus>60)&!dot.serpent_sting.refreshable;
	if cooldown[SV.WildfireBomb].ready and nextWiBomb == SV.ShrapnelBomb and not buff[SV.MongooseFury].up and
		(cooldown[SV.KillCommand].remains > gcd or focus > 60) and not debuff[SV.SerpentSting].refreshable
	then
		return BombSpell;
	end

	-- steel_trap;
	if talents[SV.SteelTrap] and cooldown[SV.SteelTrap].ready then
		return SV.SteelTrap;
	end

	-- flanking_strike,if=focus+cast_regen<focus.max;
	if talents[SV.FlankingStrike] and cooldown[SV.FlankingStrike].ready and focusWithRegen + 30 < focusMax then
		return SV.FlankingStrike;
	end

	-- serpent_sting,if=buff.vipers_venom.up|refreshable&(!talent.mongoose_bite.enabled|!talent.vipers_venom.enabled|next_wi_bomb.volatile&!dot.shrapnel_bomb.ticking|azerite.latent_poison.enabled|azerite.venomous_fangs.enabled|buff.mongoose_fury.stack=5);
	if focus >= 20 and (buff[SV.VipersVenom].up or debuff[SV.SerpentSting].refreshable and (
		not talents[SV.MongooseBite] or
		not talents[SV.VipersVenom] or
		nextWiBomb == SV.VolatileBomb and not debuff[SV.ShrapnelBomb].up or
		azerite[A.LatentPoison] > 0 or
		azerite[A.VenomousFangs] > 0 or
		buff[SV.MongooseFury].count == 5
	))
	then
		return SV.SerpentSting;
	end

	-- harpoon,if=talent.terms_of_engagement.enabled|azerite.up_close_and_personal.enabled;
	if cooldown[SV.Harpoon].ready and (talents[SV.TermsOfEngagement] or azerite[A.UpCloseAndPersonal] > 0) then
		return SV.Harpoon;
	end

	-- mongoose_bite,if=buff.mongoose_fury.up|focus>60|dot.shrapnel_bomb.ticking;
	if talents[SV.MongooseBite] and (buff[SV.MongooseFury].up or focus > 60 or debuff[SV.ShrapnelBomb].up) then
		return MongooseBite;
	end

	-- raptor_strike;
	if not talents[SV.MongooseBite] and focus >= 30 then
		return RaptorStrike;
	end

	-- serpent_sting,if=refreshable;
	if focus >= 20 and debuff[SV.SerpentSting].refreshable then
		return SV.SerpentSting;
	end

	-- wildfire_bomb,if=next_wi_bomb.volatile&dot.serpent_sting.ticking|next_wi_bomb.pheromone|next_wi_bomb.shrapnel&focus>50;
	if cooldown[SV.WildfireBomb].ready and
		(
			nextWiBomb == SV.VolatileBomb and debuff[SV.SerpentSting].up or
			nextWiBomb == SV.PheromoneBomb or
			nextWiBomb == SV.ShrapnelBomb and focus > 50
		)
	then
		return BombSpell;
	end
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

function Hunter:SurvivalBombId()
	if MaxDps:FindSpell(SV.PheromoneBomb) then
		return SV.PheromoneBomb;
	elseif MaxDps:FindSpell(SV.VolatileBomb) then
		return SV.VolatileBomb;
	elseif MaxDps:FindSpell(SV.ShrapnelBomb) then
		return SV.ShrapnelBomb
	else
		return SV.WildfireBomb;
	end
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