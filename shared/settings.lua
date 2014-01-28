--[[
    SERVER SETTINGS
]]

if Server then
    -- Allow client's to send where they think the vehicles are? (def: true)
    trustClients = true

    -- Do people need permission to pickup vehicles? (def: false)
    pickupVehiclesRequiresPermission = false

    -- Do people need permission to pickup vehicles with players in them? (def: true)
    pickupVehiclesWithPlayersRequiresPermission = true

    -- Do people need permission to pickup static objects? (def: false)
    pickupStaticRequiresPermission = false

    -- Do people need permission to pickup players? (def: true)
    pickupPlayersRequiresPermission = true

    -- Do people need permission to spawn objects? (def: true)
    spawningRequiresPermission = true

    -- Do people need permission to remove stuff? (def: true)
    removingRequiresPermission = true

    -- A whitelist to use if permission is required (Note: Whitelist takes priority over ZED permissions!)
    whiteList = {
        ["STEAM_0:0:14045128"] = true,  -- Ash47
        ["STEAM_0:0:29540342"] = true,  -- Dude who helps me test
        ["STEAM_0:0:Z4045122"] = true,  -- Another Example
    }
end

--[[
    CLIENT SETTINGS
]]

if Client then
    -- How often to update the physguned object (in seconds) (def: 0.1)
    nUpdateTime = 0.1

    -- A multiplier for the rotation speed, smaller means slower rotation (def: 1/50)
    nRotationFactor = 1/25

    -- Do you want to start users in physgun mode? (def: false)
    physEnabled = false

    -- The command to toggle the physgun on / off (Make it all lowercase!) (def: "/phys")
    commandPhysgunToggle = "/phys"

    -- The command to change the physgun rotational speed (Make it all lowercase!) (def: "/rotspeed")
    commandPhysgunRotSpeed = "/rotspeed"

    -- Do you want to add a help item? (def: true)
    addHelpItem = true

    -- Name of the help item (def: "Physgun")
    helpItemName = "Physgun"

    -- The help text to display
    helpItemText =  " - The Physgun is a tool to grab vehicles, players and static objects, as well as spawn and remove objects\n"..
                    "\n"..
                    " - To use the physgun, you need to enter physgun mode, type "..commandPhysgunToggle.."\n"..
                    "\n"..
                    "NOTE: You may not have permission to use all the features in this plugin\n"..
                    "\n"..
                    "Physgun Mode:\n"..
                    " - Aim at a vehicle, player or static object and click to grab it\n"..
                    " - Hold E to rotate the object with the mouse\n"..
                    " - Hold Shift while rotating to snap to the nearest 45 degrees\n"..
                    " - Use the scrollwheel to change the distance of the object\n"..
                    " - Hold Q to open the spawn menu\n"..
                    " - Expand the folders to find static objects, you can click on them to spawn them\n"..
                    " - Static objects will spawn where you are looking\n"..
                    " - You can press Z to undo props in the order you spawned them\n"..
                    " - You can change tools by scrolling the mouse\n"..
                    " - Your current tool is indicated below the map\n"..
                    "\n"..
                    "Tools:\n"..
                    " - Remover - This allows you to remove static objects and vehicles\n"..
                    " - Stacker - Right click two objects to calculate an offset, then click another to stack it\n"..
                    " - Duplicator - Right click an object to copy, left click to paste\n"..
                    "\n"..
                    "Commands:\n"..
                    commandPhysgunToggle.." - Enable Physgun Mode\n"..
                    commandPhysgunRotSpeed.." - Set the rotational speed of the physgun\n"..
                    "\n"..
                    "Credits:\n"..
                    " - Written by Ash47\n"
end