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
local next_wi_bomb

local Survival = {}


local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnownOrOverridesKnown(spell) then return false end
    if spellstring == 'TouchofDeath' then
        if targethealthPerc > 15 then
            return false
        end
    end
    if spellstring == 'KillShot' then
        if (classtable.SicEmBuff and not buff[classtable.SicEmBuff].up) or (classtable.HuntersPreyBuff and not buff[classtable.HuntersPreyBuff].up) and targethealthPerc > 15 then
            return false
        end
    end
    if spellstring == 'HammerofWrath' then
        if ( (classtable.AvengingWrathBuff and not buff[classtable.AvengingWrathBuff].up) or (classtable.FinalVerdictBuff and not buff[classtable.FinalVerdictBuff].up) ) and targethealthPerc > 20 then
            return false
        end
    end
    if spellstring == 'Execute' then
        if (classtable.SuddenDeathBuff and not buff[classtable.SuddenDeathBuff].up) and targethealthPerc > 35 then
            return false
        end
    end
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


function Survival:precombat()
end
function Survival:cds()
    if (MaxDps:FindSpell(classtable.AspectoftheEagle) and CheckSpellCosts(classtable.AspectoftheEagle, 'AspectoftheEagle')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', false, true) or 0) >= 6) and cooldown[classtable.AspectoftheEagle].ready then
        MaxDps:GlowCooldown(classtable.AspectoftheEagle, cooldown[classtable.AspectoftheEagle].ready)
    end
end
function Survival:plst()
    if (MaxDps:FindSpell(classtable.KillCommand) and CheckSpellCosts(classtable.KillCommand, 'KillCommand')) and (( buff[classtable.RelentlessPrimalFerocityBuff].up and buff[classtable.TipoftheSpearBuff].count <1 )) and cooldown[classtable.KillCommand].ready then
        return classtable.KillCommand
    end
    if (MaxDps:FindSpell(classtable.Spearhead) and CheckSpellCosts(classtable.Spearhead, 'Spearhead')) and (cooldown[classtable.CoordinatedAssault].remains) and cooldown[classtable.Spearhead].ready then
        return classtable.Spearhead
    end
    if (MaxDps:FindSpell(classtable.RaptorBite) and CheckSpellCosts(classtable.RaptorBite, 'RaptorBite')) and (not debuff[classtable.SerpentStingDeBuff].up and ttd >12 and ( not talents[classtable.ContagiousReagents] or debuff[classtable.SerpentStingDebuff].count  == 0 )) and cooldown[classtable.RaptorBite].ready then
        return classtable.RaptorBite
    end
    if (MaxDps:FindSpell(classtable.RaptorBite) and CheckSpellCosts(classtable.RaptorBite, 'RaptorBite')) and (talents[classtable.ContagiousReagents] and debuff[classtable.SerpentStingDebuff].count  <targets and debuff[classtable.SerpentStingDeBuff].remains) and cooldown[classtable.RaptorBite].ready then
        return classtable.RaptorBite
    end
    if (MaxDps:FindSpell(classtable.WildfireBomb) and CheckSpellCosts(classtable.WildfireBomb, 'WildfireBomb')) and (buff[classtable.TipoftheSpearBuff].count >0 and cooldown[classtable.WildfireBomb].charges >1.7 or cooldown[classtable.WildfireBomb].charges >1.9 or cooldown[classtable.CoordinatedAssault].remains <2 * gcd) and cooldown[classtable.WildfireBomb].ready then
        return classtable.WildfireBomb
    end
    if (MaxDps:FindSpell(classtable.CoordinatedAssault) and CheckSpellCosts(classtable.CoordinatedAssault, 'CoordinatedAssault')) and (not talents[classtable.Bombardier] or talents[classtable.Bombardier] and cooldown[classtable.WildfireBomb].charges <1) and cooldown[classtable.CoordinatedAssault].ready then
        return classtable.CoordinatedAssault
    end
    if (MaxDps:FindSpell(classtable.KillShot) and CheckSpellCosts(classtable.KillShot, 'KillShot')) and (( buff[classtable.TipoftheSpearBuff].count >0 or talents[classtable.SicEm] )) and cooldown[classtable.KillShot].ready then
        return classtable.KillShot
    end
    if (MaxDps:FindSpell(classtable.FlankingStrike) and CheckSpellCosts(classtable.FlankingStrike, 'FlankingStrike')) and (buff[classtable.TipoftheSpearBuff].count <2) and cooldown[classtable.FlankingStrike].ready then
        return classtable.FlankingStrike
    end
    if (MaxDps:FindSpell(classtable.ExplosiveShot) and CheckSpellCosts(classtable.ExplosiveShot, 'ExplosiveShot')) and (( talents[classtable.Spearhead] and ( not talents[classtable.SymbioticAdrenaline] and ( buff[classtable.TipoftheSpearBuff].count >0 or buff[classtable.BombardierBuff].remains ) and cooldown[classtable.Spearhead].remains >20 or cooldown[classtable.Spearhead].remains <2 ) ) or ( ( talents[classtable.SymbioticAdrenaline] or not talents[classtable.Spearhead] ) and ( buff[classtable.TipoftheSpearBuff].count >0 or buff[classtable.BombardierBuff].remains ) and cooldown[classtable.CoordinatedAssault].remains >20 or cooldown[classtable.CoordinatedAssault].remains <2 )) and cooldown[classtable.ExplosiveShot].ready then
        return classtable.ExplosiveShot
    end
    if (MaxDps:FindSpell(classtable.RaptorBite) and CheckSpellCosts(classtable.RaptorBite, 'RaptorBite')) and (( buff[classtable.FuriousAssaultBuff].up and buff[classtable.TipoftheSpearBuff].count >0 ) and ( not talents[classtable.MongooseBite] or buff[classtable.MongooseFuryBuff].count >4 )) and cooldown[classtable.RaptorBite].ready then
        return classtable.RaptorBite
    end
    if (MaxDps:FindSpell(classtable.KillCommand) and CheckSpellCosts(classtable.KillCommand, 'KillCommand')) and cooldown[classtable.KillCommand].ready then
        return classtable.KillCommand
    end
    if (MaxDps:FindSpell(classtable.WildfireBomb) and CheckSpellCosts(classtable.WildfireBomb, 'WildfireBomb')) and (buff[classtable.TipoftheSpearBuff].count >0 and ( (targets <2) or (targets >1) and math.huge >15 )) and cooldown[classtable.WildfireBomb].ready then
        return classtable.WildfireBomb
    end
    if (MaxDps:FindSpell(classtable.FuryoftheEagle) and CheckSpellCosts(classtable.FuryoftheEagle, 'FuryoftheEagle')) and (( (targets <2) or (targets >1) and math.huge >40 )) and cooldown[classtable.FuryoftheEagle].ready then
        return classtable.FuryoftheEagle
    end
    if (MaxDps:FindSpell(classtable.Butchery) and CheckSpellCosts(classtable.Butchery, 'Butchery')) and (targets >1 and ( talents[classtable.MercilessBlows] and not buff[classtable.MercilessBlowsBuff].up or not talents[classtable.MercilessBlows] )) and cooldown[classtable.Butchery].ready then
        return classtable.Butchery
    end
    if (MaxDps:FindSpell(classtable.RaptorBite) and CheckSpellCosts(classtable.RaptorBite, 'RaptorBite')) and (not talents[classtable.ContagiousReagents]) and cooldown[classtable.RaptorBite].ready then
        return classtable.RaptorBite
    end
    if (MaxDps:FindSpell(classtable.RaptorBite) and CheckSpellCosts(classtable.RaptorBite, 'RaptorBite')) and cooldown[classtable.RaptorBite].ready then
        return classtable.RaptorBite
    end
end
function Survival:plcleave()
    if (MaxDps:FindSpell(classtable.Spearhead) and CheckSpellCosts(classtable.Spearhead, 'Spearhead')) and (cooldown[classtable.CoordinatedAssault].remains) and cooldown[classtable.Spearhead].ready then
        return classtable.Spearhead
    end
    if (MaxDps:FindSpell(classtable.KillCommand) and CheckSpellCosts(classtable.KillCommand, 'KillCommand')) and (buff[classtable.RelentlessPrimalFerocityBuff].up and buff[classtable.TipoftheSpearBuff].count <1) and cooldown[classtable.KillCommand].ready then
        return classtable.KillCommand
    end
    if (MaxDps:FindSpell(classtable.ExplosiveShot) and CheckSpellCosts(classtable.ExplosiveShot, 'ExplosiveShot')) and (buff[classtable.BombardierBuff].remains) and cooldown[classtable.ExplosiveShot].ready then
        return classtable.ExplosiveShot
    end
    if (MaxDps:FindSpell(classtable.WildfireBomb) and CheckSpellCosts(classtable.WildfireBomb, 'WildfireBomb')) and (buff[classtable.TipoftheSpearBuff].count >0 and cooldown[classtable.WildfireBomb].charges >1.7 or cooldown[classtable.WildfireBomb].charges >1.9 or cooldown[classtable.CoordinatedAssault].remains <2 * gcd) and cooldown[classtable.WildfireBomb].ready then
        return classtable.WildfireBomb
    end
    if (MaxDps:FindSpell(classtable.CoordinatedAssault) and CheckSpellCosts(classtable.CoordinatedAssault, 'CoordinatedAssault')) and (not talents[classtable.Bombardier] or talents[classtable.Bombardier] and cooldown[classtable.WildfireBomb].charges <1) and cooldown[classtable.CoordinatedAssault].ready then
        return classtable.CoordinatedAssault
    end
    if (MaxDps:FindSpell(classtable.FlankingStrike) and CheckSpellCosts(classtable.FlankingStrike, 'FlankingStrike')) and (buff[classtable.TipoftheSpearBuff].count <2) and cooldown[classtable.FlankingStrike].ready then
        return classtable.FlankingStrike
    end
    if (MaxDps:FindSpell(classtable.ExplosiveShot) and CheckSpellCosts(classtable.ExplosiveShot, 'ExplosiveShot')) and (( buff[classtable.TipoftheSpearBuff].count >0 or buff[classtable.BombardierBuff].remains ) and cooldown[classtable.CoordinatedAssault].remains >20 or cooldown[classtable.CoordinatedAssault].remains <2) and cooldown[classtable.ExplosiveShot].ready then
        return classtable.ExplosiveShot
    end
    if (MaxDps:FindSpell(classtable.FuryoftheEagle) and CheckSpellCosts(classtable.FuryoftheEagle, 'FuryoftheEagle')) and (buff[classtable.TipoftheSpearBuff].count >0) and cooldown[classtable.FuryoftheEagle].ready then
        return classtable.FuryoftheEagle
    end
    if (MaxDps:FindSpell(classtable.KillShot) and CheckSpellCosts(classtable.KillShot, 'KillShot')) and (buff[classtable.SicEmBuff].remains and targets <4) and cooldown[classtable.KillShot].ready then
        return classtable.KillShot
    end
    if (MaxDps:FindSpell(classtable.KillCommand) and CheckSpellCosts(classtable.KillCommand, 'KillCommand')) and (Focus + FocusRegen <FocusMax) and cooldown[classtable.KillCommand].ready then
        return classtable.KillCommand
    end
    if (MaxDps:FindSpell(classtable.WildfireBomb) and CheckSpellCosts(classtable.WildfireBomb, 'WildfireBomb')) and (buff[classtable.TipoftheSpearBuff].count >0) and cooldown[classtable.WildfireBomb].ready then
        return classtable.WildfireBomb
    end
    if (MaxDps:FindSpell(classtable.RaptorBite) and CheckSpellCosts(classtable.RaptorBite, 'RaptorBite')) and (buff[classtable.MercilessBlowsBuff].up) and cooldown[classtable.RaptorBite].ready then
        return classtable.RaptorBite
    end
    if (MaxDps:FindSpell(classtable.Butchery) and CheckSpellCosts(classtable.Butchery, 'Butchery')) and cooldown[classtable.Butchery].ready then
        return classtable.Butchery
    end
    if (MaxDps:FindSpell(classtable.KillShot) and CheckSpellCosts(classtable.KillShot, 'KillShot')) and cooldown[classtable.KillShot].ready then
        return classtable.KillShot
    end
    if (MaxDps:FindSpell(classtable.RaptorBite) and CheckSpellCosts(classtable.RaptorBite, 'RaptorBite')) and cooldown[classtable.RaptorBite].ready then
        return classtable.RaptorBite
    end
end
function Survival:sentst()
    if (MaxDps:FindSpell(classtable.KillCommand) and CheckSpellCosts(classtable.KillCommand, 'KillCommand')) and (( buff[classtable.RelentlessPrimalFerocityBuff].up and buff[classtable.TipoftheSpearBuff].count <1 )) and cooldown[classtable.KillCommand].ready then
        return classtable.KillCommand
    end
    if (MaxDps:FindSpell(classtable.Spearhead) and CheckSpellCosts(classtable.Spearhead, 'Spearhead')) and (cooldown[classtable.CoordinatedAssault].remains) and cooldown[classtable.Spearhead].ready then
        return classtable.Spearhead
    end
    if (MaxDps:FindSpell(classtable.RaptorBite) and CheckSpellCosts(classtable.RaptorBite, 'RaptorBite')) and (not debuff[classtable.SerpentStingDeBuff].up and ttd >12 and ( not talents[classtable.ContagiousReagents] or debuff[classtable.SerpentStingDebuff].count  == 0 )) and cooldown[classtable.RaptorBite].ready then
        return classtable.RaptorBite
    end
    if (MaxDps:FindSpell(classtable.RaptorBite) and CheckSpellCosts(classtable.RaptorBite, 'RaptorBite')) and (talents[classtable.ContagiousReagents] and debuff[classtable.SerpentStingDebuff].count  <targets and debuff[classtable.SerpentStingDeBuff].remains) and cooldown[classtable.RaptorBite].ready then
        return classtable.RaptorBite
    end
    if (MaxDps:FindSpell(classtable.WildfireBomb) and CheckSpellCosts(classtable.WildfireBomb, 'WildfireBomb')) and (buff[classtable.TipoftheSpearBuff].count >0 and cooldown[classtable.WildfireBomb].charges >1.7 or cooldown[classtable.WildfireBomb].charges >1.9 or cooldown[classtable.CoordinatedAssault].remains <2 * gcd) and cooldown[classtable.WildfireBomb].ready then
        return classtable.WildfireBomb
    end
    if (MaxDps:FindSpell(classtable.CoordinatedAssault) and CheckSpellCosts(classtable.CoordinatedAssault, 'CoordinatedAssault')) and (not talents[classtable.Bombardier] or talents[classtable.Bombardier] and cooldown[classtable.WildfireBomb].charges <1) and cooldown[classtable.CoordinatedAssault].ready then
        return classtable.CoordinatedAssault
    end
    if (MaxDps:FindSpell(classtable.FuryoftheEagle) and CheckSpellCosts(classtable.FuryoftheEagle, 'FuryoftheEagle')) and ((MaxDps.tier and MaxDps.tier[31].count >= 2)) and cooldown[classtable.FuryoftheEagle].ready then
        return classtable.FuryoftheEagle
    end
    if (MaxDps:FindSpell(classtable.FlankingStrike) and CheckSpellCosts(classtable.FlankingStrike, 'FlankingStrike')) and (buff[classtable.TipoftheSpearBuff].count <2) and cooldown[classtable.FlankingStrike].ready then
        return classtable.FlankingStrike
    end
    if (MaxDps:FindSpell(classtable.ExplosiveShot) and CheckSpellCosts(classtable.ExplosiveShot, 'ExplosiveShot')) and (( talents[classtable.Spearhead] and ( not talents[classtable.SymbioticAdrenaline] and ( buff[classtable.TipoftheSpearBuff].count >0 or buff[classtable.BombardierBuff].remains ) and cooldown[classtable.Spearhead].remains >20 or cooldown[classtable.Spearhead].remains <2 ) ) or ( ( talents[classtable.SymbioticAdrenaline] or not talents[classtable.Spearhead] ) and ( buff[classtable.TipoftheSpearBuff].count >0 or buff[classtable.BombardierBuff].remains ) and cooldown[classtable.CoordinatedAssault].remains >20 or cooldown[classtable.CoordinatedAssault].remains <2 )) and cooldown[classtable.ExplosiveShot].ready then
        return classtable.ExplosiveShot
    end
    if (MaxDps:FindSpell(classtable.KillShot) and CheckSpellCosts(classtable.KillShot, 'KillShot')) and (buff[classtable.TipoftheSpearBuff].count >0 or talents[classtable.SicEm]) and cooldown[classtable.KillShot].ready then
        return classtable.KillShot
    end
    if (MaxDps:FindSpell(classtable.KillCommand) and CheckSpellCosts(classtable.KillCommand, 'KillCommand')) and (Focus + FocusRegen <FocusMax and ( not buff[classtable.RelentlessPrimalFerocityBuff].up or ( buff[classtable.RelentlessPrimalFerocityBuff].up and buff[classtable.TipoftheSpearBuff].count <2 ) )) and cooldown[classtable.KillCommand].ready then
        return classtable.KillCommand
    end
    if (MaxDps:FindSpell(classtable.WildfireBomb) and CheckSpellCosts(classtable.WildfireBomb, 'WildfireBomb')) and (buff[classtable.TipoftheSpearBuff].count >0 and ( (targets <2) or (targets >1) and math.huge >15 )) and cooldown[classtable.WildfireBomb].ready then
        return classtable.WildfireBomb
    end
    if (MaxDps:FindSpell(classtable.FuryoftheEagle) and CheckSpellCosts(classtable.FuryoftheEagle, 'FuryoftheEagle')) and (( (targets <2) or (targets >1) and math.huge >40 )) and cooldown[classtable.FuryoftheEagle].ready then
        return classtable.FuryoftheEagle
    end
    if (MaxDps:FindSpell(classtable.Butchery) and CheckSpellCosts(classtable.Butchery, 'Butchery')) and (targets >1 and ( talents[classtable.MercilessBlows] and not buff[classtable.MercilessBlowsBuff].up or not talents[classtable.MercilessBlows] )) and cooldown[classtable.Butchery].ready then
        return classtable.Butchery
    end
    if (MaxDps:FindSpell(classtable.RaptorBite) and CheckSpellCosts(classtable.RaptorBite, 'RaptorBite')) and (not talents[classtable.ContagiousReagents]) and cooldown[classtable.RaptorBite].ready then
        return classtable.RaptorBite
    end
    if (MaxDps:FindSpell(classtable.RaptorBite) and CheckSpellCosts(classtable.RaptorBite, 'RaptorBite')) and cooldown[classtable.RaptorBite].ready then
        return classtable.RaptorBite
    end
end
function Survival:sentcleave()
    if (MaxDps:FindSpell(classtable.Spearhead) and CheckSpellCosts(classtable.Spearhead, 'Spearhead')) and (cooldown[classtable.CoordinatedAssault].remains) and cooldown[classtable.Spearhead].ready then
        return classtable.Spearhead
    end
    if (MaxDps:FindSpell(classtable.KillCommand) and CheckSpellCosts(classtable.KillCommand, 'KillCommand')) and (buff[classtable.RelentlessPrimalFerocityBuff].up and buff[classtable.TipoftheSpearBuff].count <1) and cooldown[classtable.KillCommand].ready then
        return classtable.KillCommand
    end
    if (MaxDps:FindSpell(classtable.ExplosiveShot) and CheckSpellCosts(classtable.ExplosiveShot, 'ExplosiveShot')) and (buff[classtable.BombardierBuff].remains) and cooldown[classtable.ExplosiveShot].ready then
        return classtable.ExplosiveShot
    end
    if (MaxDps:FindSpell(classtable.WildfireBomb) and CheckSpellCosts(classtable.WildfireBomb, 'WildfireBomb')) and (buff[classtable.TipoftheSpearBuff].count >0 and cooldown[classtable.WildfireBomb].charges >1.7 or cooldown[classtable.WildfireBomb].charges >1.9 or cooldown[classtable.CoordinatedAssault].remains <2 * gcd) and cooldown[classtable.WildfireBomb].ready then
        return classtable.WildfireBomb
    end
    if (MaxDps:FindSpell(classtable.CoordinatedAssault) and CheckSpellCosts(classtable.CoordinatedAssault, 'CoordinatedAssault')) and (not talents[classtable.Bombardier] or talents[classtable.Bombardier] and cooldown[classtable.WildfireBomb].charges <1) and cooldown[classtable.CoordinatedAssault].ready then
        return classtable.CoordinatedAssault
    end
    if (MaxDps:FindSpell(classtable.FlankingStrike) and CheckSpellCosts(classtable.FlankingStrike, 'FlankingStrike')) and (buff[classtable.TipoftheSpearBuff].count <2) and cooldown[classtable.FlankingStrike].ready then
        return classtable.FlankingStrike
    end
    if (MaxDps:FindSpell(classtable.ExplosiveShot) and CheckSpellCosts(classtable.ExplosiveShot, 'ExplosiveShot')) and (( buff[classtable.TipoftheSpearBuff].count >0 or buff[classtable.BombardierBuff].remains ) and cooldown[classtable.CoordinatedAssault].remains >20 or cooldown[classtable.CoordinatedAssault].remains <2) and cooldown[classtable.ExplosiveShot].ready then
        return classtable.ExplosiveShot
    end
    if (MaxDps:FindSpell(classtable.FuryoftheEagle) and CheckSpellCosts(classtable.FuryoftheEagle, 'FuryoftheEagle')) and (buff[classtable.TipoftheSpearBuff].count >0) and cooldown[classtable.FuryoftheEagle].ready then
        return classtable.FuryoftheEagle
    end
    if (MaxDps:FindSpell(classtable.KillShot) and CheckSpellCosts(classtable.KillShot, 'KillShot')) and (buff[classtable.SicEmBuff].remains and targets <4) and cooldown[classtable.KillShot].ready then
        return classtable.KillShot
    end
    if (MaxDps:FindSpell(classtable.KillCommand) and CheckSpellCosts(classtable.KillCommand, 'KillCommand')) and (Focus + FocusRegen <FocusMax) and cooldown[classtable.KillCommand].ready then
        return classtable.KillCommand
    end
    if (MaxDps:FindSpell(classtable.WildfireBomb) and CheckSpellCosts(classtable.WildfireBomb, 'WildfireBomb')) and (buff[classtable.TipoftheSpearBuff].count >0) and cooldown[classtable.WildfireBomb].ready then
        return classtable.WildfireBomb
    end
    if (MaxDps:FindSpell(classtable.RaptorBite) and CheckSpellCosts(classtable.RaptorBite, 'RaptorBite')) and (buff[classtable.MercilessBlowsBuff].up) and cooldown[classtable.RaptorBite].ready then
        return classtable.RaptorBite
    end
    if (MaxDps:FindSpell(classtable.Butchery) and CheckSpellCosts(classtable.Butchery, 'Butchery')) and cooldown[classtable.Butchery].ready then
        return classtable.Butchery
    end
    if (MaxDps:FindSpell(classtable.KillShot) and CheckSpellCosts(classtable.KillShot, 'KillShot')) and cooldown[classtable.KillShot].ready then
        return classtable.KillShot
    end
    if (MaxDps:FindSpell(classtable.RaptorBite) and CheckSpellCosts(classtable.RaptorBite, 'RaptorBite')) and cooldown[classtable.RaptorBite].ready then
        return classtable.RaptorBite
    end
end

function Survival:callaction()
    if (MaxDps:FindSpell(classtable.Muzzle) and CheckSpellCosts(classtable.Muzzle, 'Muzzle')) and cooldown[classtable.Muzzle].ready then
        MaxDps:GlowCooldown(classtable.Muzzle, select(8,UnitCastingInfo('target') == false) and cooldown[classtable.Muzzle].ready)
    end
    local cdsCheck = Survival:cds()
    if cdsCheck then
        return cdsCheck
    end
    if (targets <3 and talents[classtable.ViciousHunt]) then
        local plstCheck = Survival:plst()
        if plstCheck then
            return Survival:plst()
        end
    end
    if (targets >2 and talents[classtable.ViciousHunt]) then
        local plcleaveCheck = Survival:plcleave()
        if plcleaveCheck then
            return Survival:plcleave()
        end
    end
    if (targets <3 and not talents[classtable.ViciousHunt]) then
        local sentstCheck = Survival:sentst()
        if sentstCheck then
            return Survival:sentst()
        end
    end
    if (targets >2 and not talents[classtable.ViciousHunt]) then
        local sentcleaveCheck = Survival:sentcleave()
        if sentcleaveCheck then
            return Survival:sentcleave()
        end
    end
end
function Hunter:Survival()
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
    next_wi_bomb = function()
        local spellinfo = GetSpellInfo(GetSpellInfo(259495))
        return spellinfo and spellinfo.spellID or 0
    end
    if talents[classtable.MongooseBite] then
        classtable.RaptorBite = classtable.MongooseBite
    else
        classtable.RaptorBite = classtable.RaptorStrike
    end
    for spellId in pairs(MaxDps.Flags) do
        self.Flags[spellId] = false
        self:ClearGlowIndependent(spellId, spellId)
    end
    classtable.HuntersMarkDeBuff = 257284
    classtable.RelentlessPrimalFerocityBuff = 360952
    classtable.TipoftheSpearBuff = 260286
    classtable.SerpentStingDeBuff = 259491
    classtable.BombardierBuff = 459859
    classtable.FuriousAssaultBuff = 448814
    classtable.MongooseFuryBuff = 259388
    classtable.MercilessBlowsBuff = 459870
    classtable.SicEmBuff = 461409

    local precombatCheck = Survival:precombat()
    if precombatCheck then
        return Survival:precombat()
    end
    local callactionCheck = Survival:callaction()
    if callactionCheck then
        return Survival:callaction()
    end
end
