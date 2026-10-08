local _, addon = ...
---@class KT
local KT = addon

---@param profile KT.Profile
---@return table table Description for this option section
function KT.SoundKits.GetOptionsDesc(profile)
    return {
        name = "Sound kit",
        type = "group",
        disabled = function () return profile.useSoundKit == false end,
        hidden = function () return profile.useSoundKit == false end,
        args = {
            randomizeSoundKit = {
                name = "Use random sound",
                type = "toggle",
                set = function()
                    profile.useRandomSoundKit = not profile.useRandomSoundKit
                end,
                get = function () return profile.useRandomSoundKit end,
                order = 1,
            },
            soundKitSelect = {
                name = "Random Sound",
                desc = "Sound kits",
                type = "select",
                values = KT.SoundKits.GetAvailableSoundKitNames(),
                get = function()
                    return profile.selectedSoundKit
                end,
                set = function(_, value)
                    profile.selectedSoundKit = value
                end,
                order = 2,
                disabled = function()
                    return profile.useRandomSoundKit
                end
            },
            useSoundKitButton = {
                name = "Listen",
                type = "execute",
                func = function()
                    KT.SoundKits.PlaySoundKit(profile.useRandomSoundKit, profile.selectedSoundKit)
                end,
                width = "half",
                order = 3
            }
        }
    }
end