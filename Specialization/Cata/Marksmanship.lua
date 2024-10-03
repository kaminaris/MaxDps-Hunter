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

local Marksmanship = {}



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




local function ClearCDs()
    MaxDps:GlowCooldown(classtable.HuntersMark, false)
end

function Marksmanship:callaction()
    if (MaxDps:CheckSpellUsable(classtable.HuntersMark, 'HuntersMark')) and (ttd >= 21) and cooldown[classtable.HuntersMark].ready then
        MaxDps:GlowCooldown(classtable.HuntersMark, cooldown[classtable.HuntersMark].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.TrueshotAura, 'TrueshotAura')) and cooldown[classtable.TrueshotAura].ready then
        if not setSpell then setSpell = classtable.TrueshotAura end
    end
    if (MaxDps:CheckSpellUsable(classtable.AspectoftheHawk, 'AspectoftheHawk')) and cooldown[classtable.AspectoftheHawk].ready then
        if not setSpell then setSpell = classtable.AspectoftheHawk end
    end
    if (MaxDps:CheckSpellUsable(classtable.AspectoftheFox, 'AspectoftheFox')) and cooldown[classtable.AspectoftheFox].ready then
        if not setSpell then setSpell = classtable.AspectoftheFox end
    end
    if (MaxDps:CheckSpellUsable(classtable.AutoShot, 'AutoShot')) and cooldown[classtable.AutoShot].ready then
        if not setSpell then setSpell = classtable.AutoShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveTrap, 'ExplosiveTrap')) and (target.adds >0) and cooldown[classtable.ExplosiveTrap].ready then
        if not setSpell then setSpell = classtable.ExplosiveTrap end
    end
    if (MaxDps:CheckSpellUsable(classtable.MultiShot, 'MultiShot')) and (target.adds >5) and cooldown[classtable.MultiShot].ready then
        if not setSpell then setSpell = classtable.MultiShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and (target.adds >5) and cooldown[classtable.SteadyShot].ready then
        if not setSpell then setSpell = classtable.SteadyShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.SerpentSting, 'SerpentSting')) and (not debuff[classtable.SerpentStingDeBuff].up and targetHP <= 90) and cooldown[classtable.SerpentSting].ready then
        if not setSpell then setSpell = classtable.SerpentSting end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChimeraShot, 'ChimeraShot')) and (targetHP <= 90) and cooldown[classtable.ChimeraShot].ready then
        if not setSpell then setSpell = classtable.ChimeraShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.RapidFire, 'RapidFire')) and (not MaxDps:Bloodlust() or ttd <= 30) and cooldown[classtable.RapidFire].ready then
        if not setSpell then setSpell = classtable.RapidFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Readiness, 'Readiness')) and cooldown[classtable.Readiness].ready then
        if not setSpell then setSpell = classtable.Readiness end
    end
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and (buff[classtable.PreImprovedSteadyShotBuff].up and buff[classtable.ImprovedSteadyShotBuff].remains <3) and cooldown[classtable.SteadyShot].ready then
        if not setSpell then setSpell = classtable.SteadyShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.AimedShot, 'AimedShot')) and (buff[classtable.MasterMarksmanFireBuff].up) and cooldown[classtable.AimedShot].ready then
        if not setSpell then setSpell = classtable.AimedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneShot, 'ArcaneShot')) and (( Focus >= 66 or cooldown[classtable.ChimeraShot].remains >= 4 ) and ( targetHP <90 and not buff[classtable.RapidFireBuff].up and not MaxDps:Bloodlust() and not buff[classtable.BerserkingBuff].up and not buff[classtable.Tier134pcBuff].up and cooldown[classtable.BuffTier134pc].remains <= 0 )) and cooldown[classtable.ArcaneShot].ready then
        if not setSpell then setSpell = classtable.ArcaneShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.AimedShot, 'AimedShot')) and (( cooldown[classtable.ChimeraShot].remains >5 or Focus >= 80 ) and ( MaxDps:Bloodlust() or buff[classtable.Tier134pcBuff].up or cooldown[classtable.BuffTier134pc].remains >0 ) or buff[classtable.RapidFireBuff].up or targetHP >90) and cooldown[classtable.AimedShot].ready then
        if not setSpell then setSpell = classtable.AimedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and cooldown[classtable.SteadyShot].ready then
        if not setSpell then setSpell = classtable.SteadyShot end
    end
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
    classtable.DeathblowBuff = 378770
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.bloodlust = 0
    classtable.RapidFireBuff = 0
    classtable.SerpentStingDeBuff = 0
    classtable.PreImprovedSteadyShotBuff = 0
    classtable.ImprovedSteadyShotBuff = 0
    classtable.MasterMarksmanFireBuff = 0
    classtable.BerserkingBuff = 0
    classtable.Tier134pcBuff = 0
    setSpell = nil
    ClearCDs()

    Marksmanship:callaction()
    if setSpell then return setSpell end
end
