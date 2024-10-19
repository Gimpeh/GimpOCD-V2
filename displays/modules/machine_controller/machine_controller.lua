local widgetsAreUs = require("lib.widgetsAreUs")
local event = require("event")
local c = require("lib.gimp_colors")
local contextMenu = require("displays.glasses_elements.contextMenu")
local PagedWindow = require("lib.PagedWindow")
local s = require("serialization")
local gimpHelper = require("lib.gimpHelper")

--------------------------------------
--- Forward Declarations

local machine_controller = {}
machine_controller.onClick = nil
machine_controller.onClickRight = nil
machine_controller.remove = nil
machine_controller.setVisible = nil

local methodReturn = nil
local remote_execute = nil

machine_controller.remote_execute_return = nil

machine_controller.players = {}
machine_controller.groups = {}
machine_controller.machines = {}                                  

local createGroupWidget
local createMachineWidget

--------------------------------------
--- Initializations

local function init_allFocus(player)
    component.glasses = require("displays.glasses_display").getGlassesProxy(player)
    if machine_controller.players[player].display then
        machine_controller.players[player].display:clearDisplayedItems()
        machine_controller.players[player].display = nil
    end

    local window = machine_controller.players[player].window
    machine_controller.players[player].display = PagedWindow.new(machine_controller.groups, 107, 75, {x = window.x, y = window.y+64, x2 = window.x+window.width, y2 = window.y+window.height - 22}, 5, createGroupWidget, player)
    machine_controller.players[player].prev = function() machine_controller.display:prevPage() end
    machine_controller.players[player].next = function() machine_controller.display:nextPage() end

    machine_controller.players[player].display:displayItems()
end

local function init_groupFocus(player, group)
    component.glasses = require("displays.glasses_display").getGlassesProxy(player)
    if machine_controller.players[player].display then
        machine_controller.players[player].display:clearDisplayedItems()
        machine_controller.players[player].display = nil
    end

    local window = machine_controller.players[player].window
    machine_controller.players[player].display = PagedWindow.new(machine_controller.groups[group], 85, 34, {x = window.x, y = window.y+64, x2 = window.x+window.width, y2 = window.y+window.height - 22}, 5, createMachineWidget, player)
    machine_controller.players[player].prev = function() machine_controller.display:prevPage() end
    machine_controller.players[player].next = function() machine_controller.display:nextPage() end

    machine_controller.players[player].display:displayItems()
end

function machine_controller.init(player)
    component.modem.broadcast(301, player, " ", "init", " ")

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
    machine_controller.players[player].named_machines = {}

    local cur_page = players[player].current_hudPage
    players[player].modules[cur_page].machine_controller = {}
    players[player].modules[cur_page].machine_controller.onClick= machine_controller.onClick
    players[player].modules[cur_page].machine_controller.onClickRight = machine_controller.onClickRight
    players[player].modules[cur_page].machine_controller.remove = machine_controller.remove
    players[player].modules[cur_page].machine_controller.setVisible = machine_controller.setVisible

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

    --***CREATE SEARCH BAR*** it should search machine names AND text players have set on the machine

    -- Paged Window Navigation Buttons
    local prev_button = widgetsAreUs.symbolBox(window.x + ((window.width/2)-10), window.y+44, "▲", c.navbutton, machine_controller.prev, player)
    local next_button = widgetsAreUs.symbolBox(window.x + ((window.width/2)-10), window.y+window.height-22, "▼", c.navbutton, machine_controller.next, player)
    machine_controller.players[player].elements.prev_button = prev_button
    machine_controller.players[player].elements.next_button = next_button

    -- Create a re-populate button

    component.modem.broadcast(301, player, "all", "init", " ")
    os.sleep(timing.twenty)
    init_allFocus(player)
end

--------------------------------------
--- Command and Control

function machine_controller.onClick(eventName, address, player, x, y, button)
    for key, element in pairs(machine_controller.players[player].elements) do
        if key == "backgroundBox" then
            print("skipping background")
        elseif element.box.contains(x, y) then
            element.onClick(eventName, address, player, x, y, button)
        end
    end
    for key, element in ipairs(machine_controller.players[player].display) do
        if element.box.contains(x, y) then
            element.onClick(eventName, address, player, x, y, button)
        end
    end
end

function machine_controller.onClickRight(eventName, address, player, x, y, button)
    for key, element in pairs(machine_controller.players[player].elements) do
        if key == "backgroundBox" then
            print("skipping background")
        elseif element.box.contains(x, y) then
            element.onClickRight(eventName, address, player, x, y, button)
        end
    end
    for key, element in ipairs(machine_controller.players[player].display) do
        if element.box.contains(x, y) then
            element.onClickRight(eventName, address, player, x, y, button)
        end
    end
end

function machine_controller.remove(player)
    if machine_controller.players[player].display then
        machine_controller.players[player].display:clearDisplayedItems()
        machine_controller.players[player].display = nil
    end
    for k, v in pairs(machine_controller.players[player].elements) do
        v.remove()
        machine_controller.players[player].elements[k] = nil
    end
