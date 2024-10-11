local widgetsAreUs = require("lib.widgetsAreUs")
local event = require("event")
local c = require("lib.gimp_colors")

--------------------------------------
--- Forward Declarations

local machine_overseer = {}
machine_overseer.onClick = nil
machine_overseer.onClickRight = nil
machine_overseer.remove = nil
machine_overseer.setVisible = nil

machine_overseer.players = {}

--------------------------------------
--- Initializations

local function init_machineFocus(player)

end

local function init_groupFocus(player)

end

local function init_allFocus(player)

end

function machine_overseer.init(player)
    component.glasses = require("displays.glasses_display").getGlassesProxy(player)
    local windowPre = players[player].hudSetup.elements.window
    local window = {}
    window.x = windowPre.x
    window.y = windowPre.y
    window.width = windowPre.x2-windowPre.x
    window.height = windowPre.y2-windowPre.y

    players[player].modules[players[player].current_hudPage].machine_overseer = {}


    local backgroundBox = widgetsAreUs.createBox(window.x, window.y, window.width, window.height, c.background, 0.5)
end

--------------------------------------
--- Command and Control

function machine_overseer.onClick(eventName, address, player, x, y, button)

end

function machine_overseer.onClickRight(eventName, address, player, x, y, button)

end

function machine_overseer.remove(player)

end

function machine_overseer.setVisible(player, visible)

end

function machine_overseer.onModemMessage(player)

end

--------------------------------------
--- Module Specific Event Handling

local function handleComponentChange()

end

event.listen("component_added", handleComponentChange)
event.listen("component_removed", handleComponentChange)

--------------------------------------

return machine_overseer
