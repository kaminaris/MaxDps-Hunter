local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then return end
local MaxDps = MaxDps;
local Hunter = addonTable.Hunter;

local BM = {
	AMurderOfCrows = 131894,
	AspectOfTheWild = 193530,
	BarbedShot = 217200,
	Barrage = 120360,
	BestialWrath = 19574,
	Bloodshed = 321530,
	CallOfTheWild = 359844,
	CobraShot = 193455,
	DeathChakram = 375891,
	DireBeast = 120679,
	ExplosiveShot = 212431,
	Flare = 1543,
	FreezingTrap = 187650,
	KillCommand = 34026,
	KillShot = 53351,
	Multishot = 2643,
	ScentOfBlood = 193532,
	SerpentSting = 271788,
	Stampede = 201430,
	SteelTrap = 162488,
	TarTrap = 187698,
	WailingArrow = 392060,
	Frenzy = 272790,
	BeastCleave = 115939,
	BeastCleaveBuff = 118455
}

setmetatable(BM, Hunter.spellMeta);

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

local function getSpellCost(spellId, defaultCost)
	local cost = GetSpellPowerCost(spellId);
	if cost ~= nil then
		return cost[1].cost;
	end

	return defaultCost
end

function Hunter:BeastMastery()
	local fd = MaxDps.FrameData
	fd.targets = MaxDps:SmartAoe()
	fd.castRegen = UnitPower('player', Enum.PowerType.CastRegen)
	local focus, focusMax, focusRegen = Hunter:Focus(0, fd.timeShift);
	fd.focus = focus
	fd.focusMax = focusMax
	fd.focusRegen = focusRegen
	fd.targetHp = MaxDps:TargetPercentHealth();
	local focusTimeToMax = Hunter:FocusTimeToMax();
	fd.focusTimeToMax = focusTimeToMax;
	local cooldown = fd.cooldown
	local talents = fd.talents

	if not fd.pet then
		fd.pet = {};
		setmetatable(fd.pet, auraMetaTable);
	end
	MaxDps:CollectAura('pet', fd.timeShift, fd.pet);

	MaxDps:GlowCooldown(BM.AspectOfTheWild, talents[BM.AspectOfTheWild] and cooldown[BM.AspectOfTheWild].ready);

	-- call_action_list,name=st,if=active_enemies<2
	if fd.targets < 2 then
		return Hunter:BeastMasterySt()
	end

	return Hunter:BeastMasteryCleave()
end

