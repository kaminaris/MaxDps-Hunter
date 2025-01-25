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

local time_to_die


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
    if (MaxDps:CheckSpellUsable(classtable.AspectoftheHawk, 'AspectoftheHawk')) and (not buff[classtable.AspectBuff].up and false and false) and cooldown[classtable.AspectoftheHawk].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.AspectoftheHawk end
    end
    if (MaxDps:CheckSpellUsable(classtable.AspectoftheFox, 'AspectoftheFox')) and (not buff[classtable.AspectBuff].up and false and false) and cooldown[classtable.AspectoftheFox].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.AspectoftheFox end
    end
    if (MaxDps:CheckSpellUsable(classtable.AspectoftheCheetah, 'AspectoftheCheetah')) and (not buff[classtable.AspectBuff].up and false and false) and cooldown[classtable.AspectoftheCheetah].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.AspectoftheCheetah end
    end
    if (MaxDps:CheckSpellUsable(classtable.AspectofthePack, 'AspectofthePack')) and (not buff[classtable.AspectBuff].up and false and false) and cooldown[classtable.AspectofthePack].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.AspectofthePack end
    end
    if (MaxDps:CheckSpellUsable(classtable.AspectoftheWild, 'AspectoftheWild')) and (not buff[classtable.AspectBuff].up and false and false) and cooldown[classtable.AspectoftheWild].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.AspectoftheWild end
    end
    if (MaxDps:CheckSpellUsable(classtable.HuntersMark, 'HuntersMark')) and (not debuff[classtable.HuntersMarkDeBuff].up) and cooldown[classtable.HuntersMark].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.HuntersMark end
    end
    if (MaxDps:CheckSpellUsable(classtable.Misdirection, 'Misdirection')) and (false) and cooldown[classtable.Misdirection].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Misdirection end
    end
end
function Marksmanship:init()
    time_to_die = ( debuff[classtable.TrainingDummyDeBuff].up and 300 ) or ttd
end
function Marksmanship:aoe()
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and (( not buff[classtable.ImprovedSteadyShotBuff].up or buff[classtable.ImprovedSteadyShotBuff].remains <1.5 ) and (MaxDps.spellHistory[1] == classtable.SteadyShot)) and cooldown[classtable.SteadyShot].ready then
        if not setSpell then setSpell = classtable.SteadyShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.Misdirection, 'Misdirection')) and (false) and cooldown[classtable.Misdirection].ready then
        if not setSpell then setSpell = classtable.Misdirection end
    end
    if (MaxDps:CheckSpellUsable(classtable.AspectoftheHawk, 'AspectoftheHawk')) and (false and false and not (GetUnitSpeed('player') >0)) and cooldown[classtable.AspectoftheHawk].ready then
        if not setSpell then setSpell = classtable.AspectoftheHawk end
    end
    if (MaxDps:CheckSpellUsable(classtable.RapidFire, 'RapidFire')) and (cooldown[classtable.CalloftheWild].ready and not buff[classtable.RapidFireBuff].up) and cooldown[classtable.RapidFire].ready then
        if not setSpell then setSpell = classtable.RapidFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.CalloftheWild, 'CalloftheWild')) and (cooldown[classtable.RapidFire].ready and not false) and cooldown[classtable.CalloftheWild].ready then
        if not setSpell then setSpell = classtable.CalloftheWild end
    end
    if (MaxDps:CheckSpellUsable(classtable.Readiness, 'Readiness')) and (cooldown[classtable.RapidFire].remains >60) and cooldown[classtable.Readiness].ready then
        if not setSpell then setSpell = classtable.Readiness end
    end
    if (MaxDps:CheckSpellUsable(classtable.TrapLauncher, 'TrapLauncher')) and (cooldown[classtable.ExplosiveTrap].ready and not false) and cooldown[classtable.TrapLauncher].ready then
        if not setSpell then setSpell = classtable.TrapLauncher end
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveTrap, 'ExplosiveTrap')) and cooldown[classtable.ExplosiveTrap].ready then
        if not setSpell then setSpell = classtable.ExplosiveTrap end
    end
    if (MaxDps:CheckSpellUsable(classtable.MultiShot, 'MultiShot')) and cooldown[classtable.MultiShot].ready then
        if not setSpell then setSpell = classtable.MultiShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and (not buff[classtable.ImprovedSteadyShotBuff].up or buff[classtable.ImprovedSteadyShotBuff].remains <1.5) and cooldown[classtable.SteadyShot].ready then
        if not setSpell then setSpell = classtable.SteadyShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.AimedShot, 'AimedShot')) and (buff[classtable.FireBuff].up) and cooldown[classtable.AimedShot].ready then
        if not setSpell then setSpell = classtable.AimedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and (targethealthPerc <20) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and (not (GetUnitSpeed('player') >0) or buff[classtable.AspectoftheFoxBuff].up) and cooldown[classtable.SteadyShot].ready then
        if not setSpell then setSpell = classtable.SteadyShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.AspectoftheFox, 'AspectoftheFox')) and ((GetUnitSpeed('player') >0) and false and false) and cooldown[classtable.AspectoftheFox].ready then
        if not setSpell then setSpell = classtable.AspectoftheFox end
    end
