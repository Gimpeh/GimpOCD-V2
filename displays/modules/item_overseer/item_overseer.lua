local c = require("gimp_colors")
local widgetsAreUs = require("lib.widgetsAreUs")
local contextMenu = require("displays.glasses_elements.contextMenu")
local PagedWindow = require("lib.PagedWindow")
local component = require("component")

local item_overseer = {}
item_overseer.players = {}

local itemBox_main
local itemBox_tracked

local function init_display_storage(player)
    component.glasses = require("displays.glasses_display").getGlassesProxy(player)
    local window = item_overseer.players[player].window

    if item_overseer.players[player].display then
        item_overseer.players[player].display:clearDisplayedItems()
        item_overseer.players[player].display = nil
    end
    local items = component.me_interface.getItemsInNetwork()
    item_overseer.players[player].display = PagedWindow.new(items, 80, 35, {x1=window.x, y1=window.y+44,x2=window.x+window.width, y2=window.y+window.height-22}, 3, itemBox_main, {player})
    item_overseer.players[player].display:displayItems()
end

local function init_tracked(player)
    component.glasses = require("displays.glasses_display").getGlassesProxy(player)
    local window = item_overseer.players[player].window

    if item_overseer.players[player].display then
        item_overseer.players[player].display:clearDisplayedItems()
        item_overseer.players[player].display = nil
    end
    item_overseer.players[player].display = PagedWindow.new(item_overseer.players[player].monitored_items, 80, 35, {x1=window.x, y1=window.y+44,x2=window.x+window.width, y2=window.y+window.height-22}, 3, itemBox_tracked, {player})
    item_overseer.players[player].display:displayItems()
end

local function init_crafting(player)
    component.glasses = require("displays.glasses_display").getGlassesProxy(player)
    local window = item_overseer.players[player].window

    if item_overseer.players[player].display then
        item_overseer.players[player].display:clearDisplayedItems()
        item_overseer.players[player].display = nil
    end
    item_overseer.players[player].display = PagedWindow.new(item_overseer.players[player].crafting_items, 150, 30, {x1=window.x, y1=window.y+44,x2=window.x+window.width, y2=window.y+window.height-22}, 3, widgetsAreUs.levelMaintainer, {player})
    item_overseer.players[player].display:displayItems()
end

function item_overseer.init(player)
    component.glasses = require("displays.glasses_display").getGlassesProxy(player)
    players[player].availableModules.item_overseer = nil
    local windowPre = players[player].hudSetup.elements.window
    local window = {}
    window.x = windowPre.x
    window.y = windowPre.y
    window.width = windowPre.width
    window.height = windowPre.height
    item_overseer.players[player] = {}
    item_overseer.players[player].window = window

    local cur_page = players[player].current_hudPage
    players[player].modules[cur_page].item_overseer = {}

    item_overseer.players[player].elements = {}
    item_overseer.players[player].monitored_items = {}
    item_overseer.players[player].crafting_items = {}

    local background = widgetsAreUs.createBox(window.x, window.y, window.width, window.height, c.background, 0.5)
    item_overseer.players[player].elements.background = background

    local search_bar = widgetsAreUs.searchBar(window.x, window.y, window.width)
    item_overseer.players[player].elements.search_bar = search_bar

    local function prev() item_overseer.players[player].display:prevPage() end
    local function next() item_overseer.players[player].display:nextPage() end
    local up_button = widgetsAreUs.symbolBox(window.x + ((window.width/2)-10), window.y+22, "▲", c.navbutton, prev)
    local down_button = widgetsAreUs.symbolBox(window.x + ((window.width/2)-10), window.y+window.height-22, "▼", c.navbutton, next)
    item_overseer.players[player].elements.up_button = up_button
    item_overseer.players[player].elements.down_button = down_button

    local display_main = widgetsAreUs.symbolBox(window.x+3, window.y+22, "M", c.navbutton, init_display_storage, player)
    local display_monitored = widgetsAreUs.symbolBox(window.x+window.width-44, window.y+window.height-22, "T", c.navbutton, init_tracked, player)
    local display_crafting = widgetsAreUs.symbolBox(window.x+window.width-22, window.y+window.height-22, "C", c.navbutton, init_crafting, player)
    item_overseer.players[player].elements.button_main = display_main
    item_overseer.players[player].elements.button_tracked = display_monitored
    item_overseer.players[player].elements.button_crafting = display_crafting
end

-----------------------------------------------------
--- Updated Element Creation Functions

itemBox_main = function(x, y, itemstack, player)
    component.glasses = require("displays.glasses_display").getGlassesProxy(player)
    local function mainStorage_itemBox_context()
        local context = contextMenu.init(x, y, player, {
            [1] = {text = "Add To Tracked (T)", func = function() table.insert(item_overseer.monitored_items, itemstack) end, args = {}},
            [2] = {text = "Add to Crafting (C)", func = function() item_overseer.crafting_items[itemstack.label] = {itemStack = itemstack, batch = 0, amount = 0} end, args = {}}
        })
        return true
    end

    local itemBox = widgetsAreUs.itemBox(x, y, itemstack)
    local new_itemBox = widgetsAreUs.attachOnClickRight(itemBox, mainStorage_itemBox_context)
    return new_itemBox
end

itemBox_tracked = function(x, y, itemstack, player)
    component.glasses = require("displays.glasses_display").getGlassesProxy(player)
    local function tracked_itemBox_context()
        local context = contextMenu.init(x, y, player, {
            [1] = {text = "Remove From Tracked (T)", func = function() table.remove(item_overseer.monitored_items, itemstack) end, args = {}},
            [2] = {text = "Add to Crafting (C)", func = function() item_overseer.crafting_items[itemstack.label] = {itemStack = itemstack, batch = 0, amount = 0} end, args = {}}
        })
        return true
    end
       
    local itemBox = widgetsAreUs.itemBox(x, y, itemstack)
    local new_itemBox = widgetsAreUs.attachOnClickRight(itemBox, tracked_itemBox_context)
    return new_itemBox
end



return item_overseer