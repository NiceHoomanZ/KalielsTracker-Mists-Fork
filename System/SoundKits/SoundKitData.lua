local _, addon = ...
---@class KT
local KT = addon

---@enum SoundKits.Type
local TYPE = {
    M = 1,
    F = 2
}

---@class SoundKits.SoundKit
---@field Name string
---@field SoundKitId integer
---@field WOW_PROJECT_CONST_NAME string
---@field WOW_PROJECT_ID integer
---@field Race string
---@field Type SoundKits.Type

---@private
---@type SoundKits.SoundKit[]
KT.SoundKits.AllSoundKits = {
    { Name = "Dwarf Female", SoundKitId = 6104, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Dwarf", Type = TYPE.F },
    { Name = "Dwarf Male", SoundKitId = 6113, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Dwarf", Type = TYPE.M },
    { Name = "Gnome Female", SoundKitId = 6122, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Gnome", Type = TYPE.F },
    { Name = "Gnome Male", SoundKitId = 6131, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Gnome", Type = TYPE.M },
    { Name = "Human Female", SoundKitId = 6141, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Human", Type = TYPE.F },
    { Name = "Human Male", SoundKitId = 6168, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Human", Type = TYPE.M },
    { Name = "Night Elf Female", SoundKitId = 6177, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Night Elf", Type = TYPE.F },
    { Name = "Night Elf Male", SoundKitId = 6186, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Night Elf", Type = TYPE.M },
    { Name = "Orc Female", SoundKitId = 6357, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Orc", Type = TYPE.F },
    { Name = "Orc Male", SoundKitId = 6366, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Orc", Type = TYPE.M },
    { Name = "Tauren Female", SoundKitId = 6375, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Tauren", Type = TYPE.F },
    { Name = "Tauren Male", SoundKitId = 6384, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Tauren", Type = TYPE.M },
    { Name = "Troll Female", SoundKitId = 6393, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Troll", Type = TYPE.F },
    { Name = "Troll Male", SoundKitId = 6402, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Troll", Type = TYPE.M },
    { Name = "Undead Female", SoundKitId = 6411, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Undead", Type = TYPE.F },
    { Name = "Undead Male", SoundKitId = 6420, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CLASSIC", WOW_PROJECT_ID = 2, Race = "Undead", Type = TYPE.M },
    { Name = "Blood Elf Female", SoundKitId = 9641, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_BURNING_CRUSADE_CLASSIC", WOW_PROJECT_ID = 5, Race = "Blood Elf", Type = TYPE.F },
    { Name = "Blood Elf Male", SoundKitId = 9657, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_BURNING_CRUSADE_CLASSIC", WOW_PROJECT_ID = 5, Race = "Blood Elf", Type = TYPE.M },
    { Name = "Draenei Female", SoundKitId = 9682, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_BURNING_CRUSADE_CLASSIC", WOW_PROJECT_ID = 5, Race = "Draenei", Type = TYPE.F },
    { Name = "Draenei Male", SoundKitId = 9707, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_BURNING_CRUSADE_CLASSIC", WOW_PROJECT_ID = 5, Race = "Draenei", Type = TYPE.M },
    { Name = "Gilnean Female", SoundKitId = 18647, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CATACLYSM_CLASSIC", WOW_PROJECT_ID = 14, Race = "Gilnean", Type = TYPE.F },
    { Name = "Gilnean Male", SoundKitId = 18974, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CATACLYSM_CLASSIC", WOW_PROJECT_ID = 14, Race = "Gilnean", Type = TYPE.M },
    { Name = "Goblin Male", SoundKitId = 19091, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CATACLYSM_CLASSIC", WOW_PROJECT_ID = 14, Race = "Goblin", Type = TYPE.M },
    { Name = "Goblin Female", SoundKitId = 19199, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CATACLYSM_CLASSIC", WOW_PROJECT_ID = 14, Race = "Goblin", Type = TYPE.F },
    { Name = "Worgen Male", SoundKitId = 19299, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CATACLYSM_CLASSIC", WOW_PROJECT_ID = 14, Race = "Worgen", Type = TYPE.M },
    { Name = "Worgen Female", SoundKitId = 19378, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_CATACLYSM_CLASSIC", WOW_PROJECT_ID = 14, Race = "Worgen", Type = TYPE.F },
    { Name = "Pandaren Male", SoundKitId = 28927, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_MISTS_CLASSIC", WOW_PROJECT_ID = 15, Race = "Pandaren", Type = TYPE.M },
    { Name = "Pandaren Female", SoundKitId = 29793, WOW_PROJECT_CONST_NAME = "WOW_PROJECT_MISTS_CLASSIC", WOW_PROJECT_ID = 15, Race = "Pandaren", Type = TYPE.F },
}