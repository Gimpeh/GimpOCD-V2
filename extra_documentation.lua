--[[
players[player] = {
    resolution = {                                              <-- resolution of the player's screen (in glasses pixels)
        x = max_x,
        y = max_y
    },
    current_hudPage = 1,
    contextMenu = {
        elements = {
            backgroundBox = the background box,                 <-- idk why these are on the global table.. but not reworking cuz it works and its done
            <array of all the other elements>                   <-- don't really need this I feel like.. but Im not reworking it as its called specifically (specially)
        }
        funcTable = {                                           
            [arrayOfArgs] = {                                   <-- an array representing 1 option each
                text = "Displayed Text",                        <-- text to display for context menu option
                func = function,                                <-- function to call with args stored below
                args = {arrayOfArgs}                            <-- array of args in the order they should be passed
            }
    },
    popUp = {
        contains = function,                                    <-- note the lack of a backgroundBox, this is literally just a box with an onClick function
        <all other standard box stuff>,                         <-- remove, setVisible, etc.

        onClick = function,                                     <-- function to remove the pop-up
    },
    hudSetup = {
        elements = {                                            <-- If this table is not nil (nil not empty) hudSetup click stuff gets called ahead of module click stuff (so no modules get clicks)
            window = selection window,                          <-- Used by modules when they initialize from scratch to determine boundaries        
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
        available = {
            machine_controller = machine_controller.init,       <-- In progress
            power_overseer = power_overseer.init,               <-- Needs rework, but is functional
            text_editor = text_editor.init,                     <-- FUTUREEEEE
            item_overseer = item_overseer.init,                 <-- Should be finished, additional testing required (especially the level maintaining since that's entirely untested)
            cpu_director = cpu_controller.init,                 <-- FUTUREEEEE
            robot_director = robot_director.init                <-- FARRR IN THE FUTURE
        },
        [pageNum] = {
            [moduleName] = {
                backgroundBox = box containing all widgets,     <-- Used to determine where to send clicks in lib.glasses_display.lua

                -- All of these are triggered in displays.glasses_display.lua
                onClick = function,                             <-- obvious or blank (not nil) functions (context menus provide basic documentation, plain left click doesn't)
                onClickRight = function,                        <-- CONTEXT MENUS!!!
                setVisible = function,                          <-- core critical
                remove = function,                              <-- core critical
                
                --optional (usually one or the other)
                update = function,                              <-- Periodically called, set appropriate counters to not update more than necessary
                onModemMessage = function,                      <-- hard coded based on ports, in GimpOCD-mk2.lua
                
                --not used at all right now
                onDrag = function
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