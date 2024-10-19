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
    print("mach_cont - 34: init_allFocus", tostring(player))
    component.glasses = require("displays.glasses_display").getGlassesProxy(player)
    if machine_controller.players[player].display then
        print("mach_cont - 37: init_allFocus - clearing display")
        machine_controller.players[player].display:clearDisplayedItems()
        machine_controller.players[player].display = nil
    end

    print("mach_cont - 42: init_allFocus - creating display")
    local window = machine_controller.players[player].window
    machine_controller.players[player].display = PagedWindow.new(machine_controller.groups, 107, 75, {x = window.x, y = window.y+64, x2 = window.x+window.width, y2 = window.y+window.height - 22}, 5, createGroupWidget, player)
    machine_controller.players[player].prev = function() machine_controller.display:prevPage() end
    machine_controller.players[player].next = function() machine_controller.display:nextPage() end

    print("mach_cont - 48: init_allFocus - displaying items")
    machine_controller.players[player].display:displayItems()
end

local function init_groupFocus(player, group)
    print("mach_cont - 53: init_groupFocus", tostring(player), tostring(group))
    component.glasses = require("displays.glasses_display").getGlassesProxy(player)
    if machine_controller.players[player].display then
        print("mach_cont - 56: init_groupFocus - clearing display")
        machine_controller.players[player].display:clearDisplayedItems()
        machine_controller.players[player].display = nil
    end

    print("mach_cont - 61: init_groupFocus - creating display")
    local window = machine_controller.players[player].window
    machine_controller.players[player].display = PagedWindow.new(machine_controller.groups[group], 85, 34, {x = window.x, y = window.y+64, x2 = window.x+window.width, y2 = window.y+window.height - 22}, 5, createMachineWidget, player)
    machine_controller.players[player].prev = function() machine_controller.display:prevPage() end
    machine_controller.players[player].next = function() machine_controller.display:nextPage() end

    print("mach_cont - 67: init_groupFocus - displaying items")
    machine_controller.players[player].display:displayItems()
end

function machine_controller.init(player)
    print("mach_cont - 72: init", tostring(player))
    component.modem.broadcast(301, player, " ", "init", " ")

    component.glasses = require("displays.glasses_display").getGlassesProxy(player)
    local windowPre = players[player].hudSetup.elements.window
    local window = {}
    window.x = windowPre.x
    window.y = windowPre.y
    window.width = windowPre.x2-windowPre.x
    window.height = windowPre.y2-windowPre.y
    print("mach_cont - 82: init - created window")

    machine_controller.players[player] = {}
    machine_controller.players[player].window = window
    machine_controller.players[player].elements = {}
    machine_controller.players[player].named_machines = {}
    print("mach_cont - 88: init - created player table", player)

    local cur_page = players[player].current_hudPage
    players[player].modules[cur_page].machine_controller = {}
    players[player].modules[cur_page].machine_controller.onClick= machine_controller.onClick
    players[player].modules[cur_page].machine_controller.onClickRight = machine_controller.onClickRight
    players[player].modules[cur_page].machine_controller.remove = machine_controller.remove
    players[player].modules[cur_page].machine_controller.setVisible = machine_controller.setVisible
    print("mach_cont - 96: init - created module table")

    -- Create the background box
    local backgroundBox = widgetsAreUs.createBox(window.x, window.y, window.width, window.height, c.background, 0.5)
    machine_controller.players[player].elements.backgroundBox = backgroundBox
    players[player].modules[cur_page].machine_controller.backgroundBox = backgroundBox
    print("mach_cont - 102: init - created background box")

    -- Create the title bar at the top (and attach a discreet function to the right click of it)
    local title = widgetsAreUs.attachOnClickRight(widgetsAreUs.windowTitle(window.x, window.y, window.width, "Machine Controller"), 
    function(eventName, address, player, x, y, button)
        local context = contextMenu.init(x, y, player, {
            [1] = {text = "Remove Machine Controller", func = machine_controller.remove, args = {player}}
        })
    end)
    machine_controller.players[player].elements.title = title
    print("mach_cont - 112: init - created title bar")

    --***CREATE SEARCH BAR*** it should search machine names AND text players have set on the machine

    -- Paged Window Navigation Buttons
    local prev_button = widgetsAreUs.symbolBox(window.x + ((window.width/2)-10), window.y+44, "▲", c.navbutton, machine_controller.prev, player)
    local next_button = widgetsAreUs.symbolBox(window.x + ((window.width/2)-10), window.y+window.height-22, "▼", c.navbutton, machine_controller.next, player)
    machine_controller.players[player].elements.prev_button = prev_button
    machine_controller.players[player].elements.next_button = next_button
    print("mach_cont - 121: init - created navigation buttons")

    -- Create a re-populate button

    component.modem.broadcast(301, player, "all", "init", " ")
    print("mach_cont - 126: init - broadcasted init message")
    os.sleep(timing.twenty)
    print("mach_cont - 128: init - slept for 20 seconds")
    init_allFocus(player)
