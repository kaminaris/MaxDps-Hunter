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

local BeastMastery = {}

local trinket_one_stronger
local trinket_two_stronger
local sync_ready
local sync_active
local sync_remains


local function GetTotemDuration(name)
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local est_dur = math.floor(startTime+duration-GetTime())
        if (totemName == name and est_dur and est_dur > 0) then return est_dur else return 0 end
    end
end


function BeastMastery:precombat()
    if (MaxDps:CheckSpellUsable(classtable.BestialWrath, 'BestialWrath')) and (talents[classtable.ViciousHunt]) and cooldown[classtable.BestialWrath].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.BestialWrath end
    end
end
function BeastMastery:cds()
end
function BeastMastery:cleave()
    if (MaxDps:CheckSpellUsable(classtable.BarbedShot, 'BarbedShot')) and ((C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') ~= nil ) and (C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') and C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL').expirationTime or 0 ) <= gcd + barbed_shot_grace_period or (C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') and C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL').applications or 0 ) <3 and ( cooldown[classtable.BestialWrath].ready and ( not (C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') ~= nil ) or talents[classtable.ScentofBlood] ) or talents[classtable.CalloftheWild] and cooldown[classtable.CalloftheWild].ready )) and cooldown[classtable.BarbedShot].ready then
        if not setSpell then setSpell = classtable.BarbedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.MultiShot, 'MultiShot')) and (buff[classtable.BeastCleaveBuff].remains <0.25 + gcd and ( not talents[classtable.BloodyFrenzy] or cooldown[classtable.CalloftheWild].ready==false )) and cooldown[classtable.MultiShot].ready then
        if not setSpell then setSpell = classtable.MultiShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.BlackArrow, 'BlackArrow')) and (buff[classtable.BeastCleaveBuff].up) and cooldown[classtable.BlackArrow].ready then
        if not setSpell then setSpell = classtable.BlackArrow end
    end
    if (MaxDps:CheckSpellUsable(classtable.CalloftheWild, 'CalloftheWild')) and cooldown[classtable.CalloftheWild].ready then
        MaxDps:GlowCooldown(classtable.CalloftheWild, cooldown[classtable.CalloftheWild].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BestialWrath, 'BestialWrath')) and cooldown[classtable.BestialWrath].ready then
        if not setSpell then setSpell = classtable.BestialWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodshed, 'Bloodshed')) and cooldown[classtable.Bloodshed].ready then
        if not setSpell then setSpell = classtable.Bloodshed end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.BarbedShot, 'BarbedShot')) and (buff[classtable.CalloftheWildBuff].up or talents[classtable.WildCall] and cooldown[classtable.BarbedShot].charges >1.2 or talents[classtable.FuriousAssault] or talents[classtable.BlackArrow] and ( talents[classtable.BarbedScales] or talents[classtable.Savagery] ) or ttd <9) and cooldown[classtable.BarbedShot].ready then
        if not setSpell then setSpell = classtable.BarbedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.CobraShot, 'CobraShot')) and (buff[classtable.BestialWrathBuff].up and talents[classtable.KillerCobra]) and cooldown[classtable.CobraShot].ready then
        if not setSpell then setSpell = classtable.CobraShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.ExplosiveShot, 'ExplosiveShot')) and cooldown[classtable.ExplosiveShot].ready then
        if not setSpell then setSpell = classtable.ExplosiveShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.DireBeast, 'DireBeast')) and cooldown[classtable.DireBeast].ready then
        if not setSpell then setSpell = classtable.DireBeast end
    end
    if (MaxDps:CheckSpellUsable(classtable.CobraShot, 'CobraShot')) and (FocusTimeToMax <gcd * 2) and cooldown[classtable.CobraShot].ready then
        if not setSpell then setSpell = classtable.CobraShot end
    end
