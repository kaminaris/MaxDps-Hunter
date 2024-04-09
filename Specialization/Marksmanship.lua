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

local Focus
local FocusMax
local FocusDeficit

local Marksmanship = {}

local trinket_1_stronger
local trinket_2_stronger
local trueshot_ready
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
        if targethealthPerc < 15 or buff[classtable.DeathblowBuff].up then
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
local function MaxGetSpellCost(spell,power)
    local costs = GetSpellPowerCost(spell)
    if type(costs) ~= 'table' then return 0 end
    for i,costtable in pairs(costs) do
        if costtable.name == power then
            return costtable.cost
        end
    end
    return 0
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
    if (MaxDps:FindSpell(classtable.Flask) and CheckSpellCosts(classtable.Flask, 'Flask')) and cooldown[classtable.Flask].ready then
        return classtable.Flask
    end
    if (MaxDps:FindSpell(classtable.Augmentation) and CheckSpellCosts(classtable.Augmentation, 'Augmentation')) and cooldown[classtable.Augmentation].ready then
        return classtable.Augmentation
    end
    if (MaxDps:FindSpell(classtable.Food) and CheckSpellCosts(classtable.Food, 'Food')) and cooldown[classtable.Food].ready then
        return classtable.Food
    end
    if (MaxDps:FindSpell(classtable.SummonPet) and CheckSpellCosts(classtable.SummonPet, 'SummonPet')) and (not talents[classtable.LoneWolf]) and cooldown[classtable.SummonPet].ready then
        return classtable.SummonPet
    end
    if (MaxDps:FindSpell(classtable.SnapshotStats) and CheckSpellCosts(classtable.SnapshotStats, 'SnapshotStats')) and cooldown[classtable.SnapshotStats].ready then
        return classtable.SnapshotStats
    end
    --trinket_1_stronger = not trinket.2.has_cooldown or trinket.1.has_use_buff and ( not trinket.2.has_use_buff or not CheckTrinketNames('Mirror of Fractured Tomorrows') and ( CheckTrinketNames('Mirror of Fractured Tomorrows') or trinket.2.cooldown.duration <trinket.1.cooldown.duration or trinket.2.cast_time <trinket.1.cast_time or trinket.2.cast_time == trinket.1.cast_time and trinket.2.cooldown.duration == trinket.1.cooldown.duration ) ) or not trinket.1.has_use_buff and ( not trinket.2.has_use_buff and ( trinket.2.cooldown.duration <trinket.1.cooldown.duration or trinket.2.cast_time <trinket.1.cast_time or trinket.2.cast_time == trinket.1.cast_time and trinket.2.cooldown.duration == trinket.1.cooldown.duration ) )
    --trinket_2_stronger = not trinket_1_stronger
    if (MaxDps:FindSpell(classtable.Salvo) and CheckSpellCosts(classtable.Salvo, 'Salvo')) and cooldown[classtable.Salvo].ready then
        return classtable.Salvo
    end
    if (MaxDps:FindSpell(classtable.AimedShot) and CheckSpellCosts(classtable.AimedShot, 'AimedShot')) and (targets <3 and ( not talents[classtable.Volley] or targets <2 )) and cooldown[classtable.AimedShot].ready then
        return classtable.AimedShot
    end
    if (MaxDps:FindSpell(classtable.WailingArrow) and CheckSpellCosts(classtable.WailingArrow, 'WailingArrow')) and (targets >2 or not talents[classtable.SteadyFocus]) and cooldown[classtable.WailingArrow].ready then
        return classtable.WailingArrow
    end
    if (MaxDps:FindSpell(classtable.SteadyShot) and CheckSpellCosts(classtable.SteadyShot, 'SteadyShot')) and (targets >2 or talents[classtable.Volley] and targets == 2) and cooldown[classtable.SteadyShot].ready then
        return classtable.SteadyShot
    end