end

function machine_controller.setVisible(player, visible)
    for k, v in pairs(machine_controller.players[player].elements) do
        v.setVisible(visible)
    end
    for k, v in ipairs(machine_controller.players[player].display) do
        v.setVisible(visible)
    end
end

local init_timer = nil
function machine_controller.onModemMessage(messageType, group, message)

    local messageTable 
    messageTable = s.unserialize(message)

    if not messageTable then
       messageTable = message
    end

    if type(messageTable) == "string" then
        if messageTable == "error" then
            print("\n \n \n \n \n mach_control - 205, REMOTE ERROR RECIEVED", tostring(messageType), tostring(group), "\n \n \n \n \n")
            --***Maybe Do something intelligent here***
            return
        end
    end

    if messageType == "init" then
        if init_timer  then
            event.cancel(init_timer)
        end
        init_timer = event.timer(timing.seven, function() event.push("machines_init") end, 1)
        machine_controller.groups[group] = {}
        for k, v in pairs(messageTable) do
            table.insert(machine_controller.groups[group], messageTable[k])
        end
        return true
    elseif messageType == "update" then
        machine_controller.groups[messageTable.group].allowed = messageTable.allowed
        for k, v in ipairs(messageTable) do
            machine_controller.machines[messageTable[k].address].running = messageTable[k].running
            machine_controller.machines[messageTable[k].address].allowed = messageTable[k].allowed
        end
    end
end

--------------------------------------
--- Machine Controller Functions

remote_execute = function(address, command, serialized_args, player)
    print("mach_cont - 67: remote_execute", tostring(address), tostring(command), tostring(player))
    local invokeTable = {
        machine = address,
        command = command,
        args = serialized_args,
        returnAddress = component.modem.address,
        player = player or "none"
    }

    component.modem.broadcast(301, player, machine_controller.machines[address].group, "remote_execute", s.serialize(invokeTable))
    local message = event.pull("remote_return")

    local ret = s.unserialize(message)
    if ret and ret[1] and not ret[2] then
        return ret[1]
    elseif ret and ret[1] and ret[2] then
        return ret
    elseif ret and ret.x then
        return ret
    end
end

--------------------------------------
--- Widgets

machine_controller.createGroupWidget = function(x, y, group, player, detached, index)
    component.glasses = require("displays.glasses_display").getGlassesProxy(player)
    local text

    local groupWidget = widgetsAreUs.machineGroup(x, y, group)
    groupWidget.index = index
    groupWidget.group = group.name

    local funcTable = {
        [1] = {text = "View Group", func = init_groupFocus, args = {player, group}},
        [2] = {text =  "Turn Group On", func = function() component.modem.broadcast(301, " ", group, "group on") end, args = {}},
        [3] = {text =  "Turn Group Off", func = function() component.modem.broadcast(301, " ", group, "group off") end, args = {}},
        [4] = {text = "Set Tag", func = function()
            if not machine_controller.groups[group] then
                machine_controller.groups[group] = {}
            end
            
            machine_controller.groups[group].tag = widgetsAreUs.getText_popUp(player)
        end
            , args = {}},
        [5] = {text = text, func = function()
                if detached then 
                    groupWidget.remove()
                    detached = false
                    return
                end
                --popup explaining.. then detach that widget object and place it nearby.
                --set the objects drag and click up to be able to move the widget around the display
                --extend the objects context menu to include "Remove"
                local args = {players[player].resolution.x - 107, 200, group, player, true}
                event.push("detach_element", createGroupWidget, args, player) end, args = {}},
    }
    if detached then funcTable[6] = {text = "Set Page", func = function()
        local contextMenu = contextMenu.init(x, y, player, {
            [1] = {text = "Set Page 1", func = function()
                table.remove(players[player].glasses_display.elements.detached[players[player].current_hudPage], groupWidget.index)
                table.insert(players[player].glasses_display.elements.detached[1], groupWidget)
                groupWidget.index = #players[player].glasses_display.elements.detached[1]
                if players[player].current_hudPage == 1 then
                    groupWidget.setVisible(true)
                else
                    groupWidget.setVisible(false)
                end
            end, args = {}},
            [2] = {text = "Set Page 2", func = function()
                table.remove(players[player].glasses_display.elements.detached[players[player].current_hudPage], groupWidget.index)
                table.insert(players[player].glasses_display.elements.detached[2], groupWidget)
                groupWidget.index = #players[player].glasses_display.elements.detached[2]
                if players[player].current_hudPage == 2 then
                    groupWidget.setVisible(true)
                else
                    groupWidget.setVisible(false)
                end
            end, args = {}},
            [3] = {text = "Set Page 3", func = function()
                table.remove(players[player].glasses_display.elements.detached[players[player].current_hudPage], groupWidget.index)
                table.insert(players[player].glasses_display.elements.detached[3], groupWidget)
                groupWidget.index = #players[player].glasses_display.elements.detached[3]
                if players[player].current_hudPage == 3 then
                    groupWidget.setVisible(true)
                else
                    groupWidget.setVisible(false)
                end
            end, args = {}}})
        end, args = {}
    } end

    groupWidget = widgetsAreUs.attachOnClickRight(groupWidget, function(eventName, address, player, x2, y2, button)
        if detached then
            text = "Attach Element"
        else
            text = "Remove Element"
        end

        local context = contextMenu.init(x2, y2, player, funcTable)
    end)
    groupWidget.funcTable = funcTable
    return groupWidget
