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
local FocusRegen
local FocusTimeToMax
local FocusPerc
local petHP
local petmaxHP
local pethealthPerc

local Marksmanship = {}


function Marksmanship:precombat()
    if (MaxDps:CheckSpellUsable(classtable.HuntersMark, 'HuntersMark')) and (ttd >= 21 and not debuff[classtable.RangedVulnerabilityDeBuff].up) and cooldown[classtable.HuntersMark].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.HuntersMark, cooldown[classtable.HuntersMark].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.TrueshotAura, 'TrueshotAura')) and cooldown[classtable.TrueshotAura].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.TrueshotAura end
    end
    --if (MaxDps:CheckSpellUsable(classtable.TolvirPotion, 'TolvirPotion')) and cooldown[classtable.TolvirPotion].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.TolvirPotion end
    --end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.HuntersMark, false)
    MaxDps:GlowCooldown(classtable.DireBeast, false)
    MaxDps:GlowCooldown(classtable.ExplosiveTrap, false)
    MaxDps:GlowCooldown(classtable.RapidFire, false)
    MaxDps:GlowCooldown(classtable.TrapLauncher, false)
    MaxDps:GlowCooldown(classtable.Stampede, false)
    MaxDps:GlowCooldown(classtable.AMurderofCrows, false)
end

