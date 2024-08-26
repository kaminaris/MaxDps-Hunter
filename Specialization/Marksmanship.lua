local _, addonTable = ...
local Hunter = addonTable.Hunter
local MaxDps = _G.MaxDps
if not MaxDps then return end

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

local trinket_one_stronger
local trinket_two_stronger
local trueshot_ready
local sync_ready
local sync_active
local sync_remains

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
end
function Marksmanship:cds()
    if (MaxDps:CheckSpellUsable(classtable.Salvo, 'Salvo')) and (targets >2 or cooldown[classtable.Volley].remains <10) and cooldown[classtable.Salvo].ready then
        MaxDps:GlowCooldown(classtable.Salvo, cooldown[classtable.Salvo].ready)
    end
end
function Marksmanship:st()
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and (talents[classtable.SteadyFocus] and SteadyFocusTrack() and buff[classtable.SteadyFocusBuff].remains <8) and cooldown[classtable.SteadyShot].ready then
        return classtable.SteadyShot
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and (buff[classtable.RazorFragmentsBuff].up) and cooldown[classtable.KillShot].ready then
        return classtable.KillShot
    end
    if (MaxDps:CheckSpellUsable(classtable.BlackArrow, 'BlackArrow')) and cooldown[classtable.BlackArrow].ready then
        return classtable.BlackArrow
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and (targets >1) and cooldown[classtable.ExplosiveShot].ready then
        return classtable.ExplosiveShot
    end
    if (MaxDps:CheckSpellUsable(classtable.Volley, 'Volley')) and cooldown[classtable.Volley].ready then
        return classtable.Volley
    end
    if (MaxDps:CheckSpellUsable(classtable.RapidFire, 'RapidFire')) and (not talents[classtable.LunarStorm] or ( not cooldown[classtable.LunarStorm].ready==false or cooldown[classtable.LunarStorm].remains >5 )) and cooldown[classtable.RapidFire].ready then
        return classtable.RapidFire
    end
    if (MaxDps:CheckSpellUsable(classtable.Trueshot, 'Trueshot')) and (trueshot_ready) and cooldown[classtable.Trueshot].ready then
        MaxDps:GlowCooldown(classtable.Trueshot, cooldown[classtable.Trueshot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.MultiShot, 'MultiShot')) and (buff[classtable.SalvoBuff].up and not talents[classtable.Volley]) and cooldown[classtable.MultiShot].ready then
        return classtable.MultiShot
    end
    if (MaxDps:CheckSpellUsable(classtable.WailingArrow, 'WailingArrow')) and cooldown[classtable.WailingArrow].ready then
        return classtable.WailingArrow
    end
    if (MaxDps:CheckSpellUsable(classtable.AimedShot, 'AimedShot')) and (not buff[classtable.PreciseShotsBuff].up or ( buff[classtable.TrueshotBuff].up or FocusTimeToMax <gcd + ( classtable and classtable.AimedShot and GetSpellInfo(classtable.AimedShot).castTime /1000 ) ) and ( targets <2 or not talents[classtable.ChimaeraShot] ) or ( buff[classtable.TrickShotsBuff].remains >timeShift and targets >1 )) and cooldown[classtable.AimedShot].ready then
        return classtable.AimedShot
    end
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and (talents[classtable.SteadyFocus] and not buff[classtable.SteadyFocusBuff].up and not buff[classtable.TrueshotBuff].up) and cooldown[classtable.SteadyShot].ready then
        return classtable.SteadyShot
    end
    if (MaxDps:CheckSpellUsable(classtable.ChimaeraShot, 'ChimaeraShot')) and (buff[classtable.PreciseShotsBuff].up) and cooldown[classtable.ChimaeraShot].ready then
        return classtable.ChimaeraShot
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneShot, 'ArcaneShot')) and (buff[classtable.PreciseShotsBuff].up) and cooldown[classtable.ArcaneShot].ready then
        return classtable.ArcaneShot
    end
    if (MaxDps:CheckSpellUsable(classtable.Barrage, 'Barrage')) and (talents[classtable.RapidFireBarrage]) and cooldown[classtable.Barrage].ready then
        return classtable.Barrage
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and cooldown[classtable.ExplosiveShot].ready then
        return classtable.ExplosiveShot
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneShot, 'ArcaneShot')) and (Focus >MaxDps:GetSpellCost(classtable.ArcaneShot, 'FOCUS') + MaxDps:GetSpellCost(classtable.AimedShot, 'FOCUS')) and cooldown[classtable.ArcaneShot].ready then
        return classtable.ArcaneShot
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and cooldown[classtable.KillShot].ready then
        return classtable.KillShot
    end
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and cooldown[classtable.SteadyShot].ready then
        return classtable.SteadyShot
    end
