local _, addon = ...
---@class KT
local KT = addon

-- TODO Better layout
--- Append sound kit related option to the section passed as parameter
---@param section any The section to modify
---@param profile KT.Profile
function KT.SoundKits.AppendOptions(section, profile)
        section.args.spaceBeforeSoundKit = {
            name = " ",
            type = "description",
            order = 8.2,
    }

    section.args.soundKitToggle = {
        name = "Use Sound Kit",
        type = "toggle",
        order = 8.21,
        width = "normal",
        get = function () return profile.useSoundKit end,
        set = function()
            profile.useSoundKit = not profile.useSoundKit
        end,
        disabled = function() return not profile.soundQuest end,
    }

    section.args.soundKitSection = {
        name = " ",
        type = "group",
        order = 8.3,
        disabled = function () return not profile.useSoundKit end,
        args = {
            listenButton = {
                name = "Listen",
                type = "execute",
                func = function()
                    KT.SoundKits.PlaySoundKits(profile.useRandomSoundKit, profile.selectedSoundKits)
                end,
                width = "full",
                order = 1
            },

            allToggle = {
                name = "All",
                type = "toggle",
                get = function () return profile.useRandomSoundKit end,
                set = function(self, value)
                    profile.useRandomSoundKit = value

                    if value then
                        for keyIndex, value in pairs(KT.SoundKits.GetAvailableSoundKits()) do
                            profile.selectedSoundKits[keyIndex] = keyIndex
                        end
                    else
                        table.wipe(profile.selectedSoundKits)
                    end
                end,
                order = 2
            },
            femaleToggle = {
                name = "Female",
                type = "toggle",
                get = function () return profile.toggleFemale end,
                set = function(self, toggleFemale)
                    profile.toggleFemale = toggleFemale

                    for keyIndex, skValue in pairs(KT.SoundKits.GetAvailableSoundKits()) do
                        if skValue.Type == 2 then
                            if toggleFemale then
                                profile.selectedSoundKits[keyIndex] = keyIndex
                            else
                                profile.selectedSoundKits[keyIndex] = nil
                            end
                        end
                    end
                end,
                order = 2.1
            },
            maleToggle = {
                name = "Male",
                type = "toggle",
                get = function () return profile.toggleMale end,
                set = function(self, toggleMale)
                    profile.toggleMale = toggleMale

                    for keyIndex, skValue in pairs(KT.SoundKits.GetAvailableSoundKits()) do
                        if skValue.Type == 1 then
                            if toggleMale then
                                profile.selectedSoundKits[keyIndex] = keyIndex
                            else
                                profile.selectedSoundKits[keyIndex] = nil
                            end
                        end
                    end
                end,
                order = 2.2
            },

            allianceToggle = {
                name = "Alliance",
                type = "toggle",
                get = function () return profile.toggleAlliance end,
                set = function(self, toggleAlliance)
                    profile.toggleAlliance = toggleAlliance

                    for keyIndex, skValue in pairs(KT.SoundKits.GetAvailableSoundKits()) do
                        if skValue.Faction == 1 then
                            if toggleAlliance then
                                profile.selectedSoundKits[keyIndex] = keyIndex
                            else
                                profile.selectedSoundKits[keyIndex] = nil
                            end
                        end
                    end
                end,
                order = 3
            },
            hordeToggle = {
                name = "Horde",
                type = "toggle",
                get = function () return profile.toggleHorde end,
                set = function(self, toggleHorde)
                    profile.toggleHorde = toggleHorde

                    for keyIndex, skValue in pairs(KT.SoundKits.GetAvailableSoundKits()) do
                        if skValue.Faction == 2 then
                            if toggleHorde then
                                profile.selectedSoundKits[keyIndex] = keyIndex
                            else
                                profile.selectedSoundKits[keyIndex] = nil
                            end
                        end
                    end
                end,
                order = 3
            },
            neutralToggle = {
                name = "Neutral",
                type = "toggle",
                get = function () return profile.toggleNeutral end,
                set = function(self, toggleNeutral)
                    profile.toggleNeutral = toggleNeutral

                    for keyIndex, skValue in pairs(KT.SoundKits.GetAvailableSoundKits()) do
                        if skValue.Faction == 3 then
                            if toggleNeutral then
                                profile.selectedSoundKits[keyIndex] = keyIndex
                            else
                                profile.selectedSoundKits[keyIndex] = nil
                            end
                        end
                    end
                end,
                order = 3
            },

            soundKitSelect = {
                name = "Specific",
                type = "multiselect",
                values = KT.SoundKits.GetAvailableSoundKitNames(),
                get = function(self, keyIndex)
                    if profile.selectedSoundKits[keyIndex] then return keyIndex end
                end,
                set = function(self, keyIndex, isSelected)
                    if isSelected then
                        profile.selectedSoundKits[keyIndex] = keyIndex
                    else
                        profile.selectedSoundKits[keyIndex] = nil
                    end
                end,
                order = 10,
            }
        }
    }
end