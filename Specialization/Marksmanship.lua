local _, addonTable = ...
local Hunter = addonTable.Hunter
local MaxDps = _G.MaxDps
if not MaxDps then return end
local LibStub = LibStub
local setSpell

local ceil = ceil
local floor = floor
local fmod = fmod
local format = format
local max = max
local min = min
local pairs = pairs
local select = select
local strsplit = strsplit
local GetTime = GetTime

local UnitAffectingCombat = UnitAffectingCombat
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitName = UnitName
local UnitSpellHaste = UnitSpellHaste
local UnitThreatSituation = UnitThreatSituation
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
local GetSpellCastCount = C_Spell.GetSpellCastCount
local GetUnitSpeed = GetUnitSpeed
local GetCritChance = GetCritChance
local GetInventoryItemLink = GetInventoryItemLink
local GetItemInfo = C_Item.GetItemInfo
local GetItemSpell = C_Item.GetItemSpell
local GetNamePlates = C_NamePlate.GetNamePlates and C_NamePlate.GetNamePlates or GetNamePlates
local GetPowerRegenForPowerType = GetPowerRegenForPowerType
local GetSpellName = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName or GetSpellInfo
local GetTotemInfo = GetTotemInfo
local IsStealthed = IsStealthed
local IsCurrentSpell = C_Spell and C_Spell.IsCurrentSpell
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

local ManaPT = Enum.PowerType.Mana
local RagePT = Enum.PowerType.Rage
local FocusPT = Enum.PowerType.Focus
local EnergyPT = Enum.PowerType.Energy
local ComboPointsPT = Enum.PowerType.ComboPoints
local RunesPT = Enum.PowerType.Runes
local RunicPowerPT = Enum.PowerType.RunicPower
local SoulShardsPT = Enum.PowerType.SoulShards
local DemonicFuryPT = Enum.PowerType.DemonicFury
local BurningEmbersPT = Enum.PowerType.BurningEmbers
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
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local Focus
local FocusMax
local FocusDeficit
local FocusPerc
local FocusRegen
local FocusRegenCombined
local FocusTimeToMax
local petHP
local petmaxHP
local pethealthPerc

local Marksmanship = {}

local trinket_1_stronger = false
local trinket_2_stronger = false
local trueshot_ready = false
local buff_sync_ready = false
local buff_sync_remains = false
local buff_sync_active = false
local damage_sync_active = false
local damage_sync_remains = false


local function SteadyFocusTrack()
    if MaxDps.spellHistory and MaxDps.spellHistory[1] and MaxDps.spellHistory[2] then
        --if MaxDps.spellHistory[1] == classtable.SteadyShot and MaxDps.spellHistory[2] ~= classtable.SteadyShot then
        --    return true
        if MaxDps.spellHistory[1] == classtable.SteadyShot and MaxDps.spellHistory[2] == classtable.SteadyShot then
            return false
        else
            return true
        end
    end
    return true
end


function Marksmanship:precombat()
    trinket_1_stronger = not MaxDps:HasOnUseEffect('14') or MaxDps:HasOnUseEffect('13') and (not MaxDps:HasOnUseEffect('14') or not MaxDps:CheckTrinketNames('MirrorofFracturedTomorrows') and (MaxDps:CheckTrinketNames('MirrorofFracturedTomorrows') or MaxDps:CheckTrinketCooldownDuration('14') <MaxDps:CheckTrinketCooldownDuration('13') or MaxDps:CheckTrinketCastTime('14') <MaxDps:CheckTrinketCastTime('13') or MaxDps:CheckTrinketCastTime('14') == MaxDps:CheckTrinketCastTime('13') and MaxDps:CheckTrinketCooldownDuration('14') == MaxDps:CheckTrinketCooldownDuration('13'))) or not MaxDps:HasOnUseEffect('13') and (not MaxDps:HasOnUseEffect('14') and (MaxDps:CheckTrinketCooldownDuration('14') <MaxDps:CheckTrinketCooldownDuration('13') or MaxDps:CheckTrinketCastTime('14') <MaxDps:CheckTrinketCastTime('13') or MaxDps:CheckTrinketCastTime('14') == MaxDps:CheckTrinketCastTime('13') and MaxDps:CheckTrinketCooldownDuration('14') == MaxDps:CheckTrinketCooldownDuration('13')))
    trinket_2_stronger = not trinket_1_stronger
    if (MaxDps:CheckSpellUsable(classtable.HuntersMark, 'HuntersMark')) and ((false or MaxDps:boss()) and MaxDps:DebuffCounter(classtable.HuntersMarkDeBuff) == 0 and MaxDps:GetTimeToPct(80) >20) and cooldown[classtable.HuntersMark].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.HuntersMark, cooldown[classtable.HuntersMark].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.AimedShot, 'AimedShot')) and (targets <3 or talents[classtable.BlackArrow] and talents[classtable.Headshot]) and cooldown[classtable.AimedShot].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.AimedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and cooldown[classtable.SteadyShot].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.SteadyShot end
    end