function Marksmanship:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Stampede, 'Stampede')) and cooldown[classtable.Stampede].ready then
        --if not setSpell then setSpell = classtable.Stampede end
        MaxDps:GlowCooldown(classtable.Stampede, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and (targethealthPerc < 20) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.AspectoftheHawk, 'AspectoftheHawk')) and (not buff[classtable.AspectoftheHawkBuff].up) and cooldown[classtable.AspectoftheHawk].ready then
        if not setSpell then setSpell = classtable.AspectoftheHawk end
    end
    --if (MaxDps:CheckSpellUsable(classtable.AspectoftheFox, 'AspectoftheFox')) and cooldown[classtable.AspectoftheFox].ready then
    --    if not setSpell then setSpell = classtable.AspectoftheFox end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.AutoShot, 'AutoShot')) and cooldown[classtable.AutoShot].ready then
    --    if not setSpell then setSpell = classtable.AutoShot end
    --end
    if (MaxDps:CheckSpellUsable(classtable.TrapLauncher, 'TrapLauncher')) and (not buff[classtable.TrapLauncherBuff].up) and cooldown[classtable.TrapLauncher].ready then
        --if not setSpell then setSpell = classtable.TrapLauncher end
        MaxDps:GlowCooldown(classtable.TrapLauncher, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveTrap, 'ExplosiveTrap')) and (targets >1) and cooldown[classtable.ExplosiveTrap].ready then
        --if not setSpell then setSpell = classtable.ExplosiveTrap end
        MaxDps:GlowCooldown(classtable.ExplosiveTrap, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.GlaiveToss, 'GlaiveToss')) and cooldown[classtable.GlaiveToss].ready then
        if not setSpell then setSpell = classtable.GlaiveToss end
    end
    if (MaxDps:CheckSpellUsable(classtable.Powershot, 'Powershot')) and cooldown[classtable.Powershot].ready then
        if not setSpell then setSpell = classtable.Powershot end
    end
    if (MaxDps:CheckSpellUsable(classtable.Barrage, 'Barrage')) and cooldown[classtable.Barrage].ready then
        if not setSpell then setSpell = classtable.Barrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.BlinkStrike, 'BlinkStrike')) and cooldown[classtable.BlinkStrike].ready then
        if not setSpell then setSpell = classtable.BlinkStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.LynxRush, 'LynxRush')) and (not debuff[classtable.LynxRushDeBuff].up) and cooldown[classtable.LynxRush].ready then
        if not setSpell then setSpell = classtable.LynxRush end
    end
    if (MaxDps:CheckSpellUsable(classtable.MultiShot, 'MultiShot')) and (targets >5) and cooldown[classtable.MultiShot].ready then
        if not setSpell then setSpell = classtable.MultiShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and (targets >5) and cooldown[classtable.SteadyShot].ready then
        if not setSpell then setSpell = classtable.SteadyShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.SerpentSting, 'SerpentSting')) and (not debuff[classtable.SerpentStingDeBuff].up) and cooldown[classtable.SerpentSting].ready then
        if not setSpell then setSpell = classtable.SerpentSting end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChimeraShot, 'ChimeraShot')) and cooldown[classtable.ChimeraShot].ready then
        if not setSpell then setSpell = classtable.ChimeraShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.DireBeast, 'DireBeast')) and cooldown[classtable.DireBeast].ready then
        MaxDps:GlowCooldown(classtable.DireBeast, cooldown[classtable.DireBeast].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.RapidFire, 'RapidFire')) and (not buff[classtable.RapidFireBuff].up) and cooldown[classtable.RapidFire].ready then
        --if not setSpell then setSpell = classtable.RapidFire end
        MaxDps:GlowCooldown(classtable.RapidFire, true)
    end
    --if (MaxDps:CheckSpellUsable(classtable.Readiness, 'Readiness')) and cooldown[classtable.Readiness].ready then
    --    if not setSpell then setSpell = classtable.Readiness end
    --end
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and (MaxDps.spellHistory[1] == 56641 and buff[classtable.SteadyFocusBuff].remains <3) and cooldown[classtable.SteadyShot].ready then
        if not setSpell then setSpell = classtable.SteadyShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.AimedShot, 'AimedShot')) and (buff[classtable.MasterMarksmanFireBuff].up) and cooldown[classtable.AimedShot].ready then
        if not setSpell then setSpell = classtable.AimedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.AMurderofCrows, 'AMurderofCrows')) and (not debuff[classtable.AMurderofCrowsDeBuff].up) and cooldown[classtable.AMurderofCrows].ready then
        MaxDps:GlowCooldown(classtable.AMurderofCrows, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneShot, 'ArcaneShot')) and (buff[classtable.ThrilloftheHuntBuff].up) and cooldown[classtable.ArcaneShot].ready then
        if not setSpell then setSpell = classtable.ArcaneShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneShot, 'ArcaneShot')) and (( Focus >= 66 or cooldown[classtable.ChimeraShot].remains >= 4 ) and ( not buff[classtable.RapidFireBuff].up and not MaxDps:Bloodlust(1) and not buff[classtable.BerserkingBuff].up and not buff[classtable.Tier134pcBuff].up and cooldown[classtable.BuffTier134pc].remains <= 0 )) and cooldown[classtable.ArcaneShot].ready then
        if not setSpell then setSpell = classtable.ArcaneShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.AimedShot, 'AimedShot')) and (( cooldown[classtable.ChimeraShot].remains >5 or Focus >= 80 ) and ( MaxDps:Bloodlust(1) or buff[classtable.Tier134pcBuff].up or cooldown[classtable.BuffTier134pc].remains >0 ) or buff[classtable.RapidFireBuff].up or targethealthPerc >90) and cooldown[classtable.AimedShot].ready then
        if not setSpell then setSpell = classtable.AimedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.Fervor, 'Fervor')) and (Focus <= 50) and cooldown[classtable.Fervor].ready then
        if not setSpell then setSpell = classtable.Fervor end
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
    petHP = UnitHealth('pet')
    petmaxHP = UnitHealthMax('pet')
    pethealthPerc = (petHP > 0 and petmaxHP > 0 and (petHP / petmaxHP) * 100)  or 100

    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end

    local function debugg()
    end

    --classtable.AspectoftheFox
    classtable.AspectoftheHawk = talents[109260] and 109260 or 13165
    classtable.ExplosiveTrap = buff[classtable.TrapLauncherBuff].up and 82939 or 13813
    classtable.BlinkStrike = 130392

    classtable.AspectoftheHawkBuff = talents[109260] and 109260 or 13165
    classtable.TrapLauncherBuff = 77769

    classtable.RapidFireBuff = 3045
    --classtable.PreSteadyFocusBuff
    classtable.SteadyFocusBuff = 53220
    classtable.MasterMarksmanFireBuff = 82926
    classtable.ThrilloftheHuntBuff = 34720
    --classtable.BerserkingBuff
    classtable.Tier134pcBuff = 0
    classtable.BuffTier134pc = 0
    classtable.RangedVulnerabilityDeBuff = 1130
    classtable.SerpentStingDeBuff = 118253
    classtable.AMurderofCrowsDeBuff = 131894
    --classtable.LynxRushDeBuff

    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Marksmanship:precombat()

    Marksmanship:callaction()
    if setSpell then return setSpell end
end
