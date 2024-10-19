package.path = package.path .. ";/home/GimpOCD-V2/?.lua"
local event = require("event")
component = require("component")
local glasses_display = require("displays.glasses_display")
timing = {}
local time = require("lib.timing")
local shell = require("shell")
local thread = require("thread")


--------------------------------------
--- Shell Arguments

local args, options = shell.parse(...)

--[[local verbosity = false
if options and options.verbose then
    verbosity = true
end
if not verbosity then
    print = function() end
end]]

if args and args[1] and type(args[1]) == "number" then
    time(args[1])
else
    time(1)
end

--------------------------------------
--- Initialization - Events

print("removing all widgets")
component.glasses.removeAll()

component.modem.open(202) -- Power
component.modem.open(301) -- Output Machine Controller commands
component.modem.open(302) -- remote return information
component.modem.open(201) -- Input Machine Controller Information
players = {}
gimp_globals = {}
gimp_globals.mutexes = {}
gimp_globals.mutexes.power_overseer = false

glasses_display.init()

--------------------------------------
--- Event Handling

local function onClick(eventName, address, player, x, y, button)
    print("Handling onClick event")
    local suc, err = pcall(function()
        if eventName == "hud_click" and button == 0 then
            print("Left-click detected")
            glasses_display.onClick(eventName, address, player, x, y, button)
        elseif eventName == "hud_click" and button == 1 then
            print("Right-click detected")
            glasses_display.onClickRight(eventName, address, player, x, y, button)
        end     
    end)
end

local function onDrag(eventName, address, player, x, y, button)
    if gimp_globals.mutexes.power_overseer then return end
    print("Handling onDrag event")
    local suc, err = pcall(function()
        if eventName == "hud_drag" then
            print("Drag detected")
            glasses_display.onDrag(eventName, address, player, x, y, button)
        end
    end)
end

local modemListener = function()
    while true do
        local suc, err = pcall(function()
            local _, _, _, port, _, message1, group, message = event.pull("modem_message")
            if port == 202 then
                event.push("power_message", message1)
            elseif port == 201 then
                event.push("machine_update", message1, group, message)
            elseif port == 302 and component.modem.address == message1 then
                event.push("remote_return", message)
            end
        end)
        if not suc then
            print("GimpOCD_mk2 - 84 - Error in onModemMessage: " .. err)
        else
            print("GimpOCD_mk2 - 86 - onModemMessage successful")
        end
    end
end

local modemThread = thread.create(modemListener)
modemThread:detach()

local function onPowerMessage(message1)
    print("GimpOCD_mk2 - 71 - Power message received")
    for playerName, playerTable in pairs(players) do
        if players[playerName].modules[players[playerName].current_hudPage] and players[playerName].modules[players[playerName].current_hudPage].power_overseer then
            players[playerName].modules[players[playerName].current_hudPage].power_overseer.onModemMessage(message1)
        end
    end
    return true
end

local function onMachineUpdate(messageType, group, message)
    for playerName, playerTable in pairs(players) do
        if players[playerName].modules[players[playerName].current_hudPage] and players[playerName].modules[players[playerName].current_hudPage].machine_controller then
            players[playerName].modules[players[playerName].current_hudPage].machine_controller.onModemMessage(messageType, group, message)
        end
    end
    return true
end

function enableOnClick()
    event.listen("hud_click", onClick)
    event.listen("hud_drag", onDrag)
end
function disableOnClick()
    event.ignore("hud_click", onClick)
    event.ignore("hud_drag", onDrag)
end

event.listen("machine_update", onMachineUpdate)
event.listen("power_message", onPowerMessage)
enableOnClick() 

--------------------------------------
--- ZZZZZZZZZZZZZZZZZZZ

while true do
    os.sleep(5)
end