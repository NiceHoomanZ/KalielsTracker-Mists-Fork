local Util = {}

Util.FORMAT_itemid = "item:%d:0:0:0:0:0:0:0"
Util.PATTERN_itemlink = "|c%x+|H"..Util.PATTERN_itemid.."|h%[.-%]|h|r"
Util.PATTERN_itemid = "item:(%-?%d+):%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+"

---@param object any
---@param depth number
---@param current number?
function Util.Dump(object, depth, current)
	if current == nil then current = 0 end

	if type(object) == 'table' then
		if(current > depth) then return "TABLE" end

		local s = '{ '
      for k,v in pairs(object) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. Util.Dump(v, depth, current + 1) .. ','
      end
      return s .. '} '
   else
		return tostring(object)
   end
end

---@param object any
---@param depth number?
function Util.PrintDump(object, depth)
	if depth == nil then depth = 1 end
	print(Util.Dump(object, depth))
end

---From LibQuestItem addon
---@param link any
---@return number
function Util.GetBaseId(link)
	if link then
		if type(link) == "number" then return link end
		local baseid = strmatch(link, Util.PATTERN_itemlink)
		if not baseid then
			baseid = strmatch(link, Util.PATTERN_itemid)
		end
		if not baseid then
			baseid = link
		end
		return tonumber(baseid)
	end
	return 0
end

---From LibQuestItem addon
---@param itemId string|number
---@return string
function Util.GetItemString(itemId)
	return string.format(Util.FORMAT_itemid, itemId)
end

-- *****************************************************************************************************
-- ***** ITEM FUNCTIONS
-- *****************************************************************************************************
local function OnRelease(framePool, frame)
	frame:Hide();
	frame:ClearAllPoints();
	frame:SetParent(nil);
end

local g_questObjectiveItemPool = CreateFramePool("BUTTON", nil, "QuestObjectiveItemButtonTemplate", OnRelease);
function QuestObjectiveItem_AcquireButton(parent)
	local itemButton = g_questObjectiveItemPool:Acquire();
	itemButton:SetParent(parent);

	return itemButton;
end

function QuestObjectiveItem_ReleaseButton(button)
	g_questObjectiveItemPool:Release(button);
end

function QuestObjectiveItem_Initialize(itemButton, questLogIndex)
	local link, iconID, charges = GetQuestLogSpecialItemInfo(questLogIndex);
	itemButton:SetID(questLogIndex);
	itemButton.link = link;
	itemButton.charges = charges;
	itemButton.rangeTimer = -1;
	SetItemButtonTexture(itemButton, iconID);
	SetItemButtonCount(itemButton, charges);

	local itemId = Util.GetBaseId(link)
	print("Item link => " .. (link or "Nil"))
	print("Item id => " .. (itemId or "Nil"))
	local item = Util.GetItemString(itemId)
	print("Item => " .. (itemId or "Nil"))
	itemButton:SetAttribute("item", item)

	print("Item after initial full initialisation")
	print(itemButton:GetAttribute("item"))
	
	QuestObjectiveItem_UpdateCooldown(itemButton);
end

function QuestObjectiveItem_OnLoad(self)
	self:RegisterForClicks("AnyUp");
end

--- It doesn't work because the "UseQuestLogSpecialItem" WoW function is bugged on this version :
--- It "taints" (modify) the C code on execution so it needs a workaround.
--- The bug is well known.
--- https://warcraft.wiki.gg/wiki/SecureActionButtonTemplate
---@param button Button
---@param mouseButton string
function QuestObjectiveItem_OnClick(button, mouseButton)
	if ( IsModifiedClick("CHATLINK") and ChatEdit_GetActiveWindow() ) then
		local link = GetQuestLogSpecialItemInfo(button:GetID());
		if ( link ) then
			ChatEdit_InsertLink(link);
		end
	else
		print("Time UTC => " .. time())
		print("Click using button => " .. mouseButton);
		-- UseQuestLogSpecialItem(button:GetID());			-- Protected function
	end
end

function QuestObjectiveItem_OnEvent(self, event, ...)
	if ( event == "PLAYER_TARGET_CHANGED" ) then
		self.rangeTimer = -1;
	elseif ( event == "BAG_UPDATE_COOLDOWN" ) then
		QuestObjectiveItem_UpdateCooldown(self);
	end
end

function QuestObjectiveItem_OnUpdate(self, elapsed)
	-- Handle range indicator
	local rangeTimer = self.rangeTimer;
	if ( rangeTimer ) then
		rangeTimer = rangeTimer - elapsed;
		if ( rangeTimer <= 0 ) then
			local link, item, charges, showItemWhenComplete = GetQuestLogSpecialItemInfo(self:GetID());
			if ( not charges or charges ~= self.charges ) then
				ObjectiveTracker_Update(OBJECTIVE_TRACKER_UPDATE_MODULE_QUEST);
				return;
			end
			local count = self.HotKey;
			local valid = IsQuestLogSpecialItemInRange(self:GetID());
			if ( valid == 0 ) then
				count:Show();
				count:SetVertexColor(1.0, 0.1, 0.1);
			elseif ( valid == 1 ) then
				count:Show();
				count:SetVertexColor(0.6, 0.6, 0.6);
			else
				count:Hide();
			end
			rangeTimer = TOOLTIP_UPDATE_TIME;
		end

		self.rangeTimer = rangeTimer;
	end
