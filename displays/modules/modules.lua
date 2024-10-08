print("modules.lua loaded and processing")

--local me_cpu_controller = require("displays.modules.autocrafting_controller.me_cpu_controller").init
local item_overseer = require("displays.modules.item_overseer.item_overseer").init
--local machine_overseer = require("displays.modules.machine_overseer.machine_overseer").init
--local power_overseer = require("displays.modules.power_overseer/power_overseer").init
--local robot_director = require("displays.modules.robot_director/robot_director").init
--local text_editor = require("displays.modules.text_editor/text_editor").init

local modules = {
    --me_cpu_controller = me_cpu_controller,
    item_overseer = item_overseer,
    --machine_overseer = machine_overseer,
    --power_overseer = power_overseer,
    --robot_director = robot_director,
    --text_editor = text_editor
}

print("modules.lua finished processing")

return modules