end

--------------------------------------
--- Command and Control

function machine_controller.onClick(eventName, address, player, x, y, button)
    print("mach_cont - 136: onClick", tostring(x), tostring(y), tostring(button))
    for key, element in pairs(machine_controller.players[player].elements) do
        if key == "backgroundBox" then
            print("mach_cont - 139: skipping background")
        elseif element.box.contains(x, y) then
            print("mach_cont - 141: element contains click", tostring(key))
            element.onClick(eventName, address, player, x, y, button)
        end
    end
    for key, element in ipairs(machine_controller.players[player].display.currentlyDisplayed) do
        if element.box.contains(x, y) then
            print("mach_cont - 147: display element contains click")
            element.onClick(eventName, address, player, x, y, button)
        end
    end
end

function machine_controller.onClickRight(eventName, address, player, x, y, button)
    print("mach_cont - 154: onClickRight", tostring(x), tostring(y), tostring(button))
    for key, element in pairs(machine_controller.players[player].elements) do
        if key == "backgroundBox" then
            print("mach_cont - 157: skipping background")
        elseif element.box.contains(x, y) then
            print("mach_cont - 159: element contains click", tostring(key))
            element.onClickRight(eventName, address, player, x, y, button)
        end
    end
    if machine_controller.players[player].display then
        for key, element in ipairs(machine_controller.players[player].display.currentlyDisplayed) do
            if element.box.contains(x, y) then
                print("mach_cont - 165: display element contains click")
                element.onClickRight(eventName, address, player, x, y, button)
            end
        end
    end
end

function machine_controller.remove(player)
    component.glasses = require("displays.glasses_display").getGlassesProxy(player)
    print("mach_cont - 173: remove", tostring(player))
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
    component.glasses = require("displays.glasses_display").getGlassesProxy(player)
    print("mach_cont - 186: setVisible", tostring(player), tostring(visible))
    for k, v in pairs(machine_controller.players[player].elements) do
        v.setVisible(visible)
    end
    for k, v in ipairs(machine_controller.players[player].display.currentlyDisplayed) do
        v.setVisible(visible)
    end
end

function machine_controller.update()
    for playerName, playerTable in pairs(machine_controller.players) do
        for k, v in pairs(machine_controller.players[playerName].display.currentlyDisplayed) do
            v.update()
        end
    end
end

local init_timer = nil
function machine_controller.onModemMessage(messageType, group, message)
    print("mach_cont - 197: onModemMessage", tostring(messageType), tostring(group), tostring(message))
    local messageTable 
    messageTable = s.unserialize(message)

    if not messageTable then
       messageTable = message
    end

    if type(messageTable) == "string" then
        if messageTable == "error" then
            print("\n \n \n \n \n mach_control - 207, REMOTE ERROR RECIEVED", tostring(messageType), tostring(group), "\n \n \n \n \n")
            --***Maybe Do something intelligent here***
            return
        end
    end

    if messageType == "init" then
        print("mach_cont - 214: init message recieved")
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
        print("mach_cont - 225: update message recieved")
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
    print("mach_cont - 238: remote_execute", tostring(address), tostring(command), tostring(player))
    local invokeTable = {
        machine = address,
        command = command,
        args = serialized_args,
        returnAddress = component.modem.address,
        player = player or "none"
    }

    component.modem.broadcast(301, player, machine_controller.machines[address].group, "remote_execute", s.serialize(invokeTable))
    print("mach_cont - 248: remote_execute - broadcasted message, waiting for return")
    local message = event.pull("remote_return")
    print("mach_cont - 250: remote_execute - recieved return message", tostring(message))

    local ret = s.unserialize(message)
    if ret and ret[1] and not ret[2] then
        print("mach_cont - 254: remote_execute - return is a single value")
        return ret[1]
    elseif ret and ret[1] and ret[2] then
        print("mach_cont - 257: remote_execute - return is a table")
        return ret
    elseif ret and ret.x then
        print("mach_cont - 260: remote_execute - return is a coordinate table")
        return ret
    end