end
function BeastMastery:st()
    if (MaxDps:CheckSpellUsable(classtable.BarbedShot, 'BarbedShot')) and ((C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') ~= nil ) and (C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') and C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL').expirationTime or 0 ) <= gcd + barbed_shot_grace_period or (C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') and C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL').applications or 0 ) <3 and ( cooldown[classtable.BestialWrath].ready and ( not (C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') ~= nil ) or talents[classtable.ScentofBlood] ) or talents[classtable.CalloftheWild] and cooldown[classtable.CalloftheWild].ready )) and cooldown[classtable.BarbedShot].ready then
        if not setSpell then setSpell = classtable.BarbedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and (talents[classtable.CalloftheWild] and cooldown[classtable.CalloftheWild].remains <gcd + 0.25) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and (talents[classtable.VenomsBite] and ( not debuff[classtable.SerpentStingDeBuff].count  or debuff[classtable.SerpentStingDeBuff].refreshable )) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.CalloftheWild, 'CalloftheWild')) and cooldown[classtable.CalloftheWild].ready then
        MaxDps:GlowCooldown(classtable.CalloftheWild, cooldown[classtable.CalloftheWild].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodshed, 'Bloodshed')) and cooldown[classtable.Bloodshed].ready then
        if not setSpell then setSpell = classtable.Bloodshed end
    end
    if (MaxDps:CheckSpellUsable(classtable.BestialWrath, 'BestialWrath')) and cooldown[classtable.BestialWrath].ready then
        if not setSpell then setSpell = classtable.BestialWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and (cooldown[classtable.KillCommand].fullRecharge <1.25 * gcd) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.MultiShot, 'MultiShot')) and (buff[classtable.BeastCleaveBuff].remains <gcd * 1.25 and talents[classtable.BleakPowder] and ( buff[classtable.DeathblowBuff].up or ( cooldown[classtable.BlackArrow].remains <gcd and ( targetHP <20 or targetHP >81 ) ) )) and cooldown[classtable.MultiShot].ready then
        if not setSpell then setSpell = classtable.MultiShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.BlackArrow, 'BlackArrow')) and cooldown[classtable.BlackArrow].ready then
        if not setSpell then setSpell = classtable.BlackArrow end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillCommand, 'KillCommand')) and cooldown[classtable.KillCommand].ready then
        if not setSpell then setSpell = classtable.KillCommand end
    end
    if (MaxDps:CheckSpellUsable(classtable.DireBeast, 'DireBeast')) and cooldown[classtable.DireBeast].ready then
        if not setSpell then setSpell = classtable.DireBeast end
    end
    if (MaxDps:CheckSpellUsable(classtable.BarbedShot, 'BarbedShot')) and (talents[classtable.WildCall] and cooldown[classtable.BarbedShot].charges >1.4 or buff[classtable.CalloftheWildBuff].up or FocusTimeToMax <gcd and cooldown[classtable.BestialWrath].ready==false or talents[classtable.ScentofBlood] and ( cooldown[classtable.BestialWrath].remains <12 + gcd ) or talents[classtable.FuriousAssault] or talents[classtable.BlackArrow] and ( talents[classtable.BarbedScales] or talents[classtable.Savagery] ) or MaxDps:boss() and ttd <9) and cooldown[classtable.BarbedShot].ready then
        if not setSpell then setSpell = classtable.BarbedShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.CobraShot, 'CobraShot')) and (buff[classtable.BestialWrathBuff].up and talents[classtable.KillerCobra]) and cooldown[classtable.CobraShot].ready then
        if not setSpell then setSpell = classtable.CobraShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillShot, 'KillShot')) and cooldown[classtable.KillShot].ready then
        if not setSpell then setSpell = classtable.KillShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.CobraShot, 'CobraShot')) and cooldown[classtable.CobraShot].ready then
        if not setSpell then setSpell = classtable.CobraShot end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcanePulse, 'ArcanePulse')) and (not buff[classtable.BestialWrathBuff].up or ttd <5) and cooldown[classtable.ArcanePulse].ready then
        if not setSpell then setSpell = classtable.ArcanePulse end
    end
end
function BeastMastery:trinkets()
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.CounterShot, false)
    MaxDps:GlowCooldown(classtable.HuntersMark, false)
    MaxDps:GlowCooldown(classtable.CalloftheWild, false)
end

function BeastMastery:callaction()
    if (MaxDps:CheckSpellUsable(classtable.CounterShot, 'CounterShot')) and cooldown[classtable.CounterShot].ready then
        MaxDps:GlowCooldown(classtable.CounterShot, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    --if (MaxDps:CheckSpellUsable(classtable.TranquilizingShot, 'TranquilizingShot')) and cooldown[classtable.TranquilizingShot].ready then
    --    if not setSpell then setSpell = classtable.TranquilizingShot end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.MendPet, 'MendPet')) and cooldown[classtable.MendPet].ready then
    --    if not setSpell then setSpell = classtable.MendPet end
    --end
    if (MaxDps:CheckSpellUsable(classtable.HuntersMark, 'HuntersMark')) and (debuff[classtable.HuntersMarkDeBuff].count  == 0 and MaxDps:GetTimeToPct(80) >20) and cooldown[classtable.HuntersMark].ready then
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
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.BeastCleaveBuff = 268877
    classtable.CalloftheWildBuff = 361582
    classtable.BestialWrathBuff = 19574
    classtable.SerpentStingDeBuff = 271788
    classtable.DeathblowBuff = 378770
    classtable.HuntersMarkDeBuff = 257284
    setSpell = nil
    ClearCDs()

    BeastMastery:precombat()

    BeastMastery:callaction()
    if setSpell then return setSpell end
end
