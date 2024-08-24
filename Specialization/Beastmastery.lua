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

local BeastMastery = {}

local trinket_one_stronger
local trinket_two_stronger
local sync_ready
local sync_active
local sync_remains

local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnown(spell) then return false end
    if not C_Spell.IsSpellUsable(spell) then return false end
    local costs = C_Spell.GetSpellPowerCost(spell)
    if type(costs) ~= 'table' and spellstring then return true end
    for i,costtable in pairs(costs) do
        if UnitPower('player', costtable.type) < costtable.cost then
            return false
        end
    end
    return true
end
local function MaxGetSpellCost(spell,power)
    local costs = C_Spell.GetSpellPowerCost(spell)
    if type(costs) ~= 'table' then return 0 end
    for i,costtable in pairs(costs) do
        if costtable.name == power then
            return costtable.cost
        end
    end
    return 0
end



local function CheckTrinketNames(checkName)
    --if slot == 1 then
    --    slot = 13
    --end
    --if slot == 2 then
    --    slot = 14
    --end
    for i=13,14 do
        local itemID = GetInventoryItemID('player', i)
        local itemName = C_Item.GetItemInfo(itemID)
        if checkName == itemName then
            return true
        end
    end
    return false
end


local function CheckTrinketCooldown(slot)
    if slot == 1 then
        slot = 13
    end
    if slot == 2 then
        slot = 14
    end
    if slot == 13 or slot == 14 then
        local itemID = GetInventoryItemID('player', slot)
        local _, duration, _ = C_Item.GetItemCooldown(itemID)
        if duration == 0 then return true else return false end
    else
        local tOneitemID = GetInventoryItemID('player', 13)
        local tTwoitemID = GetInventoryItemID('player', 14)
        local tOneitemName = C_Item.GetItemInfo(tOneitemID)
        local tTwoitemName = C_Item.GetItemInfo(tTwoitemID)
        if tOneitemName == slot then
            local _, duration, _ = C_Item.GetItemCooldown(tOneitemID)
            if duration == 0 then return true else return false end
        end
        if tTwoitemName == slot then
            local _, duration, _ = C_Item.GetItemCooldown(tTwoitemID)
            if duration == 0 then return true else return false end
        end
    end
end




local function CheckPrevSpell(spell)
    if MaxDps and MaxDps.spellHistory then
        if MaxDps.spellHistory[1] then
            if MaxDps.spellHistory[1] == spell then
                return true
            end
            if MaxDps.spellHistory[1] ~= spell then
                return false
            end
        end
    end
    return true
end


local function boss()
    if UnitExists('boss1')
    or UnitExists('boss2')
    or UnitExists('boss3')
    or UnitExists('boss4')
    or UnitExists('boss5')
    or UnitExists('boss6')
    or UnitExists('boss7')
    or UnitExists('boss8')
    or UnitExists('boss9')
    or UnitExists('boss10') then
        return true
    end
    return false
end


function BeastMastery:precombat()
    if (CheckSpellCosts(classtable.HuntersMark, 'HuntersMark')) and (debuff[classtable.HuntersMarkDeBuff].count  == 0 and MaxDps:GetTimeToPct(80) >20) and cooldown[classtable.HuntersMark].ready then
        MaxDps:GlowCooldown(classtable.HuntersMark, cooldown[classtable.HuntersMark].ready)
    end
