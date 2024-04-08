local _, addonTable = ...
local Hunter = addonTable.Hunter
local MaxDps = _G.MaxDps
if not MaxDps then return end

local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = UnitAura
local GetSpellDescription = GetSpellDescription
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local SpellHaste
local SpellCrit

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

local Focus
local FocusMax
local FocusDeficit

local Beast_mastery = {}

local trinket_1_stronger
local trinket_2_stronger
local cotw_ready
local sync_ready
local sync_active
local sync_remains

local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnownOrOverridesKnown(spell) then return false end
    if spellstring == 'TouchofDeath' then
        if targethealthPerc < 15 then
            return true
        else
            return false
        end
    end
    if spellstring == 'KillShot' then
        if targethealthPerc < 20 then
            return true
        else
            return false
        end
    end
    local costs = GetSpellPowerCost(spell)
    if type(costs) ~= 'table' and spellstring then print('no cost found for ',spellstring) return true end
    for i,costtable in pairs(costs) do
        if UnitPower('player', costtable.type) < costtable.cost then
            return false
        end
    end
    return true
end



local function CheckEquipped(checkName)
    for i=1,14 do
        local itemID = GetInventoryItemID('player', i)
        local itemName = itemID and C_Item.GetItemInfo(itemID) or ''
        if checkName == itemName then
            return true
        end
    end
    return false
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


function Beast_mastery:precombat()
    --if (MaxDps:FindSpell(classtable.Flask) and CheckSpellCosts(classtable.Flask, 'Flask')) and cooldown[classtable.Flask].ready then
    --    return classtable.Flask
    --end
    --if (MaxDps:FindSpell(classtable.Augmentation) and CheckSpellCosts(classtable.Augmentation, 'Augmentation')) and cooldown[classtable.Augmentation].ready then
    --    return classtable.Augmentation
    --end
    --if (MaxDps:FindSpell(classtable.Food) and CheckSpellCosts(classtable.Food, 'Food')) and cooldown[classtable.Food].ready then
    --    return classtable.Food
    --end
    --if (MaxDps:FindSpell(classtable.SummonPet) and CheckSpellCosts(classtable.SummonPet, 'SummonPet')) and cooldown[classtable.SummonPet].ready then
    --    return classtable.SummonPet
    --end
    --if (MaxDps:FindSpell(classtable.SnapshotStats) and CheckSpellCosts(classtable.SnapshotStats, 'SnapshotStats')) and cooldown[classtable.SnapshotStats].ready then
    --    return classtable.SnapshotStats
    --end
    --trinket_1_stronger = not trinket.2.has_cooldown or trinket.1.has_use_buff and ( not trinket.2.has_use_buff or not CheckTrinketNames('Mirror of Fractured Tomorrows') and ( CheckTrinketNames('Mirror of Fractured Tomorrows') or trinket.2.cooldown.duration <trinket.1.cooldown.duration or trinket.2.cast_time <trinket.1.cast_time or trinket.2.cast_time == trinket.1.cast_time and trinket.2.cooldown.duration == trinket.1.cooldown.duration ) ) or not trinket.1.has_use_buff and ( not trinket.2.has_use_buff and ( trinket.2.cooldown.duration <trinket.1.cooldown.duration or trinket.2.cast_time <trinket.1.cast_time or trinket.2.cast_time == trinket.1.cast_time and trinket.2.cooldown.duration == trinket.1.cooldown.duration ) )
    --trinket_2_stronger = not trinket_1_stronger
    --if (MaxDps:FindSpell(classtable.SteelTrap) and CheckSpellCosts(classtable.SteelTrap, 'SteelTrap')) and (not talents[classtable.WailingArrow] and talents[classtable.SteelTrap]) and cooldown[classtable.SteelTrap].ready then
    --    return classtable.SteelTrap
    --end
end
function Beast_mastery:cds()
    --if (MaxDps:FindSpell(classtable.Potion) and CheckSpellCosts(classtable.Potion, 'Potion')) and (buff[classtable.CalloftheWildBuff].up or not talents[classtable.CalloftheWild] and buff[classtable.BestialWrathBuff].up or ttd <31) and cooldown[classtable.Potion].ready then
    --    return classtable.Potion
    --end
