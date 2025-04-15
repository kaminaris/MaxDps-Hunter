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

local BeastMastery = {}

local trinket_1_stronger = false
local trinket_2_stronger = false
local sync_ready = false
local sync_active = false
local sync_remains = 0


local function howl_summon_ready()
    return buff[classtable.HowlofthePackLeaderBear].up or buff[classtable.HowlofthePackLeaderBoar].up or buff[classtable.HowlofthePackLeaderWyvern].up or false
end


function BeastMastery:precombat()
    if (MaxDps:CheckSpellUsable(classtable.BarbedShot, 'BarbedShot')) and (false) and cooldown[classtable.BarbedShot].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.BarbedShot end
    end
end
function BeastMastery:cds()
end
function BeastMastery:cleave()
    if (MaxDps:CheckSpellUsable(classtable.BestialWrath, 'BestialWrath')) and cooldown[classtable.BestialWrath].ready then
        MaxDps:GlowCooldown(classtable.BestialWrath, cooldown[classtable.BestialWrath].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DireBeast, 'DireBeast')) and (talents[classtable.HuntmastersCall] and buff[classtable.HuntmastersCallBuff].count == 2) and cooldown[classtable.DireBeast].ready then
        MaxDps:GlowCooldown(classtable.DireBeast, cooldown[classtable.DireBeast].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BlackArrow, 'BlackArrow') and talents[classtable.BlackArrow]) and (buff[classtable.BeastCleaveBuff].remains and buff[classtable.WitheringFireBuff].up) and cooldown[classtable.BlackArrow].ready then
        MaxDps:GlowCooldown(classtable.BlackArrow, cooldown[classtable.BlackArrow].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BarbedShot, 'BarbedShot')) and (FocusTimeToMax <gcd or cooldown[classtable.BarbedShot].charges >= cooldown[classtable.KillCommand].charges or talents[classtable.CalloftheWild] and cooldown[classtable.CalloftheWild].ready or howl_summon_ready() and FocusTimeToMax <8) and cooldown[classtable.BarbedShot].ready then
        if not setSpell then setSpell = classtable.BarbedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.MultiShot, 'MultiShot')) and (not buff[classtable.BeastCleaveBuff].up and ( not talents[classtable.BloodyFrenzy] or not cooldown[classtable.CalloftheWild].ready )) and cooldown[classtable.MultiShot].ready then
        if not setSpell then setSpell = classtable.MultiShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.BlackArrow, 'BlackArrow') and talents[classtable.BlackArrow]) and (buff[classtable.BeastCleaveBuff].up) and cooldown[classtable.BlackArrow].ready then
        MaxDps:GlowCooldown(classtable.BlackArrow, cooldown[classtable.BlackArrow].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.CalloftheWild, 'CalloftheWild') and talents[classtable.CalloftheWild]) and cooldown[classtable.CalloftheWild].ready then
        MaxDps:GlowCooldown(classtable.CalloftheWild, cooldown[classtable.CalloftheWild].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodshed, 'Bloodshed') and talents[classtable.Bloodshed]) and cooldown[classtable.Bloodshed].ready then
        MaxDps:GlowCooldown(classtable.Bloodshed, cooldown[classtable.Bloodshed].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DireBeast, 'DireBeast')) and (talents[classtable.ShadowHounds] or talents[classtable.DireCleave]) and cooldown[classtable.DireBeast].ready then
        MaxDps:GlowCooldown(classtable.DireBeast, cooldown[classtable.DireBeast].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and (talents[classtable.ThunderingHooves]) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.BarbedShot, 'BarbedShot')) and (buff[classtable.CalloftheWildBuff].up or talents[classtable.BlackArrow] and ( talents[classtable.BarbedScales] or talents[classtable.Savagery] ) or (MaxDps.tier and MaxDps.tier[33].count) >= 2 or MaxDps:boss() and ttd <9) and cooldown[classtable.BarbedShot].ready then
        if not setSpell then setSpell = classtable.BarbedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.CobraShot, 'CobraShot')) and (FocusTimeToMax <gcd * 2 or buff[classtable.HogstriderBuff].count >3) and cooldown[classtable.CobraShot].ready then
        if not setSpell then setSpell = classtable.CobraShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.DireBeast, 'DireBeast')) and cooldown[classtable.DireBeast].ready then
        MaxDps:GlowCooldown(classtable.DireBeast, cooldown[classtable.DireBeast].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
end
function BeastMastery:st()
    if (MaxDps:CheckSpellUsable(classtable.DireBeast, 'DireBeast')) and (talents[classtable.HuntmastersCall]) and cooldown[classtable.DireBeast].ready then
        MaxDps:GlowCooldown(classtable.DireBeast, cooldown[classtable.DireBeast].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BestialWrath, 'BestialWrath')) and cooldown[classtable.BestialWrath].ready then
        MaxDps:GlowCooldown(classtable.BestialWrath, cooldown[classtable.BestialWrath].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BlackArrow, 'BlackArrow') and talents[classtable.BlackArrow]) and (buff[classtable.WitheringFireBuff].up) and cooldown[classtable.BlackArrow].ready then
        MaxDps:GlowCooldown(classtable.BlackArrow, cooldown[classtable.BlackArrow].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BarbedShot, 'BarbedShot')) and (FocusTimeToMax <gcd or cooldown[classtable.BarbedShot].charges >= cooldown[classtable.KillCommand].charges or talents[classtable.CalloftheWild] and cooldown[classtable.CalloftheWild].ready or howl_summon_ready() and FocusTimeToMax <8) and cooldown[classtable.BarbedShot].ready then
        if not setSpell then setSpell = classtable.BarbedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.CalloftheWild, 'CalloftheWild') and talents[classtable.CalloftheWild]) and cooldown[classtable.CalloftheWild].ready then
        MaxDps:GlowCooldown(classtable.CalloftheWild, cooldown[classtable.CalloftheWild].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodshed, 'Bloodshed') and talents[classtable.Bloodshed]) and cooldown[classtable.Bloodshed].ready then
        MaxDps:GlowCooldown(classtable.Bloodshed, cooldown[classtable.Bloodshed].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.BlackArrow, 'BlackArrow') and talents[classtable.BlackArrow]) and cooldown[classtable.BlackArrow].ready then
        MaxDps:GlowCooldown(classtable.BlackArrow, cooldown[classtable.BlackArrow].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and (talents[classtable.ThunderingHooves]) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.CobraShot, 'CobraShot')) and cooldown[classtable.CobraShot].ready then
        if not setSpell then setSpell = classtable.CobraShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.DireBeast, 'DireBeast')) and cooldown[classtable.DireBeast].ready then
        MaxDps:GlowCooldown(classtable.DireBeast, cooldown[classtable.DireBeast].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcanePulse, 'ArcanePulse')) and (not buff[classtable.BestialWrathBuff].up or ttd <5) and cooldown[classtable.ArcanePulse].ready then
        if not setSpell then setSpell = classtable.ArcanePulse end
    end