end

--------------------------------------
--- Widgets

machine_controller.createGroupWidget = function(x, y, group, player, detached, index)
    print("mach_cont - 269: createGroupWidget", tostring(x), tostring(y), tostring(group), tostring(player), tostring(detached), tostring(index))
    component.glasses = require("displays.glasses_display").getGlassesProxy(player)
    local text

    print("mach_cont - 273: createGroupWidget - creating widget")
    local groupWidget = widgetsAreUs.machineGroup(x, y, group)
    groupWidget.index = index
    groupWidget.group = group.name

    print("mach_cont - 278: createGroupWidget - setting up function table")
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
    print("mach_cont - 303: createGroupWidget - finished base function table")
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
    print("mach_cont - 338: createGroupWidget - finished function table")

    groupWidget = widgetsAreUs.attachOnClickRight(groupWidget, function(eventName, address, player, x2, y2, button)
        if detached then
            text = "Attach Element"
        else
            text = "Remove Element"
        end

        local context = contextMenu.init(x2, y2, player, funcTable)
    end)
    print("mach_cont - 349: createGroupWidget - finished attaching onClickRight")
    groupWidget.funcTable = funcTable

    groupWidget.update = function()
        if machine_controller.groups[group].allowed and machine_controller.groups[group].allowed == #machine_controller.groups[group] then
            groupWidget.backgroundInterior.setColor(0, 1, 0)
        elseif machine_controller.groups[group].allowed and machine_controller.groups[group].allowed < #machine_controller.groups[group] and machine_controller.groups[group].allowed > 0 then
            groupWidget.backgroundInterior.setColor(table.unpack(c.yellow))
        elseif machine_controller.groups[group].allowed and machine_controller.groups[group].allowed == 0 then
            groupWidget.backgroundInterior.setColor(1, 0, 0)
        end
        groupWidget.canRun.setText(tostring(machine_controller.groups[group].allowed))
    end

    return groupWidget
end

createMachineWidget = function(x, y, machineGroup, player, detached, index)
    print("mach_cont - 356: createMachineWidget", tostring(x), tostring(y), tostring(machineGroup), tostring(player), tostring(detached), tostring(index))
    local machine = machineGroup.address
    local text = "Detach"
    if detached then
        text = "Remove"
    end
    local index = index

    print("mach_cont - 363: createMachineWidget - setting up widget")
    component.glasses = require("displays.glasses_display").getGlassesProxy(player)
    local machineWidget = widgetsAreUs.machine(x, y, machine)
    if machine_controller.machines[machine].name then
        print("mach_cont - 367: createMachineWidget - setting name")
        machineWidget.setName(machine_controller.machines[machine].name)
    end
    machineWidget.group = machine_controller.machines[machine].group

    print("mach_cont - 372: createMachineWidget - setting up function table")
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
    print("mach_cont - 411: createMachineWidget - finished base function table")
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
    print("mach_cont - 446: createMachineWidget - finished function table")

    machineWidget = widgetsAreUs.attachOnClickRight(machineWidget, function(eventName, address, player, x2, y2, button)
        local context = contextMenu.init(x2, y2, player, funcTable)
    end)
    print("mach_cont - 451: createMachineWidget - finished attaching onClickRight")
    
    machineWidget.update = function()
        if machine_controller.machines[machine].running then
            machineWidget.state.setText("Running")
        else
            machineWidget.state.setText("Stopped")
        end
        if machine_controller.machines[machine].allowed then
            machineWidget.backgroundInterior.setColor(0, 1, 0)
        else
            machineWidget.backgroundInterior.setColor(1, 0, 0)
        end
    end

    return machineWidget
end

--------------------------------------
--- Module Specific Event Handling

local function init_machines_table()
    print("mach_cont - 460: init_machines_table")
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