end
function Marksmanship:cds()
end
function Marksmanship:cleave()
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and (talents[classtable.PrecisionDetonation] and (MaxDps.spellHistory[1] == classtable.AimedShot) and (not buff[classtable.TrueshotBuff].up or not talents[classtable.WindrunnerQuiver])) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and (talents[classtable.BlackArrow] and buff[classtable.PreciseShotsBuff].up and not buff[classtable.MovingTargetBuff].up and trueshot_ready) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.Volley, 'Volley') and talents[classtable.Volley]) and ((talents[classtable.DoubleTap] and not buff[classtable.DoubleTapBuff].up or not talents[classtable.AspectoftheHydra]) and (not buff[classtable.PreciseShotsBuff].up or buff[classtable.MovingTargetBuff].up)) and cooldown[classtable.Volley].ready then
        MaxDps:GlowCooldown(classtable.Volley, cooldown[classtable.Volley].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.RapidFire, 'RapidFire')) and (talents[classtable.Bulletstorm] and not buff[classtable.BulletstormBuff].up and (not talents[classtable.DoubleTap] or buff[classtable.DoubleTapBuff].up or not talents[classtable.AspectoftheHydra] and buff[classtable.TrickShotsBuff].remains >timeShift) and (not buff[classtable.PreciseShotsBuff].up or buff[classtable.MovingTargetBuff].up or not talents[classtable.Volley])) and cooldown[classtable.RapidFire].ready then
        if not setSpell then setSpell = classtable.RapidFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Volley, 'Volley') and talents[classtable.Volley]) and (not talents[classtable.DoubleTap] and (not buff[classtable.PreciseShotsBuff].up or buff[classtable.MovingTargetBuff].up)) and cooldown[classtable.Volley].ready then
        MaxDps:GlowCooldown(classtable.Volley, cooldown[classtable.Volley].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Trueshot, 'Trueshot')) and (trueshot_ready and (not buff[classtable.DoubleTapBuff].up or not talents[classtable.Volley]) and ((MaxDps.ActiveHeroTree == 'darkranger') or buff[classtable.LunarStormCooldownBuff].up or not talents[classtable.DoubleTap] or not talents[classtable.Volley]) and (not buff[classtable.PreciseShotsBuff].up or buff[classtable.MovingTargetBuff].up or not talents[classtable.Volley])) and cooldown[classtable.Trueshot].ready then
        MaxDps:GlowCooldown(classtable.Trueshot, cooldown[classtable.Trueshot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.RapidFire, 'RapidFire')) and (talents[classtable.LunarStorm] and not buff[classtable.LunarStormCooldownBuff].up and (not buff[classtable.PreciseShotsBuff].up or buff[classtable.MovingTargetBuff].up or not cooldown[classtable.Volley].ready and not cooldown[classtable.Trueshot].ready or not talents[classtable.Volley])) and cooldown[classtable.RapidFire].ready then
        if not setSpell then setSpell = classtable.RapidFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and (not talents[classtable.BlackArrow] and (talents[classtable.Headshot] and buff[classtable.PreciseShotsBuff].up and (not debuff[classtable.SpottersMarkDeBuff].up or not buff[classtable.MovingTargetBuff].up) or not talents[classtable.Headshot] and buff[classtable.RazorFragmentsBuff].up)) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and (talents[classtable.BlackArrow] and (talents[classtable.Headshot] and buff[classtable.PreciseShotsBuff].up and (not debuff[classtable.SpottersMarkDeBuff].up or not buff[classtable.MovingTargetBuff].up) or not talents[classtable.Headshot] and buff[classtable.RazorFragmentsBuff].up)) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.MultiShot, 'MultiShot')) and (buff[classtable.PreciseShotsBuff].up and (not debuff[classtable.SpottersMarkDeBuff].up or not buff[classtable.MovingTargetBuff].up) and not talents[classtable.AspectoftheHydra] and (talents[classtable.SymphonicArsenal] or talents[classtable.SmallGameHunter])) and cooldown[classtable.MultiShot].ready then
        if not setSpell then setSpell = classtable.MultiShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneShot, 'ArcaneShot')) and (buff[classtable.PreciseShotsBuff].up and (not debuff[classtable.SpottersMarkDeBuff].up or not buff[classtable.MovingTargetBuff].up)) and cooldown[classtable.ArcaneShot].ready then
        if not setSpell then setSpell = classtable.ArcaneShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.AimedShot, 'AimedShot')) and ((not buff[classtable.PreciseShotsBuff].up or debuff[classtable.SpottersMarkDeBuff].up and buff[classtable.MovingTargetBuff].up) and FocusTimeToMax <2+( classtable and classtable.AimedShot and GetSpellInfo(classtable.AimedShot).castTime /1000 or 0) and (not talents[classtable.Bulletstorm] or buff[classtable.BulletstormBuff].up) and talents[classtable.WindrunnerQuiver]) and cooldown[classtable.AimedShot].ready then
        if not setSpell then setSpell = classtable.AimedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.RapidFire, 'RapidFire')) and (not talents[classtable.Bulletstorm] or buff[classtable.BulletstormBuff].count <= 10 or talents[classtable.AspectoftheHydra]) and cooldown[classtable.RapidFire].ready then
        if not setSpell then setSpell = classtable.RapidFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.AimedShot, 'AimedShot')) and (not buff[classtable.PreciseShotsBuff].up or debuff[classtable.SpottersMarkDeBuff].up and buff[classtable.MovingTargetBuff].up) and cooldown[classtable.AimedShot].ready then
        if not setSpell then setSpell = classtable.AimedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.RapidFire, 'RapidFire')) and cooldown[classtable.RapidFire].ready then
        if not setSpell then setSpell = classtable.RapidFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and (talents[classtable.PrecisionDetonation] or not buff[classtable.TrueshotBuff].up) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and (talents[classtable.BlackArrow] and not talents[classtable.Headshot]) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and cooldown[classtable.SteadyShot].ready then
        if not setSpell then setSpell = classtable.SteadyShot end
    end
