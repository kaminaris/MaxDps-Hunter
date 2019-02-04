local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then return end
local MaxDps = MaxDps;
local Hunter = addonTable.Hunter;
local IsSpellInRange = IsSpellInRange;
local GetSpellInfo = GetSpellInfo;

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

setmetatable(MM, Hunter.spellMeta);

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
