import "Turbine";
import "Turbine.UI";
import "Turbine.UI.Lotro";

LootTrackerWindow = class(Turbine.UI.Lotro.Window);

function LootTrackerWindow:Constructor(characterName)
	Turbine.UI.Lotro.Window.Constructor(self);

    self.history = {};
    self.characterName = characterName or "Unknown";
    self.activeTab = "Group";

    self:SetSize(500, 420);
    self:SetText("LootTracker");

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
    self.clearButton:SetPosition(400, 42);
    self.clearButton:SetSize(80, 28);
    self.clearButton:SetText("Clear");
    self.clearButton.Click = function()
        self.history = {};
        _G.lootTrackerHistory = self.history;
        self:ClearList();
    end

    self.verticalScrollbar = Turbine.UI.Lotro.ScrollBar();
    self.verticalScrollbar:SetOrientation(Turbine.UI.Orientation.Vertical);
    self.verticalScrollbar:SetParent(self);
    self.verticalScrollbar:SetZOrder(1);
    self.verticalScrollbar:SetPosition(500 - 20, 78);
    self.verticalScrollbar:SetSize(10, 420 - 98);

    self.list = Turbine.UI.ListBox();
    self.list:SetParent(self);
    self.list:SetPosition(20, 78);
    self.list:SetSize(500 - 40, 420 - 98);
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
    if self.activeTab == "Group" then
        for _, data in pairs(self.history) do
            if data.user ~= self.characterName then
                table.insert(displayData, data);
            end
        end
    else
        for _, data in pairs(self.history) do
            if data.user == self.characterName then
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