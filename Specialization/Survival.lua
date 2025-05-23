local _, addonTable = ...
local Hunter = addonTable.Hunter
local MaxDps = _G.MaxDps
if not MaxDps then return end
local setSpell

local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = C_UnitAuras.GetAuraDataByIndex
local UnitAuraByName = C_UnitAuras.GetAuraDataBySpellName
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local SpellHaste
local SpellCrit
local GetSpellInfo = C_Spell.GetSpellInfo
local GetSpellCooldown = C_Spell.GetSpellCooldown
local GetSpellCount = C_Spell.GetSpellCastCount

local ManaPT = Enum.PowerType.Mana
local RagePT = Enum.PowerType.Rage
local FocusPT = Enum.PowerType.Focus
local EnergyPT = Enum.PowerType.Energy
local ComboPointsPT = Enum.PowerType.ComboPoints
local RunesPT = Enum.PowerType.Runes
local RunicPowerPT = Enum.PowerType.RunicPower
local SoulShardsPT = Enum.PowerType.SoulShards
local LunarPowerPT = Enum.PowerType.LunarPower
local HolyPowerPT = Enum.PowerType.HolyPower
local MaelstromPT = Enum.PowerType.Maelstrom
local ChiPT = Enum.PowerType.Chi
local InsanityPT = Enum.PowerType.Insanity
local ArcaneChargesPT = Enum.PowerType.ArcaneCharges
local FuryPT = Enum.PowerType.Fury
local PainPT = Enum.PowerType.Pain
local EssencePT = Enum.PowerType.Essence
local RuneBloodPT = Enum.PowerType.RuneBlood
local RuneFrostPT = Enum.PowerType.RuneFrost
local RuneUnholyPT = Enum.PowerType.RuneUnholy

local fd
local ttd
local timeShift
local gcd
local cooldown
local buff
local debuff
local talents
local targets
local targetHP
local targetmaxHP
local targethealthPerc
local curentHP
local maxHP
local healthPerc
local timeInCombat
local className, classFilename, classId = UnitClass('player')
local currentSpec = GetSpecialization()
local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or 'None'
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local Focus
local FocusMax
local FocusDeficit
local FocusRegen
local FocusTimeToMax
local FocusPerc
local petHP
local petmaxHP
local pethealthPerc
local next_wi_bomb

local Survival = {}



local function howl_summon_ready()
    return buff[classtable.HowlofthePackLeaderBear].up or buff[classtable.HowlofthePackLeaderBoar].up or buff[classtable.HowlofthePackLeaderWyvern].up or false
end


function Survival:precombat()
    if (MaxDps:CheckSpellUsable(classtable.HuntersMark, 'HuntersMark')) and (( false or MaxDps:boss() ) and MaxDps:DebuffCounter(classtable.HuntersMarkDeBuff) == 0 and MaxDps:GetTimeToPct(80) >20) and cooldown[classtable.HuntersMark].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.HuntersMark, cooldown[classtable.HuntersMark].ready)
    end
end
function Survival:cds()
    if (MaxDps:CheckSpellUsable(classtable.Harpoon, 'Harpoon')) and (false and MaxDps:CheckPrevSpell(classtable.KillCommand)) and cooldown[classtable.Harpoon].ready then
        MaxDps:GlowCooldown(classtable.Harpoon, cooldown[classtable.Harpoon].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.AspectoftheEagle, 'AspectoftheEagle')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', false, true) or 0) >= 6) and cooldown[classtable.AspectoftheEagle].ready then
        MaxDps:GlowCooldown(classtable.AspectoftheEagle, cooldown[classtable.AspectoftheEagle].ready)
    end
