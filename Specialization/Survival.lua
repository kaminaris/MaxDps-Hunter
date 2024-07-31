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

local mb_rs_cost

local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnownOrOverridesKnown(spell) then return false end
    if spellstring == 'TouchofDeath' then
        if targethealthPerc > 15 then
            return false
        end
    end
    if spellstring == 'KillShot' then
        if (classtable.SicEmBuff and not buff[classtable.SicEmBuff].up) and targethealthPerc > 15 then
            return false
        end
    end
    if spellstring == 'HammerofWrath' then
        if not ( (classtable.AvengingWrathBuff and buff[classtable.AvengingWrathBuff].up) or (classtable.FinalVerdictBuff and buff[classtable.FinalVerdictBuff].up) ) and targethealthPerc > 20 then
            return false
        end
    end
    if spellstring == 'Execute' then
        if not (classtable.SuddenDeathBuff and buff[classtable.SuddenDeathBuff].up) and targethealthPerc > 35 then
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
    if talents[classtable.MongooseBite] then
        mb_rs_cost = MaxGetSpellCost(classtable.MongooseBite, 'FOCUS')
    else
        mb_rs_cost = MaxGetSpellCost(classtable.RaptorStrike, 'FOCUS')
    end
    if (MaxDps:FindSpell(classtable.SteelTrap) and CheckSpellCosts(classtable.SteelTrap, 'SteelTrap')) and cooldown[classtable.SteelTrap].ready then
        return classtable.SteelTrap
    end