end
function Marksmanship:st()
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and (talents[classtable.PrecisionDetonation] and (MaxDps.spellHistory[1] == classtable.AimedShot) and not buff[classtable.TrueshotBuff].up) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Volley, 'Volley') and talents[classtable.Volley]) and (not buff[classtable.DoubleTapBuff].up) and cooldown[classtable.Volley].ready then
        MaxDps:GlowCooldown(classtable.Volley, cooldown[classtable.Volley].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Trueshot, 'Trueshot')) and (trueshot_ready and not buff[classtable.DoubleTapBuff].up) and cooldown[classtable.Trueshot].ready then
        MaxDps:GlowCooldown(classtable.Trueshot, cooldown[classtable.Trueshot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and (talents[classtable.BlackArrow] and Focus + FocusRegen<FocusMax and (MaxDps.spellHistory[1] == classtable.AimedShot) and not buff[classtable.DeathblowBuff].up and not buff[classtable.TrueshotBuff].up and not cooldown[classtable.Trueshot].ready) and cooldown[classtable.SteadyShot].ready then
        if not setSpell then setSpell = classtable.SteadyShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.RapidFire, 'RapidFire')) and (talents[classtable.LunarStorm] and not buff[classtable.LunarStormCooldownBuff].up) and cooldown[classtable.RapidFire].ready then
        if not setSpell then setSpell = classtable.RapidFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and (not talents[classtable.BlackArrow] and (talents[classtable.Headshot] and buff[classtable.PreciseShotsBuff].up and (not debuff[classtable.SpottersMarkDeBuff].up or not buff[classtable.MovingTargetBuff].up) or not talents[classtable.Headshot] and buff[classtable.RazorFragmentsBuff].up)) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and (talents[classtable.BlackArrow] and (not talents[classtable.Headshot] or talents[classtable.Headshot] and buff[classtable.PreciseShotsBuff].up and (not debuff[classtable.SpottersMarkDeBuff].up or not buff[classtable.MovingTargetBuff].up))) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneShot, 'ArcaneShot')) and (buff[classtable.PreciseShotsBuff].up and (not debuff[classtable.SpottersMarkDeBuff].up or not buff[classtable.MovingTargetBuff].up)) and cooldown[classtable.ArcaneShot].ready then
        if not setSpell then setSpell = classtable.ArcaneShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.AimedShot, 'AimedShot')) and ((not buff[classtable.PreciseShotsBuff].up or debuff[classtable.SpottersMarkDeBuff].up and buff[classtable.MovingTargetBuff].up) and FocusTimeToMax <2+( classtable and classtable.AimedShot and GetSpellInfo(classtable.AimedShot).castTime /1000 or 0) and (not talents[classtable.Bulletstorm] or buff[classtable.BulletstormBuff].up) and talents[classtable.WindrunnerQuiver]) and cooldown[classtable.AimedShot].ready then
        if not setSpell then setSpell = classtable.AimedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.RapidFire, 'RapidFire')) and cooldown[classtable.RapidFire].ready then
        if not setSpell then setSpell = classtable.RapidFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.AimedShot, 'AimedShot')) and (not buff[classtable.PreciseShotsBuff].up or debuff[classtable.SpottersMarkDeBuff].up and buff[classtable.MovingTargetBuff].up) and cooldown[classtable.AimedShot].ready then
        if not setSpell then setSpell = classtable.AimedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and (talents[classtable.PrecisionDetonation] or not buff[classtable.TrueshotBuff].up) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and cooldown[classtable.SteadyShot].ready then
        if not setSpell then setSpell = classtable.SteadyShot end
    end
