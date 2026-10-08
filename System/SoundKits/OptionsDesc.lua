local _, addon = ...
---@class KT
local KT = addon

---@param profile KT.Profile
---@return table table Description for this option section
function KT.SoundKits.AppendOptions(section, profile)
    section.args.soundKitToggle = {
        name = "Use Sound Kit",
        type = "toggle",
        set = function()
            profile.useSoundKit = not profile.useSoundKit
        end,
        get = function () return profile.useSoundKit end,
        order = 8.2,
    }

    section.args.soundKitSection = {
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
            useSoundKitButton = {
                name = "Listen",
                type = "execute",
                func = function()
                    KT.SoundKits.PlaySoundKit(profile.useRandomSoundKit, profile.selectedSoundKits)
                end,
                width = "half",
                order = 2
            },
            soundKitSelect = {
                name = "Sound kit",
                type = "multiselect",
                values = KT.SoundKits.GetAvailableSoundKitNames(),
                -- TODO Implements
                get = function(self, keyIndex)
                    if profile.selectedSoundKits[keyIndex] then return keyIndex end
                end,
                set = function(self, keyIndex, isSelected)
                    local printableBool
                    if isSelected then printableBool = "true" else printableBool = "false" end

                    KT.Utils.Log(keyIndex)
                    KT.Utils.Log("Is selected =>".. printableBool)

                    if isSelected then
                        table.insert(profile.selectedSoundKits, keyIndex, keyIndex)
                    else 
                        table.remove(profile.selectedSoundKits, keyIndex)
                    end

                    KT.Utils.Log(KT.Utils.Dump(profile.selectedSoundKits, 2))
                end,
                order = 3,
                disabled = function()
                    return profile.useRandomSoundKit
                end
            }
        }
    }
end