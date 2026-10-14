---@meta KalielsTracker

---@class KT.QuestBlock: Frame Frame containing the quest information
---@field id integer
---@field fixedTag Frame | BackdropTemplate
---@field itemButton KT.QuestButton

---@class KT.QuestButtonBar: Frame, BackdropTemplate
---@field shouldRefresh boolean
---@field buttonCount integer

---@class KT.QuestButton: Button, SecureActionButtonTemplate Quest button item
---@field icon SimpleTexture
---@field Count SimpleFontString
---@field Cooldown table | Cooldown | CooldownFrameTemplate
---@field HotKey SimpleFontString
---@field text SimpleFontString
---@field rangeTimer number
---@field charges number
---@field link string
---@field item number

---@alias Direction
---|"Up"
---|"Down"
---|"Left"
---|"Right"