end
function Survival:cds()
    if (MaxDps:FindSpell(classtable.Harpoon) and CheckSpellCosts(classtable.Harpoon, 'Harpoon')) and (talents[classtable.TermsofEngagement] and Focus <FocusMax) and cooldown[classtable.Harpoon].ready then
        MaxDps:GlowCooldown(classtable.Harpoon, cooldown[classtable.Harpoon].ready)
    end
    if (MaxDps:FindSpell(classtable.Muzzle) and CheckSpellCosts(classtable.Muzzle, 'Muzzle')) and cooldown[classtable.Muzzle].ready then
        MaxDps:GlowCooldown(classtable.Muzzle, select(8,UnitCastingInfo('target') == false) and cooldown[classtable.Muzzle].ready)
    end
    if (MaxDps:FindSpell(classtable.AspectoftheEagle) and CheckSpellCosts(classtable.AspectoftheEagle, 'AspectoftheEagle')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', false, true) or 0) >= 6) and cooldown[classtable.AspectoftheEagle].ready then
        MaxDps:GlowCooldown(classtable.AspectoftheEagle, cooldown[classtable.AspectoftheEagle].ready)
    end
end
function Survival:cleave()
    if (MaxDps:FindSpell(classtable.KillShot) and CheckSpellCosts(classtable.KillShot, 'KillShot')) and (buff[classtable.CoordinatedAssaultEmpowerBuff].up and talents[classtable.BirdsofPrey]) and cooldown[classtable.KillShot].ready then
        return classtable.KillShot
    end
    if (MaxDps:FindSpell(classtable.DeathChakram) and CheckSpellCosts(classtable.DeathChakram, 'DeathChakram')) and (cooldown[classtable.DeathChakram].duration==45) and cooldown[classtable.DeathChakram].ready then
        return classtable.DeathChakram
    end
    if (MaxDps:FindSpell(classtable.WildfireBomb) and CheckSpellCosts(classtable.WildfireBomb, 'WildfireBomb')) and cooldown[classtable.WildfireBomb].ready then
        return classtable.WildfireBomb
    end
    if (MaxDps:FindSpell(classtable.Stampede) and CheckSpellCosts(classtable.Stampede, 'Stampede')) and cooldown[classtable.Stampede].ready then
        return classtable.Stampede
    end
    if (MaxDps:FindSpell(classtable.CoordinatedAssault) and CheckSpellCosts(classtable.CoordinatedAssault, 'CoordinatedAssault')) and (( cooldown[classtable.FuryoftheEagle].remains or not talents[classtable.FuryoftheEagle] )) and cooldown[classtable.CoordinatedAssault].ready then
        return classtable.CoordinatedAssault
    end
    if (MaxDps:FindSpell(classtable.ExplosiveShot) and CheckSpellCosts(classtable.ExplosiveShot, 'ExplosiveShot')) and cooldown[classtable.ExplosiveShot].ready then
        return classtable.ExplosiveShot
    end
    if (MaxDps:FindSpell(classtable.Carve) and CheckSpellCosts(classtable.Carve, 'Carve')) and (cooldown[classtable.WildfireBomb].fullRecharge >targets % 2) and cooldown[classtable.Carve].ready then
        return classtable.Carve
    end
    if (MaxDps:FindSpell(classtable.FuryoftheEagle) and CheckSpellCosts(classtable.FuryoftheEagle, 'FuryoftheEagle')) and (cooldown[classtable.Butchery].fullRecharge >( classtable and classtable.FuryoftheEagle and GetSpellInfo(classtable.FuryoftheEagle).castTime /1000 ) and (targets >1) or not talents[classtable.Butchery]) and cooldown[classtable.FuryoftheEagle].ready then
        return classtable.FuryoftheEagle
    end
    if (MaxDps:FindSpell(classtable.Butchery) and CheckSpellCosts(classtable.Butchery, 'Butchery')) and ((targets >1)) and cooldown[classtable.Butchery].ready then
        return classtable.Butchery
    end
    if (MaxDps:FindSpell(classtable.Butchery) and CheckSpellCosts(classtable.Butchery, 'Butchery')) and (( FocusTimeToMax >gcd or debuff[classtable.ShrapnelBombDeBuff].up and ( debuff[classtable.InternalBleedingDeBuff].count <2 or debuff[classtable.ShrapnelBombDeBuff].remains <gcd or targets <10 ) ) and (targets <2)) and cooldown[classtable.Butchery].ready then
        return classtable.Butchery
    end
    if (MaxDps:FindSpell(classtable.FuryoftheEagle) and CheckSpellCosts(classtable.FuryoftheEagle, 'FuryoftheEagle')) and ((targets <2)) and cooldown[classtable.FuryoftheEagle].ready then
        return classtable.FuryoftheEagle
    end
    if (MaxDps:FindSpell(classtable.Carve) and CheckSpellCosts(classtable.Carve, 'Carve')) and (debuff[classtable.ShrapnelBombDeBuff].up) and cooldown[classtable.Carve].ready then
        return classtable.Carve
    end
    if (MaxDps:FindSpell(classtable.Butchery) and CheckSpellCosts(classtable.Butchery, 'Butchery')) and (( not next_wi_bomb == classtable.Shrapnel or not talents[classtable.WildfireInfusion] )) and cooldown[classtable.Butchery].ready then
        return classtable.Butchery
    end
    if (MaxDps:FindSpell(classtable.MongooseBite) and CheckSpellCosts(classtable.MongooseBite, 'MongooseBite')) and (debuff[classtable.LatentPoisonDeBuff].count >8) and cooldown[classtable.MongooseBite].ready then
        return classtable.MongooseBite
    end
    if (MaxDps:FindSpell(classtable.RaptorStrike) and CheckSpellCosts(classtable.RaptorStrike, 'RaptorStrike')) and (debuff[classtable.LatentPoisonDeBuff].count >8) and cooldown[classtable.RaptorStrike].ready then
        return classtable.RaptorStrike
    end
    if (MaxDps:FindSpell(classtable.KillCommand) and CheckSpellCosts(classtable.KillCommand, 'KillCommand')) and (Focus + FocusRegen <FocusMax and FocusTimeToMax >gcd) and cooldown[classtable.KillCommand].ready then
        return classtable.KillCommand
    end
    if (MaxDps:FindSpell(classtable.FlankingStrike) and CheckSpellCosts(classtable.FlankingStrike, 'FlankingStrike')) and (Focus + FocusRegen <FocusMax) and cooldown[classtable.FlankingStrike].ready then
        return classtable.FlankingStrike
    end
    if (MaxDps:FindSpell(classtable.Carve) and CheckSpellCosts(classtable.Carve, 'Carve')) and cooldown[classtable.Carve].ready then
        return classtable.Carve
    end
    if (MaxDps:FindSpell(classtable.KillShot) and CheckSpellCosts(classtable.KillShot, 'KillShot')) and (not buff[classtable.CoordinatedAssaultBuff].up) and cooldown[classtable.KillShot].ready then
        return classtable.KillShot
    end
    if (MaxDps:FindSpell(classtable.SteelTrap) and CheckSpellCosts(classtable.SteelTrap, 'SteelTrap')) and (Focus + FocusRegen <FocusMax) and cooldown[classtable.SteelTrap].ready then
        return classtable.SteelTrap
    end
    if (MaxDps:FindSpell(classtable.Spearhead) and CheckSpellCosts(classtable.Spearhead, 'Spearhead')) and cooldown[classtable.Spearhead].ready then
        return classtable.Spearhead
    end
    if (MaxDps:FindSpell(classtable.MongooseBite) and CheckSpellCosts(classtable.MongooseBite, 'MongooseBite')) and (buff[classtable.SpearheadBuff].remains) and cooldown[classtable.MongooseBite].ready then
        return classtable.MongooseBite
    end
    if (MaxDps:FindSpell(classtable.SerpentSting) and CheckSpellCosts(classtable.SerpentSting, 'SerpentSting')) and (debuff[classtable.SerpentSting].refreshable and ttd >12 and ( not talents[classtable.VipersVenom] or talents[classtable.HydrasBite] )) and cooldown[classtable.SerpentSting].ready then
        return classtable.SerpentSting
    end
    if (MaxDps:FindSpell(classtable.MongooseBite) and CheckSpellCosts(classtable.MongooseBite, 'MongooseBite')) and (debuff[classtable.SerpentStingDeBuff].remains) and cooldown[classtable.MongooseBite].ready then
        return classtable.MongooseBite
    end
    if (MaxDps:FindSpell(classtable.RaptorStrike) and CheckSpellCosts(classtable.RaptorStrike, 'RaptorStrike')) and (debuff[classtable.SerpentStingDeBuff].remains) and cooldown[classtable.RaptorStrike].ready then
        return classtable.RaptorStrike
    end
end
function Survival:st()
    if (MaxDps:FindSpell(classtable.KillShot) and CheckSpellCosts(classtable.KillShot, 'KillShot')) and (buff[classtable.CoordinatedAssaultEmpowerBuff].up) and cooldown[classtable.KillShot].ready then
        return classtable.KillShot
    end
    if (MaxDps:FindSpell(classtable.WildfireBomb) and CheckSpellCosts(classtable.WildfireBomb, 'WildfireBomb')) and (talents[classtable.Spearhead] and cooldown[classtable.Spearhead].remains <2 * gcd and FocusTimeToMax >gcd or talents[classtable.Bombardier] and ( cooldown[classtable.CoordinatedAssault].remains <gcd and cooldown[classtable.FuryoftheEagle].remains or buff[classtable.CoordinatedAssaultBuff].up and buff[classtable.CoordinatedAssaultBuff].remains <2 * gcd ) or FocusTimeToMax >gcd or CheckPrevSpell(classtable.FuryoftheEagle) and (MaxDps.tier and MaxDps.tier[31].count >= 2) or buff[classtable.ContainedExplosionBuff].remains and ( next_wi_bomb == classtable.Pheromone and debuff[classtable.PheromoneBombDeBuff].refreshable or next_wi_bomb == classtable.Volatile and debuff[classtable.VolatileBombDeBuff].refreshable or next_wi_bomb == classtable.Shrapnel and debuff[classtable.ShrapnelBombDeBuff].refreshable ) or cooldown[classtable.FuryoftheEagle].remains <gcd and FocusTimeToMax >gcd and (MaxDps.tier and MaxDps.tier[31].count >= 2) or ( cooldown[classtable.FuryoftheEagle].remains <gcd and talents[classtable.RuthlessMarauder] and (MaxDps.tier and MaxDps.tier[31].count >= 2) ) and (targets <2)) and cooldown[classtable.WildfireBomb].ready then
        return classtable.WildfireBomb
    end
    if (MaxDps:FindSpell(classtable.DeathChakram) and CheckSpellCosts(classtable.DeathChakram, 'DeathChakram')) and (Focus + FocusRegen <FocusMax or talents[classtable.Spearhead] and not cooldown[classtable.Spearhead].remains and cooldown[classtable.FuryoftheEagle].remains or talents[classtable.Bombardier] and not cooldown[classtable.FuryoftheEagle].remains) and cooldown[classtable.DeathChakram].ready then
        return classtable.DeathChakram
    end
    if (MaxDps:FindSpell(classtable.MongooseBite) and CheckSpellCosts(classtable.MongooseBite, 'MongooseBite')) and (CheckPrevSpell(classtable.FuryoftheEagle)) and cooldown[classtable.MongooseBite].ready then
        return classtable.MongooseBite
    end
    if (MaxDps:FindSpell(classtable.FuryoftheEagle) and CheckSpellCosts(classtable.FuryoftheEagle, 'FuryoftheEagle')) and (( (targets <2) and (MaxDps.tier and MaxDps.tier[31].count >= 2) or (targets >1) and math.huge >40 and (MaxDps.tier and MaxDps.tier[31].count >= 2) )) and cooldown[classtable.FuryoftheEagle].ready then
        return classtable.FuryoftheEagle
    end
    if (MaxDps:FindSpell(classtable.Spearhead) and CheckSpellCosts(classtable.Spearhead, 'Spearhead')) and (Focus + FocusRegen >FocusMax - 10 and ( cooldown[classtable.DeathChakram].remains or not talents[classtable.DeathChakram] )) and cooldown[classtable.Spearhead].ready then
        return classtable.Spearhead
    end
    if (MaxDps:FindSpell(classtable.KillCommand) and CheckSpellCosts(classtable.KillCommand, 'KillCommand')) and (FocusTimeToMax >gcd and Focus + FocusRegen <FocusMax and ( buff[classtable.DeadlyDuoBuff].count >2 or talents[classtable.FlankersAdvantage] and buff[classtable.DeadlyDuoBuff].count >1 or buff[classtable.SpearheadBuff].remains and debuff[classtable.PheromoneBombDeBuff].remains )) and cooldown[classtable.KillCommand].ready then
        return classtable.KillCommand
    end
    if (MaxDps:FindSpell(classtable.MongooseBite) and CheckSpellCosts(classtable.MongooseBite, 'MongooseBite')) and (targets ==1 and ttd <Focus % ( mb_rs_cost - FocusRegen ) * gcd or buff[classtable.MongooseFuryBuff].up and buff[classtable.MongooseFuryBuff].remains <gcd or buff[classtable.SpearheadBuff].remains) and cooldown[classtable.MongooseBite].ready then
        return classtable.MongooseBite
    end
    if (MaxDps:FindSpell(classtable.KillShot) and CheckSpellCosts(classtable.KillShot, 'KillShot')) and (not buff[classtable.CoordinatedAssaultBuff].up and not buff[classtable.SpearheadBuff].up) and cooldown[classtable.KillShot].ready then
        return classtable.KillShot
    end
    if (MaxDps:FindSpell(classtable.KillCommand) and CheckSpellCosts(classtable.KillCommand, 'KillCommand')) and (FocusTimeToMax >gcd and Focus + FocusRegen <FocusMax and debuff[classtable.PheromoneBombDeBuff].remains and talents[classtable.FuryoftheEagle] and cooldown[classtable.FuryoftheEagle].remains >gcd) and cooldown[classtable.KillCommand].ready then
        return classtable.KillCommand
    end
    if (MaxDps:FindSpell(classtable.RaptorStrike) and CheckSpellCosts(classtable.RaptorStrike, 'RaptorStrike')) and (targets ==1 and ttd <Focus % ( mb_rs_cost - FocusRegen ) * gcd) and cooldown[classtable.RaptorStrike].ready then
        return classtable.RaptorStrike
    end
    if (MaxDps:FindSpell(classtable.SerpentSting) and CheckSpellCosts(classtable.SerpentSting, 'SerpentSting')) and (not debuff[classtable.SerpentStingDeBuff].up and ttd >7 and not talents[classtable.VipersVenom]) and cooldown[classtable.SerpentSting].ready then
        return classtable.SerpentSting
    end
    if (MaxDps:FindSpell(classtable.FuryoftheEagle) and CheckSpellCosts(classtable.FuryoftheEagle, 'FuryoftheEagle')) and (CheckEquipped('DjaruunPillaroftheElderFlame') and buff[classtable.SeethingRageBuff].up and buff[classtable.SeethingRageBuff].remains <3 * gcd and ( (targets <2) or targets >1 ) or (targets >1) and math.huge >40 and buff[classtable.SeethingRageBuff].up and buff[classtable.SeethingRageBuff].remains <3 * gcd) and cooldown[classtable.FuryoftheEagle].ready then
        return classtable.FuryoftheEagle
    end
    if (MaxDps:FindSpell(classtable.MongooseBite) and CheckSpellCosts(classtable.MongooseBite, 'MongooseBite')) and (talents[classtable.AlphaPredator] and buff[classtable.MongooseFuryBuff].up and buff[classtable.MongooseFuryBuff].remains <Focus % ( mb_rs_cost - FocusRegen ) * gcd or CheckEquipped('DjaruunPillaroftheElderFlame') and buff[classtable.SeethingRageBuff].remains and targets ==1 or next_wi_bomb == classtable.Pheromone and cooldown[classtable.WildfireBomb].remains <Focus % ( mb_rs_cost - FocusRegen ) * gcd and (MaxDps.tier and MaxDps.tier[31].count >= 2)) and cooldown[classtable.MongooseBite].ready then
        return classtable.MongooseBite
    end
    if (MaxDps:FindSpell(classtable.FlankingStrike) and CheckSpellCosts(classtable.FlankingStrike, 'FlankingStrike')) and (Focus + FocusRegen <FocusMax) and cooldown[classtable.FlankingStrike].ready then
        return classtable.FlankingStrike
    end
    if (MaxDps:FindSpell(classtable.Stampede) and CheckSpellCosts(classtable.Stampede, 'Stampede')) and cooldown[classtable.Stampede].ready then
        return classtable.Stampede
    end
    if (MaxDps:FindSpell(classtable.CoordinatedAssault) and CheckSpellCosts(classtable.CoordinatedAssault, 'CoordinatedAssault')) and (( not talents[classtable.CoordinatedKill] and targetHP <20 and ( not buff[classtable.SpearheadBuff].up and cooldown[classtable.Spearhead].remains or not talents[classtable.Spearhead] ) or talents[classtable.CoordinatedKill] and ( not buff[classtable.SpearheadBuff].up and cooldown[classtable.Spearhead].remains or not talents[classtable.Spearhead] ) ) and ( (targets <2) or math.huge >90 )) and cooldown[classtable.CoordinatedAssault].ready then
        return classtable.CoordinatedAssault
    end
    if (MaxDps:FindSpell(classtable.WildfireBomb) and CheckSpellCosts(classtable.WildfireBomb, 'WildfireBomb')) and (next_wi_bomb == classtable.Pheromone and Focus <mb_rs_cost and (MaxDps.tier and MaxDps.tier[31].count >= 2)) and cooldown[classtable.WildfireBomb].ready then
        return classtable.WildfireBomb
    end
    if (MaxDps:FindSpell(classtable.KillCommand) and CheckSpellCosts(classtable.KillCommand, 'KillCommand')) and (FocusTimeToMax >gcd and Focus + FocusRegen <FocusMax and ( cooldown[classtable.FlankingStrike].remains or not talents[classtable.FlankingStrike] )) and cooldown[classtable.KillCommand].ready then
        return classtable.KillCommand
    end
    if (MaxDps:FindSpell(classtable.SerpentSting) and CheckSpellCosts(classtable.SerpentSting, 'SerpentSting')) and (debuff[classtable.SerpentSting].refreshable and not talents[classtable.VipersVenom]) and cooldown[classtable.SerpentSting].ready then
        return classtable.SerpentSting
    end
    if (MaxDps:FindSpell(classtable.MongooseBite) and CheckSpellCosts(classtable.MongooseBite, 'MongooseBite')) and (debuff[classtable.ShrapnelBombDeBuff].up) and cooldown[classtable.MongooseBite].ready then
        return classtable.MongooseBite
    end
    if (MaxDps:FindSpell(classtable.WildfireBomb) and CheckSpellCosts(classtable.WildfireBomb, 'WildfireBomb')) and (math.huge >cooldown[classtable.WildfireBomb].fullRecharge - ( cooldown[classtable.WildfireBomb].fullRecharge % 3.5 ) and ( not debuff[classtable.WildfireBombDeBuff].up and Focus + FocusRegen <FocusMax or targets >1 )) and cooldown[classtable.WildfireBomb].ready then
        return classtable.WildfireBomb
    end
    if (MaxDps:FindSpell(classtable.MongooseBite) and CheckSpellCosts(classtable.MongooseBite, 'MongooseBite')) and (buff[classtable.MongooseFuryBuff].up) and cooldown[classtable.MongooseBite].ready then
        return classtable.MongooseBite
    end
    if (MaxDps:FindSpell(classtable.SteelTrap) and CheckSpellCosts(classtable.SteelTrap, 'SteelTrap')) and cooldown[classtable.SteelTrap].ready then
        return classtable.SteelTrap
    end
    if (MaxDps:FindSpell(classtable.ExplosiveShot) and CheckSpellCosts(classtable.ExplosiveShot, 'ExplosiveShot')) and (talents[classtable.Ranger] and ( (targets <2) or math.huge >28 )) and cooldown[classtable.ExplosiveShot].ready then
        return classtable.ExplosiveShot
    end
    if (MaxDps:FindSpell(classtable.FuryoftheEagle) and CheckSpellCosts(classtable.FuryoftheEagle, 'FuryoftheEagle')) and (( (targets <2) or (targets >1) and math.huge >40 )) and cooldown[classtable.FuryoftheEagle].ready then
        return classtable.FuryoftheEagle
    end
    if (MaxDps:FindSpell(classtable.MongooseBite) and CheckSpellCosts(classtable.MongooseBite, 'MongooseBite')) and cooldown[classtable.MongooseBite].ready then
        return classtable.MongooseBite
    end
    if (MaxDps:FindSpell(classtable.RaptorStrike) and CheckSpellCosts(classtable.RaptorStrike, 'RaptorStrike')) and (debuff[classtable.LatentPoisonDeBuff].count) and cooldown[classtable.RaptorStrike].ready then
        return classtable.RaptorStrike
    end
    if (MaxDps:FindSpell(classtable.KillCommand) and CheckSpellCosts(classtable.KillCommand, 'KillCommand')) and (Focus + FocusRegen <FocusMax) and cooldown[classtable.KillCommand].ready then
        return classtable.KillCommand
    end
    if (MaxDps:FindSpell(classtable.CoordinatedAssault) and CheckSpellCosts(classtable.CoordinatedAssault, 'CoordinatedAssault')) and (not talents[classtable.CoordinatedKill] and ttd >140) and cooldown[classtable.CoordinatedAssault].ready then
        return classtable.CoordinatedAssault
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
    classtable.CoordinatedAssaultEmpowerBuff = 0
    classtable.ShrapnelBombDeBuff = 0
    classtable.InternalBleedingDeBuff = 0
    classtable.LatentPoisonDeBuff = 0
    classtable.CoordinatedAssaultBuff = 360952
    classtable.SpearheadBuff = 0
    classtable.SerpentStingDeBuff = 259491
    classtable.ContainedExplosionBuff = 0
    classtable.PheromoneBombDeBuff = 0
    classtable.VolatileBombDeBuff = 0
    classtable.DeadlyDuoBuff = 0
    classtable.MongooseFuryBuff = 0
    classtable.SeethingRageBuff = 0
    classtable.WildfireBombDeBuff = 269747
	classtable.SicEmBuff = 461409

	Survival:precombat()

    --if (MaxDps:FindSpell(classtable.AutoAttack) and CheckSpellCosts(classtable.AutoAttack, 'AutoAttack')) and cooldown[classtable.AutoAttack].ready then
    --    return classtable.AutoAttack
    --end
    local cdsCheck = Survival:cds()
    if cdsCheck then
        return cdsCheck
    end
    if (targets <3) then
        local stCheck = Survival:st()
        if stCheck then
            return Survival:st()
        end
    end
    if (targets >2) then
        local cleaveCheck = Survival:cleave()
        if cleaveCheck then
            return Survival:cleave()
        end
    end

end