end
function Marksmanship:cds()
    if (MaxDps:FindSpell(classtable.Potion) and CheckSpellCosts(classtable.Potion, 'Potion')) and (buff[classtable.TrueshotBuff].up and ( MaxDps:Bloodlust() or targetHP <20 ) or ttd <26) and cooldown[classtable.Potion].ready then
        return classtable.Potion
    end
    if (MaxDps:FindSpell(classtable.Salvo) and CheckSpellCosts(classtable.Salvo, 'Salvo')) and (targets >2 or cooldown[classtable.Volley].remains <10) and cooldown[classtable.Salvo].ready then
        return classtable.Salvo
    end
end
function Marksmanship:st()
    if (MaxDps:FindSpell(classtable.SteadyShot) and CheckSpellCosts(classtable.SteadyShot, 'SteadyShot')) and (talents[classtable.SteadyFocus] and SteadyFocusTrack() and ( buff[classtable.SteadyFocusBuff].remains <8 or not buff[classtable.SteadyFocusBuff].up and not buff[classtable.TrueshotBuff].up )) and cooldown[classtable.SteadyShot].ready then
        return classtable.SteadyShot
    end
    if (MaxDps:FindSpell(classtable.RapidFire) and CheckSpellCosts(classtable.RapidFire, 'RapidFire')) and (buff[classtable.TrickShotsBuff].remains <timeShift) and cooldown[classtable.RapidFire].ready then
        return classtable.RapidFire
    end
    if (MaxDps:FindSpell(classtable.KillShot) and CheckSpellCosts(classtable.KillShot, 'KillShot')) and (Focus + FocusRegen <FocusMax) and cooldown[classtable.KillShot].ready then
        return classtable.KillShot
    end
    if (MaxDps:FindSpell(classtable.Volley) and CheckSpellCosts(classtable.Volley, 'Volley')) and (buff[classtable.SalvoBuff].up or trueshot_ready or cooldown[classtable.Trueshot].remains >45 or ttd <12) and cooldown[classtable.Volley].ready then
        return classtable.Volley
    end
    if (MaxDps:FindSpell(classtable.SerpentSting) and CheckSpellCosts(classtable.SerpentSting, 'SerpentSting')) and (debuff[classtable.SerpentSting].refreshable and not talents[classtable.SerpentstalkersTrickery] and not buff[classtable.TrueshotBuff].up) and cooldown[classtable.SerpentSting].ready then
        return classtable.SerpentSting
    end
    if (MaxDps:FindSpell(classtable.ExplosiveShot) and CheckSpellCosts(classtable.ExplosiveShot, 'ExplosiveShot')) and cooldown[classtable.ExplosiveShot].ready then
        return classtable.ExplosiveShot
    end
    if (MaxDps:FindSpell(classtable.Stampede) and CheckSpellCosts(classtable.Stampede, 'Stampede')) and cooldown[classtable.Stampede].ready then
        return classtable.Stampede
    end
    if (MaxDps:FindSpell(classtable.DeathChakram) and CheckSpellCosts(classtable.DeathChakram, 'DeathChakram')) and cooldown[classtable.DeathChakram].ready then
        return classtable.DeathChakram
    end
    if (MaxDps:FindSpell(classtable.WailingArrow) and CheckSpellCosts(classtable.WailingArrow, 'WailingArrow')) and (targets >1) and cooldown[classtable.WailingArrow].ready then
        return classtable.WailingArrow
    end
    if (MaxDps:FindSpell(classtable.RapidFire) and CheckSpellCosts(classtable.RapidFire, 'RapidFire')) and (( talents[classtable.SurgingShots] or cooldown[classtable.AimedShot].fullRecharge >( select(4,GetSpellInfo(classtable.AimedShot)) / 1000 ) + ( select(4,GetSpellInfo(classtable.RapidFire)) /1000) ) and ( Focus + FocusRegen <FocusMax )) and cooldown[classtable.RapidFire].ready then
        return classtable.RapidFire
    end
    if (MaxDps:FindSpell(classtable.Trueshot) and CheckSpellCosts(classtable.Trueshot, 'Trueshot')) and (trueshot_ready) and cooldown[classtable.Trueshot].ready then
        return classtable.Trueshot
    end
    if (MaxDps:FindSpell(classtable.MultiShot) and CheckSpellCosts(classtable.MultiShot, 'Multishot')) and (buff[classtable.SalvoBuff].up and not talents[classtable.Volley]) and cooldown[classtable.MultiShot].ready then
        return classtable.MultiShot
    end
    if (MaxDps:FindSpell(classtable.AimedShot) and CheckSpellCosts(classtable.AimedShot, 'AimedShot')) and (talents[classtable.SerpentstalkersTrickery] and ( not buff[classtable.PreciseShotsBuff].up or ( buff[classtable.TrueshotBuff].up ) and ( not talents[classtable.ChimaeraShot] or targets <2 or (targethealthPerc >70) ) or buff[classtable.TrickShotsBuff].remains >timeShift and targets >1 )) and cooldown[classtable.AimedShot].ready then
        return classtable.AimedShot
    end
    if (MaxDps:FindSpell(classtable.AimedShot) and CheckSpellCosts(classtable.AimedShot, 'AimedShot')) and (not buff[classtable.PreciseShotsBuff].up or ( buff[classtable.TrueshotBuff].up ) and ( not talents[classtable.ChimaeraShot] or targets <2 or (targethealthPerc >70) ) or buff[classtable.TrickShotsBuff].remains >timeShift and targets >1) and cooldown[classtable.AimedShot].ready then
        return classtable.AimedShot
    end
    if (MaxDps:FindSpell(classtable.WailingArrow) and CheckSpellCosts(classtable.WailingArrow, 'WailingArrow')) and (not buff[classtable.TrueshotBuff].up) and cooldown[classtable.WailingArrow].ready then
        return classtable.WailingArrow
    end
    if (MaxDps:FindSpell(classtable.KillCommand) and CheckSpellCosts(classtable.KillCommand, 'KillCommand')) and (not buff[classtable.TrueshotBuff].up) and cooldown[classtable.KillCommand].ready then
        return classtable.KillCommand
    end
    if (MaxDps:FindSpell(classtable.SteelTrap) and CheckSpellCosts(classtable.SteelTrap, 'SteelTrap')) and cooldown[classtable.SteelTrap].ready then
        return classtable.SteelTrap
    end
    if (MaxDps:FindSpell(classtable.ChimaeraShot) and CheckSpellCosts(classtable.ChimaeraShot, 'ChimaeraShot')) and (buff[classtable.PreciseShotsBuff].up or Focus >(MaxGetSpellCost(classtable.ChimaeraShot,'FOCUS')) + MaxGetSpellCost(classtable.AimedShot, 'FOCUS')) and cooldown[classtable.ChimaeraShot].ready then
        return classtable.ChimaeraShot
    end
    if (MaxDps:FindSpell(classtable.ArcaneShot) and CheckSpellCosts(classtable.ArcaneShot, 'ArcaneShot')) and (buff[classtable.PreciseShotsBuff].up or Focus >(MaxGetSpellCost(classtable.ArcaneShot,'FOCUS')) + MaxGetSpellCost(classtable.AimedShot, 'FOCUS')) and cooldown[classtable.ArcaneShot].ready then
        return classtable.ArcaneShot
    end
    if (MaxDps:FindSpell(classtable.SteadyShot) and CheckSpellCosts(classtable.SteadyShot, 'SteadyShot')) and cooldown[classtable.SteadyShot].ready then
        return classtable.SteadyShot
    end
