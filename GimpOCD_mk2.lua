package.path = package.path .. ";/home/GimpOCD-V2/?.lua"
local event = require("event")
component = require("component")
local glasses_display = require("displays.glasses_display")

verbosity = true
if not verbosity then
    print = function() end
end


print("removing all widgets")
component.glasses.removeAll()

players = {}

glasses_display.init()

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
    print("Handling onDrag event")
    local suc, err = pcall(function()
        if eventName == "hud_drag" then
            print("Drag detected")
            glasses_display.onDrag(eventName, address, player, x, y, button)
        end
    end)
end

event.listen("hud_drag", onDrag)
event.listen("hud_click", onClick)

while true do
    os.sleep(5)
end