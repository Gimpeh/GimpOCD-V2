--------------------------------------------------------------------------
--[[ The Configs 

***MUCH SMARTER TO LEAVE THESE AS IS**
I do not guarantee that this program will be errorless and cannot crash.
Controlling Power Via Covers is the best way to go and is much more reliable.
If you want to use this functionality, proceed at your own risk.

And remember, I am not responsible for any damage that may occur to your base or your world,
or for fuel shortages or any other problems that may arise from using this part of the program.

If you want to use this functionality, you can change the values below.
the 2nd value is the TOTAL amount of energy stored in all connected battery type structures, not including wireless energy.

If you extend this functionality (or other functionality).. give me a holler and let me see what you did!
I'd love to add it to the main program to make it available for others to use!
and I'll if course give you credit for your work!

  -- Gimpeh
]]

local output_redstone = false
local output_redstone_when_this_amount_of_energy_is_stored = nil
local stop_outputting_power_at_this_amount_of_energy = nil 

--------------------------------------------------------------------------
--[[ The Notes

Designed for the 'Gregtech: New Horizons' modpack
This program is designed to send power metrics from any number of LSCs, Substations, and Battery Buffers wirelessly over port 202.
Actual Displays Sold Separately. 

Basic resiliency is built in, if a machine is removed or added, the program will automatically update the list of machines it is monitoring.
Basic error handling is also built in around the main function.. so if there is an error, the program won't just shit itself and die.

If I'm missing a type of battery or something doesn't function properly, give me a holler!

    -- Gimpeh
]]

--------------------------------------------------------------------------
--- The Libraries and Such 

local component = require("component")
local s = require("serialization")
local helper = require("gimpHelper")
local event = require("event")

local modem = component.modem
local powerMetricsPort = 202
modem.open(202)

local controllers = {}
controllers.lsc = {}
controllers.substation = {}
controllers.batteryBuffer = {}

--------------------------------------------------------------------------
--- The Functions

local function proxies()
  local gt_machines = {}
  for address, componentType in pairs(component.list("gt_machine")) do
    table.insert(gt_machines, component.proxy(address))
  end
  for address, componentType in pairs(component.list("gt_batterybuffer")) do
    table.insert(controllers.batteryBuffer, component.proxy(address))
  end
  return gt_machines
end

local function sortProxies(proxiesToSort)
  local function is_lsc(name)
    local prefix = "multimachine.supercapacitor"
    local prefix_length = #prefix
    
    local first_part = string.sub(name, 1, prefix_length)
    
    return first_part == prefix
  end

  local function is_substation(name)
    local prefix = "substation"
    local prefix_length = #prefix

    local first_part = string.sub(name, 1, prefix_length)

    return first_part == prefix
  end

  for k, proxy in pairs(proxiesToSort) do
    local name = proxy.getName()
    if is_lsc(name) then
      table.insert(controllers.lsc, proxy)
    elseif is_substation(name) then
      table.insert(controllers.substation, proxy)
    end
  end
end

local function init()
    controllers.lsc = {}
    controllers.substation = {}
    controllers.batteryBuffer = {}
  sortProxies(proxies())
end

local function getMetrics()
    local powerMetrics = {}
    powerMetrics.powerIn = 0
    powerMetrics.powerOut = 0
    powerMetrics.stored = 0
    powerMetrics.max = 0
    powerMetrics.wireless = 0

    for index, controller in pairs(controllers.lsc) do
        local sensorInfo = controller.getSensorInformation()
        local powerInTable = helper.extractNumbers(sensorInfo[10])
        powerMetrics.powerIn = tonumber(powerMetrics.powerIn) + tonumber(powerInTable[1])
        local powerOutTable = helper.extractNumbers(sensorInfo[11])
        powerMetrics.powerOut = tonumber(powerMetrics.powerOut) + tonumber(powerOutTable[1])
        powerMetrics.max = powerMetrics.max + tonumber(controller.getEUCapacityString())
        local str = sensorInfo[2]
        local number = str:match("%d[, %d]*")
        number = number:gsub(",", "")
        powerMetrics.stored = powerMetrics.stored + tonumber(number)
    end
    if controllers.lsc[1] then
        local sensorInfo = controllers.lsc[1].getSensorInformation()
        local str = sensorInfo[19]
        local number = str:match("%d[, %d]*")
        number = number:gsub(",", "")
        powerMetrics.wireless = powerMetrics.stored + tonumber(number)
    end

    for index, controller in pairs(controllers.substation) do
        local sensorInfo = controller.getSensorInformation()
        local powerStoredTable = helper.extractNumbers(sensorInfo[3])
        powerMetrics.stored = powerMetrics.stored + tonumber(powerStoredTable[1])
        powerMetrics.max = powerMetrics.max + tonumber(controller.getEUCapacityString())
        local powerInTable = helper.extractNumbers(sensorInfo[10])
        powerMetrics.powerIn = tonumber(powerMetrics.powerIn) + tonumber(powerInTable[1] - 90)
        local powerOutTable = helper.extractNumbers(sensorInfo[11])
        powerMetrics.powerOut = tonumber(powerMetrics.powerOut) + tonumber(powerOutTable[1] - 60)
    end

    for index, controller in pairs(controllers.batteryBuffer) do
        local sensorInfo = controller.getSensorInformation()
        local powerStoredTable = helper.extractNumbers(sensorInfo[3])
        powerMetrics.stored = powerMetrics.stored + tonumber(powerStoredTable[1])
        powerMetrics.max = powerMetrics.max + tonumber(powerStoredTable[2])
        local powerInTable = helper.extractNumbers(sensorInfo[5])
        powerMetrics.powerIn = tonumber(powerMetrics.powerIn) + tonumber(powerInTable[1])
        local powerOutTable = helper.extractNumbers(sensorInfo[7])
        powerMetrics.powerOut = tonumber(powerMetrics.powerOut) + tonumber(powerOutTable[1])
    end

    return powerMetrics
end


local function setGenerator(energyStored)
    local rs = component.list("redstone")
    for k, v in component.list("redstone") do
        if type(k) ~= "string" then
            return
        else
            break
        end
    end

    if output_redstone and output_redstone_when_this_amount_of_energy_is_stored then
        if output_redstone_when_this_amount_of_energy_is_stored > tonumber(energyStored) then
            component.redstone.setOutput({[0]=15,15,15,15,15,15})
        elseif stop_outputting_power_at_this_amount_of_energy < tonumber(energyStored) then
            component.redstone.setOutput({[0]=0,0,0,0,0,0})
        end
    end
end


local function main()
    local suc, powerMetrics = pcall(getMetrics)
    if not suc then
        print(powerMetrics)
    else
        local suc1, err1 = pcall(setGenerator, powerMetrics.stored)
        if not suc1 then print("error in setGenerator: " .. err1) end
        local suc2, err2 = pcall(modem.broadcast, powerMetricsPort, s.serialize(powerMetrics))
        if not suc2 then print("error in modem.broadcast: " .. err2) end
    end
end

--------------------------------------------------------------------------
--- The MAIN event

init()

event.listen("component_added", function()
    init()
end)

event.listen("component_removed", function()
    init()
end)

while true do
    local success, err = pcall(main)
    if not success then print(err) end
    os.sleep(2)
end