end
function Marksmanship:trickshots()
    if (MaxDps:FindSpell(classtable.SteadyShot) and CheckSpellCosts(classtable.SteadyShot, 'SteadyShot')) and (talents[classtable.SteadyFocus] and SteadyFocusTrack() and buff[classtable.SteadyFocusBuff].remains <8) and cooldown[classtable.SteadyShot].ready then
        return classtable.SteadyShot
    end
    if (MaxDps:FindSpell(classtable.KillShot) and CheckSpellCosts(classtable.KillShot, 'KillShot')) and (buff[classtable.RazorFragmentsBuff].up) and cooldown[classtable.KillShot].ready then
        return classtable.KillShot
    end
    if (MaxDps:FindSpell(classtable.ExplosiveShot) and CheckSpellCosts(classtable.ExplosiveShot, 'ExplosiveShot')) and cooldown[classtable.ExplosiveShot].ready then
        return classtable.ExplosiveShot
    end
    if (MaxDps:FindSpell(classtable.DeathChakram) and CheckSpellCosts(classtable.DeathChakram, 'DeathChakram')) and cooldown[classtable.DeathChakram].ready then
        return classtable.DeathChakram
    end
    if (MaxDps:FindSpell(classtable.Stampede) and CheckSpellCosts(classtable.Stampede, 'Stampede')) and cooldown[classtable.Stampede].ready then
        return classtable.Stampede
    end
    if (MaxDps:FindSpell(classtable.WailingArrow) and CheckSpellCosts(classtable.WailingArrow, 'WailingArrow')) and cooldown[classtable.WailingArrow].ready then
        return classtable.WailingArrow
    end
    if (MaxDps:FindSpell(classtable.SerpentSting) and CheckSpellCosts(classtable.SerpentSting, 'SerpentSting')) and (debuff[classtable.SerpentSting].refreshable and talents[classtable.HydrasBite] and not talents[classtable.SerpentstalkersTrickery]) and cooldown[classtable.SerpentSting].ready then
        return classtable.SerpentSting
    end
    if (MaxDps:FindSpell(classtable.Barrage) and CheckSpellCosts(classtable.Barrage, 'Barrage')) and (targets >7) and cooldown[classtable.Barrage].ready then
        return classtable.Barrage
    end
    if (MaxDps:FindSpell(classtable.Volley) and CheckSpellCosts(classtable.Volley, 'Volley')) and cooldown[classtable.Volley].ready then
        return classtable.Volley
    end
    if (MaxDps:FindSpell(classtable.RapidFire) and CheckSpellCosts(classtable.RapidFire, 'RapidFire')) and (buff[classtable.TrickShotsBuff].remains >= timeShift and talents[classtable.SurgingShots]) and cooldown[classtable.RapidFire].ready then
        return classtable.RapidFire
    end
    if (MaxDps:FindSpell(classtable.Trueshot) and CheckSpellCosts(classtable.Trueshot, 'Trueshot')) and (trueshot_ready) and cooldown[classtable.Trueshot].ready then
        return classtable.Trueshot
    end
    if (MaxDps:FindSpell(classtable.AimedShot) and CheckSpellCosts(classtable.AimedShot, 'AimedShot')) and (talents[classtable.SerpentstalkersTrickery] and ( buff[classtable.TrickShotsBuff].remains >= timeShift and ( not buff[classtable.PreciseShotsBuff].up or buff[classtable.TrueshotBuff].up ) )) and cooldown[classtable.AimedShot].ready then
        return classtable.AimedShot
    end
    if (MaxDps:FindSpell(classtable.AimedShot) and CheckSpellCosts(classtable.AimedShot, 'AimedShot')) and (( buff[classtable.TrickShotsBuff].remains >= timeShift and ( not buff[classtable.PreciseShotsBuff].up or buff[classtable.TrueshotBuff].up ) )) and cooldown[classtable.AimedShot].ready then
        return classtable.AimedShot
    end
    if (MaxDps:FindSpell(classtable.RapidFire) and CheckSpellCosts(classtable.RapidFire, 'RapidFire')) and (buff[classtable.TrickShotsBuff].remains >= timeShift) and cooldown[classtable.RapidFire].ready then
        return classtable.RapidFire
    end
    if (MaxDps:FindSpell(classtable.ChimaeraShot) and CheckSpellCosts(classtable.ChimaeraShot, 'ChimaeraShot')) and (buff[classtable.TrickShotsBuff].up and buff[classtable.PreciseShotsBuff].up and Focus >(MaxGetSpellCost(classtable.ChimaeraShot,'FOCUS')) + MaxGetSpellCost(classtable.AimedShot, 'FOCUS') and targets <4) and cooldown[classtable.ChimaeraShot].ready then
        return classtable.ChimaeraShot
    end
    if (MaxDps:FindSpell(classtable.MultiShot) and CheckSpellCosts(classtable.MultiShot, 'Multishot')) and (not buff[classtable.TrickShotsBuff].up or ( buff[classtable.PreciseShotsBuff].up or buff[classtable.BulletstormBuff].count == 10 ) and Focus >(MaxGetSpellCost(classtable.MultiShot,'FOCUS')) + MaxGetSpellCost(classtable.AimedShot, 'FOCUS')) and cooldown[classtable.MultiShot].ready then
        return classtable.MultiShot
    end
    if (MaxDps:FindSpell(classtable.SerpentSting) and CheckSpellCosts(classtable.SerpentSting, 'SerpentSting')) and (debuff[classtable.SerpentSting].refreshable and talents[classtable.PoisonInjection] and not talents[classtable.SerpentstalkersTrickery]) and cooldown[classtable.SerpentSting].ready then
        return classtable.SerpentSting
    end
    if (MaxDps:FindSpell(classtable.SteelTrap) and CheckSpellCosts(classtable.SteelTrap, 'SteelTrap')) and (not buff[classtable.TrueshotBuff].up) and cooldown[classtable.SteelTrap].ready then
        return classtable.SteelTrap
    end
    if (MaxDps:FindSpell(classtable.KillShot) and CheckSpellCosts(classtable.KillShot, 'KillShot')) and (Focus >(MaxGetSpellCost(classtable.KillShot,'FOCUS')) + MaxGetSpellCost(classtable.AimedShot, 'FOCUS')) and cooldown[classtable.KillShot].ready then
        return classtable.KillShot
    end
    if (MaxDps:FindSpell(classtable.MultiShot) and CheckSpellCosts(classtable.MultiShot, 'Multishot')) and (Focus >(MaxGetSpellCost(classtable.MultiShot,'FOCUS')) + MaxGetSpellCost(classtable.AimedShot, 'FOCUS')) and cooldown[classtable.MultiShot].ready then
        return classtable.MultiShot
    end
    if (MaxDps:FindSpell(classtable.SteadyShot) and CheckSpellCosts(classtable.SteadyShot, 'SteadyShot')) and cooldown[classtable.SteadyShot].ready then
        return classtable.SteadyShot
    end