end
function Marksmanship:cleave()
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and (( not buff[classtable.ImprovedSteadyShotBuff].up or buff[classtable.ImprovedSteadyShotBuff].remains <1.5 ) and (MaxDps.spellHistory[1] == classtable.SteadyShot)) and cooldown[classtable.SteadyShot].ready then
        if not setSpell then setSpell = classtable.SteadyShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.Misdirection, 'Misdirection')) and (false) and cooldown[classtable.Misdirection].ready then
        if not setSpell then setSpell = classtable.Misdirection end
    end
    if (MaxDps:CheckSpellUsable(classtable.AspectoftheHawk, 'AspectoftheHawk')) and (false and false and not (GetUnitSpeed('player') >0)) and cooldown[classtable.AspectoftheHawk].ready then
        if not setSpell then setSpell = classtable.AspectoftheHawk end
    end
    if (MaxDps:CheckSpellUsable(classtable.HuntersMark, 'HuntersMark')) and (not debuff[classtable.HuntersMarkDeBuff].up) and cooldown[classtable.HuntersMark].ready then
        if not setSpell then setSpell = classtable.HuntersMark end
    end
    if (MaxDps:CheckSpellUsable(classtable.RapidFire, 'RapidFire')) and (cooldown[classtable.CalloftheWild].ready and not buff[classtable.RapidFireBuff].up) and cooldown[classtable.RapidFire].ready then
        if not setSpell then setSpell = classtable.RapidFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.CalloftheWild, 'CalloftheWild')) and (cooldown[classtable.RapidFire].ready and not false) and cooldown[classtable.CalloftheWild].ready then
        if not setSpell then setSpell = classtable.CalloftheWild end
    end
    if (MaxDps:CheckSpellUsable(classtable.Readiness, 'Readiness')) and (cooldown[classtable.RapidFire].remains >60) and cooldown[classtable.Readiness].ready then
        if not setSpell then setSpell = classtable.Readiness end
    end
    if (MaxDps:CheckSpellUsable(classtable.SerpentSting, 'SerpentSting')) and (not debuff[classtable.SerpentStingDeBuff].up) and cooldown[classtable.SerpentSting].ready then
        if not setSpell then setSpell = classtable.SerpentSting end
    end
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and (not buff[classtable.ImprovedSteadyShotBuff].up or buff[classtable.ImprovedSteadyShotBuff].remains <1.5) and cooldown[classtable.SteadyShot].ready then
        if not setSpell then setSpell = classtable.SteadyShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChimeraShot, 'ChimeraShot')) and cooldown[classtable.ChimeraShot].ready then
        if not setSpell then setSpell = classtable.ChimeraShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.AimedShot, 'AimedShot')) and (buff[classtable.FireBuff].up) and cooldown[classtable.AimedShot].ready then
        if not setSpell then setSpell = classtable.AimedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and (targethealthPerc <20) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.AimedShot, 'AimedShot')) and (targethealthPerc >90) and cooldown[classtable.AimedShot].ready then
        if not setSpell then setSpell = classtable.AimedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneShot, 'ArcaneShot')) and (Focus >75) and cooldown[classtable.ArcaneShot].ready then
        if not setSpell then setSpell = classtable.ArcaneShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and (not (GetUnitSpeed('player') >0) or buff[classtable.AspectoftheFoxBuff].up) and cooldown[classtable.SteadyShot].ready then
        if not setSpell then setSpell = classtable.SteadyShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.AspectoftheFox, 'AspectoftheFox')) and ((GetUnitSpeed('player') >0) and false and false) and cooldown[classtable.AspectoftheFox].ready then
        if not setSpell then setSpell = classtable.AspectoftheFox end
    end
