print("modules.lua loaded and processing")

--local cpu_director = require("displays.modules.cpu_controller.cpu_director").init
local item_overseer = require("displays.modules.item_overseer.item_overseer").init
--local machine_controller = require("displays.modules.machine_overseer.machine_controller").init
local power_overseer = require("displays.modules.power_overseer/power_overseer").init
--local robot_director = require("displays.modules.robot_director/robot_director").init
--local text_editor = require("displays.modules.text_editor/text_editor").init

local modules = {}

local function new()
    local available_modules = {
        --me_cpu_controller = me_cpu_controller,
        item_overseer = item_overseer,
        --machine_overseer = machine_overseer,
        power_overseer = power_overseer,
        --robot_director = robot_director,
        --text_editor = text_editor
    }
    return available_modules
end

function modules.init(player)
    if not players[player].modules then
        players[player].modules = {}
    end

    if not players[player].modules.available then
        players[player].modules.available = new()
    end
end

print("modules.lua finished processing")

return modules