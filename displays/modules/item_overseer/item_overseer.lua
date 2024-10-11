local c = require("lib.gimp_colors")
local widgetsAreUs = require("lib.widgetsAreUs")
local contextMenu = require("displays.glasses_elements.contextMenu")
local PagedWindow = require("lib.PagedWindow")

local item_overseer = {}

item_overseer.onClick = nil
item_overseer.onClickRight = nil
item_overseer.load = nil
item_overseer.save = nil
item_overseer.update = nil
item_overseer.remove = nil

item_overseer.players = {}
item_overseer.crafts = {}

local itemBox_main
local itemBox_tracked
local levelMaintainer

function item_overseer.prev(player) item_overseer.players[player].display:prevPage() end
function item_overseer.next(player) item_overseer.players[player].display:nextPage() end

function item_overseer.init_display_storage(player)
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
        item_overseer.players[player].display = PagedWindow.new(items, 80, 35, {x1=window.x, y1=window.y+64,x2=window.x+window.width, y2=window.y+window.height-22}, 3, itemBox_main, {player})
        print("item_overseer: Displaying items for player " .. tostring(player))
        item_overseer.players[player].display:displayItems()
    end)
    if not suc then print(err) end
end

function item_overseer.init_tracked(player)
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
        item_overseer.players[player].display = PagedWindow.new(item_overseer.players[player].monitored_items, 80, 35, {x1=window.x, y1=window.y+64,x2=window.x+window.width, y2=window.y+window.height-22}, 3, itemBox_tracked, {player})
        print("item_overseer: Displaying tracked items for player " .. tostring(player))
        item_overseer.players[player].display:displayItems()
    end)
    if not suc then print(err) end
end

function item_overseer.init_crafting(player)
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
        item_overseer.players[player].display = PagedWindow.new(item_overseer.players[player].crafting_items, 150, 30, {x1=window.x, y1=window.y+64,x2=window.x+window.width, y2=window.y+window.height-22}, 3, levelMaintainer, {player})
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
        players[player].modules.available.item_overseer = nil
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
        players[player].modules[cur_page].item_overseer.backgroundBox = background

        print("item_overseer: Creating title element for player " .. tostring(player))
        local title = widgetsAreUs.attachOnClickRight(widgetsAreUs.windowTitle(window.x, window.y, window.width, "Item Overseer"), function(eventName, address, player, x, y, button)
            local context = contextMenu.init(x, y, player, {
                [1] = {text = "Remove Item Overseer", func = item_overseer.remove, args = {player}}
            })
        end)
        item_overseer.players[player].elements.title = title

        local search_bar
        print("item_overseer: Creating search bar element for player " .. tostring(player))
        search_bar = widgetsAreUs.attachOnClickRight(widgetsAreUs.attachOnClick(widgetsAreUs.searchBar(window.x, window.y+20, window.width), function(eventName, address, player, x, y, button)
            local function string_contains(str, pattern) -- left click
                return string.find(str, pattern) ~= nil
            end

            local search_items = {}

            local search_text = widgetsAreUs.handleTextInput(search_bar.text, player)
            if search_text then
                local items = component.me_interface.getItemsInNetwork()
                for index, item in ipairs(items) do
                   if string_contains(item.label, search_text) then
                       table.insert(search_items, item)
                   end
                end
                item_overseer.players[player].display:clearDisplayedItems()
                item_overseer.players[player].display = nil
                item_overseer.players[player].display = PagedWindow.new(search_items, 80, 35, {x1=window.x, y1=window.y+64,x2=window.x+window.width, y2=window.y+window.height-22}, 3, itemBox_main, {player})
                item_overseer.players[player].display:displayItems()
            end
        end), function(eventName, address, player, x, y, button) -- Right-click
            local context = contextMenu.init(x, y, player, {
                [1] = {text = "Remove Item Overseer", func = item_overseer.remove, args = {player}}
            })
        end)
        item_overseer.players[player].elements.search_bar = search_bar

        print("item_overseer: Creating navigation buttons for player " .. tostring(player))
        local up_button = widgetsAreUs.symbolBox(window.x + ((window.width/2)-10), window.y+42, "▲", c.navbutton, item_overseer.prev, player)
        local down_button = widgetsAreUs.symbolBox(window.x + ((window.width/2)-10), window.y+window.height-22, "▼", c.navbutton, item_overseer.next, player)
        item_overseer.players[player].elements.up_button = up_button
        item_overseer.players[player].elements.down_button = down_button

        print("item_overseer: Creating display control buttons for player " .. tostring(player))
        local display_main_button = widgetsAreUs.attachOnClickRight(widgetsAreUs.symbolBox(window.x+3, window.y+42, "M", c.navbutton, item_overseer.init_display_storage, player), function(eventName, address, player, x, y, button)
            local context = contextMenu.init(x, y, player, {
                [1] = {text = "Remove Item Overseer", func = item_overseer.remove, args = {player}}
            })
        end)
        local display_monitored_button = widgetsAreUs.symbolBox(window.x+window.width-44, window.y+window.height-22, "T", c.navbutton, item_overseer.init_tracked, player)
        local display_crafting_button = widgetsAreUs.symbolBox(window.x+window.width-22, window.y+window.height-22, "C", c.navbutton, item_overseer.init_crafting, player)
        item_overseer.players[player].elements.button_main = display_main_button
        item_overseer.players[player].elements.button_tracked = display_monitored_button
        item_overseer.players[player].elements.button_crafting = display_crafting_button

        players[player].modules[cur_page].item_overseer.onClick = item_overseer.onClick
        players[player].modules[cur_page].item_overseer.onClickRight = item_overseer.onClickRight
        players[player].modules[cur_page].item_overseer.setVisible = item_overseer.setVisible

        item_overseer.load(player)
    end)
    if not suc then print(err) end