function Hunter:BeastMasteryCleave()
	local fd = MaxDps.FrameData
	local pet = fd.pet
	local cooldown = fd.cooldown
	local buff = fd.buff
	local debuff = fd.debuff
	local talents = fd.talents
	local timeShift = fd.timeShift
	local gcd = fd.gcd
	local timeToDie = fd.timeToDie
	local focus = fd.focus
	local castRegen = fd.castRegen
	local focusMax = fd.focusMax
	local targetHp = fd.targetHp
	local focusTimeToMax = fd.focusTimeToMax

	local killCommandCost = getSpellCost(BM.KillCommand, 30)
	local multiShotCost = getSpellCost(BM.Multishot, 40)

	-- aspect_of_the_wild,if=!raid_event.adds.exists|raid_event.adds.remains>=10|active_enemies>=raid_event.adds.count*2
	if talents[BM.AspectOfTheWild] and cooldown[BM.AspectOfTheWild].ready then
		return BM.AspectOfTheWild
	end

	-- call_of_the_wild
	if talents[BM.CallOfTheWild] and cooldown[BM.CallOfTheWild].ready then
		return BM.CallOfTheWild
	end

	-- multishot,if=gcd-pet.main.buff.beast_cleave.remains>0.25
	if talents[BM.BeastCleave] and talents[BM.Multishot] and (gcd - pet[BM.BeastCleaveBuff].remains > 0.25) then
		return BM.Multishot
	end

	-- explosive_shot
	if talents[BM.ExplosiveShot] and cooldown[BM.ExplosiveShot].ready then
		return BM.ExplosiveShot
	end

	-- steel_trap
	if talents[BM.SteelTrap] and cooldown[BM.SteelTrap].ready then
		return BM.SteelTrap
	end

	-- death_chakram,if=focus+cast_regen<focus.max
	if talents[BM.DeathChakram] and cooldown[BM.DeathChakram].ready and (focus + castRegen < focusMax) then
		return BM.DeathChakram
	end

	-- barbed_shot,target_if=min:dot.barbed_shot.remains,if=full_recharge_time<gcd&cooldown.bestial_wrath.remains|cooldown.bestial_wrath.remains<12+gcd&talent.scent_of_blood
	if talents[BM.BarbedShot] and cooldown[BM.BarbedShot].ready and (cooldown[BM.BarbedShot].fullRecharge < gcd and not cooldown[BM.BestialWrath].ready or cooldown[BM.BestialWrath].remains < 12 + gcd and talents[BM.ScentOfBlood]) then
		return BM.BarbedShot
	end

	-- bestial_wrath,if=!raid_event.adds.exists|raid_event.adds.remains>=5|active_enemies>=raid_event.adds.count*2
	if talents[BM.BestialWrath] and cooldown[BM.BestialWrath].ready then
		return BM.BestialWrath
	end

	-- stampede,if=buff.bestial_wrath.up|target.time_to_die<15
	if talents[BM.Stampede] and cooldown[BM.Stampede].ready and (buff[BM.BestialWrath].up or timeToDie < 15) then
		return BM.Stampede
	end

	-- wailing_arrow,if=pet.main.buff.frenzy.remains>execute_time
	if talents[BM.WailingArrow] and cooldown[BM.WailingArrow].ready and (pet[BM.Frenzy].remains > timeShift) then
		return BM.WailingArrow
	end

	-- kill_shot
	if talents[BM.KillShot] and cooldown[BM.KillShot].ready and targetHp < 0.2 then
		return BM.KillShot
	end

	-- serpent_sting,target_if=min:dot.serpent_sting.remains,if=refreshable
	if talents[BM.SerpentSting] and (debuff[BM.SerpentSting].refreshable) then
		return BM.SerpentSting
	end

	-- bloodshed
	if talents[BM.Bloodshed] and cooldown[BM.Bloodshed].ready then
		return BM.Bloodshed
	end

	-- a_murder_of_crows
	if talents[BM.AMurderOfCrows] and cooldown[BM.AMurderOfCrows].ready then
		return BM.AMurderOfCrows
	end

	-- barrage,if=pet.main.buff.frenzy.remains>execute_time
	if talents[BM.Barrage] and cooldown[BM.Barrage].ready and (pet[BM.Frenzy].remains > timeShift) then
		return BM.Barrage
	end

	-- kill_command,if=focus>cost+action.multishot.cost
	if talents[BM.KillCommand] and cooldown[BM.KillCommand].ready and focus > (killCommandCost + multiShotCost) then
		return BM.KillCommand
	end

	-- dire_beast
	if talents[BM.DireBeast] and cooldown[BM.DireBeast].ready then
		return BM.DireBeast
	end

	local cobraShotCost = getSpellCost(BM.CobraShot, 35)

	-- cobra_shot,if=focus.time_to_max<gcd*2
	if talents[BM.CobraShot] and focus >= cobraShotCost and (focusTimeToMax < gcd * 2) then
		return BM.CobraShot
	end
end

