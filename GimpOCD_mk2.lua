package.path = package.path .. ";/GimpOCD-V2/?.lua"
local event = require("event")
component = require("component")
local glasses_display = require("displays.glasses_display")

print("removing all widgets")
component.glasses.removeAll()

players = {}

while true do
    os.sleep(5)
end