end
function Marksmanship:trickshots()
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and (talents[classtable.PrecisionDetonation] and (MaxDps.spellHistory[1] == classtable.AimedShot) and not buff[classtable.TrueshotBuff].up and (not talents[classtable.ShrapnelShot] or not buff[classtable.LockandLoadBuff].up)) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Volley, 'Volley') and talents[classtable.Volley]) and (not buff[classtable.DoubleTapBuff].up and (not talents[classtable.ShrapnelShot] or not buff[classtable.LockandLoadBuff].up)) and cooldown[classtable.Volley].ready then
        MaxDps:GlowCooldown(classtable.Volley, cooldown[classtable.Volley].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.RapidFire, 'RapidFire')) and (talents[classtable.Bulletstorm] and not buff[classtable.BulletstormBuff].up and buff[classtable.TrickShotsBuff].remains >timeShift) and cooldown[classtable.RapidFire].ready then
        if not setSpell then setSpell = classtable.RapidFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.RapidFire, 'RapidFire')) and ((MaxDps.ActiveHeroTree == 'sentinel') and not buff[classtable.LunarStormCooldownBuff].up and buff[classtable.TrickShotsBuff].remains >timeShift) and cooldown[classtable.RapidFire].ready then
        if not setSpell then setSpell = classtable.RapidFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and (talents[classtable.BlackArrow] and Focus + FocusRegen<FocusMax and (MaxDps.spellHistory[1] == classtable.AimedShot) and not buff[classtable.DeathblowBuff].up and not buff[classtable.TrueshotBuff].up and not cooldown[classtable.Trueshot].ready) and cooldown[classtable.SteadyShot].ready then
        if not setSpell then setSpell = classtable.SteadyShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and (talents[classtable.BlackArrow] and (not talents[classtable.Headshot] or buff[classtable.PreciseShotsBuff].up or not buff[classtable.TrickShotsBuff].up)) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.MultiShot, 'MultiShot')) and (buff[classtable.PreciseShotsBuff].up and not buff[classtable.MovingTargetBuff].up or not buff[classtable.TrickShotsBuff].up) and cooldown[classtable.MultiShot].ready then
        if not setSpell then setSpell = classtable.MultiShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.Trueshot, 'Trueshot')) and (trueshot_ready and not buff[classtable.DoubleTapBuff].up) and cooldown[classtable.Trueshot].ready then
        MaxDps:GlowCooldown(classtable.Trueshot, cooldown[classtable.Trueshot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Volley, 'Volley') and talents[classtable.Volley]) and (not buff[classtable.DoubleTapBuff].up and (not talents[classtable.Salvo] or not talents[classtable.PrecisionDetonation] or (not buff[classtable.PreciseShotsBuff].up or debuff[classtable.SpottersMarkDeBuff].up and buff[classtable.MovingTargetBuff].up))) and cooldown[classtable.Volley].ready then
        MaxDps:GlowCooldown(classtable.Volley, cooldown[classtable.Volley].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.AimedShot, 'AimedShot')) and ((not buff[classtable.PreciseShotsBuff].up or debuff[classtable.SpottersMarkDeBuff].up and buff[classtable.MovingTargetBuff].up) and buff[classtable.TrickShotsBuff].up and buff[classtable.BulletstormBuff].up and FocusTimeToMax <gcd) and cooldown[classtable.AimedShot].ready then
        if not setSpell then setSpell = classtable.AimedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.RapidFire, 'RapidFire')) and (buff[classtable.TrickShotsBuff].remains >timeShift and (not talents[classtable.BlackArrow] or not buff[classtable.DeathblowBuff].up) and (not talents[classtable.NoScope] or not debuff[classtable.SpottersMarkDeBuff].up) and (talents[classtable.NoScope] or not buff[classtable.BulletstormBuff].up)) and cooldown[classtable.RapidFire].ready then
        if not setSpell then setSpell = classtable.RapidFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and (talents[classtable.PrecisionDetonation] and talents[classtable.ShrapnelShot] and not buff[classtable.LockandLoadBuff].up and (not buff[classtable.PreciseShotsBuff].up or debuff[classtable.SpottersMarkDeBuff].up and buff[classtable.MovingTargetBuff].up)) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.AimedShot, 'AimedShot')) and ((not buff[classtable.PreciseShotsBuff].up or debuff[classtable.SpottersMarkDeBuff].up and buff[classtable.MovingTargetBuff].up) and buff[classtable.TrickShotsBuff].up) and cooldown[classtable.AimedShot].ready then
        if not setSpell then setSpell = classtable.AimedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and (not talents[classtable.ShrapnelShot]) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and (Focus + FocusRegen<FocusMax) and cooldown[classtable.SteadyShot].ready then
        if not setSpell then setSpell = classtable.SteadyShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.MultiShot, 'MultiShot')) and cooldown[classtable.MultiShot].ready then
        if not setSpell then setSpell = classtable.MultiShot end
    end
