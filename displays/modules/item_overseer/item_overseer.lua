local c = require("lib.gimp_colors")
local widgetsAreUs = require("lib.widgetsAreUs")
local contextMenu = require("displays.glasses_elements.contextMenu")
local PagedWindow = require("lib.PagedWindow")

local item_overseer = {}
item_overseer.players = {}

local itemBox_main
local itemBox_tracked
local levelMaintainer

local function init_display_storage(player)
    local suc, err = pcall(function()
        print("item_overseer: Initializing display storage for player " .. tostring(player))
        print("item_overseer: Getting glasses proxy for player " .. tostring(player))
        component.glasses = require("displays.glasses_display").getGlassesProxy(player)
        print("item_overseer: Accessing window for player " .. tostring(player))
        local window = item_overseer.players[player].window

        print("item_overseer: Checking if display exists for player " .. tostring(player))
        if item_overseer.players[player].display then
            print("item_overseer: Clearing displayed items for player " .. tostring(player))
            item_overseer.players[player].display:clearDisplayedItems()
            item_overseer.players[player].display = nil
        end
        local items = component.me_interface.getItemsInNetwork()
        print("item_overseer: Creating new PagedWindow for player " .. tostring(player))
        item_overseer.players[player].display = PagedWindow.new(items, 80, 35, {x1=window.x, y1=window.y+44,x2=window.x+window.width, y2=window.y+window.height-22}, 3, itemBox_main, {player})
        print("item_overseer: Displaying items for player " .. tostring(player))
        item_overseer.players[player].display:displayItems()
    end)
    if not suc then print(err) end
end

local function init_tracked(player)
    local suc, err = pcall(function()
        print("item_overseer: Initializing tracked items for player " .. tostring(player))
        print("item_overseer: Getting glasses proxy for player " .. tostring(player))
        component.glasses = require("displays.glasses_display").getGlassesProxy(player)
        print("item_overseer: Accessing window for player " .. tostring(player))
        local window = item_overseer.players[player].window

        print("item_overseer: Checking if display exists for player " .. tostring(player))
        if item_overseer.players[player].display then
            print("item_overseer: Clearing displayed items for player " .. tostring(player))
            item_overseer.players[player].display:clearDisplayedItems()
            item_overseer.players[player].display = nil
        end
        print("item_overseer: Creating new PagedWindow for tracked items for player " .. tostring(player))
        item_overseer.players[player].display = PagedWindow.new(item_overseer.players[player].monitored_items, 80, 35, {x1=window.x, y1=window.y+44,x2=window.x+window.width, y2=window.y+window.height-22}, 3, itemBox_tracked, {player})
        print("item_overseer: Displaying tracked items for player " .. tostring(player))
        item_overseer.players[player].display:displayItems()
    end)
    if not suc then print(err) end
end

local function init_crafting(player)
    local suc, err = pcall(function()
        print("item_overseer: Initializing crafting items for player " .. tostring(player))
        print("item_overseer: Getting glasses proxy for player " .. tostring(player))
        component.glasses = require("displays.glasses_display").getGlassesProxy(player)
        print("item_overseer: Accessing window for player " .. tostring(player))
        local window = item_overseer.players[player].window

        print("item_overseer: Checking if display exists for player " .. tostring(player))
        if item_overseer.players[player].display then
            print("item_overseer: Clearing displayed items for player " .. tostring(player))
            item_overseer.players[player].display:clearDisplayedItems()
            item_overseer.players[player].display = nil
        end
        print("item_overseer: Creating new PagedWindow for crafting items for player " .. tostring(player))
        item_overseer.players[player].display = PagedWindow.new(item_overseer.players[player].crafting_items, 150, 30, {x1=window.x, y1=window.y+44,x2=window.x+window.width, y2=window.y+window.height-22}, 3, levelMaintainer, {player})
        print("item_overseer: Displaying crafting items for player " .. tostring(player))
        item_overseer.players[player].display:displayItems()
    end)
    if not suc then print(err) end
end