end
function Marksmanship:single()
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and (( not buff[classtable.ImprovedSteadyShotBuff].up or buff[classtable.ImprovedSteadyShotBuff].remains <1.5 ) and (MaxDps.spellHistory[1] == classtable.SteadyShot)) and cooldown[classtable.SteadyShot].ready then
        if not setSpell then setSpell = classtable.SteadyShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.Misdirection, 'Misdirection')) and (false) and cooldown[classtable.Misdirection].ready then
        if not setSpell then setSpell = classtable.Misdirection end
    end
    if (MaxDps:CheckSpellUsable(classtable.AspectoftheHawk, 'AspectoftheHawk')) and (false and false and not (GetUnitSpeed('player') >0)) and cooldown[classtable.AspectoftheHawk].ready then
        if not setSpell then setSpell = classtable.AspectoftheHawk end
    end
    if (MaxDps:CheckSpellUsable(classtable.HuntersMark, 'HuntersMark')) and (not debuff[classtable.HuntersMarkDeBuff].up) and cooldown[classtable.HuntersMark].ready then
        if not setSpell then setSpell = classtable.HuntersMark end
    end
    if (MaxDps:CheckSpellUsable(classtable.RapidFire, 'RapidFire')) and (cooldown[classtable.CalloftheWild].ready and not buff[classtable.RapidFireBuff].up) and cooldown[classtable.RapidFire].ready then
        if not setSpell then setSpell = classtable.RapidFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.CalloftheWild, 'CalloftheWild')) and (cooldown[classtable.RapidFire].ready and not false) and cooldown[classtable.CalloftheWild].ready then
        if not setSpell then setSpell = classtable.CalloftheWild end
    end
    if (MaxDps:CheckSpellUsable(classtable.Readiness, 'Readiness')) and (cooldown[classtable.RapidFire].remains >60) and cooldown[classtable.Readiness].ready then
        if not setSpell then setSpell = classtable.Readiness end
    end
    if (MaxDps:CheckSpellUsable(classtable.SerpentSting, 'SerpentSting')) and (not debuff[classtable.SerpentStingDeBuff].up and not (MaxDps.spellHistory[1] == classtable.SerpentSting)) and cooldown[classtable.SerpentSting].ready then
        if not setSpell then setSpell = classtable.SerpentSting end
    end
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and (not buff[classtable.ImprovedSteadyShotBuff].up or buff[classtable.ImprovedSteadyShotBuff].remains <1.5) and cooldown[classtable.SteadyShot].ready then
        if not setSpell then setSpell = classtable.SteadyShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChimeraShot, 'ChimeraShot')) and cooldown[classtable.ChimeraShot].ready then
        if not setSpell then setSpell = classtable.ChimeraShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.AimedShot, 'AimedShot')) and (buff[classtable.FireBuff].up) and cooldown[classtable.AimedShot].ready then
        if not setSpell then setSpell = classtable.AimedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and (targethealthPerc <20) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.AimedShot, 'AimedShot')) and (targethealthPerc >90) and cooldown[classtable.AimedShot].ready then
        if not setSpell then setSpell = classtable.AimedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneShot, 'ArcaneShot')) and (Focus >75) and cooldown[classtable.ArcaneShot].ready then
        if not setSpell then setSpell = classtable.ArcaneShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and (not (GetUnitSpeed('player') >0) or buff[classtable.AspectoftheFoxBuff].up) and cooldown[classtable.SteadyShot].ready then
        if not setSpell then setSpell = classtable.SteadyShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.AspectoftheFox, 'AspectoftheFox')) and ((GetUnitSpeed('player') >0) and false and false) and cooldown[classtable.AspectoftheFox].ready then
        if not setSpell then setSpell = classtable.AspectoftheFox end
    end
end


local function ClearCDs()
end

function Marksmanship:callaction()
    Marksmanship:init()
    if (targets >2) then
        Marksmanship:aoe()
    end
    if (targets == 2) then
        Marksmanship:cleave()
    end
    Marksmanship:single()
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
    classtable.DeathblowBuff = 378770
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.ImprovedSteadyShotBuff = 53220
    classtable.RapidFireBuff = 3045
    classtable.FireBuff = 3045
    classtable.AspectoftheFoxBuff = 82661
    classtable.HuntersMarkDeBuff = 1130
    classtable.SerpentStingDeBuff = 1978
    classtable.AspectoftheHawk = 13165
    classtable.AspectoftheFox = 82661
    classtable.AspectoftheCheetah = 5118
    classtable.AspectofthePack = 13159
    classtable.AspectoftheWild = 20043
    classtable.HuntersMark = 1130
    classtable.Misdirection = 34477
    classtable.SteadyShot = 56641
    classtable.RapidFire = 3045
    classtable.CalloftheWild = 53434
    classtable.Readiness = 23989
    classtable.TrapLauncher = 77769
    classtable.ExplosiveTrap = 13813
    classtable.MultiShot = 2643
    classtable.AimedShot = 19434
    classtable.KillShot = 53351
    classtable.SerpentSting = 1978
    classtable.ChimeraShot = 53209
    classtable.ArcaneShot = 3044

    local function debugg()
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
