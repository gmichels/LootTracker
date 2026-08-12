import "Turbine";
import "LootTracker";

local function GetCharacterName()
    local player = Turbine.Gameplay.LocalPlayer.GetInstance();
    return player:GetName();
end

local lootWindow = LootTrackerWindow();

-- cache the current character name so we don't call the API on every chat message
local currentCharacterName = nil;

function HandleReceivedMessage(sender, args)
    local characterName = currentCharacterName or GetCharacterName();
    local message = args.Message or "";
    local user = message:match('(.+) has acquired');
    if not user or user == "" then
        if message:match('^You have acquired') then
            user = characterName;
        end
    end
    if not user or user == "" then
        user = nil;
    end

    if (args.ChatType == Turbine.ChatType.FellowLoot or user) then
        -- Turbine.Shell.WriteLine("LootTracker received: " .. message);
        local idHex = message:match('<Examine:IIDDID:.*:(.*)>%b[]<\\Examine>');
        local infoStr = message:match('<ExamineItemInstance:ItemInfo:(.*)>%b[]<\\ExamineItemInstance>');
        local id = (idHex and idHex) or (infoStr and "0x" .. GetHex(ItemLinkDecode.DecodeLinkData(infoStr, false).itemGID));

        if id then
            -- Turbine.Shell.WriteLine("LootTracker: adding to history id=" .. id);
            local time = Turbine.Engine.GetLocalTime();
            local data = {
                id = id,
                user = user or characterName or "Unknown",
                time = time,
            };
            table.insert(_G.lootTrackerHistory, data);
            lootWindow:Refresh();
        end
    end
end

Turbine.Chat.Received = HandleReceivedMessage;

-- command
OpenLootTrackerWindow = Turbine.ShellCommand();

function OpenLootTrackerWindow:Execute(cmd, args)
    lootWindow:SetVisible(true);
end

Turbine.Shell.AddCommand("lt", OpenLootTrackerWindow);

-- load / unload
Plugins.LootTracker.Load = function ()
    local characterName = GetCharacterName();
    currentCharacterName = characterName;
    local historyKey = "LootTrackerHistory";
    local windowKey = "LootTrackerWindow";
    local rawLootList = Turbine.PluginData.Load(Turbine.DataScope.Character, historyKey) or {};
    local windowState = Turbine.PluginData.Load(Turbine.DataScope.Character, windowKey) or {};
    _G.lootTrackerHistory = FilterLootTrackerListPeriod(rawLootList, ONE_DAY_IN_SECONDS);
    table.sort(_G.lootTrackerHistory, function (a, b)
        return a.time < b.time;
    end);
    if windowState.left and windowState.top then
        lootWindow:SetPosition(windowState.left, windowState.top);
    end
    if windowState.qualityFilter then
        lootWindow:RestoreQualityFilter(windowState.qualityFilter);
    end
    if characterName then
        lootWindow:SetCharacterName(characterName);
    end
    lootWindow:LoadData(_G.lootTrackerHistory);
end

Plugins.LootTracker.Unload = function ()
    local historyKey = "LootTrackerHistory";
    local windowKey = "LootTrackerWindow";
    local filteredLootList = FilterLootTrackerListPeriod(_G.lootTrackerHistory or {}, ONE_DAY_IN_SECONDS);
    Turbine.PluginData.Save(Turbine.DataScope.Character, historyKey, filteredLootList);
    Turbine.PluginData.Save(Turbine.DataScope.Character, windowKey, {
        left = lootWindow:GetLeft(),
        top = lootWindow:GetTop(),
        qualityFilter = lootWindow:GetQualityFilter(),
    });
    currentCharacterName = nil;
end
