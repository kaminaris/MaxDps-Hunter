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

local Marksmanship = {}

local trinket_1_stronger = false
local trinket_2_stronger = false
local trueshot_ready = false
local sync_ready = false
local sync_active = false
local sync_remains = 0


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
    if (MaxDps:CheckSpellUsable(classtable.HuntersMark, 'HuntersMark')) and (( false or MaxDps:boss() ) and MaxDps:DebuffCounter(classtable.HuntersMarkDeBuff) == 0 and MaxDps:GetTimeToPct(80) >20) and cooldown[classtable.HuntersMark].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.HuntersMark, cooldown[classtable.HuntersMark].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.AimedShot, 'AimedShot')) and (targets == 1 or targets == 2 and not talents[classtable.Volley]) and cooldown[classtable.AimedShot].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.AimedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and cooldown[classtable.SteadyShot].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.SteadyShot end
    end
end
function Marksmanship:cds()
    if (MaxDps:CheckSpellUsable(classtable.Salvo, 'Salvo')) and (targets >2 or cooldown[classtable.Volley].remains <10) and cooldown[classtable.Salvo].ready then
        MaxDps:GlowCooldown(classtable.Salvo, cooldown[classtable.Salvo].ready)
    end
end
function Marksmanship:st()
    if (MaxDps:CheckSpellUsable(classtable.Volley, 'Volley') and talents[classtable.Volley]) and (not talents[classtable.DoubleTap]) and cooldown[classtable.Volley].ready then
        MaxDps:GlowCooldown(classtable.Volley, cooldown[classtable.Volley].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.RapidFire, 'RapidFire')) and ((MaxDps.ActiveHeroTree == 'sentinel') and not buff[classtable.LunarStormCooldownBuff].up or talents[classtable.Bulletstorm] and not buff[classtable.BulletstormBuff].up) and cooldown[classtable.RapidFire].ready then
        if not setSpell then setSpell = classtable.RapidFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Trueshot, 'Trueshot')) and (trueshot_ready) and cooldown[classtable.Trueshot].ready then
        MaxDps:GlowCooldown(classtable.Trueshot, cooldown[classtable.Trueshot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Volley, 'Volley') and talents[classtable.Volley]) and (talents[classtable.DoubleTap] and not buff[classtable.DoubleTapBuff].up) and cooldown[classtable.Volley].ready then
        MaxDps:GlowCooldown(classtable.Volley, cooldown[classtable.Volley].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BlackArrow, 'BlackArrow')) and (talents[classtable.Headshot] and buff[classtable.PreciseShotsBuff].up or not talents[classtable.Headshot] and buff[classtable.RazorFragmentsBuff].up) and cooldown[classtable.BlackArrow].ready then
        MaxDps:GlowCooldown(classtable.BlackArrow, cooldown[classtable.BlackArrow].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and (talents[classtable.Headshot] and buff[classtable.PreciseShotsBuff].up or not talents[classtable.Headshot] and buff[classtable.RazorFragmentsBuff].up) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcaneShot, 'ArcaneShot')) and (buff[classtable.PreciseShotsBuff].up) and cooldown[classtable.ArcaneShot].ready then
        if not setSpell then setSpell = classtable.ArcaneShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.RapidFire, 'RapidFire')) and (not (MaxDps.ActiveHeroTree == 'sentinel') or buff[classtable.LunarStormCooldownBuff].remains >cooldown[classtable.RapidFire].remains / 3) and cooldown[classtable.RapidFire].ready then
        if not setSpell then setSpell = classtable.RapidFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and (talents[classtable.PrecisionDetonation] and not buff[classtable.PreciseShotsBuff].up) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.AimedShot, 'AimedShot')) and (not buff[classtable.PreciseShotsBuff].up) and cooldown[classtable.AimedShot].ready then
        if not setSpell then setSpell = classtable.AimedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and (talents[classtable.PrecisionDetonation] or targets >1 or not buff[classtable.TrueshotBuff].up) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BlackArrow, 'BlackArrow')) and (not talents[classtable.Headshot]) and cooldown[classtable.BlackArrow].ready then
        MaxDps:GlowCooldown(classtable.BlackArrow, cooldown[classtable.BlackArrow].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and (not talents[classtable.Headshot]) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and cooldown[classtable.SteadyShot].ready then
        if not setSpell then setSpell = classtable.SteadyShot end
    end
end
function Marksmanship:trickshots()
    if (MaxDps:CheckSpellUsable(classtable.Volley, 'Volley') and talents[classtable.Volley]) and (not talents[classtable.DoubleTap]) and cooldown[classtable.Volley].ready then
        MaxDps:GlowCooldown(classtable.Volley, cooldown[classtable.Volley].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Trueshot, 'Trueshot')) and (trueshot_ready) and cooldown[classtable.Trueshot].ready then
        MaxDps:GlowCooldown(classtable.Trueshot, cooldown[classtable.Trueshot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Volley, 'Volley') and talents[classtable.Volley]) and (talents[classtable.DoubleTap] and not buff[classtable.DoubleTapBuff].up) and cooldown[classtable.Volley].ready then
        MaxDps:GlowCooldown(classtable.Volley, cooldown[classtable.Volley].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BlackArrow, 'BlackArrow')) and (buff[classtable.WitheringFireBuff].up and buff[classtable.TrickShotsBuff].up) and cooldown[classtable.BlackArrow].ready then
        MaxDps:GlowCooldown(classtable.BlackArrow, cooldown[classtable.BlackArrow].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.MultiShot, 'MultiShot')) and (buff[classtable.PreciseShotsBuff].up or not buff[classtable.TrickShotsBuff].up) and cooldown[classtable.MultiShot].ready then
        if not setSpell then setSpell = classtable.MultiShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.RapidFire, 'RapidFire')) and (buff[classtable.TrickShotsBuff].up and ( not (MaxDps.ActiveHeroTree == 'sentinel') or buff[classtable.LunarStormCooldownBuff].remains >cooldown[classtable.RapidFire].remains / 3 or not buff[classtable.LunarStormCooldownBuff].up )) and cooldown[classtable.RapidFire].ready then
        if not setSpell then setSpell = classtable.RapidFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and (talents[classtable.PrecisionDetonation] and not buff[classtable.PreciseShotsBuff].up and buff[classtable.TrickShotsBuff].up) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.AimedShot, 'AimedShot')) and (not buff[classtable.PreciseShotsBuff].up and buff[classtable.TrickShotsBuff].up) and cooldown[classtable.AimedShot].ready then
        if not setSpell then setSpell = classtable.AimedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BlackArrow, 'BlackArrow')) and cooldown[classtable.BlackArrow].ready then
        MaxDps:GlowCooldown(classtable.BlackArrow, cooldown[classtable.BlackArrow].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.SteadyShot, 'SteadyShot')) and cooldown[classtable.SteadyShot].ready then
        if not setSpell then setSpell = classtable.SteadyShot end
    end