end
function BeastMastery:trinkets()
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.CounterShot, false)
    MaxDps:GlowCooldown(classtable.TranquilizingShot, false)
    MaxDps:GlowCooldown(classtable.MendPet, false)
    MaxDps:GlowCooldown(classtable.HuntersMark, false)
    MaxDps:GlowCooldown(classtable.BestialWrath, false)
    MaxDps:GlowCooldown(classtable.DireBeast, false)
    MaxDps:GlowCooldown(classtable.BlackArrow, false)
    MaxDps:GlowCooldown(classtable.CalloftheWild, false)
    MaxDps:GlowCooldown(classtable.Bloodshed, false)
    MaxDps:GlowCooldown(classtable.ExplosiveShot, false)
end

function BeastMastery:callaction()
    if (MaxDps:CheckSpellUsable(classtable.CounterShot, 'CounterShot')) and cooldown[classtable.CounterShot].ready then
        MaxDps:GlowCooldown(classtable.CounterShot, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    --if (MaxDps:CheckSpellUsable(classtable.TranquilizingShot, 'TranquilizingShot')) and cooldown[classtable.TranquilizingShot].ready then
    --    MaxDps:GlowCooldown(classtable.TranquilizingShot, cooldown[classtable.TranquilizingShot].ready)
    --end
    if (MaxDps:CheckSpellUsable(classtable.MendPet, 'MendPet')) and (pethealthPerc <80) and cooldown[classtable.MendPet].ready then
        MaxDps:GlowCooldown(classtable.MendPet, cooldown[classtable.MendPet].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.HuntersMark, 'HuntersMark')) and (( false or MaxDps:boss() ) and MaxDps:DebuffCounter(classtable.HuntersMarkDeBuff) == 0 and MaxDps:GetTimeToPct(80) >20) and cooldown[classtable.HuntersMark].ready then
        MaxDps:GlowCooldown(classtable.HuntersMark, cooldown[classtable.HuntersMark].ready)
    end
    BeastMastery:cds()
    BeastMastery:trinkets()
    if (targets <2 or not talents[classtable.BeastCleave] and targets <3) then
        BeastMastery:st()
    end
    if (targets >2 or talents[classtable.BeastCleave] and targets >1) then
        BeastMastery:cleave()
    end
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
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.CalloftheWildBuff = 359844
    classtable.BestialWrathBuff = 19574
    classtable.HuntmastersCallBuff = 459731
    classtable.BeastCleaveBuff = 268877
    classtable.WitheringFireBuff = 466991
    classtable.HogstriderBuff = 472640
    classtable.ArcanePulse = 260369
    classtable.MendPet = 136

    local function debugg()
        talents[classtable.BeastCleave] = 1
        talents[classtable.Bloodshed] = 1
        talents[classtable.CalloftheWild] = 1
        talents[classtable.HuntmastersCall] = 1
        talents[classtable.BloodyFrenzy] = 1
        talents[classtable.ShadowHounds] = 1
        talents[classtable.DireCleave] = 1
        talents[classtable.ThunderingHooves] = 1
        talents[classtable.BlackArrow] = 1
        talents[classtable.BarbedScales] = 1
        talents[classtable.Savagery] = 1
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    BeastMastery:precombat()

    BeastMastery:callaction()
    if setSpell then return setSpell end
end
