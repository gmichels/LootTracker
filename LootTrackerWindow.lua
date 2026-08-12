import "Turbine";
import "Turbine.UI";
import "Turbine.UI.Lotro";
import "Turbine.Gameplay";

LootTrackerWindow = class(Turbine.UI.Lotro.Window);

function LootTrackerWindow:Constructor(characterName)
	Turbine.UI.Lotro.Window.Constructor(self);

    self.history = {};
    self.characterName = characterName or "Unknown";
    self.activeTab = "Group";

    -- Quality filter state: all qualities enabled by default
    self.qualityFilter = {};
    self.qualityFilter[Turbine.Gameplay.ItemQuality.Common] = true;
    self.qualityFilter[Turbine.Gameplay.ItemQuality.Uncommon] = true;
    self.qualityFilter[Turbine.Gameplay.ItemQuality.Rare] = true;
    self.qualityFilter[Turbine.Gameplay.ItemQuality.Incomparable] = true;
    self.qualityFilter[Turbine.Gameplay.ItemQuality.Legendary] = true;

    self:SetSize(600, 420);
    self:SetText("LootTracker");

    -- Buttons
    self.tabGroup = Turbine.UI.Lotro.Button();
    self.tabGroup:SetParent(self);
    self.tabGroup:SetPosition(18, 42);
    self.tabGroup:SetSize(90, 28);
    self.tabGroup:SetText("Group");
    self.tabGroup.Click = function()
        self:SetActiveTab("Group");
    end

    self.tabMine = Turbine.UI.Lotro.Button();
    self.tabMine:SetParent(self);
    self.tabMine:SetPosition(118, 42);
    self.tabMine:SetSize(90, 28);
    self.tabMine:SetText("Mine");
    self.tabMine.Click = function()
        self:SetActiveTab("Mine");
    end

    self.clearButton = Turbine.UI.Lotro.Button();
    self.clearButton:SetParent(self);
    self.clearButton:SetPosition(500, 42);
    self.clearButton:SetSize(80, 28);
    self.clearButton:SetText("Clear");
    self.clearButton.Click = function()
        self.history = {};
        _G.lootTrackerHistory = self.history;
        self:ClearList();
    end

    -- Quality filter checkboxes
    local qualityCheckboxes = {
        {quality = Turbine.Gameplay.ItemQuality.Common, name = "Common", x = 25},
        {quality = Turbine.Gameplay.ItemQuality.Uncommon, name = "Uncommon", x = 130},
        {quality = Turbine.Gameplay.ItemQuality.Rare, name = "Rare", x = 250},
        {quality = Turbine.Gameplay.ItemQuality.Incomparable, name = "Incomparable", x = 340},
        {quality = Turbine.Gameplay.ItemQuality.Legendary, name = "Legendary", x = 480},
    };

    self.qualityCheckboxes = {};
    for _, qinfo in ipairs(qualityCheckboxes) do
        local checkbox = Turbine.UI.Lotro.CheckBox();
        checkbox:SetParent(self);
        checkbox:SetPosition(qinfo.x, 70);
        checkbox:SetSize(120, 18);
        checkbox:SetText(qinfo.name);
        checkbox:SetChecked(true);
        local quality = qinfo.quality;
        checkbox.CheckedChanged = function()
            self.qualityFilter[quality] = checkbox:IsChecked();
            self:Refresh();
        end
        table.insert(self.qualityCheckboxes, checkbox);
    end


    -- Scroll bars
    self.verticalScrollbar = Turbine.UI.Lotro.ScrollBar();
    self.verticalScrollbar:SetOrientation(Turbine.UI.Orientation.Vertical);
    self.verticalScrollbar:SetParent(self);
    self.verticalScrollbar:SetZOrder(1);
    self.verticalScrollbar:SetPosition(600 - 20, 78);
    self.verticalScrollbar:SetSize(10, 420 - 98);


    -- Content list
    self.list = Turbine.UI.ListBox();
    self.list:SetParent(self);
    self.list:SetPosition(20, 88);
    self.list:SetSize(600 - 40, 420 - 108);
    self.list:SetVerticalScrollBar(self.verticalScrollbar);

    self:SetActiveTab(self.activeTab);
end

function LootTrackerWindow:SetCharacterName(name)
    self.characterName = name or self.characterName;
    self:SetText("LootTracker: " .. self.characterName);
    self:Refresh();
end

function LootTrackerWindow:SetActiveTab(tabName)
    self.activeTab = tabName;
    self:Refresh();
end

function LootTrackerWindow:AddItemToList(data)
    local item = LootTrackerItem(data);
    item:SetParent(self);
    self.list:InsertItem(-1, item);
end

function LootTrackerWindow:ClearList()
    while self.list:GetItemCount() > 0 do
        self.list:RemoveItemAt(1);
    end
end

function LootTrackerWindow:Refresh()
    local displayData = {};

    for _, data in pairs(self.history) do
        -- Tab filter
        local passesTabFilter = false;
        if self.activeTab == "Group" then
            passesTabFilter = (data.user ~= self.characterName);
        else
            passesTabFilter = (data.user == self.characterName);
        end

        if passesTabFilter then
            -- Quality filter: try to get item quality
            local passesQualityFilter = true;
            local itemInspect = ItemInspect(data.id);
            local itemInfo = itemInspect:GetItemInfo();
            if itemInfo then
                local quality = itemInfo:GetQuality();
                passesQualityFilter = self.qualityFilter[quality] or false;
            end

            if passesQualityFilter then
                table.insert(displayData, data);
            end
        end
    end

    self:ClearList();
    for _, data in pairs(displayData) do
        self:AddItemToList(data);
    end
end

function LootTrackerWindow:LoadData(dataList)
    self.history = dataList or {};
    self:Refresh();
end
function LootTrackerWindow:GetQualityFilter()
    return self.qualityFilter;
end

function LootTrackerWindow:RestoreQualityFilter(savedFilter)
    if not savedFilter then
        return;
    end
    for quality, enabled in pairs(savedFilter) do
        self.qualityFilter[quality] = enabled;
    end
    -- Update checkbox states to match restored filter
    for i, checkbox in ipairs(self.qualityCheckboxes) do
        local qinfo = {
            {quality = Turbine.Gameplay.ItemQuality.Common},
            {quality = Turbine.Gameplay.ItemQuality.Uncommon},
            {quality = Turbine.Gameplay.ItemQuality.Rare},
            {quality = Turbine.Gameplay.ItemQuality.Legendary},
            {quality = Turbine.Gameplay.ItemQuality.Incomparable},
        };
        if i <= #qinfo then
            checkbox:SetChecked(self.qualityFilter[qinfo[i].quality] or false);
        end
    end
    self:Refresh();
end
