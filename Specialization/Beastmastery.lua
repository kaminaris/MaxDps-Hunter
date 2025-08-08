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

local BeastMastery = {}

local trinket_1_stronger = false
local trinket_2_stronger = false
local buff_sync_ready = false
local buff_sync_remains = false
local buff_sync_active = false
local damage_sync_active = false
local damage_sync_remains = false


local function GetTotemInfoByName(name)
    local info = {
        duration = 0,
        remains = 0,
        up = false,
    }
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local remains = math.floor(startTime+duration-GetTime())
        if (totemName == name ) then
            info.duration = duration
            info.up = true
            info.remains = remains
            break
        end
    end
    return info
end

local function GetTotemInfoById(sSpellID)
    local info = {
        duration = 0,
        remains = 0,
        up = false,
    }
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon, modRate, spellID = GetTotemInfo(index)
        local sName = sSpellID and GetSpellInfo(sSpellID).name or ''
        local remains = math.floor(startTime+duration-GetTime())
        if (spellID == sSpellID) or (totemName == sName ) then
            info.duration = duration
            info.up = true
            info.remains = remains
            break
        end
    end
    return info
end

local function GetTotemTypeActive(i)
   local arg1, totemName, startTime, duration, icon = GetTotemInfo(i)
   return duration > 0
end




local function howl_summon_ready()
    return buff[classtable.HowlofthePackLeaderBear].up or buff[classtable.HowlofthePackLeaderBoar].up or buff[classtable.HowlofthePackLeaderWyvern].up or false
end


function BeastMastery:precombat()
    trinket_1_stronger = not MaxDps:HasOnUseEffect('14') or MaxDps:HasOnUseEffect('13') and (not MaxDps:HasOnUseEffect('14') or not MaxDps:CheckTrinketNames('MirrorofFracturedTomorrows') and (MaxDps:CheckTrinketNames('MirrorofFracturedTomorrows') or MaxDps:CheckTrinketCooldownDuration('14') <MaxDps:CheckTrinketCooldownDuration('13') or MaxDps:CheckTrinketCastTime('14') <MaxDps:CheckTrinketCastTime('13') or MaxDps:CheckTrinketCastTime('14') == MaxDps:CheckTrinketCastTime('13') and MaxDps:CheckTrinketCooldownDuration('14') == MaxDps:CheckTrinketCooldownDuration('13'))) or not MaxDps:HasOnUseEffect('13') and (not MaxDps:HasOnUseEffect('14') and (MaxDps:CheckTrinketCooldownDuration('14') <MaxDps:CheckTrinketCooldownDuration('13') or MaxDps:CheckTrinketCastTime('14') <MaxDps:CheckTrinketCastTime('13') or MaxDps:CheckTrinketCastTime('14') == MaxDps:CheckTrinketCastTime('13') and MaxDps:CheckTrinketCooldownDuration('14') == MaxDps:CheckTrinketCooldownDuration('13')))
    trinket_2_stronger = not trinket_1_stronger
    if (MaxDps:CheckSpellUsable(classtable.BarbedShot, 'BarbedShot')) and (false) and cooldown[classtable.BarbedShot].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.BarbedShot end
    end
end
function BeastMastery:cds()
end
function BeastMastery:drcleave()
    if (MaxDps:CheckSpellUsable(classtable.BestialWrath, 'BestialWrath')) and cooldown[classtable.BestialWrath].ready then
        MaxDps:GlowCooldown(classtable.BestialWrath, cooldown[classtable.BestialWrath].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and (buff[classtable.WitheringFireBuff].up or (C_UnitAuras.GetAuraDataBySpellName('BeastCleave', 'pet', 'HELPFUL') and C_UnitAuras.GetAuraDataBySpellName('BeastCleave', 'pet', 'HELPFUL').expirationTime or 0 ) <gcd) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.BarbedShot, 'BarbedShot')) and (FocusTimeToMax <gcd) and cooldown[classtable.BarbedShot].ready then
        if not setSpell then setSpell = classtable.BarbedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.MultiShot, 'MultiShot') and talents[classtable.MultiShot]) and ((not buff[classtable.BeastCleaveBuff].up) and (not talents[classtable.BloodyFrenzy] or not cooldown[classtable.CalloftheWild].ready)) and cooldown[classtable.MultiShot].ready then
        if not setSpell then setSpell = classtable.MultiShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.CalloftheWild, 'CalloftheWild') and talents[classtable.CalloftheWild]) and cooldown[classtable.CalloftheWild].ready then
        MaxDps:GlowCooldown(classtable.CalloftheWild, cooldown[classtable.CalloftheWild].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodshed, 'Bloodshed')) and cooldown[classtable.Bloodshed].ready then
        MaxDps:GlowCooldown(classtable.Bloodshed, cooldown[classtable.Bloodshed].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and (talents[classtable.ThunderingHooves]) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.CobraShot, 'CobraShot')) and (FocusTimeToMax <gcd*2 or not talents[classtable.MultiShot]) and cooldown[classtable.CobraShot].ready then
        if not setSpell then setSpell = classtable.CobraShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
