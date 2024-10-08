local component = require("component")
local basic_elements = require("displays.glasses_elements.basic_elements")
local context_menu = require("displays.glasses_elements.contextMenu")

local horizontalSteps = 4
local verticalSteps = 9

function hudConfigurator(player)
    local glasses_display = require("displays.glasses_display")
    local Module = {}
    local gridEnabled = true
    local xThresholds = {}
    local yThresholds = {}
    local function init(window, element)
        print("HudConfigurator-12: init")
        --Sets up the module, called on boot.
        local res = glasses_display.getResolution(player)
        Module.grid = {}

        local gridLines = {}
        --Hotbar edges
        local div1 = res.x/2-91
        local div2 = res.x/2+91
        --Vertical lines
        local step = div1 / horizontalSteps
        print("hudConfigurator-27: horizontalSteps 1")
        for i=1, horizontalSteps, 1 do
            local line = basic_elements.createBox(step*i, 0, 1, res.y, {0.1333, 0.1333, 0.1333}, 0.4)
            table.insert(gridLines, line)
            table.insert(xThresholds, step*i)
        end
        print("hudConfigurator-33: horizontalSteps 2")
        for i=0, horizontalSteps, 1 do
            local line = basic_elements.createBox(div2 + step*i, 0, 1, res.y, {0.1333, 0.1333, 0.1333}, 0.4)
            table.insert(gridLines, line)
            table.insert(xThresholds, div2 + step*i)
        end
        --Horizontal lines
        step = res.y / verticalSteps
        print("hudConfigurator-41: verticalSteps")
        for i=1, verticalSteps, 1 do
            local line = basic_elements.createBox(0, step * i, res.x, 1, {0.1333, 0.1333, 0.1333}, 0.4)
            table.insert(gridLines, line)
            table.insert(yThresholds, step*i)
        end

        Module.grid = gridLines

        local surface = basic_elements.createBox(0, 0, res.x, res.y, {0.1333, 0.1333, 0.1333}, 0.0)
        print("hudConfigurator-51: surface")
        surface.onClick = function (eventName, address, player, x, y, button)
            print("hudConfigurator-53: surface.onClick")
            if eventName == "hud_click" and button == 0 then
                if Module.data.selectionWindow then
                    Module.data.selectionWindow.remove()
                    Module.data.selectionWindow = nil
                    Module.data.selection = nil
                end
                Module.data.selectionStart = {x=x, y=y}
            end
            return true
        end

        local function toggleGrid()
            print("hudConfigurator-66: toggleGrid")
        end

        surface.onClickRight = function (eventName, address, player, x, y, button)
            print("hudConfigurator-70: surface.onClickRight")
            if button == 1 then
                local contextWindow = glasses_display.create(player, "Context Surface 2", 0, 0, res.x, res.y)
                contextWindow.options.closeOnFocusLoss = false
                local menu = context_menu({
                    ["Toggle grid"] = toggleGrid,
                }, {x=x, y=y})
                contextWindow.addElement(menu)
                glasses_display.render(contextWindow)
                return true
            end
        end

        surface.onDrag = function (eventName, address, player, x, y, button)
            print("hudConfigurator-84: surface.onDrag")
            if eventName == "hud_drag" then
                if Module.data.selection == nil then
                    Module.data.selection = {x=x, y=y, w=1, h=1}
                end

                Module.data.selection = {
                    x=math.min(x, Module.data.selectionStart.x),
                    y=math.min(y, Module.data.selectionStart.y),
                    w=math.abs(x - Module.data.selectionStart.x),
                    h=math.abs(y - Module.data.selectionStart.y)}

                if Module.data.selectionWindow then
                    Module.data.selectionWindow.remove()
                    Module.data.selectionWindow = nil
                end

                local selection = basic_elements.create(player, "Selection",
                    Module.data.selection.x, Module.data.selection.y,
                    Module.data.selection.w, Module.data.selection.h)
                selection.options.closeOnFocusLoss = false
                local selectionRect = basic_elements.createBox(0, 0, Module.data.selection.w, Module.data.selection.h, {0.4667, 0.4667, 0.4667}, 0.5)
                selection.addElement(selectionRect)
                Module.data.selectionWindow = selection
                selectionRect.onClick = function() return false end
                selectionRect.onDrag = function() return false end

                local gridSelectionLeft = 0
                local gridSelectionRight = nil
                local gridSelectionTop = 0
                local gridSelectionBottom = nil
                for _, value in ipairs(xThresholds) do
                    if value < Module.data.selection.x then gridSelectionLeft = value end
                    if gridSelectionRight == nil then
                        if value > Module.data.selection.x + Module.data.selection.w then gridSelectionRight = value end
                    end
                end
                for _, value in ipairs(yThresholds) do
                    if value < Module.data.selection.y then gridSelectionTop = value end
                    if gridSelectionBottom == nil then
                        if value > Module.data.selection.y + Module.data.selection.h then gridSelectionBottom = value end
                    end
                end

                if Module.data.gridSelection ~= nil then
                    Module.data.gridSelection.remove()
                    Module.data.gridSelection = nil
                end
                local gridSelectionWindow = glasses_display.create(player, "Grid Selection",
                gridSelectionLeft, gridSelectionTop, gridSelectionRight - gridSelectionLeft, gridSelectionBottom - gridSelectionTop)

                local selectionWidth = gridSelectionRight - gridSelectionLeft
                local selectionHeight = gridSelectionBottom - gridSelectionTop
                local gridSelectionRect = basic_elements.createBox(1, y,selectionWidth - 1, selectionHeight - 1, theme.primaryColour, 0.2)
                Module.data.gridSelection = gridSelectionWindow
                gridSelectionRect.onClick = function() return false end
                gridSelectionRect.onDrag = function() return false end

                local function removeGridSelection()
                    print("hudConfigurator-143: removeGridSelection")
                    if Module.data.gridSelection ~= nil then
                        Module.data.gridSelection.remove()
                        Module.data.gridSelection = nil
                    end
                end

                local function addModule_autocrafter()
                    print("hudConfigurator-151: addModule_autocrafter")
                    if type(Module.data.moduleCount) ~= "number" then
                        Module.data.moduleCount = 0
                    else
                        Module.data.moduleCount = Module.data.moduleCount + 1
                    end
                    local moduleWindow = glasses_display.create(player, "autocrafting_controller", gridSelectionLeft, gridSelectionTop, selectionWidth, selectionHeight)
                    moduleWindow.init()
                end

                local function addModule_items()
                    print("hudConfigurator-162: addModule_items")
                    if type(Module.data.moduleCount) ~= "number" then
                        Module.data.moduleCount = 0
                    else
                        Module.data.moduleCount = Module.data.moduleCount + 1
                    end
                    local moduleWindow = glasses_display.create(player, "item_overseer", gridSelectionLeft, gridSelectionTop, selectionWidth, selectionHeight)
                    moduleWindow.init()
                end

                local function addModule_machines()
                    print("hudConfigurator-173: addModule_machines")
                    if type(Module.data.moduleCount) ~= "number" then
                        Module.data.moduleCount = 0
                    else
                        Module.data.moduleCount = Module.data.moduleCount + 1
                    end
                    local moduleWindow = glasses_display.create(player, "machine_overseer", gridSelectionLeft, gridSelectionTop, selectionWidth, selectionHeight)
                    moduleWindow.init()
                end

                local function addModule_power()
                    print("hudConfigurator-184: addModule_power")
                    if type(Module.data.moduleCount) ~= "number" then
                        Module.data.moduleCount = 0
                    else
                        Module.data.moduleCount = Module.data.moduleCount + 1
                    end
                    local moduleWindow = glasses_display.create(player, "power_overseer", gridSelectionLeft, gridSelectionTop, selectionWidth, selectionHeight)
                    moduleWindow.init()
                end

                local function addModule_robots()
                    print("hudConfigurator-195: addModule_robots")
                    if type(Module.data.moduleCount) ~= "number" then
                        Module.data.moduleCount = 0
                    else
                        Module.data.moduleCount = Module.data.moduleCount + 1
                    end
                    local moduleWindow = glasses_display.create(player, "robot_director", gridSelectionLeft, gridSelectionTop, selectionWidth, selectionHeight)
                    moduleWindow.init()
                end

                local function addModule_text()
                    print("hudConfigurator-206: addModule_text")
                    if type(Module.data.moduleCount) ~= "number" then
                        Module.data.moduleCount = 0
                    else
                        Module.data.moduleCount = Module.data.moduleCount + 1
                    end
                    local moduleWindow = glasses_display.create(player, "text_editor", gridSelectionLeft, gridSelectionTop, selectionWidth, selectionHeight)
                    moduleWindow.init()
                end

                gridSelectionRect.onClickRight = function (window2, element2, eventName2, address2, x2, y2, button2, name2)
                    print("hudConfigurator-217: gridSelectionRect.onClickRight")
                    local contextWindow
                    
                    local function addModuleContext()
                        print("hudConfigurator-221: addModuleContext")
                        --local contextWindow = glasses_display.create(player, "Context Surface 3", 0, 0, res.x, res.y)
                        local menu2 = context_menu({
                            ["autocrafting_controller"] = addModule_autocrafter,
                            ["item_overseer"] = addModule_items,
                            ["machine_overseer"] = addModule_machines,
                            ["power_overseer"] = addModule_power,
                            ["robot_director"] = addModule_robots,
                            ["text_editor"] = addModule_text
                        }, {x=x2, y=y2})
                        contextWindow.addElement(menu2)
                        glasses_display.render(contextWindow)
                    end

                    contextWindow = glasses_display.create(player, "Context Surface", 0, 0, res.x, res.y)
                    local menu = context_menu({
                        ["Remove selection"] = removeGridSelection,
                        ["Add module"] = addModuleContext
                    }, {x=x2, y=y2})
                    contextWindow.addElement(menu)
                    glasses_display.render(contextWindow)
                    return true
                end

                gridSelectionWindow.addElement(gridSelectionRect)
                glasses_display.render(gridSelectionWindow)
                return true
            end
        end

        Module.grid.addElement(surface)
        glasses_display.render()
        print("hudConfigurator-253: init finished")
    end
    local function update()
        --Processes the Module logic, called by the main thread once per tick.
    end
    local function save()
        --Save the Module.data to a file.
    end
    local function load()
        --Load the saved data.
    end


    Module = {
        name = "HudConfigurator",
        init = init,
        update = update,
        save = save,
        load = load,
        data = {
            moduleCount = 0,
            selection = nil,
            selectionWindow = nil,
            selectionStart = nil,
            contextMenu = nil,
            gridSelection = nil}
    }

    return Module
end

return hudConfigurator