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

while true do
    os.sleep(5)
end