end

function QuestObjectiveItem_OnShow(self)
	self:RegisterEvent("PLAYER_TARGET_CHANGED");
	self:RegisterEvent("BAG_UPDATE_COOLDOWN");
end

function QuestObjectiveItem_OnHide(self)
	self:UnregisterEvent("PLAYER_TARGET_CHANGED");
	self:UnregisterEvent("BAG_UPDATE_COOLDOWN");
end

function QuestObjectiveItem_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetQuestLogSpecialItem(self:GetID());
end

function QuestObjectiveItem_UpdateCooldown(itemButton)
	local start, duration, enable = GetQuestLogSpecialItemCooldown(itemButton:GetID());
	if ( start ) then
		CooldownFrame_Set(itemButton.Cooldown, start, duration, enable);
		if ( duration > 0 and enable == 0 ) then
			SetItemButtonTextureVertexColor(itemButton, 0.4, 0.4, 0.4);
		else
			SetItemButtonTextureVertexColor(itemButton, 1, 1, 1);
		end
	end
end

local g_questFindGroupButtonPool = CreateFramePool("BUTTON", nil, "QuestObjectiveFindGroupButtonTemplate", OnRelease);
function QuestObjectiveFindGroup_AcquireButton(parent, questID)
	local button = g_questFindGroupButtonPool:Acquire();
	button:SetParent(parent);
	button.questID = questID;

	return button;
end

function QuestObjectiveFindGroup_ReleaseButton(self)
	self.questID = nil;
	g_questFindGroupButtonPool:Release(self);
end

function QuestObjectiveFindGroup_OnMouseDown(self)
	if self:IsEnabled() then
		self.Icon:SetPoint("CENTER", self, "CENTER", -2, -1);
	end
end

function QuestObjectiveFindGroup_OnMouseUp(self)
	if self:IsEnabled() then
		self.Icon:SetPoint("CENTER", self, "CENTER", -1, 0);
	end
end

function QuestObjectiveFindGroup_OnEnter(self)
	GameTooltip:SetOwner(self);
	GameTooltip:AddLine(TOOLTIP_TRACKER_FIND_GROUP_BUTTON, HIGHLIGHT_FONT_COLOR:GetRGB());

	GameTooltip:Show();
end

function QuestObjectiveFindGroup_OnLeave(self)
	GameTooltip:Hide();
end

function QuestObjectiveFindGroup_OnClick(self)
	local isFromGreenEyeButton = true;
	--We only want green eye button groups to display the create a group button if there are already groups there. 
	LFGListUtil_FindQuestGroup(self.questID, isFromGreenEyeButton);
end

local defaultInitialAnchorOffsets = { 0, 0 };

function QuestObjectiveSetupBlockButton_AddRightButton(block, button, initialAnchorOffsets)
	if block.rightButton == button then
		-- TODO: Fix for real, some event causes the findGroup button to get added twice (could happen for any button)
		-- so it doesn't need to be reanchored another time
		return;
	end

	button:ClearAllPoints();

	local paddingBetweenButtons = block.module.paddingBetweenButtons or 0;

	if block.rightButton then
		button:SetPoint("RIGHT", block.rightButton, "LEFT", -paddingBetweenButtons, 0);
	else
		initialAnchorOffsets = initialAnchorOffsets or defaultInitialAnchorOffsets;
		button:SetPoint("TOPRIGHT", block, initialAnchorOffsets[1], initialAnchorOffsets[2]);
	end

	button:Show();

	block.rightButton = button;
	block.lineWidth = block.lineWidth - button:GetWidth() - paddingBetweenButtons;
end

function QuestObjectiveSetupBlockButton_FindGroup(block, questID)
	return false
end

function QuestObjectiveReleaseBlockButton_FindGroup(block)
	block.hasGroupFinderButton = nil;

	if block.groupFinderButton then
		QuestObjectiveFindGroup_ReleaseButton(block.groupFinderButton);
		block.groupFinderButton = nil;
	end
end

function QuestObjectiveSetupBlockButton_Item(block, questLogIndex, isQuestComplete)
	local _, item, _, showItemWhenComplete = GetQuestLogSpecialItemInfo(questLogIndex);
	local shouldShowItem = item and (not isQuestComplete or showItemWhenComplete);

	if shouldShowItem then
		local itemButton = block.itemButton;
		if not itemButton then
			itemButton = QuestObjectiveItem_AcquireButton(block);
			block.itemButton = itemButton;
		end

		QuestObjectiveItem_Initialize(itemButton, questLogIndex);
		QuestObjectiveSetupBlockButton_AddRightButton(block, itemButton, block.module.buttonOffsets.useItem);
	else
		QuestObjectiveReleaseBlockButton_Item(block);
	end

	return shouldShowItem;
end

function QuestObjectiveReleaseBlockButton_Item(block)
	if block.itemButton then
		QuestObjectiveItem_ReleaseButton(block.itemButton);
		block.itemButton = nil;
	end
end

function QuestObjective_SetupHeader(block, initialLineWidth)
	block.rightButton = nil;
	block.lineWidth = initialLineWidth or OBJECTIVE_TRACKER_TEXT_WIDTH;
end