end
function Marksmanship:trickshots()
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and (talents[classtable.SteadyFocus] and SteadyFocusTrack() and buff[classtable.SteadyFocusBuff].remains <8) and cooldown[classtable.SteadyShot].ready then
        return classtable.SteadyShot
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and cooldown[classtable.ExplosiveShot].ready then
        return classtable.ExplosiveShot
    end
    if (MaxDps:CheckSpellUsable(classtable.Volley, 'Volley')) and cooldown[classtable.Volley].ready then
        return classtable.Volley
    end
    if (MaxDps:CheckSpellUsable(classtable.Barrage, 'Barrage')) and (talents[classtable.RapidFireBarrage] and buff[classtable.TrickShotsBuff].remains >= timeShift) and cooldown[classtable.Barrage].ready then
        return classtable.Barrage
    end
    if (MaxDps:CheckSpellUsable(classtable.RapidFire, 'RapidFire')) and (buff[classtable.TrickShotsBuff].remains >= timeShift) and cooldown[classtable.RapidFire].ready then
        return classtable.RapidFire
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and (buff[classtable.RazorFragmentsBuff].up) and cooldown[classtable.KillShot].ready then
        return classtable.KillShot
    end
    if (MaxDps:CheckSpellUsable(classtable.BlackArrow, 'BlackArrow')) and cooldown[classtable.BlackArrow].ready then
        return classtable.BlackArrow
    end
    if (MaxDps:CheckSpellUsable(classtable.WailingArrow, 'WailingArrow')) and (not buff[classtable.PreciseShotsBuff].up) and cooldown[classtable.WailingArrow].ready then
        return classtable.WailingArrow
    end
    if (MaxDps:CheckSpellUsable(classtable.WailingArrow, 'WailingArrow')) and (not buff[classtable.PreciseShotsBuff].up or buff[classtable.TrueshotBuff].up) and cooldown[classtable.WailingArrow].ready then
        return classtable.WailingArrow
    end
    if (MaxDps:CheckSpellUsable(classtable.Trueshot, 'Trueshot')) and (trueshot_ready) and cooldown[classtable.Trueshot].ready then
        MaxDps:GlowCooldown(classtable.Trueshot, cooldown[classtable.Trueshot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.AimedShot, 'AimedShot')) and (buff[classtable.TrickShotsBuff].remains >= timeShift and not buff[classtable.PreciseShotsBuff].up) and cooldown[classtable.AimedShot].ready then
        return classtable.AimedShot
    end
    if (MaxDps:CheckSpellUsable(classtable.MultiShot, 'MultiShot')) and (not buff[classtable.TrickShotsBuff].up or buff[classtable.PreciseShotsBuff].up or Focus >MaxDps:GetSpellCost(classtable.MultiShot, 'FOCUS') + MaxDps:GetSpellCost(classtable.AimedShot, 'FOCUS')) and cooldown[classtable.MultiShot].ready then
        return classtable.MultiShot
    end
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and cooldown[classtable.SteadyShot].ready then
        return classtable.SteadyShot
    end
end
function Marksmanship:trinkets()
end

function Marksmanship:callaction()
    if (MaxDps:CheckSpellUsable(classtable.CounterShot, 'CounterShot')) and cooldown[classtable.CounterShot].ready then
        MaxDps:GlowCooldown(classtable.CounterShot, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    --if (MaxDps:CheckSpellUsable(classtable.TranquilizingShot, 'TranquilizingShot')) and cooldown[classtable.TranquilizingShot].ready then
    --    return classtable.TranquilizingShot
    --end
    trueshot_ready = cooldown[classtable.Trueshot].ready-- and ( (targets <2) and ( not talents[classtable.Bullseye] or ttd >cooldown[classtable.Trueshot].duration + buff[classtable.TrueshotBuff].duration % 2 or buff[classtable.BullseyeBuff].count == buff[classtable.BullseyeBuff].maxStacks ) or (targets >1) and ( not (targets >1) and ( (targets>1 and MaxDps:MaxAddDuration() or 0) + math.huge <25 or math.huge >60 ) or (targets >1) and targets >10 ) or MaxDps:boss() and ttd <25 )
    local cdsCheck = Marksmanship:cds()
    if cdsCheck then
        return cdsCheck
    end
    local trinketsCheck = Marksmanship:trinkets()
    if trinketsCheck then
        return trinketsCheck
    end
    if (MaxDps:CheckSpellUsable(classtable.HuntersMark, 'HuntersMark')) and (debuff[classtable.HuntersMarkDeBuff].count  == 0 and MaxDps:GetTimeToPct(80) >20) and cooldown[classtable.HuntersMark].ready then
        MaxDps:GlowCooldown(classtable.HuntersMark, cooldown[classtable.HuntersMark].ready)
    end
    if (targets <3 or not talents[classtable.TrickShots]) then
        local stCheck = Marksmanship:st()
        if stCheck then
            return Marksmanship:st()
        end
    end
    if (targets >2) then
        local trickshotsCheck = Marksmanship:trickshots()
        if trickshotsCheck then
            return Marksmanship:trickshots()
        end
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
    targethealthPerc = (targetHP / targetmaxHP) * 100
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
    for spellId in pairs(MaxDps.Flags) do
        self.Flags[spellId] = false
        self:ClearGlowIndependent(spellId, spellId)
    end
    classtable.HuntersMarkDeBuff = 257284
    classtable.SteadyFocusBuff = 193534
    classtable.RazorFragmentsBuff = 388998
    classtable.SalvoBuff = 400456
    classtable.PreciseShotsBuff = 260242
    classtable.TrueshotBuff = 288613
    classtable.TrickShotsBuff = 257622
    classtable.BullseyeBuff = 204090

    local precombatCheck = Marksmanship:precombat()
    if precombatCheck then
        return Marksmanship:precombat()
    end

    local callactionCheck = Marksmanship:callaction()
    if callactionCheck then
        return Marksmanship:callaction()
    end
end
