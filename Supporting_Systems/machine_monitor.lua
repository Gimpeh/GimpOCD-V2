-- Script for monitoring groups of gregtech blocks and reporting the data wirelessly
-- (also used to turn machines on and off if commanded to do so)

--------------------------------------------------------------------------
-- The config if you will....
-- Set the name of the group of machines or it will error and the computer that actually runs the glasses stuff will have issues... probably.... 
local groupName = "default"
--group names are as follows;
--
--------------------------------------------------------------------------
--import statements
local component = require("component")
local event = require("event")
local s = require("serialization")
local shell = require("shell")

--------------------------------------------------------------------------
--- args

local args, options = shell.parse(...)

if args and args[1] then
    groupName = args[1]
end

--------------------------------------------------------------------------
-- variables

-- Different players might want multiple things...
local players = {}	

-- Modem stuff
local modem = component.modem
--out
local metricsPort = 201 -- port for sending metrics

--in
local commandsPort = 301  -- port for recieving commands to execute.. mainly for turning stuff on and off

--stuff we're actually interested in monitoring (and possibly turning on and off)
local stuffToMonitor = {}				--initialize the table
stuffToMonitor.tanks = {}
stuffToMonitor.machines = {}

local power_amounts = {
	["LV"] = 32,
	["MV"] = 128,
	["HV"] = 512,
	["EV"] = 2048,
	["IV"] = 8192,
	["LuV"] = 32768,
	["ZPM"] = 131072,
	["UV"] = 524288,
	["UHV"] = 2097152,
	["UEV"] = 8388608,
	["UIV"] = 33554432,
	["UMV"] = 134217728,
	["UXV"] = 536870912,
	["MAX"] = 2147483647
}

local broadcastGroup
local broadcastInit
--------------------------------------------------------------------------
-- initialization functions. Which are mostly getting proxies of what were monitoring and sorting them
	--into the appropriate tables so we can actually call them

-- all in a blob
local function proxyAll()
	local gt_machines = {}
	for address, componentType in component.list("gt_machine") do
		table.insert(gt_machines, component.proxy(address))
	end

	return gt_machines
end