end
function Survival:plcleave()
    if (MaxDps:CheckSpellUsable(classtable.Spearhead, 'Spearhead') and talents[classtable.Spearhead]) and (cooldown[classtable.CoordinatedAssault].ready) and cooldown[classtable.Spearhead].ready then
        MaxDps:GlowCooldown(classtable.Spearhead, cooldown[classtable.Spearhead].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.RaptorBite, 'RaptorBite')) and (buff[classtable.StrikeItRichBuff].up and buff[classtable.StrikeItRichBuff].remains <gcd or buff[classtable.HogstriderBuff].up) and cooldown[classtable.RaptorBite].ready then
        if not setSpell then setSpell = classtable.RaptorBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and (buff[classtable.RelentlessPrimalFerocityBuff].up and buff[classtable.TipoftheSpearBuff].count <1) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.WildfireBomb, 'WildfireBomb')) and (buff[classtable.TipoftheSpearBuff].count >0 and cooldown[classtable.WildfireBomb].charges >1.7 or cooldown[classtable.WildfireBomb].charges >1.9 or cooldown[classtable.CoordinatedAssault].remains <2 * gcd or talents[classtable.Butchery] and cooldown[classtable.Butchery].remains <gcd or howl_summon_ready()) and cooldown[classtable.WildfireBomb].ready then
        if not setSpell then setSpell = classtable.WildfireBomb end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlankingStrike, 'FlankingStrike')) and (buff[classtable.TipoftheSpearBuff].count == 2 or buff[classtable.TipoftheSpearBuff].count == 1) and cooldown[classtable.FlankingStrike].ready then
        if not setSpell then setSpell = classtable.FlankingStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Butchery, 'Butchery') and talents[classtable.Butchery]) and cooldown[classtable.Butchery].ready then
        if not setSpell then setSpell = classtable.Butchery end
    end
    if (MaxDps:CheckSpellUsable(classtable.CoordinatedAssault, 'CoordinatedAssault') and talents[classtable.CoordinatedAssault]) and (not talents[classtable.Bombardier] or talents[classtable.Bombardier] and cooldown[classtable.WildfireBomb].charges <1) and cooldown[classtable.CoordinatedAssault].ready then
        MaxDps:GlowCooldown(classtable.CoordinatedAssault, cooldown[classtable.CoordinatedAssault].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FuryoftheEagle, 'FuryoftheEagle')) and (buff[classtable.TipoftheSpearBuff].count >0) and cooldown[classtable.FuryoftheEagle].ready then
        if not setSpell then setSpell = classtable.FuryoftheEagle end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and (Focus + FocusRegen <FocusMax) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.WildfireBomb, 'WildfireBomb')) and (buff[classtable.TipoftheSpearBuff].count >0) and cooldown[classtable.WildfireBomb].ready then
        if not setSpell then setSpell = classtable.WildfireBomb end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and (buff[classtable.DeathblowBuff].remains and talents[classtable.SicEm]) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.RaptorBite, 'RaptorBite')) and cooldown[classtable.RaptorBite].ready then
        if not setSpell then setSpell = classtable.RaptorBite end
    end