end
function BeastMastery:drst()
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodshed, 'Bloodshed')) and cooldown[classtable.Bloodshed].ready then
        MaxDps:GlowCooldown(classtable.Bloodshed, cooldown[classtable.Bloodshed].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.CalloftheWild, 'CalloftheWild') and talents[classtable.CalloftheWild]) and (ttd >60 or MaxDps:boss() and ttd <30) and cooldown[classtable.CalloftheWild].ready then
        MaxDps:GlowCooldown(classtable.CalloftheWild, cooldown[classtable.CalloftheWild].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BestialWrath, 'BestialWrath')) and (cooldown[classtable.CalloftheWild].remains >20 or not talents[classtable.CalloftheWild] or cooldown[classtable.CalloftheWild].ready) and cooldown[classtable.BestialWrath].ready then
        MaxDps:GlowCooldown(classtable.BestialWrath, cooldown[classtable.BestialWrath].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and ((MaxDps:CheckPrevSpell(classtable.BlackArrow,1) or MaxDps:CheckPrevSpell(classtable.KillShot,1)) and buff[classtable.WitheringFireBuff].up) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.BarbedShot, 'BarbedShot')) and (FocusTimeToMax <gcd or cooldown[classtable.BarbedShot].charges >= cooldown[classtable.KillCommand].charges) and cooldown[classtable.BarbedShot].ready then
        if not setSpell then setSpell = classtable.BarbedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.CobraShot, 'CobraShot')) and cooldown[classtable.CobraShot].ready then
        if not setSpell then setSpell = classtable.CobraShot end
    end
end
function BeastMastery:cleave()
    if (MaxDps:CheckSpellUsable(classtable.BarbedShot, 'BarbedShot')) and (cooldown[classtable.BestialWrath].ready and talents[classtable.ScentofBlood]) and cooldown[classtable.BarbedShot].ready then
        if not setSpell then setSpell = classtable.BarbedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.BestialWrath, 'BestialWrath')) and (buff[classtable.HowlofthePackLeaderCooldownBuff].remains - buff[classtable.LeadFromtheFrontBuff].duration<buff[classtable.LeadFromtheFrontBuff].duration%gcd * 0.5 or talents[classtable.MultiShot] or not (MaxDps.tier and MaxDps.tier[34].count >= 4)) and cooldown[classtable.BestialWrath].ready then
        MaxDps:GlowCooldown(classtable.BestialWrath, cooldown[classtable.BestialWrath].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BarbedShot, 'BarbedShot')) and (FocusTimeToMax <gcd or cooldown[classtable.BarbedShot].charges >= cooldown[classtable.KillCommand].charges or talents[classtable.CalloftheWild] and cooldown[classtable.CalloftheWild].ready or howl_summon_ready() and FocusTimeToMax <8) and cooldown[classtable.BarbedShot].ready then
        if not setSpell then setSpell = classtable.BarbedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodshed, 'Bloodshed')) and cooldown[classtable.Bloodshed].ready then
        MaxDps:GlowCooldown(classtable.Bloodshed, cooldown[classtable.Bloodshed].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.MultiShot, 'MultiShot') and talents[classtable.MultiShot]) and ((not buff[classtable.BeastCleaveBuff].up) and (not talents[classtable.BloodyFrenzy] or not cooldown[classtable.CalloftheWild].ready)) and cooldown[classtable.MultiShot].ready then
        if not setSpell then setSpell = classtable.MultiShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.CalloftheWild, 'CalloftheWild') and talents[classtable.CalloftheWild]) and cooldown[classtable.CalloftheWild].ready then
        MaxDps:GlowCooldown(classtable.CalloftheWild, cooldown[classtable.CalloftheWild].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and (talents[classtable.ThunderingHooves]) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.CobraShot, 'CobraShot')) and (FocusTimeToMax <gcd*2 or buff[classtable.HogstriderBuff].count >3 or not talents[classtable.MultiShot]) and cooldown[classtable.CobraShot].ready then
        if not setSpell then setSpell = classtable.CobraShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and cooldown[classtable.ExplosiveShot].ready then
        MaxDps:GlowCooldown(classtable.ExplosiveShot, cooldown[classtable.ExplosiveShot].ready)
    end
