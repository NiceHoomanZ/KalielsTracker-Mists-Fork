-- TODO Move the source csv to a folder external to the addon
-- TODO Update Changelog, version, TOC credit...

local _, addon = ...
---@class KT
local KT = addon

---@class SoundKits
---@field AllSoundKits SoundKits.SoundKit[]
local SoundKits = {}
KT.SoundKits = SoundKits;

---@type SoundKits.SoundKit[]?
local availableSoundKits = nil

---@return SoundKits.SoundKit[]
function SoundKits.GetAvailableSoundKits()
    if availableSoundKits ~= nil then return availableSoundKits end

    availableSoundKits = {}
    
    for _, soundKit in ipairs(SoundKits.AllSoundKits) do
            if WOW_PROJECT_ID >= soundKit.WOW_PROJECT_ID then
                table.insert(availableSoundKits, soundKit)
            end
    end

    return availableSoundKits
end

function SoundKits.GetAvailableSoundKitNames()
    local availableSoundKitNames = {}

    for index, soundKit in ipairs(SoundKits.GetAvailableSoundKits()) do
        availableSoundKitNames[index] = soundKit.Name
    end

    return availableSoundKitNames
end

---Either play a random sound among all or among the list of the specified sound kit.
---@param useRandom boolean
---@param indexDict { [integer]: integer }?
function SoundKits.PlaySoundKits(useRandom, indexDict)
    if useRandom then
        SoundKits:PlayRandomSK()
        return
    end

    SoundKits.PlayRandomSKAmongIndexes(indexDict)
end

---@private
---@param indexDict { [integer]: integer }
function SoundKits.PlayRandomSKAmongIndexes(indexDict)
    if next(indexDict) == nil then
        KT.Utils.LogError("No sound kit to play !")
        return
    end

    local indexArray = {}
    for _, value in pairs(indexDict) do
        table.insert(indexArray, value)
    end

    local randIndex = random(#indexArray)
    local skRandIndex = indexArray[randIndex]

    local soundKit = SoundKits:GetAvailableSoundKits()[skRandIndex]
    PlaySound(soundKit.Id, "SFX")
end

---@private
function SoundKits.PlayRandomSK()
    local randIndex = math.random(#SoundKits:GetAvailableSoundKits())
    local soundKit = SoundKits:GetAvailableSoundKits()[randIndex]
    PlaySound(soundKit.Id, "SFX")
end