end
function Survival:plst()
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and (( buff[classtable.RelentlessPrimalFerocityBuff].up and buff[classtable.TipoftheSpearBuff].count <1 ) or ( howl_summon_ready() ) and ttd <20) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and (cooldown[classtable.CoordinatedAssault].remains and cooldown[classtable.CoordinatedAssault].remains <gcd) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Spearhead, 'Spearhead') and talents[classtable.Spearhead]) and (cooldown[classtable.CoordinatedAssault].ready) and cooldown[classtable.Spearhead].ready then
        MaxDps:GlowCooldown(classtable.Spearhead, cooldown[classtable.Spearhead].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.RaptorBite, 'RaptorBite')) and (not debuff[classtable.SerpentStingDeBuff].up and ttd >12 and ( not talents[classtable.ContagiousReagents] or MaxDps:DebuffCounter(classtable.SerpentStingDeBuff) == 0 )) and cooldown[classtable.RaptorBite].ready then
        if not setSpell then setSpell = classtable.RaptorBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.RaptorBite, 'RaptorBite')) and (talents[classtable.ContagiousReagents] and MaxDps:DebuffCounter(classtable.SerpentStingDeBuff) <targets and debuff[classtable.SerpentStingDeBuff].up) and cooldown[classtable.RaptorBite].ready then
        if not setSpell then setSpell = classtable.RaptorBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.Butchery, 'Butchery') and talents[classtable.Butchery]) and cooldown[classtable.Butchery].ready then
        if not setSpell then setSpell = classtable.Butchery end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and (buff[classtable.StrikeItRichBuff].remains and buff[classtable.TipoftheSpearBuff].count <1) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.RaptorBite, 'RaptorBite')) and (buff[classtable.StrikeItRichBuff].remains and buff[classtable.TipoftheSpearBuff].count >0) and cooldown[classtable.RaptorBite].ready then
        if not setSpell then setSpell = classtable.RaptorBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlankingStrike, 'FlankingStrike')) and (buff[classtable.TipoftheSpearBuff].count == 1 or buff[classtable.TipoftheSpearBuff].count == 2) and cooldown[classtable.FlankingStrike].ready then
        if not setSpell then setSpell = classtable.FlankingStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.FuryoftheEagle, 'FuryoftheEagle')) and (buff[classtable.TipoftheSpearBuff].count >0 and ( (targets <2) or (targets >1) and math.huge >40 )) and cooldown[classtable.FuryoftheEagle].ready then
        if not setSpell then setSpell = classtable.FuryoftheEagle end
    end
    if (MaxDps:CheckSpellUsable(classtable.WildfireBomb, 'WildfireBomb')) and (buff[classtable.TipoftheSpearBuff].count >0 and cooldown[classtable.WildfireBomb].charges >1.4 or cooldown[classtable.WildfireBomb].charges >1.9 or cooldown[classtable.CoordinatedAssault].remains <2 * gcd and talents[classtable.Bombardier] or howl_summon_ready()) and cooldown[classtable.WildfireBomb].ready then
        if not setSpell then setSpell = classtable.WildfireBomb end
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and (cooldown[classtable.CoordinatedAssault].remains <gcd) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.CoordinatedAssault, 'CoordinatedAssault') and talents[classtable.CoordinatedAssault]) and (not talents[classtable.Bombardier] or talents[classtable.Bombardier] and cooldown[classtable.WildfireBomb].charges <1) and cooldown[classtable.CoordinatedAssault].ready then
        MaxDps:GlowCooldown(classtable.CoordinatedAssault, cooldown[classtable.CoordinatedAssault].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and (Focus + FocusRegen <FocusMax and ( not buff[classtable.RelentlessPrimalFerocityBuff].up or ( buff[classtable.RelentlessPrimalFerocityBuff].up and buff[classtable.TipoftheSpearBuff].count <1 or Focus <30 ) )) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.WildfireBomb, 'WildfireBomb')) and (buff[classtable.TipoftheSpearBuff].count >0 and ( (targets <2) or (targets >1) and math.huge >15 )) and cooldown[classtable.WildfireBomb].ready then
        if not setSpell then setSpell = classtable.WildfireBomb end
    end
    if (MaxDps:CheckSpellUsable(classtable.RaptorBite, 'RaptorBite')) and (not talents[classtable.ContagiousReagents]) and cooldown[classtable.RaptorBite].ready then
        if not setSpell then setSpell = classtable.RaptorBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.RaptorBite, 'RaptorBite')) and cooldown[classtable.RaptorBite].ready then
        if not setSpell then setSpell = classtable.RaptorBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