end
function Marksmanship:trinkets()
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.HuntersMark, false)
    MaxDps:GlowCooldown(classtable.CounterShot, false)
    MaxDps:GlowCooldown(classtable.TranquilizingShot, false)
    MaxDps:GlowCooldown(classtable.MendPet, false)
    MaxDps:GlowCooldown(classtable.ExplosiveShot, false)
    MaxDps:GlowCooldown(classtable.Volley, false)
    MaxDps:GlowCooldown(classtable.Trueshot, false)
    MaxDps:GlowCooldown(classtable.trinket1, false)
    MaxDps:GlowCooldown(classtable.trinket2, false)
end

function Marksmanship:callaction()
    if (MaxDps:CheckSpellUsable(classtable.CounterShot, 'CounterShot')) and cooldown[classtable.CounterShot].ready then
        MaxDps:GlowCooldown(classtable.CounterShot, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.TranquilizingShot, 'TranquilizingShot')) and cooldown[classtable.TranquilizingShot].ready then
        MaxDps:GlowCooldown(classtable.TranquilizingShot, cooldown[classtable.TranquilizingShot].ready)
    end
    trueshot_ready = cooldown[classtable.Trueshot].ready and ((not (targets >1) or 1 == 1) and (not talents[classtable.Bullseye] or ttd >cooldown[classtable.Trueshot].duration+buff[classtable.TrueshotBuff].duration%2 or buff[classtable.BullseyeBuff].count == buff[classtable.BullseyeBuff].maxStacks) and (not MaxDps:HasOnUseEffect('13') or MaxDps:CheckTrinketCooldown('13') >30 or MaxDps:CheckTrinketReady('13')) and (not MaxDps:HasOnUseEffect('14') or MaxDps:CheckTrinketCooldown('14') >30 or MaxDps:CheckTrinketReady('14')) or (targets >1) and (not (targets >1) and ((targets>1 and MaxDps:MaxAddDuration() or 0) + math.huge<25 or math.huge >60) or (targets >1) and targets >10) or MaxDps:boss() and ttd <25)
    if (MaxDps:CheckSpellUsable(classtable.MendPet, 'MendPet')) and (pethealthPerc <80) and cooldown[classtable.MendPet].ready then
        MaxDps:GlowCooldown(classtable.MendPet, cooldown[classtable.MendPet].ready)
    end
    Marksmanship:cds()
    Marksmanship:trinkets()
    if (MaxDps:CheckSpellUsable(classtable.HuntersMark, 'HuntersMark')) and ((false or MaxDps:boss()) and MaxDps:DebuffCounter(classtable.HuntersMarkDeBuff) == 0 and MaxDps:GetTimeToPct(80) >20) and cooldown[classtable.HuntersMark].ready then
        MaxDps:GlowCooldown(classtable.HuntersMark, cooldown[classtable.HuntersMark].ready)
    end
    if (targets >2 and talents[classtable.TrickShots]) then
        Marksmanship:trickshots()
    end
    if (targets >1) then
        Marksmanship:cleave()
    end
    Marksmanship:st()