end
function BeastMastery:cds()
end
function BeastMastery:cleave()
    if (CheckSpellCosts(classtable.BarbedShot, 'BarbedShot')) and ((C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') ~= nil ) and (C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') and C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL').expirationTime or 0 ) <= gcd + 0.25 or (C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') and C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL').applications or 0 ) <3 and ( cooldown[classtable.BestialWrath].ready and ( not (C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') ~= nil ) or talents[classtable.ScentofBlood] ) or talents[classtable.CalloftheWild] and cooldown[classtable.CalloftheWild].ready )) and cooldown[classtable.BarbedShot].ready then
        return classtable.BarbedShot
    end
    if (CheckSpellCosts(classtable.BlackArrow, 'BlackArrow')) and cooldown[classtable.BlackArrow].ready then
        return classtable.BlackArrow
    end
    if (CheckSpellCosts(classtable.MultiShot, 'MultiShot')) and (buff[classtable.BeastCleaveBuff].remains <0.25 + gcd and ( not talents[classtable.BloodyFrenzy] or cooldown[classtable.CalloftheWild].ready==false )) and cooldown[classtable.MultiShot].ready then
        return classtable.MultiShot
    end
    if (CheckSpellCosts(classtable.DireBeast, 'DireBeast')) and cooldown[classtable.DireBeast].ready then
        return classtable.DireBeast
    end
    if (CheckSpellCosts(classtable.CalloftheWild, 'CalloftheWild')) and cooldown[classtable.CalloftheWild].ready then
        MaxDps:GlowCooldown(classtable.CalloftheWild, cooldown[classtable.CalloftheWild].ready)
    end
    if (CheckSpellCosts(classtable.BestialWrath, 'BestialWrath')) and cooldown[classtable.BestialWrath].ready then
        return classtable.BestialWrath
    end
    if (CheckSpellCosts(classtable.Bloodshed, 'Bloodshed')) and cooldown[classtable.Bloodshed].ready then
        return classtable.Bloodshed
    end
    if (CheckSpellCosts(classtable.KillCommand, 'KillCommand')) and cooldown[classtable.KillCommand].ready then
        return classtable.KillCommand
    end
    if (CheckSpellCosts(classtable.BarbedShot, 'BarbedShot')) and (buff[classtable.CalloftheWildBuff].up or boss and ttd <9 or talents[classtable.WildCall] and cooldown[classtable.BarbedShot].charges >1.2 or talents[classtable.Savagery]) and cooldown[classtable.BarbedShot].ready then
        return classtable.BarbedShot
    end
    if (CheckSpellCosts(classtable.ExplosiveShot, 'ExplosiveShot')) and cooldown[classtable.ExplosiveShot].ready then
        return classtable.ExplosiveShot
    end
    if (CheckSpellCosts(classtable.CobraShot, 'CobraShot')) and (buff[classtable.BestialWrathBuff].up and talents[classtable.KillerCobra]) and cooldown[classtable.CobraShot].ready then
        return classtable.CobraShot
    end
    if (CheckSpellCosts(classtable.KillShot, 'KillShot')) and (talents[classtable.VenomsBite] and debuff[classtable.SerpentStingDeBuff].refreshable) and cooldown[classtable.KillShot].ready then
        return classtable.KillShot
    end
    if (CheckSpellCosts(classtable.ExplosiveShot, 'ExplosiveShot')) and cooldown[classtable.ExplosiveShot].ready then
        return classtable.ExplosiveShot
    end
    if (CheckSpellCosts(classtable.CobraShot, 'CobraShot')) and cooldown[classtable.CobraShot].ready then
        return classtable.CobraShot
    end
