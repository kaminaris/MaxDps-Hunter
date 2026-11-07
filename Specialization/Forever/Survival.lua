local _, addonTable = ...
local Hunter = addonTable.Hunter
local MaxDps = _G.MaxDps
if not MaxDps then return end

local Survival = {}

function Hunter:Survival()
    if not MaxDps.Near(8) then
        if (not MaxDps.IsTrackedAuraActive(1978) and (MaxDps.Power("mana") >= 30)) and not MaxDps.IsSpellOnCooldown(1978, true) then return 1978 end --  Serpent Sting
    end
    --if not MaxDps.IsSpellOnCooldown(75, true) then return 75 end --  Auto Shot
    if (not MaxDps.IsTrackedAuraActive(1130)) and not MaxDps.IsSpellOnCooldown(1130, true) then return 1130 end --  Hunter's Mark
    if MaxDps.Near(8) then
        if not MaxDps.IsSpellOnCooldown(2973, true) then return 2973 end --  Raptor Strike
        if not MaxDps.IsSpellOnCooldown(1495, true) then return 1495 end --  Mongoose Bite
    end
    if not MaxDps.IsSpellOnCooldown(61304, false) and MaxDps.IsSpellOnCooldown(19434, true) then return 3045 end --  Rapid Fire
    if MaxDps.Near(8) then
        if MaxDps.IsSpellOnCooldown(61304, false) then return 19434 end --  Aimed Shot
        if MaxDps.IsSpellOnCooldown(61304, false) then return 2643 end --  Multi-Shot
        if MaxDps.IsSpellOnCooldown(61304, false) and (MaxDps.Power("mana") >= 30) then return 3044 end --  Arcane Shot
    end
end