function item_overseer.init(player)
    local suc, err = pcall(function()
        print("item_overseer: Initializing item overseer for player " .. tostring(player))
        print("item_overseer: Getting glasses proxy for player " .. tostring(player))
        component.glasses = require("displays.glasses_display").getGlassesProxy(player)
        print("item_overseer: Setting availableModules.item_overseer to nil for player " .. tostring(player))
        players[player].availableModules.item_overseer = nil
        local windowPre = players[player].hudSetup.elements.window
        local window = {}
        window.x = windowPre.x
        window.y = windowPre.y
        window.width = windowPre.x2-windowPre.x
        window.height = windowPre.y2-windowPre.y
        print("item_overseer: Initializing player table for " .. tostring(player))
        item_overseer.players[player] = {}
        item_overseer.players[player].window = window

        local cur_page = players[player].current_hudPage
        players[player].modules[cur_page].item_overseer = {}

        print("item_overseer: Initializing elements table for player " .. tostring(player))
        item_overseer.players[player].elements = {}
        print("item_overseer: Initializing monitored items table for player " .. tostring(player))
        item_overseer.players[player].monitored_items = {}
        print("item_overseer: Initializing crafting items table for player " .. tostring(player))
        item_overseer.players[player].crafting_items = {}

        print("item_overseer: Creating background element for player " .. tostring(player))
        local background = widgetsAreUs.createBox(window.x, window.y, window.width, window.height, c.background, 0.5)
        item_overseer.players[player].elements.background = background

        print("item_overseer: Creating search bar element for player " .. tostring(player))
        local search_bar = widgetsAreUs.searchBar(window.x, window.y, window.width)
        item_overseer.players[player].elements.search_bar = search_bar

        print("item_overseer: Creating navigation buttons for player " .. tostring(player))
        local function prev() item_overseer.players[player].display:prevPage() end
        local function next() item_overseer.players[player].display:nextPage() end
        local up_button = widgetsAreUs.symbolBox(window.x + ((window.width/2)-10), window.y+22, "▲", c.navbutton, prev)
        local down_button = widgetsAreUs.symbolBox(window.x + ((window.width/2)-10), window.y+window.height-22, "▼", c.navbutton, next)
        item_overseer.players[player].elements.up_button = up_button
        item_overseer.players[player].elements.down_button = down_button

        print("item_overseer: Creating display control buttons for player " .. tostring(player))
        local display_main = widgetsAreUs.symbolBox(window.x+3, window.y+22, "M", c.navbutton, init_display_storage, player)
        local display_monitored = widgetsAreUs.symbolBox(window.x+window.width-44, window.y+window.height-22, "T", c.navbutton, init_tracked, player)
        local display_crafting = widgetsAreUs.symbolBox(window.x+window.width-22, window.y+window.height-22, "C", c.navbutton, init_crafting, player)
        item_overseer.players[player].elements.button_main = display_main
        item_overseer.players[player].elements.button_tracked = display_monitored
        item_overseer.players[player].elements.button_crafting = display_crafting
    end)
    if not suc then print(err) end
end

-----------------------------------------------------
--- Updated Element Creation Functions

itemBox_main = function(x, y, itemstack, player)
    local suc, err = pcall(function()
        print("item_overseer: Creating main item box for player " .. tostring(player) .. ", itemstack: " .. tostring(itemstack.label))
        component.glasses = require("displays.glasses_display").getGlassesProxy(player)
        local function mainStorage_itemBox_context()
            print("item_overseer: Creating context menu for main item box for player " .. tostring(player))
            local context = contextMenu.init(x, y, player, {
                [1] = {text = "Add To Tracked (T)", func = function() table.insert(item_overseer.players[player].monitored_items, itemstack) end, args = {}},
                [2] = {text = "Add to Crafting (C)", func = function() item_overseer.players[player].crafting_items[itemstack.label] = {itemStack = itemstack, batch = 0, amount = 0} end, args = {}}
            })
            return true
        end

        local itemBox = widgetsAreUs.itemBox(x, y, itemstack)
        print("item_overseer: Attaching context menu to main item box for player " .. tostring(player))
        local new_itemBox = widgetsAreUs.attachOnClickRight(itemBox, mainStorage_itemBox_context)
        return new_itemBox
    end)
    if not suc then print(err) end