-- sort the blob
local function sortProxies(gt_machines)
	--helper function for determining if a machine is an energy hatch
	local function is_hatch_energy(name)
		-- Get the length of "hatch.energy"
		local prefix = "hatch.energy"
		local prefix_length = #prefix
		
		-- Get the first part of the string
		local first_part = string.sub(name, 1, prefix_length)
		
		-- Check if the first part matches "hatch.energy"
		return first_part == prefix
	end

	--helper function for determining if a machine is a wireless energy hatch (which we don't do anything with at this point except NOT add it to the machines tables)
	local function is_wireless_energy_hatch(name)
		-- Get the length of "hatch.energy"
		local prefix = "hatch.wireless"
		local prefix_length = #prefix
		
		-- Get the first part of the string
		local first_part = string.sub(name, 1, prefix_length)
		
		-- Check if the first part matches "hatch.energy"
		return first_part == prefix
	end

	--helper function for determining if a machine is a super tank
	local function is_super_tank(name)
		-- Get the length of "hatch.energy"
		local prefix = "super.tank"
		local prefix_length = #prefix
		
		-- Get the first part of the string
		local first_part = string.sub(name, 1, prefix_length)
		
		-- Check if the first part matches "hatch.energy"
		return first_part == prefix
	end

	-- the business side of this function
	-- which sorts components into their respective tables
	for k, machine in ipairs(gt_machines) do	-- for every machine in the table specified by the function argument
		local name = machine.getName()			-- Get the name of machine.. so we can sort using it

		-- if its a super tank
		if is_super_tank(name) then
			table.insert(stuffToMonitor.tanks, machine)
		-- if it isnt a super tank but is an energy hatch
		elseif is_hatch_energy(name) then
			table.insert(stuffToMonitor.energyHatches, machine)
		-- if it isn't either of the above then it must be....
		else
			if not is_wireless_energy_hatch(name) then
				table.insert(stuffToMonitor.machines, machine)
			end
		end
	end
end

--function to actually do all the startup things
local function init()
	modem.open(metricsPort)		--open port for sending metrics (port 201)
	modem.open(commandsPort)	--open port for recieving commands (port 301)
	sortProxies(proxyAll())		--first proxy all gregtech 'components', then sort them into appropriate tables
	
	for k, table in pairs(stuffToMonitor) do
		print(k)
		for v, thing in ipairs(table) do
			print(thing.getName())
		end
	end
end

local function addPlayer(playerName)
	players[playerName] = {}
	players[playerName].task = broadcastGroup
	players[playerName].machineToFocus = nil
	players[playerName].all = true
end

---------------------------------------------------------------
-- functions for getting information we need to update the overlay or HUD

------machines individual -- will need to do these in such a way that we are referencing/passing coords to uniquely identify the machine

-- Find machine from coordinates
local function find_machine(xyzTable)
	for k, machine in ipairs(stuffToMonitor.machines) do
		local x1, y1, z1 = machine.getCoordinates()
		if xyzTable.x == x1 and xyzTable.y == y1 and xyzTable.z == z1 then
			return machine
		end
	end
end

-- Check individual running state
local function is_machine_running(machine)
	return machine.isMachineActive()
end

-- Check individual on/off state
local function can_machine_work(machine)
	return machine.isWorkAllowed()
end

-- Estimate Power Consumption (highest possible for tier)
local function estimate_power_consumption(machine)
	local function find_voltage_tier(sensor_info, search_string)
		for lineNumber, lineText in ipairs(sensor_info) do
			print("219 - Searching Sensor Info for Tier. sensor line:", tostring(lineNumber))
			local startPos, endPos = string.find(lineText, search_string, 1, true)

			if startPos and endPos then
				local tier = string.sub(lineText, endPos + 1, endPos + 4)
				print("224 - found tier", tostring(tier))
				return tier
			else
				print("227 - Nothing on line ", tostring(lineNumber))
			end
		end
		return false
	end

	print("235 - getting sensor info")
	local sensor_info = machine.getSensorInformation()
	print("237 - finding tier")
	local tier = find_voltage_tier(sensor_info, "Tier: ")

	if tier and power_amounts[tier] then
		return power_amounts[tier]
	else
		print("243- either no tier or tier doesnt exist on table")
		return 0
	end
end

-- Get machine name
local function get_machine_name(xyzTable)
	local machine = find_machine(xyzTable)
	return machine.getName()
end

-- Turn machine on
local function turn_machine_on(xyzTable)
	local machine = find_machine(xyzTable)
	machine.setWorkAllowed(true)
end

-- Turn machine off
local function turn_machine_off(xyzTable)
	local machine = find_machine(xyzTable)
	machine.setWorkAllowed(false)
end

-- Get machine coordinates
local function get_machine_coordinates(machine)
	local x, y, z = machine.getCoordinates()
	local xyzTable = {x = x, y = y, z = z}
	return xyzTable
end

-----machines groups
local function amountOfMachines()
	return #stuffToMonitor.machines
end

-- check how many machines are allowed to work
local function amountAllowedToWork()
	local amount = 0	--init the return variable as a number

	-- check each machine
	for k, machine in ipairs(stuffToMonitor.machines) do
		if machine.isWorkAllowed() then
			amount = amount + 1		-- if its allowed to work increase amount by 1
		end
	end

	return amount
end

-- check how much power the group of machines are using
local function powerConsumed()
	local powerUse = 0		--init the return variable as a number

	for k, machine in ipairs(stuffToMonitor.machines) do
		if machine.isMachineActive() then
			powerUse = powerUse + estimate_power_consumption(machine.getCoordinates())
		end
	end

	return powerUse
end

-- check how many machines are running
local function amountRunning()
	local machinesRunning = 0	--init the return variable as a number

	--check each energy hatch. If its using power it must be running
	for k, energyHatch in ipairs(stuffToMonitor.energyHatches) do
		if energyHatch.getEUInputAverage() > 0 then		--if its recieving power
			machinesRunning = machinesRunning + 1	--update the return variable
		end
	end

	return machinesRunning
end

-- Turn off all machines
local function turnOffAllMachines()
	for k, machine in ipairs(stuffToMonitor.machines) do
		machine.setWorkAllowed(false)
	end
end

-- Turn on all machines
local function turnOnAllMachines()
	for k, machine in ipairs(stuffToMonitor.machines) do
		machine.setWorkAllowed(true)
	end
end

-- check for maintenance problems for all connected machines
local function needsMaintenance()
	local maintenanceCoordinates = {} --initalize a new temporary table, It will just contain a list of coordinates to machines requiring maintenance

	--helper function to iterate through sensor information and check if there is required maintenance
	local function hasProblems(sensor_info)
		for _, line in ipairs(sensor_info) do
			if line:match("Problems: §c%d+§r") then
				local problems = tonumber(line:match("Problems: §c(%d+)§r"))
				if problems > 0 then
					return true
				end
			end
		end
		return false
	end

	for _, machine in ipairs(stuffToMonitor.machines) do				--iterate through all machines
		local sensor_info = machine.getSensorInformation()				--get the 'sensor information'
		if hasProblems(sensor_info) then								--check if the machine has problems
			local x, y, z = machine.getCoordinates()					--if it does, get the coordinates of the machine
			table.insert(maintenanceCoordinates, {x = x, y = y, z = z})	--and store them on our temporary table
		end
	end

	if #maintenanceCoordinates > 0 then		--if there are any entries on our temporary table
		return maintenanceCoordinates		--shoot them out to whatever is asking (calling this function)
	else
		return false
	end
end

----------------------
-- Tanks

-- find tank from coordinates
local function find_tank(xyzTable)
	for k, tank in ipairs(stuffToMonitor.tanks) do
		local x1, y1, z1 = tank.getCoordinates()
		if xyzTable.x == x1 and xyzTable.y == y1 and xyzTable.z == z1 then
			return tank
		end
	end
end

-- get the amount of fluid (nitrobenzene) in connected tanks <-- This is old, im keeping it because I might want it later.. right now it isn't used
local function amountInTank(xyzTable)
	-----------------------------------------
	--helper functions for sifting through gt_machine.getSensorInformation() to get whats in the tank
    local function extractFluidLevel(sensorInfo)
		local fluidLevel = 0
		for _, lineText in ipairs(sensorInfo) do
			local startPos, endPos = string.find(lineText, "Tank 0: ", 1, true)
			if startPos and endPos then
				local firstL = string.find(lineText, " L ", endPos + 1, true)

				if firstL then
					local current_amount = string.sub(lineText, endPos + 1, firstL - 2)
					local endL = string.find(lineText, "L", firstL + 1, true)
					local max_amount = string.sub(lineText, firstL + 4, endL - 2)
					local tank_fluid_info = {current_amount = tonumber(current_amount), max_amount = tonumber(max_amount)}
					return tank_fluid_info
				end
			end
		end
    end
	----------------------------------------
	-- business end of the actual function

	return extractFluidLevel(find_tank(xyzTable).getSensorInformation())
end

--------------------------------------------------------------------------
-- the function for sending all the information (it calls the functions for getting the info)
-- minus maintenance problems. thats the next function

broadcastGroup = function()
	local groupInfo = {
		amountOfMachines = amountOfMachines(),
		amountAllowedToWork = amountAllowedToWork(),
		powerConsumed = powerConsumed(),
		amountRunning = amountRunning(),
		machines_coords = {}
	}

	modem.broadcast(metricsPort, "group", groupName, s.serialize(groupInfo))
end

local function broadcastSingle(machine)
	local machineInfo = {
		running = is_machine_running(machine),
		canWork = can_machine_work(machine),
		powerConsumed = estimate_power_consumption(machine)
	}
	modem.broadcast(metricsPort, "single", s.serialize(get_machine_coordinates(machine)), s.serialize(machineInfo))
end

local function broadcastMaintenance()
	local maintenanceCoords = needsMaintenance()

	if maintenanceCoords then
		modem.broadcast(metricsPort, "maintenance", groupName, s.serialize(maintenanceCoords))
	end
end

broadcastInit = function()
	local machine_coords = {}

	for k, machine in ipairs(stuffToMonitor.machines) do
		local x, y, z = machine.getCoordinates()
		local tbl = {
			x = x,
			y = y,
			z = z,
			name = machine.getName()
		}
		table.insert(machine_coords, tbl)
	end

	modem.broadcast(metricsPort, "init", groupName, s.serialize(machine_coords))
end

--------------------------------------------------------------------------
-- the wireless message handler. Used to turn machines on and off when correct message is sent
local function modemMessageHandler(_, _, _, port, _, player, group, typeOfMessage, message)
	local suc, err = pcall(function()
		--only run if the message is for machine controllers and if it is for this group
		if port == commandsPort then
			if typeOfMessage == "init" then
				addPlayer(player)
				broadcastInit()
			end
			if typeOfMessage == "all monitor" then
				players[player].all = true
				players[player].task = broadcastGroup
				return
			end
			if group == groupName then
				--if the message is to turn a group of machines on
				if typeOfMessage == "group on" then
					turnOnAllMachines()
				--if the message is to turn a group of machines off
				elseif typeOfMessage == "group off" then
					turnOffAllMachines()
				--if the message is to turn a single machine on
				elseif typeOfMessage == "single on" then
					turn_machine_on(s.deserialize(message))
				--if the message is to turn a single machine off
				elseif typeOfMessage == "single off" then
					turn_machine_off(s.deserialize(message))				
				--if the message is to report on the group
				elseif typeOfMessage == "group monitor" then
					players[player].task = function()
                        for k, machine in ipairs(stuffToMonitor.machines) do
                            broadcastSingle(machine)
                        end
                    end
				--if the message is to report on a single machine
				elseif typeOfMessage == "single monitor" then
					players[player].machineToFocus = find_machine(s.deserialize(message))
					local coords = s.deserialize(message)
					players[player].task = function()
						broadcastSingle(players[player].machineToFocus)
					end
				end
			elseif group ~= groupName then
				if typeOfMessage == "group monitor" then
					players[player].task = function() end
				elseif typeOfMessage == "single monitor" then
					players[player].task = function() end
				end
			end
		end
	end)
	if not suc then print("Error handling command", err) end
end

event.listen("modem_message", modemMessageHandler)
event.listen("component_removed", init)
event.listen("component_added", init)
event.timer(120, broadcastMaintenance, math.huge)

--------------------------------------------------------------------------
-- Actually doing everything. The main method if you will.
init()	--initialize
print("Initialized and Running")

while true do -- infinite loop
	local suc, err = pcall(function()
		local all = true
		for player, playerTable in pairs(players) do
			if not playerTable.all then
				all = false
			end
		end
		if all then
			broadcastGroup()
		else
			for player, playerTable in pairs(players) do
				playerTable.task()
			end
		end
	end)
	os.sleep(5)
end