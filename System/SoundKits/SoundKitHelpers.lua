-- TODO Move the source csv to a folder external to the addon
-- TODO Allow to select many sound kits
-- TODO Fix bottom of settings not being displayed fully
-- TODO Split file and make a folder

local _, addon = ...
---@class KT
local KT = addon

---@class SoundKits
---@field AllSoundKits SoundKits.SoundKit[]
local SoundKits = {}
KT.SoundKits = SoundKits;

---@type SoundKits.SoundKit[]?
local availableSoundKits = nil

---@private
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
---@param index integer?
function SoundKits.PlaySoundKit(useRandom, index)
    if useRandom then
        SoundKits:PlayRandomSK()
        return
    end

    SoundKits.PlaySKByIndex(index)
end

---@private
---@param index integer
function SoundKits.PlaySKByIndex(index)
    local sk = SoundKits:GetAvailableSoundKits()[index]
    PlaySound(sk.SoundKitId, "SFX")
end

---@private
function SoundKits.PlayRandomSK()
    local randIndex = math.random(#SoundKits:GetAvailableSoundKits())
    local soundKit = SoundKits:GetAvailableSoundKits()[randIndex]
    PlaySound(soundKit.SoundKitId, "SFX")
end