end

itemBox_tracked = function(x, y, itemstack, player)
    local suc, err = pcall(function()
        print("item_overseer: Creating tracked item box for player " .. tostring(player) .. ", itemstack: " .. tostring(itemstack.label))
        component.glasses = require("displays.glasses_display").getGlassesProxy(player)
        local function tracked_itemBox_context()
            print("item_overseer: Creating context menu for tracked item box for player " .. tostring(player))
            local context = contextMenu.init(x, y, player, {
                [1] = {text = "Remove From Tracked (T)", func = function()
                    print("item_overseer: Removing item from tracked items for player " .. tostring(player))
                    for index, monitored_item in ipairs(item_overseer.players[player].monitored_items) do
                        if monitored_item.label == itemstack.label then
                            table.remove(item_overseer.players[player].monitored_items, index)
                        end
                    end
                    print("item_overseer: Clearing displayed items and updating tracked items display for player " .. tostring(player))
                    item_overseer.players[player].display:clearDisplayedItems()
                    item_overseer.players[player].display = PagedWindow.new(item_overseer.players[player].monitored_items, 80, 35, {x1=item_overseer.players[player].window.x, y1=item_overseer.players[player].window.y+44,x2=item_overseer.players[player].window.x+item_overseer.players[player].window.width, y2=item_overseer.players[player].window.y+item_overseer.players[player].window.height-22}, 3, itemBox_tracked, {player})
                    item_overseer.players[player].display:displayItems()
                end, args = {}},
                [2] = {text = "Add to Crafting (C)", func = function() item_overseer.players[player].crafting_items[itemstack.label] = {itemStack = itemstack, batch = 0, amount = 0} end, args = {}}
            })
            return true
        end

        local itemBox = widgetsAreUs.itemBox(x, y, itemstack)
        print("item_overseer: Attaching context menu to tracked item box for player " .. tostring(player))
        local new_itemBox = widgetsAreUs.attachOnClickRight(itemBox, tracked_itemBox_context)
        return new_itemBox
    end)
    if not suc then print(err) end
end

levelMaintainer = function(x, y, argsTable, player)
    local suc, err = pcall(function()
        print("item_overseer: Creating level maintainer for player " .. tostring(player) .. ", itemStack: " .. tostring(argsTable.itemStack.label))
        component.glasses = require("displays.glasses_display").getGlassesProxy(player)
        local function levelMaintainer_context()
            print("item_overseer: Creating context menu for level maintainer for player " .. tostring(player))
            local context = contextMenu.init(x, y, player, {
                [1] = {text = "Remove From Crafting (C)", func = function()
                    print("item_overseer: Removing item from crafting items for player " .. tostring(player))
                    item_overseer.players[player].crafting_items[argsTable.itemStack.label] = nil
                    print("item_overseer: Clearing displayed items and updating crafting items display for player " .. tostring(player))
                    item_overseer.players[player].display:clearDisplayedItems()
                    item_overseer.players[player].display = PagedWindow.new(item_overseer.players[player].crafting_items, 150, 30, {x1=item_overseer.players[player].window.x, y1=item_overseer.players[player].window.y+44,x2=item_overseer.players[player].window.x+item_overseer.players[player].window.width, y2=item_overseer.players[player].window.y+item_overseer.players[player].window.height-22}, 3, levelMaintainer, {player})
                    item_overseer.players[player].display:displayItems()
                end, args = {}}
            })
            return true
        end

        local lm = widgetsAreUs.levelMaintainer(x, y, argsTable)
        print("item_overseer: Attaching context menu to level maintainer for player " .. tostring(player))
        local new_lm = widgetsAreUs.attachOnClickRight(lm, levelMaintainer_context)
        return new_lm
    end)
    if not suc then print(err) end
end

return item_overseer