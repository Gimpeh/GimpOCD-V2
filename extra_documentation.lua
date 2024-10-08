--[[
players[player] = {
    resolution = {
        x = max_x,
        y = max_y
        },
    current_hudPage = 1,
    currentModules = {
        [moduleName]
    },
    availableModules = require("displays.modules.modules"),
    contextMenu = {  <-- ALWAYS CHECK THIS FIRST FOR onClicks (if it exists, we want to deal with it)
        elements = {
            backgroundBox = the background box,
            <array of all the other elements>
        }
        funcTable = {
            [arrayOfArgs] = {
                text = "Displayed Text",
                func = function,
                args = {arrayOfArgs}
            }
    },
    hudSetup = { <-- seperate tables for each player, to easily micromanage each player's VR setup
        xThresholds = {}, <-- for the grid
        yThresholds = {}, <-- for the grid
        elements = {
            window = selection window, <-- check first, seperate for micromanagement
            surface = just a thing for simplicity (to check if it exists before calling its onClick), <-- check second, seperate for micromanagement

            <the rest of the elements for the hud> (as an array, so we can micromanage order of box.contains checks and smartly choose what to do with onClick)
        
        }    
    }
    glasses_display = {
        elements = {
            [1], <-- Buttons for controlling hud Page
            [2],
            [3],
            grid_button <-- Button for toggling grid
        }
    }
    modules = {
        [pageNum] = {
            [moduleName] = {
                backgroundBox = the background box,
                onClick = function,
                onClickRight = function
            }
        }
    }
}
]]

--Add a FIXME button 
--  and some basic mutexes on the onClicks to prevent double-click-breaking shit

--Add persistance
--  item_overseer
--      tracked items
--      crafting items

--[[
                    Level maintainers...
                    they should check if the item in question is actually autocraftable, and give a pop-up if it isn't
]]