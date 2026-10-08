local _, addon = ...
---@class KT
local KT = addon

---@enum SoundKits.Type
local TYPE = {
    M = 1,
    F = 2
}

---@enum SoundKits.Faction
local FACTION = {
    Alliance = 1,
    Horde = 2,
    Neutral = 3
}

---@class SoundKits.SoundKit
---@field Name string
---@field Id integer
---@field WOW_PROJECT_CONST_NAME string
---@field WOW_PROJECT_ID integer
---@field Race string
---@field Type SoundKits.Type
---@field Faction SoundKits.Faction

---@private
---@type SoundKits.SoundKit[]
KT.SoundKits.AllSoundKits = {
    { Name = "Dwarf Female", Id = 6104, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Dwarf", Type = TYPE.F, Faction = FACTION.Alliance },
    { Name = "Dwarf Male", Id = 6113, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Dwarf", Type = TYPE.M, Faction = FACTION.Alliance },
    { Name = "Gnome Female", Id = 6122, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Gnome", Type = TYPE.F, Faction = FACTION.Alliance },
    { Name = "Gnome Male", Id = 6131, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Gnome", Type = TYPE.M, Faction = FACTION.Alliance },
    { Name = "Human Female", Id = 6141, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Human", Type = TYPE.F, Faction = FACTION.Alliance },
    { Name = "Human Male", Id = 6168, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Human", Type = TYPE.M, Faction = FACTION.Alliance },
    { Name = "Night Elf Female", Id = 6177, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Night Elf", Type = TYPE.F, Faction = FACTION.Alliance },
    { Name = "Night Elf Male", Id = 6186, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Night Elf", Type = TYPE.M, Faction = FACTION.Alliance },
    { Name = "Orc Female", Id = 6357, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Orc", Type = TYPE.F, Faction = FACTION.Horde },
    { Name = "Orc Male", Id = 6366, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Orc", Type = TYPE.M, Faction = FACTION.Horde },
    { Name = "Tauren Female", Id = 6375, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Tauren", Type = TYPE.F, Faction = FACTION.Horde },
    { Name = "Tauren Male", Id = 6384, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Tauren", Type = TYPE.M, Faction = FACTION.Horde },
    { Name = "Troll Female", Id = 6393, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Troll", Type = TYPE.F, Faction = FACTION.Horde },
    { Name = "Troll Male", Id = 6402, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Troll", Type = TYPE.M, Faction = FACTION.Horde },
    { Name = "Undead Female", Id = 6411, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Undead", Type = TYPE.F, Faction = FACTION.Horde },
    { Name = "Undead Male", Id = 6420, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Undead", Type = TYPE.M, Faction = FACTION.Horde },
    { Name = "Blood Elf Female", Id = 9641, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_BURNING_CRUSADE_CLASSIC", WOW_PROJECT_ID = 5, Race = "Blood Elf", Type = TYPE.F, Faction = FACTION.Horde },
    { Name = "Blood Elf Male", Id = 9657, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_BURNING_CRUSADE_CLASSIC", WOW_PROJECT_ID = 5, Race = "Blood Elf", Type = TYPE.M, Faction = FACTION.Horde },
    { Name = "Draenei Female", Id = 9682, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_BURNING_CRUSADE_CLASSIC", WOW_PROJECT_ID = 5, Race = "Draenei", Type = TYPE.F, Faction = FACTION.Alliance },
    { Name = "Draenei Male", Id = 9707, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_BURNING_CRUSADE_CLASSIC", WOW_PROJECT_ID = 5, Race = "Draenei", Type = TYPE.M, Faction = FACTION.Alliance },
    { Name = "Gilnean Female", Id = 18647, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CATACLYSM_CLASSIC", WOW_PROJECT_ID = 14, Race = "Gilnean", Type = TYPE.F, Faction = FACTION.Alliance },
    { Name = "Gilnean Male", Id = 18974, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CATACLYSM_CLASSIC", WOW_PROJECT_ID = 14, Race = "Gilnean", Type = TYPE.M, Faction = FACTION.Alliance },
    { Name = "Goblin Male", Id = 19091, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CATACLYSM_CLASSIC", WOW_PROJECT_ID = 14, Race = "Goblin", Type = TYPE.M, Faction = FACTION.Horde },
    { Name = "Goblin Female", Id = 19199, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CATACLYSM_CLASSIC", WOW_PROJECT_ID = 14, Race = "Goblin", Type = TYPE.F, Faction = FACTION.Horde },
    { Name = "Worgen Male", Id = 19299, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CATACLYSM_CLASSIC", WOW_PROJECT_ID = 14, Race = "Worgen", Type = TYPE.M, Faction = FACTION.Alliance },
    { Name = "Worgen Female", Id = 19378, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CATACLYSM_CLASSIC", WOW_PROJECT_ID = 14, Race = "Worgen", Type = TYPE.F, Faction = FACTION.Alliance },
    { Name = "Pandaren Male", Id = 28927, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_MISTS_CLASSIC", WOW_PROJECT_ID = 15, Race = "Pandaren", Type = TYPE.M, Faction = FACTION.Neutral },
    { Name = "Pandaren Female", Id = 29793, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_MISTS_CLASSIC", WOW_PROJECT_ID = 15, Race = "Pandaren", Type = TYPE.F, Faction = FACTION.Neutral },
}