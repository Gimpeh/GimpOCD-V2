local shell = require("shell")

local args, options = shell.parse(...)

if args and args[1] and type(args[1]) == "number" then
    os.execute("/home/GimpOCD-V2/GimpOCD_mk2.lua " .. tostring(args[1]))
else
    os.execute("/home/GimpOCD-V2/GimpOCD_mk2.lua")
end