end
function Beast_mastery:cleave()
    if (MaxDps:FindSpell(classtable.BarbedShot) and CheckSpellCosts(classtable.BarbedShot, 'BarbedShot')) and (debuff[classtable.LatentPoisonDeBuff].count >9 and ( (C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') ~= nil ) and (C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') and C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL').expirationTime or 0 ) <= gcd + 0.25 or talents[classtable.ScentofBlood] and cooldown[classtable.BestialWrath].remains <12 + gcd or (C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') and C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL').applications or 0 ) <3 and ( cooldown[classtable.BestialWrath].ready or cooldown[classtable.CalloftheWild].ready ) )) and cooldown[classtable.BarbedShot].ready then
        return classtable.BarbedShot
    end
    if (MaxDps:FindSpell(classtable.BarbedShot) and CheckSpellCosts(classtable.BarbedShot, 'BarbedShot')) and ((C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') ~= nil ) and (C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') and C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL').expirationTime or 0 ) <= gcd + 0.25 or talents[classtable.ScentofBlood] and cooldown[classtable.BestialWrath].remains <12 + gcd or (C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') and C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL').applications or 0 ) <3 and ( cooldown[classtable.BestialWrath].ready or cooldown[classtable.CalloftheWild].ready ) ) and cooldown[classtable.BarbedShot].ready then
        return classtable.BarbedShot
    end
    if (MaxDps:FindSpell(classtable.Multishot) and CheckSpellCosts(classtable.Multishot, 'Multishot')) and ((C_UnitAuras.GetAuraDataBySpellName('Beast Cleave', 'pet', 'HELPFUL') and C_UnitAuras.GetAuraDataBySpellName('Beast Cleave', 'pet', 'HELPFUL').expirationTime or 0 ) <0.25 + gcd and ( not talents[classtable.BloodyFrenzy] or cooldown[classtable.CalloftheWild].remains )) and cooldown[classtable.Multishot].ready then
        return classtable.Multishot
    end
    if (MaxDps:FindSpell(classtable.BestialWrath) and CheckSpellCosts(classtable.BestialWrath, 'BestialWrath')) and cooldown[classtable.BestialWrath].ready then
        return classtable.BestialWrath
    end
    if (MaxDps:FindSpell(classtable.CalloftheWild) and CheckSpellCosts(classtable.CalloftheWild, 'CalloftheWild')) and (cotw_ready) and cooldown[classtable.CalloftheWild].ready then
        return classtable.CalloftheWild
    end
    if (MaxDps:FindSpell(classtable.KillCommand) and CheckSpellCosts(classtable.KillCommand, 'KillCommand')) and (talents[classtable.KillCleave]) and cooldown[classtable.KillCommand].ready then
        return classtable.KillCommand
    end
    if (MaxDps:FindSpell(classtable.ExplosiveShot) and CheckSpellCosts(classtable.ExplosiveShot, 'ExplosiveShot')) and cooldown[classtable.ExplosiveShot].ready then
        return classtable.ExplosiveShot
    end
    if (MaxDps:FindSpell(classtable.Stampede) and CheckSpellCosts(classtable.Stampede, 'Stampede')) and cooldown[classtable.Stampede].ready then
        return classtable.Stampede
    end
    if (MaxDps:FindSpell(classtable.Bloodshed) and CheckSpellCosts(classtable.Bloodshed, 'Bloodshed')) and cooldown[classtable.Bloodshed].ready then
        return classtable.Bloodshed
    end
    if (MaxDps:FindSpell(classtable.DeathChakram) and CheckSpellCosts(classtable.DeathChakram, 'DeathChakram')) and cooldown[classtable.DeathChakram].ready then
        return classtable.DeathChakram
    end
    if (MaxDps:FindSpell(classtable.SteelTrap) and CheckSpellCosts(classtable.SteelTrap, 'SteelTrap')) and cooldown[classtable.SteelTrap].ready then
        return classtable.SteelTrap
    end
    if (MaxDps:FindSpell(classtable.AMurderofCrows) and CheckSpellCosts(classtable.AMurderofCrows, 'AMurderofCrows')) and cooldown[classtable.AMurderofCrows].ready then
        return classtable.AMurderofCrows
    end
    if (MaxDps:FindSpell(classtable.BarbedShot) and CheckSpellCosts(classtable.BarbedShot, 'BarbedShot')) and (debuff[classtable.LatentPoisonDeBuff].count >9 and ( buff[classtable.CalloftheWildBuff].up or ttd <9 or talents[classtable.WildCall] and cooldown[classtable.BarbedShot].charges >1.2 or talents[classtable.Savagery] )) and cooldown[classtable.BarbedShot].ready then
        return classtable.BarbedShot
    end
    if (MaxDps:FindSpell(classtable.BarbedShot) and CheckSpellCosts(classtable.BarbedShot, 'BarbedShot')) and (buff[classtable.CalloftheWildBuff].up or ttd <9 or talents[classtable.WildCall] and cooldown[classtable.BarbedShot].charges >1.2 or talents[classtable.Savagery]) and cooldown[classtable.BarbedShot].ready then
        return classtable.BarbedShot
    end
    if (MaxDps:FindSpell(classtable.KillCommand) and CheckSpellCosts(classtable.KillCommand, 'KillCommand')) and cooldown[classtable.KillCommand].ready then
        return classtable.KillCommand
    end
    if (MaxDps:FindSpell(classtable.DireBeast) and CheckSpellCosts(classtable.DireBeast, 'DireBeast')) and cooldown[classtable.DireBeast].ready then
        return classtable.DireBeast
    end
    if (MaxDps:FindSpell(classtable.SerpentSting) and CheckSpellCosts(classtable.SerpentSting, 'SerpentSting')) and (debuff[classtable.SerpentSting].refreshable and ttd >( select(4,GetSpellInfo(classtable.SerpentSting)) /1000 )) and cooldown[classtable.SerpentSting].ready then
        return classtable.SerpentSting
    end
    if (MaxDps:FindSpell(classtable.Barrage) and CheckSpellCosts(classtable.Barrage, 'Barrage')) and ((C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') and C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL').expirationTime or 0 ) >MaxDps:GetTimeToPct(30)) and cooldown[classtable.Barrage].ready then
        return classtable.Barrage
    end
    if (MaxDps:FindSpell(classtable.Multishot) and CheckSpellCosts(classtable.Multishot, 'Multishot')) and ((C_UnitAuras.GetAuraDataBySpellName('Beast Cleave', 'pet', 'HELPFUL') and C_UnitAuras.GetAuraDataBySpellName('Beast Cleave', 'pet', 'HELPFUL').expirationTime or 0 ) <gcd * 2) and cooldown[classtable.Multishot].ready then
        return classtable.Multishot
    end
    if (MaxDps:FindSpell(classtable.KillShot) and CheckSpellCosts(classtable.KillShot, 'KillShot')) and cooldown[classtable.KillShot].ready then
        return classtable.KillShot
    end
    if (MaxDps:FindSpell(classtable.CobraShot) and CheckSpellCosts(classtable.CobraShot, 'CobraShot')) and (FocusTimeToMax <gcd * 2) and cooldown[classtable.CobraShot].ready then
        return classtable.CobraShot
    end
    if (MaxDps:FindSpell(classtable.WailingArrow) and CheckSpellCosts(classtable.WailingArrow, 'WailingArrow')) and ((C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') and C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL').expirationTime or 0 ) >MaxDps:GetTimeToPct(30) or ttd <5) and cooldown[classtable.WailingArrow].ready then
        return classtable.WailingArrow
    end