end
function BeastMastery:st()
    if (CheckSpellCosts(classtable.BarbedShot, 'BarbedShot')) and ((C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') ~= nil ) and (C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') and C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL').expirationTime or 0 ) <= gcd + 0.25 or (C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') and C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL').applications or 0 ) <3 and ( cooldown[classtable.BestialWrath].ready and ( not (C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') ~= nil ) or talents[classtable.ScentofBlood] ) or talents[classtable.CalloftheWild] and cooldown[classtable.CalloftheWild].ready )) and cooldown[classtable.BarbedShot].ready then
        return classtable.BarbedShot
    end
    if (CheckSpellCosts(classtable.DireBeast, 'DireBeast')) and cooldown[classtable.DireBeast].ready then
        return classtable.DireBeast
    end
    if (CheckSpellCosts(classtable.KillCommand, 'KillCommand')) and (talents[classtable.CalloftheWild] and cooldown[classtable.CalloftheWild].remains <gcd + 0.25) and cooldown[classtable.KillCommand].ready then
        return classtable.KillCommand
    end
    if (CheckSpellCosts(classtable.BlackArrow, 'BlackArrow')) and cooldown[classtable.BlackArrow].ready then
        return classtable.BlackArrow
    end
    if (CheckSpellCosts(classtable.KillShot, 'KillShot')) and (talents[classtable.VenomsBite] and debuff[classtable.SerpentStingDeBuff].refreshable and talents[classtable.BlackArrow]) and cooldown[classtable.KillShot].ready then
        return classtable.KillShot
    end
    if (CheckSpellCosts(classtable.CalloftheWild, 'CalloftheWild')) and cooldown[classtable.CalloftheWild].ready then
        MaxDps:GlowCooldown(classtable.CalloftheWild, cooldown[classtable.CalloftheWild].ready)
    end
    if (CheckSpellCosts(classtable.Bloodshed, 'Bloodshed')) and cooldown[classtable.Bloodshed].ready then
        return classtable.Bloodshed
    end
    if (CheckSpellCosts(classtable.BestialWrath, 'BestialWrath')) and cooldown[classtable.BestialWrath].ready then
        return classtable.BestialWrath
    end
    if (CheckSpellCosts(classtable.KillCommand, 'KillCommand')) and cooldown[classtable.KillCommand].ready then
        return classtable.KillCommand
    end
    if (CheckSpellCosts(classtable.KillShot, 'KillShot')) and (talents[classtable.VenomsBite] and debuff[classtable.SerpentStingDeBuff].refreshable and talents[classtable.CulltheHerd]) and cooldown[classtable.KillShot].ready then
        return classtable.KillShot
    end
    if (CheckSpellCosts(classtable.BarbedShot, 'BarbedShot')) and (talents[classtable.WildCall] and cooldown[classtable.BarbedShot].charges >1.4 or buff[classtable.CalloftheWildBuff].up or FocusTimeToMax <gcd and cooldown[classtable.BestialWrath].ready==false or talents[classtable.ScentofBlood] and ( cooldown[classtable.BestialWrath].remains <12 + gcd ) or talents[classtable.Savagery] or boss and ttd <9) and cooldown[classtable.BarbedShot].ready then
        return classtable.BarbedShot
    end
    if (CheckSpellCosts(classtable.CobraShot, 'CobraShot')) and (buff[classtable.BestialWrathBuff].up and talents[classtable.KillerCobra]) and cooldown[classtable.CobraShot].ready then
        return classtable.CobraShot
    end
    if (CheckSpellCosts(classtable.ExplosiveShot, 'ExplosiveShot')) and (not buff[classtable.BestialWrathBuff].up and talents[classtable.KillerCobra] or not talents[classtable.KillerCobra]) and cooldown[classtable.ExplosiveShot].ready then
        return classtable.ExplosiveShot
    end
    if (CheckSpellCosts(classtable.KillShot, 'KillShot')) and cooldown[classtable.KillShot].ready then
        return classtable.KillShot
    end
    if (CheckSpellCosts(classtable.CobraShot, 'CobraShot')) and cooldown[classtable.CobraShot].ready then
        return classtable.CobraShot
    end
    if (CheckSpellCosts(classtable.ArcanePulse, 'ArcanePulse')) and (not buff[classtable.BestialWrathBuff].up or ttd <5) and cooldown[classtable.ArcanePulse].ready then
        return classtable.ArcanePulse
    end
end
function BeastMastery:trinkets()
end

function BeastMastery:callaction()
    if (CheckSpellCosts(classtable.CounterShot, 'CounterShot')) and cooldown[classtable.CounterShot].ready then
        MaxDps:GlowCooldown(classtable.CounterShot, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    --if (CheckSpellCosts(classtable.TranquilizingShot, 'TranquilizingShot')) and cooldown[classtable.TranquilizingShot].ready then
    --    return classtable.TranquilizingShot
    --end
    local cdsCheck = BeastMastery:cds()
    if cdsCheck then
        return cdsCheck
    end
    local trinketsCheck = BeastMastery:trinkets()
    if trinketsCheck then
        return trinketsCheck
    end
    if (CheckSpellCosts(classtable.HuntersMark, 'HuntersMark')) and (debuff[classtable.HuntersMarkDeBuff].count  == 0 and MaxDps:GetTimeToPct(80) >20) and cooldown[classtable.HuntersMark].ready then
        MaxDps:GlowCooldown(classtable.HuntersMark, cooldown[classtable.HuntersMark].ready)
    end
    if (targets <2 or not talents[classtable.BeastCleave] and targets <3) then
        local stCheck = BeastMastery:st()
        if stCheck then
            return BeastMastery:st()
        end
    end
    if (targets >2 or talents[classtable.BeastCleave] and targets >1) then
        local cleaveCheck = BeastMastery:cleave()
        if cleaveCheck then
            return BeastMastery:cleave()
        end
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
    for spellId in pairs(MaxDps.Flags) do
        self.Flags[spellId] = false
        self:ClearGlowIndependent(spellId, spellId)
    end
    classtable.HuntersMarkDeBuff = 257284
    classtable.BeastCleaveBuff = 268877
    classtable.CalloftheWildBuff = 361582
    classtable.BestialWrathBuff = 19574
    classtable.SerpentStingDeBuff = 271788

    local precombatCheck = BeastMastery:precombat()
    if precombatCheck then
        return BeastMastery:precombat()
    end

    local callactionCheck = BeastMastery:callaction()
    if callactionCheck then
        return BeastMastery:callaction()
    end
end