end
local function trinkets()
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
    classtable.TrueshotBuff = 288613
    classtable.SteadyFocusBuff = 193534
    classtable.TrickShotsBuff = 257622
    classtable.SalvoBuff = 400456
    classtable.PreciseShotsBuff = 260242
    classtable.RazorFragmentsBuff = 388998
    classtable.BulletstormBuff = 389020
	classtable.DeathblowBuff = 378770

    trueshot_ready = cooldown[classtable.Trueshot].ready and ( targets <2 and ( not talents[classtable.Bullseye] or ttd >cooldown[classtable.Trueshot].duration + buff[classtable.TrueshotBuff].duration % 2 or buff[classtable.BullseyeBuff].count == buff[classtable.BullseyeBuff].maxStacks ))-- and ( not trinket.1.has_use_buff or CheckTrinketCooldown('1') >30 or trinket.1.cooldown.ready ) and ( not trinket.2.has_use_buff or CheckTrinketCooldown('2') >30 or trinket.2.cooldown.ready ) or targets >1 and ( not targets >1 and ( TODO + TODO <25 or TODO ) or targets >1 and TODO ) or ttd <25 )
    --if (MaxDps:FindSpell(classtable.AutoShot) and CheckSpellCosts(classtable.AutoShot, 'AutoShot')) and cooldown[classtable.AutoShot].ready then
    --    return classtable.AutoShot
    --end
    local cdsCheck = Marksmanship:cds()
    if cdsCheck then
        return cdsCheck
    end
    --local trinketsCheck = Marksmanship:trinkets()
    --if trinketsCheck then
    --    return trinketsCheck
    --end
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