end
function Beast_mastery:st()
    if (MaxDps:FindSpell(classtable.BarbedShot) and CheckSpellCosts(classtable.BarbedShot, 'BarbedShot')) and ((C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') ~= nil ) and (C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') and C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL').expirationTime or 0 ) <= gcd + 0.25 or talents[classtable.ScentofBlood] and (C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') and C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL').applications or 0 ) <3 and ( cooldown[classtable.BestialWrath].ready or cooldown[classtable.CalloftheWild].ready )) and cooldown[classtable.BarbedShot].ready then
        return classtable.BarbedShot
    end
    if (MaxDps:FindSpell(classtable.KillCommand) and CheckSpellCosts(classtable.KillCommand, 'KillCommand')) and (not talents[classtable.WildInstincts] and talents[classtable.AlphaPredator]) and cooldown[classtable.KillCommand].ready then
        return classtable.KillCommand
    end
    if (MaxDps:FindSpell(classtable.CalloftheWild) and CheckSpellCosts(classtable.CalloftheWild, 'CalloftheWild')) and (not talents[classtable.WildInstincts] and cotw_ready) and cooldown[classtable.CalloftheWild].ready then
        return classtable.CalloftheWild
    end
    if (MaxDps:FindSpell(classtable.Stampede) and CheckSpellCosts(classtable.Stampede, 'Stampede')) and cooldown[classtable.Stampede].ready then
        return classtable.Stampede
    end
    if (MaxDps:FindSpell(classtable.Bloodshed) and CheckSpellCosts(classtable.Bloodshed, 'Bloodshed')) and cooldown[classtable.Bloodshed].ready then
        return classtable.Bloodshed
    end
    if (MaxDps:FindSpell(classtable.BestialWrath) and CheckSpellCosts(classtable.BestialWrath, 'BestialWrath')) and cooldown[classtable.BestialWrath].ready then
        return classtable.BestialWrath
    end
    if (MaxDps:FindSpell(classtable.DeathChakram) and CheckSpellCosts(classtable.DeathChakram, 'DeathChakram')) and cooldown[classtable.DeathChakram].ready then
        return classtable.DeathChakram
    end
    if (MaxDps:FindSpell(classtable.CalloftheWild) and CheckSpellCosts(classtable.CalloftheWild, 'CalloftheWild')) and (cotw_ready) and cooldown[classtable.CalloftheWild].ready then
        return classtable.CalloftheWild
    end
    if (MaxDps:FindSpell(classtable.KillCommand) and CheckSpellCosts(classtable.KillCommand, 'KillCommand')) and cooldown[classtable.KillCommand].ready then
        return classtable.KillCommand
    end
    if (MaxDps:FindSpell(classtable.AMurderofCrows) and CheckSpellCosts(classtable.AMurderofCrows, 'AMurderofCrows')) and cooldown[classtable.AMurderofCrows].ready then
        return classtable.AMurderofCrows
    end
    if (MaxDps:FindSpell(classtable.SteelTrap) and CheckSpellCosts(classtable.SteelTrap, 'SteelTrap')) and cooldown[classtable.SteelTrap].ready then
        return classtable.SteelTrap
    end
    if (MaxDps:FindSpell(classtable.ExplosiveShot) and CheckSpellCosts(classtable.ExplosiveShot, 'ExplosiveShot')) and cooldown[classtable.ExplosiveShot].ready then
        return classtable.ExplosiveShot
    end
    if (MaxDps:FindSpell(classtable.BarbedShot) and CheckSpellCosts(classtable.BarbedShot, 'BarbedShot')) and (talents[classtable.WildCall] and cooldown[classtable.BarbedShot].charges >1.4 or buff[classtable.CalloftheWildBuff].up or talents[classtable.ScentofBlood] and ( cooldown[classtable.BestialWrath].remains <12 + gcd ) or talents[classtable.Savagery] or ttd <9) and cooldown[classtable.BarbedShot].ready then
        return classtable.BarbedShot
    end
    if (MaxDps:FindSpell(classtable.DireBeast) and CheckSpellCosts(classtable.DireBeast, 'DireBeast')) and cooldown[classtable.DireBeast].ready then
        return classtable.DireBeast
    end
    if (MaxDps:FindSpell(classtable.SerpentSting) and CheckSpellCosts(classtable.SerpentSting, 'SerpentSting')) and (debuff[classtable.SerpentSting].refreshable and ttd >( select(4,GetSpellInfo(classtable.SerpentSting)) /1000 )) and cooldown[classtable.SerpentSting].ready then
        return classtable.SerpentSting
    end
    if (MaxDps:FindSpell(classtable.KillShot) and CheckSpellCosts(classtable.KillShot, 'KillShot')) and cooldown[classtable.KillShot].ready then
        return classtable.KillShot
    end
    if (MaxDps:FindSpell(classtable.CobraShot) and CheckSpellCosts(classtable.CobraShot, 'CobraShot')) and cooldown[classtable.CobraShot].ready then
        return classtable.CobraShot
    end
    if (MaxDps:FindSpell(classtable.WailingArrow) and CheckSpellCosts(classtable.WailingArrow, 'WailingArrow')) and ((C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL') and C_UnitAuras.GetAuraDataBySpellName('Frenzy', 'pet', 'HELPFUL').expirationTime or 0 ) >MaxDps:GetTimeToPct(30) or ttd <5) and cooldown[classtable.WailingArrow].ready then
        return classtable.WailingArrow
    end
    if (MaxDps:FindSpell(classtable.ArcanePulse) and CheckSpellCosts(classtable.ArcanePulse, 'ArcanePulse')) and (not buff[classtable.BestialWrathBuff].up or ttd <5) and cooldown[classtable.ArcanePulse].ready then
        return classtable.ArcanePulse
    end
end
local function trinkets()
end

function Hunter:BeastMastery()
    fd = MaxDps.FrameData
    ttd = (fd.timeToDie and fd.timeToDie) or 500
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
    SpellHaste = UnitSpellHaste('target')
    SpellCrit = GetCritChance()
    Focus = UnitPower('player', FocusPT)
    FocusMax = UnitPowerMax('player', FocusPT)
    FocusDeficit = FocusMax - Focus
    Focus = UnitPower('player', FocusPT)
    FocusMax = UnitPowerMax('player', FocusPT)
    FocusDeficit = FocusMax - Focus
    FocusRegen = GetPowerRegenForPowerType(Enum.PowerType.Focus)
    FocusTimeToMax = FocusDeficit / FocusRegen
    FocusPerc = (Focus / FocusMax) * 100
    classtable.CalloftheWildBuff = 361582
    classtable.BestialWrathBuff = 19574
    classtable.LatentPoisonDeBuff = 273283

    cotw_ready = true --targets <2 and ( ( not trinket.1.has_use_buff or CheckTrinketCooldown('1') >30 or trinket.1.cooldown.ready or CheckTrinketCooldown('1') + cooldown[classtable.CalloftheWild].duration + 15 >ttd ) and ( not trinket.2.has_use_buff or CheckTrinketCooldown('2') >30 or trinket.2.cooldown.ready or CheckTrinketCooldown('2') + cooldown[classtable.CalloftheWild].duration + 15 >ttd ) or ttd <cooldown[classtable.CalloftheWild].duration + 20 ) or targets >1 and ( not targets >1 and ( TODO + TODO <25 or TODO ) or targets >1 and TODO ) or ttd <25
    if (MaxDps:FindSpell(classtable.AutoShot) and CheckSpellCosts(classtable.AutoShot, 'AutoShot')) and cooldown[classtable.AutoShot].ready then
        return classtable.AutoShot
    end
    local cdsCheck = Beast_mastery:cds()
    if cdsCheck then
        return cdsCheck
    end
    --local trinketsCheck = Beast_mastery:trinkets()
    --if trinketsCheck then
    --    return trinketsCheck
    --end
    if (targets <2 or not talents[classtable.BeastCleave] and targets <3) then
        local stCheck = Beast_mastery:st()
        if stCheck then
            return Beast_mastery:st()
        end
    end
    if (targets >2 or talents[classtable.BeastCleave] and targets >1) then
        local cleaveCheck = Beast_mastery:cleave()
        if cleaveCheck then
            return Beast_mastery:cleave()
        end
    end

end