end
function Survival:sentcleave()
    if (MaxDps:CheckSpellUsable(classtable.WildfireBomb, 'WildfireBomb')) and (not buff[classtable.LunarStormCooldownBuff].up) and cooldown[classtable.WildfireBomb].ready then
        if not setSpell then setSpell = classtable.WildfireBomb end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and (buff[classtable.RelentlessPrimalFerocityBuff].up and buff[classtable.TipoftheSpearBuff].count <1) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.WildfireBomb, 'WildfireBomb')) and (buff[classtable.TipoftheSpearBuff].count >0 and cooldown[classtable.WildfireBomb].charges >1.7 or cooldown[classtable.WildfireBomb].charges >1.9 or ( talents[classtable.Bombardier] and cooldown[classtable.CoordinatedAssault].remains <2 * gcd ) or talents[classtable.Butchery] and cooldown[classtable.Butchery].remains <gcd) and cooldown[classtable.WildfireBomb].ready then
        if not setSpell then setSpell = classtable.WildfireBomb end
    end
    if (MaxDps:CheckSpellUsable(classtable.RaptorBite, 'RaptorBite')) and (buff[classtable.StrikeItRichBuff].up and buff[classtable.StrikeItRichBuff].remains <gcd) and cooldown[classtable.RaptorBite].ready then
        if not setSpell then setSpell = classtable.RaptorBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.Butchery, 'Butchery') and talents[classtable.Butchery]) and cooldown[classtable.Butchery].ready then
        if not setSpell then setSpell = classtable.Butchery end
    end
    if (MaxDps:CheckSpellUsable(classtable.CoordinatedAssault, 'CoordinatedAssault') and talents[classtable.CoordinatedAssault]) and (not talents[classtable.Bombardier] or talents[classtable.Bombardier] and cooldown[classtable.WildfireBomb].charges <1) and cooldown[classtable.CoordinatedAssault].ready then
        MaxDps:GlowCooldown(classtable.CoordinatedAssault, cooldown[classtable.CoordinatedAssault].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FuryoftheEagle, 'FuryoftheEagle')) and (buff[classtable.TipoftheSpearBuff].count >0) and cooldown[classtable.FuryoftheEagle].ready then
        if not setSpell then setSpell = classtable.FuryoftheEagle end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlankingStrike, 'FlankingStrike')) and (( buff[classtable.TipoftheSpearBuff].count == 2 or buff[classtable.TipoftheSpearBuff].count == 1 )) and cooldown[classtable.FlankingStrike].ready then
        if not setSpell then setSpell = classtable.FlankingStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and (Focus + FocusRegen <FocusMax) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.WildfireBomb, 'WildfireBomb')) and (buff[classtable.TipoftheSpearBuff].count >0) and cooldown[classtable.WildfireBomb].ready then
        if not setSpell then setSpell = classtable.WildfireBomb end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and (buff[classtable.DeathblowBuff].remains and talents[classtable.SicEm]) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.RaptorBite, 'RaptorBite')) and (not talents[classtable.ContagiousReagents]) and cooldown[classtable.RaptorBite].ready then
        if not setSpell then setSpell = classtable.RaptorBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.RaptorBite, 'RaptorBite')) and cooldown[classtable.RaptorBite].ready then
        if not setSpell then setSpell = classtable.RaptorBite end
    end
