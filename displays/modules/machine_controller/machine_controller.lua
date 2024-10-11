local widgetsAreUs = require("lib.widgetsAreUs")
local event = require("event")

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
