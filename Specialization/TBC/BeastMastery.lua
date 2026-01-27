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
local Mana
local ManaMax
local ManaDeficit
local petHP
local petmaxHP
local pethealthPerc
local speed

local BeastMastery = {}


function BeastMastery:precombat()

end

function BeastMastery:aoe()
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'Kill Command')) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.MultiShot, 'Multi-Shot')) and cooldown[classtable.MultiShot].ready then
        if not setSpell then setSpell = classtable.MultiShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveTrap, 'Explosive Trap')) and targets >= 7 and cooldown[classtable.ExplosiveTrap].ready then
        if not setSpell then setSpell = classtable.ExplosiveTrap end
    end
    if (MaxDps:CheckSpellUsable(classtable.Volley, 'Volley')) and targets >= 10 and cooldown[classtable.Volley].ready then
        if not setSpell then setSpell = classtable.Volley end
    end
end
function BeastMastery:single()
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'Kill Command')) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.AspectoftheHawk, 'Aspect of the Hawk')) and (not MaxDps:FindBuffAuraData(classtable.AspectoftheHawk).up) and cooldown[classtable.AspectoftheHawk].ready then
        if not setSpell then setSpell = classtable.AspectoftheHawk end
    end
    if (MaxDps:CheckSpellUsable(classtable.HuntersMark, 'Hunters Mark')) and (not MaxDps:FindADAuraData(classtable.HuntersMark).up) and cooldown[classtable.HuntersMark].ready then
        if not setSpell then setSpell = classtable.HuntersMark end
    end
    if (MaxDps:CheckSpellUsable(classtable.BestialWrath, 'Bestial Wrath')) and cooldown[classtable.BestialWrath].ready then
        if not setSpell then setSpell = classtable.BestialWrath end
        MaxDps:GlowCooldown(classtable.BestialWrath, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.RapidFire, 'Rapid Fire')) and cooldown[classtable.RapidFire].ready then
        if not setSpell then setSpell = classtable.RapidFire end
        MaxDps:GlowCooldown(classtable.RapidFire, true)
    end
    if not speed or (speed and speed < 1.5) then
        if (MaxDps:CheckSpellUsable(classtable.MultiShot, 'Multi-Shot')) and (MaxDps.spellHistory[1] ~= classtable.MultiShot) and cooldown[classtable.MultiShot].ready then
            if not setSpell then setSpell = classtable.MultiShot end
        end
        if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'Steady Shot')) and (MaxDps.spellHistory[1] ~= classtable.SteadyShot) and cooldown[classtable.SteadyShot].ready then
            if not setSpell then setSpell = classtable.SteadyShot end
        end
    else
        if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'Steady Shot')) and not (MaxDps.spellHistory[1] == classtable.SteadyShot) and cooldown[classtable.SteadyShot].ready then
            if not setSpell then setSpell = classtable.SteadyShot end
        end
        if (MaxDps:CheckSpellUsable(classtable.MultiShot, 'Multi-Shot')) and not (MaxDps.spellHistory[1] == classtable.MultiShot) and cooldown[classtable.MultiShot].ready then
            if not setSpell then setSpell = classtable.MultiShot end
        end
        if (MaxDps:CheckSpellUsable(classtable.ArcaneShot, 'Arcane Shot')) and cooldown[classtable.ArcaneShot].ready then
            if not setSpell then setSpell = classtable.ArcaneShot end
        end
        if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'Steady Shot')) and cooldown[classtable.SteadyShot].ready then
            if not setSpell then setSpell = classtable.SteadyShot end
        end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.BestialWrath, false)
    MaxDps:GlowCooldown(classtable.RapidFire, false)
end

function BeastMastery:callaction()
    if (targets >2) then
        BeastMastery:aoe()
    end
    BeastMastery:single()
end
function Hunter:BeastMastery()
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

    speed = UnitRangedDamage("player")

    classtable.KillCommand = 34026
    classtable.AspectoftheHawk = 25296
    classtable.HuntersMark = 14325
    classtable.BestialWrath = 19574
    classtable.RapidFire = 3045
    classtable.MultiShot = 14290
    classtable.SerpentSting = 13555
    classtable.AimedShot = 20904
    classtable.ArcaneShot = 14287
    classtable.Volley = 14295
    classtable.ExplosiveTrap = 409535
    classtable.SteadyShot = 34120

    local function debugg()
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    BeastMastery:callaction()
    if setSpell then return setSpell end
end