end
function Survival:sentst()
    if (MaxDps:CheckSpellUsable(classtable.WildfireBomb, 'WildfireBomb')) and (not buff[classtable.LunarStormCooldownBuff].up) and cooldown[classtable.WildfireBomb].ready then
        if not setSpell then setSpell = classtable.WildfireBomb end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and (( buff[classtable.RelentlessPrimalFerocityBuff].up and buff[classtable.TipoftheSpearBuff].count <1 )) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.Spearhead, 'Spearhead') and talents[classtable.Spearhead]) and (cooldown[classtable.CoordinatedAssault].ready) and cooldown[classtable.Spearhead].ready then
        MaxDps:GlowCooldown(classtable.Spearhead, cooldown[classtable.Spearhead].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FlankingStrike, 'FlankingStrike')) and (buff[classtable.TipoftheSpearBuff].count >0) and cooldown[classtable.FlankingStrike].ready then
        if not setSpell then setSpell = classtable.FlankingStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and (buff[classtable.StrikeItRichBuff].remains and buff[classtable.TipoftheSpearBuff].count <1) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.MongooseBite, 'MongooseBite')) and (buff[classtable.StrikeItRichBuff].remains and buff[classtable.CoordinatedAssaultBuff].up) and cooldown[classtable.MongooseBite].ready then
        if not setSpell then setSpell = classtable.MongooseBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.WildfireBomb, 'WildfireBomb')) and (( buff[classtable.LunarStormCooldownBuff].remains >FocusTimeToMax - gcd ) and ( buff[classtable.TipoftheSpearBuff].count >0 and cooldown[classtable.WildfireBomb].charges >1.7 or cooldown[classtable.WildfireBomb].charges >1.9 ) or ( talents[classtable.Bombardier] and cooldown[classtable.CoordinatedAssault].remains <2 * gcd )) and cooldown[classtable.WildfireBomb].ready then
        if not setSpell then setSpell = classtable.WildfireBomb end
    end
    if (MaxDps:CheckSpellUsable(classtable.Butchery, 'Butchery') and talents[classtable.Butchery]) and cooldown[classtable.Butchery].ready then
        if not setSpell then setSpell = classtable.Butchery end
    end
    if (MaxDps:CheckSpellUsable(classtable.CoordinatedAssault, 'CoordinatedAssault') and talents[classtable.CoordinatedAssault]) and (not talents[classtable.Bombardier] or talents[classtable.Bombardier] and cooldown[classtable.WildfireBomb].charges <1) and cooldown[classtable.CoordinatedAssault].ready then
        MaxDps:GlowCooldown(classtable.CoordinatedAssault, cooldown[classtable.CoordinatedAssault].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FuryoftheEagle, 'FuryoftheEagle')) and (buff[classtable.TipoftheSpearBuff].count >0) and cooldown[classtable.FuryoftheEagle].ready then
        if not setSpell then setSpell = classtable.FuryoftheEagle end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and (buff[classtable.TipoftheSpearBuff].count <1 and cooldown[classtable.FlankingStrike].remains <gcd) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and (Focus + FocusRegen <FocusMax and ( not buff[classtable.RelentlessPrimalFerocityBuff].up or ( buff[classtable.RelentlessPrimalFerocityBuff].up and ( buff[classtable.TipoftheSpearBuff].count <2 or Focus <30 ) ) )) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.MongooseBite, 'MongooseBite')) and (buff[classtable.MongooseFuryBuff].remains <gcd and buff[classtable.MongooseFuryBuff].count >0) and cooldown[classtable.MongooseBite].ready then
        if not setSpell then setSpell = classtable.MongooseBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.WildfireBomb, 'WildfireBomb')) and (buff[classtable.TipoftheSpearBuff].count >0 and buff[classtable.LunarStormCooldownBuff].remains >FocusTimeToMax and ( (targets <2) or (targets >1) and math.huge >15 )) and cooldown[classtable.WildfireBomb].ready then
        if not setSpell then setSpell = classtable.WildfireBomb end
    end
    if (MaxDps:CheckSpellUsable(classtable.MongooseBite, 'MongooseBite')) and (buff[classtable.MongooseFuryBuff].up) and cooldown[classtable.MongooseBite].ready then
        if not setSpell then setSpell = classtable.MongooseBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.RaptorBite, 'RaptorBite')) and (not talents[classtable.ContagiousReagents]) and cooldown[classtable.RaptorBite].ready then
        if not setSpell then setSpell = classtable.RaptorBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.RaptorBite, 'RaptorBite')) and cooldown[classtable.RaptorBite].ready then
        if not setSpell then setSpell = classtable.RaptorBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.WildfireBomb, 'WildfireBomb')) and (not buff[classtable.LunarStormCooldownBuff].up) and cooldown[classtable.WildfireBomb].ready then
        if not setSpell then setSpell = classtable.WildfireBomb end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and (( buff[classtable.RelentlessPrimalFerocityBuff].up and buff[classtable.TipoftheSpearBuff].count <1 )) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.Spearhead, 'Spearhead') and talents[classtable.Spearhead]) and (cooldown[classtable.CoordinatedAssault].ready) and cooldown[classtable.Spearhead].ready then
        MaxDps:GlowCooldown(classtable.Spearhead, cooldown[classtable.Spearhead].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FlankingStrike, 'FlankingStrike')) and (buff[classtable.TipoftheSpearBuff].count >0) and cooldown[classtable.FlankingStrike].ready then
        if not setSpell then setSpell = classtable.FlankingStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and (buff[classtable.StrikeItRichBuff].remains and buff[classtable.TipoftheSpearBuff].count <1) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.MongooseBite, 'MongooseBite')) and (buff[classtable.StrikeItRichBuff].remains and buff[classtable.CoordinatedAssaultBuff].up) and cooldown[classtable.MongooseBite].ready then
        if not setSpell then setSpell = classtable.MongooseBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.WildfireBomb, 'WildfireBomb')) and (( buff[classtable.LunarStormCooldownBuff].remains >FocusTimeToMax - gcd ) and ( buff[classtable.TipoftheSpearBuff].count >0 and cooldown[classtable.WildfireBomb].charges >1.7 or cooldown[classtable.WildfireBomb].charges >1.9 ) or ( talents[classtable.Bombardier] and cooldown[classtable.CoordinatedAssault].remains <2 * gcd )) and cooldown[classtable.WildfireBomb].ready then
        if not setSpell then setSpell = classtable.WildfireBomb end
    end
    if (MaxDps:CheckSpellUsable(classtable.Butchery, 'Butchery') and talents[classtable.Butchery]) and cooldown[classtable.Butchery].ready then
        if not setSpell then setSpell = classtable.Butchery end
    end
    if (MaxDps:CheckSpellUsable(classtable.CoordinatedAssault, 'CoordinatedAssault') and talents[classtable.CoordinatedAssault]) and (not talents[classtable.Bombardier] or talents[classtable.Bombardier] and cooldown[classtable.WildfireBomb].charges <1) and cooldown[classtable.CoordinatedAssault].ready then
        MaxDps:GlowCooldown(classtable.CoordinatedAssault, cooldown[classtable.CoordinatedAssault].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FuryoftheEagle, 'FuryoftheEagle')) and (buff[classtable.TipoftheSpearBuff].count >0) and cooldown[classtable.FuryoftheEagle].ready then
        if not setSpell then setSpell = classtable.FuryoftheEagle end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and (buff[classtable.TipoftheSpearBuff].count <1 and cooldown[classtable.FlankingStrike].remains <gcd) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and (Focus + FocusRegen <FocusMax and ( not buff[classtable.RelentlessPrimalFerocityBuff].up or ( buff[classtable.RelentlessPrimalFerocityBuff].up and ( buff[classtable.TipoftheSpearBuff].count <2 or Focus <30 ) ) )) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.MongooseBite, 'MongooseBite')) and (buff[classtable.MongooseFuryBuff].remains <gcd and buff[classtable.MongooseFuryBuff].count >0) and cooldown[classtable.MongooseBite].ready then
        if not setSpell then setSpell = classtable.MongooseBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.WildfireBomb, 'WildfireBomb')) and (buff[classtable.TipoftheSpearBuff].count >0 and buff[classtable.LunarStormCooldownBuff].remains >FocusTimeToMax and ( (targets <2) or (targets >1) and math.huge >15 )) and cooldown[classtable.WildfireBomb].ready then
        if not setSpell then setSpell = classtable.WildfireBomb end
    end
    if (MaxDps:CheckSpellUsable(classtable.MongooseBite, 'MongooseBite')) and (buff[classtable.MongooseFuryBuff].up) and cooldown[classtable.MongooseBite].ready then
        if not setSpell then setSpell = classtable.MongooseBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.RaptorBite, 'RaptorBite')) and (not talents[classtable.ContagiousReagents]) and cooldown[classtable.RaptorBite].ready then
        if not setSpell then setSpell = classtable.RaptorBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.RaptorBite, 'RaptorBite')) and cooldown[classtable.RaptorBite].ready then
        if not setSpell then setSpell = classtable.RaptorBite end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.HuntersMark, false)
    MaxDps:GlowCooldown(classtable.Muzzle, false)
    MaxDps:GlowCooldown(classtable.TranquilizingShot, false)
    MaxDps:GlowCooldown(classtable.MendPet, false)
    MaxDps:GlowCooldown(classtable.Harpoon, false)
    MaxDps:GlowCooldown(classtable.AspectoftheEagle, false)
    MaxDps:GlowCooldown(classtable.Spearhead, false)
    MaxDps:GlowCooldown(classtable.CoordinatedAssault, false)
    MaxDps:GlowCooldown(classtable.ExplosiveShot, false)