function Hunter:BeastMasterySt()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local buff = fd.buff
	local debuff = fd.debuff
	local talents = fd.talents
	local gcd = fd.gcd
	local timeToDie = fd.timeToDie
	local focus = fd.focus
	local castRegen = fd.castRegen
	local targetHp = fd.targetHp
	local focusMax = fd.focusMax
	local focusRegen = fd.focusRegen;
	local pet = fd.pet
	local timeShift = fd.timeShift

	-- call_of_the_wild
	if talents[BM.CallOfTheWild] and cooldown[BM.CallOfTheWild].ready then
		return BM.CallOfTheWild
	end

	-- steel_trap
	if talents[BM.SteelTrap] and cooldown[BM.SteelTrap].ready then
		return BM.SteelTrap
	end

	-- bloodshed
	if talents[BM.Bloodshed] and cooldown[BM.Bloodshed].ready then
		return BM.Bloodshed
	end

	-- kill_shot
	if talents[BM.KillShot] and cooldown[BM.KillShot].ready and targetHp < 0.2 then
		return BM.KillShot
	end

	-- explosive_shot
	if talents[BM.ExplosiveShot] and cooldown[BM.ExplosiveShot].ready then
		return BM.ExplosiveShot
	end

	-- wailing_arrow,if=pet.main.buff.frenzy.remains>execute_time&(cooldown.resonating_arrow.remains<gcd&(!talent.explosive_shot|buff.bloodlust.up)|!covenant.kyrian)|target.time_to_die<5
	if talents[BM.WailingArrow] and cooldown[BM.WailingArrow].ready and (pet[BM.Frenzy].remains > timeShift or timeToDie < 5) then
		return BM.WailingArrow
	end

	-- barbed_shot,if=cooldown.bestial_wrath.remains<12*charges_fractional+gcd&talent.scent_of_blood|full_recharge_time<gcd&cooldown.bestial_wrath.remains|target.time_to_die<9
	if talents[BM.BarbedShot] and cooldown[BM.BarbedShot].ready and (cooldown[BM.BestialWrath].remains < 12 * cooldown[BM.BarbedShot].charges + gcd and talents[BM.ScentOfBlood] or cooldown[BM.BarbedShot].fullRecharge < gcd and not cooldown[BM.BestialWrath].ready or timeToDie < 9) then
		return BM.BarbedShot
	end

	-- death_chakram,if=focus+cast_regen<focus.max
	if talents[BM.DeathChakram] and cooldown[BM.DeathChakram].ready and (focus + castRegen < focusMax) then
		return BM.DeathChakram
	end

	-- stampede,if=buff.bestial_wrath.up|target.time_to_die<15
	if talents[BM.Stampede] and cooldown[BM.Stampede].ready and (buff[BM.BestialWrath].up or timeToDie < 15) then
		return BM.Stampede
	end

	-- a_murder_of_crows
	if talents[BM.AMurderOfCrows] and cooldown[BM.AMurderOfCrows].ready then
		return BM.AMurderOfCrows
	end

	-- bestial_wrath,if=(cooldown.wild_spirits.remains>15|covenant.kyrian&(cooldown.resonating_arrow.remains<5|cooldown.resonating_arrow.remains>20)|target.time_to_die<15|(!covenant.night_fae&!covenant.kyrian))&(!raid_event.adds.exists|!raid_event.adds.up&(raid_event.adds.duration+raid_event.adds.in<20|raid_event.adds.count=1)|raid_event.adds.up&raid_event.adds.remains>19)
	if talents[BM.BestialWrath] and cooldown[BM.BestialWrath].ready then
		return BM.BestialWrath
	end

	-- kill_command
	if talents[BM.KillCommand] and cooldown[BM.KillCommand].ready then
		return BM.KillCommand
	end

	-- dire_beast
	if talents[BM.DireBeast] and cooldown[BM.DireBeast].ready then
		return BM.DireBeast
	end

	-- serpent_sting,target_if=min:remains,if=refreshable&target.time_to_die>duration
	if talents[BM.SerpentSting] and (debuff[BM.SerpentSting].refreshable and timeToDie > debuff[BM.SerpentSting].duration) then
		return BM.SerpentSting
	end

	local cobraShotCost = getSpellCost(BM.CobraShot, 35)
	local killCommandCost = getSpellCost(BM.KillCommand, 30)

	-- cobra_shot,if=(focus-cost+focus.regen*(cooldown.kill_command.remains-1)>action.kill_command.cost|cooldown.kill_command.remains>1+gcd)|(buff.bestial_wrath.up|buff.nesingwarys_trapping_apparatus.up)&!runeforge.qapla_eredun_war_order|target.time_to_die<3
	if talents[BM.CobraShot] and (( focus - cobraShotCost + focusRegen * ( cooldown[BM.KillCommand].remains - 1 ) > killCommandCost or cooldown[BM.KillCommand].remains > 1 + gcd ) or ( buff[BM.BestialWrath].up) or timeToDie < 3) then
		return BM.CobraShot
	end
end