end

createMachineWidget = function(x, y, machineGroup, player, detached, index)
    local machine = machineGroup.address
    local text = "Detach"
    if detached then
        text = "Remove"
    end
    local index = index

    component.glasses = require("displays.glasses_display").getGlassesProxy(player)
    local machineWidget = widgetsAreUs.machine(x, y, machine)
    if machine_controller.machines[machine].name then
        machineWidget.setName(machine_controller.machines[machine].name)
    end
    machineWidget.group = machine_controller.machines[machine].group

    local funcTable = {
        [1] = {text = "Set Name", func = function()
            machine_controller.machines[machine].name = widgetsAreUs.getText_popUp(player)
            machineWidget.setName(machine_controller.machines[machine].name)
         end, args = {player}},
        [2] = {text = "Turn Machine On", func = function() remote_execute(machine, "setWorkAllowed", s.serialize({true}), player) end, args = {}},
        [3] = {text = "Turn Machine Off", func = function() remote_execute(machine, "setWorkAllowed", s.serialize({false}), player) end, args = {}},
        [4] = {text = "Toggle Beacon", func = function()
            local beacon
            if beacon and beacon.getID then
                machineWidget.beaconStatus.setColor(1, 0, 0)
                component.glasses.removeObject(beacon.getID())
                beacon = nil
                return
            end

            machineWidget.beaconStatus.setColor(0, 1, 1)
            local coords = remote_execute(machine, "getCoordinates", " ", player)

            component.glasses = require("displays.glasses_display").getGlassesProxy(player)
            beacon = component.glasses.addCube3D()

            local correctedCoords = gimpHelper.correctedCoordinates(coords, players[player].glasses_controller_coordinates)

            beacon.set3dPos(correctedCoords.x, correctedCoords.y, correctedCoords.z)
            beacon.setVisibleThroughObjects(true)
            beacon.setColor(0, 1, 1)
            beacon.setViewDistance(500)
        end, args = {}},
        [5] = {text = text, func = function()
            if detached then
                machineWidget.remove()
                detached = false
                return
            end
            local args = {players[player].resolution.x - 85, 200, machine, player, true}
            event.push("detach_element", createMachineWidget, args, player) end, args = {}}
    }
    if detached then funcTable[6] = {text = "Set Page", func = function()
        local contextMenu = contextMenu.init(x, y, player, {
            [1] = {text = "Set Page 1", func = function()
                table.remove(players[player].glasses_display.elements.detached[players[player].current_hudPage], machineWidget.index)
                table.insert(players[player].glasses_display.elements.detached[1], machineWidget)
                machineWidget.index = #players[player].glasses_display.elements.detached[1]
                if players[player].current_hudPage == 1 then
                    machineWidget.setVisible(true)
                else
                    machineWidget.setVisible(false)
                end
            end, args = {}},
            [2] = {text = "Set Page 2", func = function()
                table.remove(players[player].glasses_display.elements.detached[players[player].current_hudPage], machineWidget.index)
                table.insert(players[player].glasses_display.elements.detached[2], machineWidget)
                machineWidget.index = #players[player].glasses_display.elements.detached[2]
                if players[player].current_hudPage == 2 then
                    machineWidget.setVisible(true)
                else
                    machineWidget.setVisible(false)
                end
            end, args = {}},
            [3] = {text = "Set Page 3", func = function()
                table.remove(players[player].glasses_display.elements.detached[players[player].current_hudPage], machineWidget.index)
                table.insert(players[player].glasses_display.elements.detached[3], machineWidget)
                machineWidget.index = #players[player].glasses_display.elements.detached[3]
                if players[player].current_hudPage == 3 then
                    machineWidget.setVisible(true)
                else
                    machineWidget.setVisible(false)
                end
            end, args = {}}})
        end, args = {}
    } end

    machineWidget = widgetsAreUs.attachOnClickRight(machineWidget, function()
        local context = contextMenu.init(x, y, player, funcTable)
    end)
end

--------------------------------------
--- Module Specific Event Handling

local function init_machines_table()
    for k, v in pairs(machine_controller.groups) do
        for i, j in ipairs(machine_controller.groups[k]) do
            machine_controller.machines[j.address] = {
                address = j.address,
                name = j.name,
                group = v.name
            }
        end
    end
end

event.listen("machines_init", init_machines_table)

--------------------------------------

return machine_controller