end

function Survival:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Muzzle, 'Muzzle')) and cooldown[classtable.Muzzle].ready then
        MaxDps:GlowCooldown(classtable.Muzzle, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    --if (MaxDps:CheckSpellUsable(classtable.TranquilizingShot, 'TranquilizingShot')) and cooldown[classtable.TranquilizingShot].ready then
    --    MaxDps:GlowCooldown(classtable.TranquilizingShot, cooldown[classtable.TranquilizingShot].ready)
    --end
    if (MaxDps:CheckSpellUsable(classtable.HuntersMark, 'HuntersMark')) and (( false or MaxDps:boss() ) and MaxDps:DebuffCounter(classtable.HuntersMarkDeBuff) == 0 and MaxDps:GetTimeToPct(80) >20) and cooldown[classtable.HuntersMark].ready then
        MaxDps:GlowCooldown(classtable.HuntersMark, cooldown[classtable.HuntersMark].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.MendPet, 'MendPet')) and (pethealthPerc <80) and cooldown[classtable.MendPet].ready then
        MaxDps:GlowCooldown(classtable.MendPet, cooldown[classtable.MendPet].ready)
    end
    Survival:cds()
    if (targets <3 and talents[classtable.HowlofthePackLeader]) then
        Survival:plst()
    end
    if (targets >2 and talents[classtable.HowlofthePackLeader]) then
        Survival:plcleave()
    end
    if (targets <3 and not talents[classtable.HowlofthePackLeader]) then
        Survival:sentst()
    end
    if (targets >2 and not talents[classtable.HowlofthePackLeader]) then
        Survival:sentcleave()
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
end
function Hunter:Survival()
    fd = MaxDps.FrameData
    ttd = (fd.timeToDie and fd.timeToDie) or 500
    timeShift = fd.timeShift
    gcd = fd.gcd
    cooldown = fd.cooldown
    buff = fd.buff
    debuff = fd.debuff
    talents = fd.talents
    targets = MaxDps:SmartAoe()
    Mana = UnitPower('player', ManaPT)
    ManaMax = UnitPowerMax('player', ManaPT)
    ManaDeficit = ManaMax - Mana
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP >0 and targetmaxHP >0 and (targetHP / targetmaxHP) * 100) or 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    Focus = UnitPower('player', FocusPT)
    FocusMax = UnitPowerMax('player', FocusPT)
    FocusDeficit = FocusMax - Focus
    FocusRegen = GetPowerRegenForPowerType(Enum.PowerType.Focus)
    FocusTimeToMax = FocusDeficit / FocusRegen
    FocusPerc = (Focus / FocusMax) * 100
    petHP = UnitHealth('pet')
    petmaxHP = UnitHealthMax('pet')
    pethealthPerc = (petHP > 0 and petmaxHP > 0 and (petHP / petmaxHP) * 100)  or 100
    next_wi_bomb = function()
        local firstSpell = GetSpellInfo(259495)
        local spellinfo = firstSpell and GetSpellInfo(firstSpell.spellID)
        return spellinfo and spellinfo.spellID or 0
    end
    if talents[classtable.MongooseBite] then
        classtable.RaptorBite = classtable.MongooseBite
    else
        classtable.RaptorBite = classtable.RaptorStrike
    end
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.CoordinatedAssaultBuff = 360952
    classtable.StrikeItRichBuff = 1216879
    classtable.HogstriderBuff = 472640
    classtable.RelentlessPrimalFerocityBuff = 459962
    classtable.TipoftheSpearBuff = 260286
    classtable.HowlofthePackLeaderWyvernBuff = 471878
    classtable.HowlofthePackLeaderBoarBuff = 472324
    classtable.HowlofthePackLeaderBearBuff = 472325
    classtable.DeathblowBuff = 378770
    classtable.LunarStormCooldownBuff = 451803
    classtable.MongooseFuryBuff = 259388
    classtable.SerpentStingDeBuff = 259491
    classtable.HowlofthePackLeader = 471876
    classtable.MendPet = 136

    local function debugg()
        talents[classtable.HowlofthePackLeader] = 1
        talents[classtable.CoordinatedAssault] = 1
        talents[classtable.Spearhead] = 1
        talents[classtable.Butchery] = 1
        talents[classtable.Bombardier] = 1
        talents[classtable.SicEm] = 1
        talents[classtable.ContagiousReagents] = 1
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Survival:precombat()

    Survival:callaction()
    if setSpell then return setSpell end
end