end

-----------------------------------------------------
--- Updated Element Creation Functions

itemBox_main = function(x, y, itemstack, player)
        print("item_overseer: Creating main item box for player " .. tostring(player) .. ", itemstack: " .. tostring(itemstack.label))
        component.glasses = require("displays.glasses_display").getGlassesProxy(player)
        local function mainStorage_itemBox_context()
            print("item_overseer: Creating context menu for main item box for player " .. tostring(player))
            local context = contextMenu.init(x, y, player, {
                [1] = {text = "Add To Tracked (T)", func = function() table.insert(item_overseer.players[player].monitored_items, itemstack) end, args = {}},
                [2] = {text = "Add to Crafting (C)", func = function() table.insert(item_overseer.players[player].crafting_items, {itemStack = itemstack, batch = 0, amount = 0}) end, args = {}}
            })
            return true
        end

        local itemBox = widgetsAreUs.itemBox(x, y, itemstack)
        print("item_overseer: Attaching context menu to main item box for player " .. tostring(player))
        local new_itemBox = widgetsAreUs.attachOnClickRight(itemBox, mainStorage_itemBox_context)
        return new_itemBox
end

itemBox_tracked = function(x, y, itemstack, player)
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
                    item_overseer.players[player].display = nil
                    item_overseer.players[player].display = PagedWindow.new(item_overseer.players[player].monitored_items, 80, 35, {x1=item_overseer.players[player].window.x, y1=item_overseer.players[player].window.y+64,x2=item_overseer.players[player].window.x+item_overseer.players[player].window.width, y2=item_overseer.players[player].window.y+item_overseer.players[player].window.height-22}, 3, itemBox_tracked, {player})
                    item_overseer.players[player].display:displayItems()
                end, args = {}},
                [2] = {text = "Add to Crafting (C)", func = function() table.insert(item_overseer.players[player].crafting_items, {itemStack = itemstack, batch = 0, amount = 0}) end, args = {}}
            })
            return true
        end

        local itemBox = widgetsAreUs.itemBox(x, y, itemstack)
        print("item_overseer: Attaching context menu to tracked item box for player " .. tostring(player))
        local new_itemBox = widgetsAreUs.attachOnClickRight(itemBox, tracked_itemBox_context)
        return new_itemBox
end

levelMaintainer = function(x, y, argsTable, player)
        print("item_overseer: Creating level maintainer for player " .. tostring(player) .. ", itemStack: " .. tostring(argsTable.itemStack.label))
        component.glasses = require("displays.glasses_display").getGlassesProxy(player)
        local function levelMaintainer_context()
            print("item_overseer: Creating context menu for level maintainer for player " .. tostring(player))
            local context = contextMenu.init(x, y, player, {
                [1] = {text = "Remove From Crafting (C)", func = function()
                    for index, crafting_item in ipairs(item_overseer.players[player].crafting_items) do
                        if crafting_item.itemStack.label == argsTable.itemStack.label then
                            print("item_overseer: Removing item from crafting items for player " .. tostring(player))
                            item_overseer.players[player].crafting_items = nil
                            print("item_overseer: Clearing displayed items and updating crafting items display for player " .. tostring(player))
                            item_overseer.players[player].display:clearDisplayedItems()
                            item_overseer.players[player].display = nil
                            item_overseer.players[player].display = PagedWindow.new(item_overseer.players[player].crafting_items, 150, 30, {x1=item_overseer.players[player].window.x, y1=item_overseer.players[player].window.y+64,x2=item_overseer.players[player].window.x+item_overseer.players[player].window.width, y2=item_overseer.players[player].window.y+item_overseer.players[player].window.height-22}, 3, levelMaintainer, {player})
                            item_overseer.players[player].display:displayItems()
                        end
                    end
                end, args = {}}
            })
            return true
        end

        local lm = widgetsAreUs.levelMaintainer(x, y, argsTable, player)
        print("item_overseer: Attaching context menu to level maintainer for player " .. tostring(player))
        local new_lm = widgetsAreUs.attachOnClickRight(lm, levelMaintainer_context)
        return new_lm
end