end
function Marksmanship:trinkets()
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.HuntersMark, false)
    MaxDps:GlowCooldown(classtable.CounterShot, false)
    MaxDps:GlowCooldown(classtable.TranquilizingShot, false)
    --MaxDps:GlowCooldown(classtable.MendPet, false)
    MaxDps:GlowCooldown(classtable.Salvo, false)
    MaxDps:GlowCooldown(classtable.Volley, false)
    MaxDps:GlowCooldown(classtable.Trueshot, false)
    MaxDps:GlowCooldown(classtable.BlackArrow, false)
    MaxDps:GlowCooldown(classtable.ExplosiveShot, false)
end

function Marksmanship:callaction()
    if (MaxDps:CheckSpellUsable(classtable.CounterShot, 'CounterShot')) and cooldown[classtable.CounterShot].ready then
        MaxDps:GlowCooldown(classtable.CounterShot, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.TranquilizingShot, 'TranquilizingShot')) and cooldown[classtable.TranquilizingShot].ready then
        MaxDps:GlowCooldown(classtable.TranquilizingShot, cooldown[classtable.TranquilizingShot].ready)
    end
    trueshot_ready = cooldown[classtable.Trueshot].ready and ( (targets <2) and ( not talents[classtable.Bullseye] or ttd >cooldown[classtable.Trueshot].duration + buff[classtable.TrueshotBuff].duration / 2 or buff[classtable.BullseyeBuff].count == buff[classtable.BullseyeBuff].maxStacks ) and ( not MaxDps:HasOnUseEffect('14') or MaxDps:CheckTrinketCooldown('1') >30 or MaxDps:CheckTrinketReady('14') ) and ( not MaxDps:HasOnUseEffect('14') or MaxDps:CheckTrinketCooldown('2') >30 or MaxDps:CheckTrinketReady('14') ) or (targets >1) and ( not (targets >1) and ( (targets>1 and MaxDps:MaxAddDuration() or 0) + math.huge <25 or math.huge >60 ) or (targets >1) and targets >10 ) or MaxDps:boss() and ttd <25 )
    --if (MaxDps:CheckSpellUsable(classtable.MendPet, 'MendPet')) and (petmath.health_pct <80) and cooldown[classtable.MendPet].ready then
    --    MaxDps:GlowCooldown(classtable.MendPet, cooldown[classtable.MendPet].ready)
    --end
    Marksmanship:cds()
    Marksmanship:trinkets()
    if (MaxDps:CheckSpellUsable(classtable.HuntersMark, 'HuntersMark')) and (( false or MaxDps:boss() ) and MaxDps:DebuffCounter(classtable.HuntersMarkDeBuff) == 0 and MaxDps:GetTimeToPct(80) >20) and cooldown[classtable.HuntersMark].ready then
        MaxDps:GlowCooldown(classtable.HuntersMark, cooldown[classtable.HuntersMark].ready)
    end
    if (targets <3 or not talents[classtable.TrickShots]) then
        Marksmanship:st()
    end
    if (targets >2) then
        Marksmanship:trickshots()
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
    classtable.DeathblowBuff = 378770
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.TrueshotBuff = 288613
    classtable.BullseyeBuff = 204090
    classtable.BloodlustBuff = 2825
    classtable.LunarStormCooldownBuff = 451803
    classtable.BulletstormBuff = 389020
    classtable.DoubleTapBuff = 260402
    classtable.PreciseShotsBuff = 260242
    classtable.RazorFragmentsBuff = 388998
    classtable.WitheringFireBuff = 466991
    classtable.TrickShotsBuff = 257622

    local function debugg()
        talents[classtable.UnbreakableBond] = 1
        talents[classtable.Volley] = 1
        talents[classtable.TrickShots] = 1
        talents[classtable.DoubleTap] = 1
        talents[classtable.Bulletstorm] = 1
        talents[classtable.Headshot] = 1
        talents[classtable.PrecisionDetonation] = 1
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