end
function BeastMastery:st()
    if (MaxDps:CheckSpellUsable(classtable.BestialWrath, 'BestialWrath')) and (buff[classtable.HowlofthePackLeaderCooldownBuff].remains - buff[classtable.LeadFromtheFrontBuff].duration<buff[classtable.LeadFromtheFrontBuff].duration%gcd * 0.5 or not (MaxDps.tier and MaxDps.tier[34].count >= 4)) and cooldown[classtable.BestialWrath].ready then
        MaxDps:GlowCooldown(classtable.BestialWrath, cooldown[classtable.BestialWrath].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BarbedShot, 'BarbedShot')) and (FocusTimeToMax <gcd) and cooldown[classtable.BarbedShot].ready then
        if not setSpell then setSpell = classtable.BarbedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.CalloftheWild, 'CalloftheWild') and talents[classtable.CalloftheWild]) and cooldown[classtable.CalloftheWild].ready then
        MaxDps:GlowCooldown(classtable.CalloftheWild, cooldown[classtable.CalloftheWild].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodshed, 'Bloodshed')) and cooldown[classtable.Bloodshed].ready then
        MaxDps:GlowCooldown(classtable.Bloodshed, cooldown[classtable.Bloodshed].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and (cooldown[classtable.KillCommand].charges >= cooldown[classtable.BarbedShot].charges) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.BarbedShot, 'BarbedShot')) and cooldown[classtable.BarbedShot].ready then
        if not setSpell then setSpell = classtable.BarbedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.CobraShot, 'CobraShot')) and cooldown[classtable.CobraShot].ready then
        if not setSpell then setSpell = classtable.CobraShot end
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
    MaxDps:GlowCooldown(classtable.CalloftheWild, false)
    MaxDps:GlowCooldown(classtable.Bloodshed, false)
    MaxDps:GlowCooldown(classtable.ExplosiveShot, false)
    MaxDps:GlowCooldown(classtable.trinket1, false)
    MaxDps:GlowCooldown(classtable.trinket2, false)
end

function BeastMastery:callaction()
    if (MaxDps:CheckSpellUsable(classtable.CounterShot, 'CounterShot')) and cooldown[classtable.CounterShot].ready then
        MaxDps:GlowCooldown(classtable.CounterShot, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.TranquilizingShot, 'TranquilizingShot')) and cooldown[classtable.TranquilizingShot].ready then
        MaxDps:GlowCooldown(classtable.TranquilizingShot, cooldown[classtable.TranquilizingShot].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.MendPet, 'MendPet')) and (pethealthPerc <80) and cooldown[classtable.MendPet].ready then
        MaxDps:GlowCooldown(classtable.MendPet, cooldown[classtable.MendPet].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.HuntersMark, 'HuntersMark')) and ((false or MaxDps:boss()) and MaxDps:DebuffCounter(classtable.HuntersMarkDeBuff) == 0 and MaxDps:GetTimeToPct(80) >20) and cooldown[classtable.HuntersMark].ready then
        MaxDps:GlowCooldown(classtable.HuntersMark, cooldown[classtable.HuntersMark].ready)
    end
    BeastMastery:cds()
    BeastMastery:trinkets()
    if (talents[classtable.BlackArrow] and (targets <2 or not talents[classtable.BeastCleave] and targets <3)) then
        BeastMastery:drst()
    end
    if (talents[classtable.BlackArrow] and (targets >2 or talents[classtable.BeastCleave] and targets >1)) then
        BeastMastery:drcleave()
    end
    if (not talents[classtable.BlackArrow] and (targets <2 or not talents[classtable.BeastCleave] and targets <3)) then
        BeastMastery:st()
    end
    if (not talents[classtable.BlackArrow] and (targets >2 or talents[classtable.BeastCleave] and targets >1)) then
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
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.CalloftheWildBuff = 359844
    classtable.BestialWrathBuff = 19574
    classtable.WitheringFireBuff = 466991
    classtable.BeastCleaveBuff = 268877
    classtable.HowlofthePackLeaderCooldownBuff = 471877
    classtable.LeadFromtheFrontBuff = 472743
    classtable.HogstriderBuff = 472640
    classtable.MendPet = 136
    classtable.KillShot = talents[classtable.BlackArrow] and 466930 or classtable.KillShot

    local function debugg()
        talents[classtable.BlackArrow] = 1
        talents[classtable.BeastCleave] = 1
        talents[classtable.CalloftheWild] = 1
        talents[classtable.BloodyFrenzy] = 1
        talents[classtable.ThunderingHooves] = 1
        talents[classtable.MultiShot] = 1
        talents[classtable.ScentofBlood] = 1
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