local function level_maintaining()
    local suc, err = pcall(function()
        for key, player in pairs(item_overseer.players) do
            for index, crafting_item in ipairs(item_overseer.players[player].crafting_items) do
                local check = item_overseer.crafts[crafting_item.itemStack.label]
                if check and check.isDone() or check.isCanceled() then
                    item_overseer.crafts[crafting_item.itemStack.label] = nil
                elseif check.hasFailed() then
                    component.glasses = require("displays.glasses_display").getGlassesProxy(player)
                    widgetsAreUs.alertMessage(c.red, "Crafting Failed: " .. crafting_item.itemStack.label, timing.three)
                end
            
                if item_overseer.crafts[crafting_item.itemStack.label] then
                
                else
                    local items_in_storage = component.me_interface.getItemsInNetwork(crafting_item.itemStack)
                    if items_in_storage and items_in_storage[1] and items_in_storage[1].isCraftable then
                        if items_in_storage[1].size < tonumber(widgetsAreUs.trim(crafting_item.amount.getText())) then
                            local craft = component.me_interface.getCraftables({label = items_in_storage[1].label, name = items_in_storage[1].name})[1].request(tonumber(widgetsAreUs.trim(crafting_item.batch.getText())))
                            item_overseer.crafts[crafting_item.itemStack.label] = craft
                        end
                    elseif items_in_storage and items_in_storage[1] and not items_in_storage[1].isCraftable then
                        component.glasses = require("displays.glasses_display").getGlassesProxy(player)
                        widgetsAreUs.alertMessage(c.red, "Item Not Craftable: " .. crafting_item.itemStack.label, timing.three)
                    end
                end
            end
        end
    end)
    if not suc then print("item_overseer.update Error - " .. tostring(err)) end
end

-----------------------------------------------------
--- Command and Control

item_overseer.onClick = function(eventName, address, player, x, y, button)
    local suc, err = pcall(function()
        if eventName == "hud_click" and button == 0 then
            print("item_overseer: Left-click detected for player " .. tostring(player))
            component.glasses = require("displays.glasses_display").getGlassesProxy(player)
            if item_overseer.players[player].elements.background.contains(x, y) then
                print("item_overseer: Click detected within background for player " .. tostring(player))
                for key, element in pairs(item_overseer.players[player].elements) do
                    print("item_overseer: Checking element " .. tostring(key))
                    if key == "background" then
                        print("skipping background")
                    elseif element.box.contains(x, y) then
                        element.onClick(eventName, address, player, x, y, button)
                        return
                    end
                end
                for index, element in ipairs(item_overseer.players[player].display.currentlyDisplayed) do
                    if element.box.contains(x, y) then
                        element.onClick(eventName, address, player, x, y, button)
                        return
                    end
                end
            else
                return false
            end
        end
    end)
    if not suc then print(err) end
    return true
end

item_overseer.onClickRight = function(eventName, address, player, x, y, button)
    local suc, err = pcall(function()
        if eventName == "hud_click" and button == 1 then
            print("item_overseer: Right-click detected for player " .. tostring(player))
            component.glasses = require("displays.glasses_display").getGlassesProxy(player)
            if item_overseer.players[player].elements.background.contains(x, y) then
                for key, element in pairs(item_overseer.players[player].elements) do
                    if key == "background" then
                        print("skipping background")
                    elseif element.box.contains(x, y) then
                        element.onClickRight(eventName, address, player, x, y, button)
                        return true
                    end
                end
                for index, element in ipairs(item_overseer.players[player].display.currentlyDisplayed) do
                    if element.box.contains(x, y) then
                        element.onClickRight(eventName, address, player, x, y, button)
                        return true
                    end
                end
            else
                return false
            end
        end
    end)
    if not suc then print(err) end
end

local update_counter = 0

function item_overseer.update()
    update_counter = update_counter + 1
    if update_counter % 5 == 0 then
        for key, player in pairs(item_overseer.players) do
            component.glasses = require("displays.glasses_display").getGlassesProxy(player)
            for index, displayed_item in ipairs(item_overseer.players[player].display.currentlyDisplayed) do
                if displayed_item.update then
                    displayed_item.update()
                end
            end
        end
    end
    if update_counter % 15 == 0 then
        level_maintaining()
    end
end

function item_overseer.setVisible(visible, player)
    for key, element in pairs(item_overseer.players[player].elements) do
        element.setVisible(visible)
    end
    for index, element in ipairs(item_overseer.players[player].display.currentlyDisplayed) do
        element.setVisible(visible)
    end
end

function item_overseer.remove(player)
    for key, element in pairs(item_overseer.players[player].elements) do
        element.remove()
    end
    if item_overseer.players[player].display then
        item_overseer.players[player].display:clearDisplayedItems()
        item_overseer.players[player].display = nil
    end
    players[player].modules[players[player].current_hudPage].item_overseer = nil
    item_overseer.players[player] = nil
    players[player].modules.available.item_overseer = require("displays.modules.item_overseer.item_overseer").init
end

return item_overseer