end
function Hunter:Marksmanship()
    fd = MaxDps.FrameData
    ttd = (fd.timeToDie and fd.timeToDie) or 500
    timeShift = fd.timeShift
    gcd = fd.gcd
    cooldown = fd.cooldown
    buff = fd.buff
    debuff = fd.debuff
    talents = fd.talents
    targets = MaxDps:SmartAoe()
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP >0 and targetmaxHP >0 and (targetHP / targetmaxHP) * 100) or 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    local trinket1ID = GetInventoryItemID('player', 13)
    local trinket2ID = GetInventoryItemID('player', 14)
    local MHID = GetInventoryItemID('player', 16)
    classtable.trinket1 = (trinket1ID and select(2,GetItemSpell(trinket1ID)) ) or 0
    classtable.trinket2 = (trinket2ID and select(2,GetItemSpell(trinket2ID)) ) or 0
    classtable.main_hand = (MHID and select(2,GetItemSpell(MHID)) ) or 0
    Focus = UnitPower('player', FocusPT)
    FocusMax = UnitPowerMax('player', FocusPT)
    FocusDeficit = FocusMax - Focus
    FocusPerc = (Focus / FocusMax) * 100
    FocusRegen = GetPowerRegenForPowerType(FocusPT)
    FocusTimeToMax = FocusDeficit / FocusRegen
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    petHP = UnitHealth('pet')
    petmaxHP = UnitHealthMax('pet')
    pethealthPerc = (petHP > 0 and petmaxHP > 0 and (petHP / petmaxHP) * 100)  or 100
    classtable.DeathblowBuff = 378770
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.TrueshotBuff = 288613
    classtable.BullseyeBuff = 204090
    classtable.BloodlustBuff = 2825
    classtable.PreciseShotsBuff = 260242
    classtable.MovingTargetBuff = 474293
    classtable.DoubleTapBuff = 260402
    classtable.BulletstormBuff = 389020
    classtable.TrickShotsBuff = 257622
    classtable.LunarStormCooldownBuff = 451803
    classtable.RazorFragmentsBuff = 388998
    classtable.DeathblowBuff = 378770
    classtable.LockandLoadBuff = 194594
    classtable.SpottersMarkDeBuff = 466872
    classtable.MendPet = 136
    classtable.KillShot = talents[classtable.BlackArrow] and 466930 or classtable.KillShot

    local function debugg()
        talents[classtable.UnbreakableBond] = 1
        talents[classtable.BlackArrow] = 1
        talents[classtable.Headshot] = 1
        talents[classtable.TrickShots] = 1
        talents[classtable.PrecisionDetonation] = 1
        talents[classtable.WindrunnerQuiver] = 1
        talents[classtable.DoubleTap] = 1
        talents[classtable.AspectoftheHydra] = 1
        talents[classtable.Bulletstorm] = 1
        talents[classtable.Volley] = 1
        talents[classtable.LunarStorm] = 1
        talents[classtable.SymphonicArsenal] = 1
        talents[classtable.SmallGameHunter] = 1
        talents[classtable.ShrapnelShot] = 1
        talents[classtable.Salvo] = 1
        talents[classtable.NoScope] = 1
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Marksmanship:precombat()

    Marksmanship:callaction()
    if setSpell then return setSpell end
end
