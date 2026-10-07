-- TODO Move the source csv to a folder external to the addon
-- TODO Allow to select many sound kits
-- TODO Fix bottom of settings not being displayed fully

local _, addon = ...
---@class KT
local KT = addon

---@class SoundKitHelper
local SoundKitHelper = {}
KT.SoundKitHelper = SoundKitHelper;

---@enum SoundKit.Type
local TYPE = {
    M = 1,
    F = 2
}

---@class SoundKit
---@field Name string
---@field SoundKitId integer
---@field WOW_PROJECT_CONST_NAME string
---@field WOW_PROJECT_ID integer
---@field Race string
---@field Type SoundKit.Type

---@type SoundKit[]
local allSoundKits = {
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

---@type SoundKit[]?
local availableSoundKits = nil

---@private
---@return SoundKit[]
function SoundKitHelper.GetAvailableSoundKits()
    if availableSoundKits ~= nil then return availableSoundKits end

    availableSoundKits = {}
    
    for _, soundKit in ipairs(allSoundKits) do
            if WOW_PROJECT_ID >= soundKit.WOW_PROJECT_ID then
                table.insert(availableSoundKits, soundKit)
            end
    end

    return availableSoundKits
end

function SoundKitHelper.GetAvailableSoundKitNames()
    local availableSoundKitNames = {}

    for index, soundKit in ipairs(SoundKitHelper.GetAvailableSoundKits()) do
        availableSoundKitNames[index] = soundKit.Name
    end

    return availableSoundKitNames
end

---Either play a random sound among all or among the list of the specified sound kit.
---@param useRandom boolean
---@param index integer?
function SoundKitHelper.PlaySoundKit(useRandom, index)
    if useRandom then
        SoundKitHelper.PlayRandomSK()
        return
    end

    SoundKitHelper.PlaySKByIndex(index)
end

---@private
---@param index integer
function SoundKitHelper.PlaySKByIndex(index)
    local sk = SoundKitHelper.GetAvailableSoundKits()[index]
    PlaySound(sk.SoundKitId, "SFX")
end

---@private
function SoundKitHelper.PlayRandomSK()
    local randIndex = math.random(#SoundKitHelper.GetAvailableSoundKits())
    local soundKit = SoundKitHelper.GetAvailableSoundKits()[randIndex]
    PlaySound(soundKit.SoundKitId, "SFX")
end

SoundKitHelper.OptionsDesc = {
    name = "Sound kit",
    type = "group",
    disabled = function () return KT.db.profile.useSoundKit == false end,
    hidden = function () return KT.db.profile.useSoundKit == false end,
    args = {
        randomizeSoundKit = {
            name = "Use random sound",
            type = "toggle",
            set = function()
                KT.db.profile.useRandomSoundKit = not KT.db.profile.useRandomSoundKit
            end,
            get = function () return KT.db.profile.useRandomSoundKit end,
            order = 1,
        },
        soundKitSelect = {
            name = "Random Sound",
            desc = "Sound kits",
            type = "select",
            values = KT.SoundKitHelper.GetAvailableSoundKitNames(),
            get = function()
                return KT.db.profile.selectedSoundKit
            end,
            set = function(_, value)
                KT.db.profile.selectedSoundKit = value
            end,
            order = 2,
            disabled = function()
                return KT.db.profile.useRandomSoundKit
            end
        },
        useSoundKitButton = {
            name = "Listen",
            type = "execute",
            func = function()
                KT.SoundKitHelper.PlaySoundKit(KT.db.profile.useRandomSoundKit, KT.db.profile.selectedSoundKit)
            end,
            width = "half",
            order = 3
        },
    }
}