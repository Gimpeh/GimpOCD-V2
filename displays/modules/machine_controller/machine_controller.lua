local widgetsAreUs = require("lib.widgetsAreUs")
local event = require("event")
local c = require("lib.gimp_colors")
local contextMenu = require("displays.glasses_elements.contextMenu")
local PagedWindow = require("lib.PagedWindow")

--------------------------------------
--- Forward Declarations

local machine_controller = {}
machine_controller.onClick = nil
machine_controller.onClickRight = nil
machine_controller.remove = nil
machine_controller.setVisible = nil

machine_controller.players = {}

--------------------------------------
--- Initializations

local function init_machineFocus(player)

end

local function init_groupFocus(player)

end

local function init_allFocus(player)

end

function machine_controller.init(player)
    component.modem.broadcast(301, "")

    component.glasses = require("displays.glasses_display").getGlassesProxy(player)
    local windowPre = players[player].hudSetup.elements.window
    local window = {}
    window.x = windowPre.x
    window.y = windowPre.y
    window.width = windowPre.x2-windowPre.x
    window.height = windowPre.y2-windowPre.y

    machine_controller.players[player] = {}
    machine_controller.players[player].window = window
    machine_controller.players[player].elements = {}
    machine_controller.players[player].named_machines = {
        --[[
        [1] = {
            name = "name",
            coordinates = {
                x = x,
                y = y,
                z = z
            },
        },
        ...
        ]]
    }

    local cur_page = players[player].current_hudPage
    players[player].modules[cur_page].machine_controller = {}

    -- Create the background box
    local backgroundBox = widgetsAreUs.createBox(window.x, window.y, window.width, window.height, c.background, 0.5)
    machine_controller.players[player].elements.backgroundBox = backgroundBox
    players[player].modules[cur_page].machine_controller.backgroundBox = backgroundBox

    -- Create the title bar at the top (and attach a discreet function to the right click of it)
    local title = widgetsAreUs.attachOnClickRight(widgetsAreUs.windowTitle(window.x, window.y, window.width, "Machine Overseer"), 
    function(eventName, address, player, x, y, button)
        local context = contextMenu.init(x, y, player, {
            [1] = {text = "Remove Machine Controller", func = machine_controller.remove, args = {player}}
        })
    end)
    machine_controller.players[player].elements.title = title

    -- Paged Window Navigation Buttons
    local prev_button = widgetsAreUs.symbolBox(window.x + ((window.width/2)-10), window.y+42, "▲", c.navbutton, machine_controller.prev, player)
    local next_button = widgetsAreUs.symbolBox(window.x + ((window.width/2)-10), window.y+window.height-22, "▼", c.navbutton, machine_controller.next, player)
    machine_controller.players[player].elements.prev_button = prev_button
    machine_controller.players[player].elements.next_button = next_button

    -- Create the Page Window Display (the pages of stuff that you can click through, eg Items, Machines, etc)
    machine_controller.players[player].display = PagedWindow.new(machine_controller.groupNames, , )
end

--------------------------------------
--- Command and Control

function machine_controller.onClick(eventName, address, player, x, y, button)

end

function machine_controller.onClickRight(eventName, address, player, x, y, button)

end

function machine_controller.remove(player)

end

function machine_controller.setVisible(player, visible)

end

function machine_controller.onModemMessage(player)

end

--------------------------------------
--- Module Specific Event Handling

local function handleComponentChange()

end

event.listen("component_added", handleComponentChange)
event.listen("component_removed", handleComponentChange)

--------------------------------------

return machine_controller
