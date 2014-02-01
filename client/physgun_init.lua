-- variables that need global plugin scope
local hGrabbed
local bRotating = false
local aCamAng
local vCamPos
local nNextThink = 0
local vRot = Vector2(0, 0)
local nLastFire = 0
local nLastFire2 = 0

-- Container for the spawn menu
local spawnMenu
local toolMenu
local inMenu = false

-- Tool related stuff
local currentTool = 1

-- We need to build the toollist once all the function are defined
local toolList
function buildToolList()
    toolList = {
        -- Physgun
        [1] = {
            name = 'Physgun',
            use = pickupEntity
        },

        -- Remover
        [2] = {
            name = 'Remover',
            pressed = removeEntity
        },

        -- Stacker
        [3] = {
            name = 'Stacker',
            pressed = stackerTool,
            pressed2 = stackerToolReference,
        },

        -- Duplicator
        [4] = {
            name = 'Duplicator',
            pressed = duplicatorTool,
            pressed2 = duplicatorToolReference
        }
    }
end

function pickupEntity()
    -- Make sure we haven't already grabbed something
    if not hGrabbed then
        local oTrace = LocalPlayer:GetAimTarget()

        -- Attempt to grab an entity
        local ent = oTrace.entity
        if ent then
            -- Store this as our grabbed entity
            hGrabbed = ent
            bRotating = false

            -- Tell the server
            Network:Send("47phys_Pickup", {
                ent = ent,
                pos = ent:GetPosition(),
                ang = ent:GetAngle(),
                plyAngle = Camera:GetAngle(),
                hitPos = oTrace.position
            })

            return
        end
    end
end

function removeEntity()
    local oTrace = LocalPlayer:GetAimTarget()

    -- Attempt to remove an ent
    local ent = oTrace.entity
    if ent then
        -- Tell the server
        Network:Send("47phys_Remove", {
            ent = ent
        })

        return
    end
end

function dropEntity()
    hGrabbed = nil
    bRotating = false
    Network:Send("47phys_Drop")
end

-- The stacker tool
local stackerRef = {
    offset = Vector3(0, 0, 0)
}
local stackerOffsetObject
function stackerTool()
    local oTrace = LocalPlayer:GetAimTarget()

    local ent = oTrace.entity
    if ent and isStaticObject(ent) then
        -- Tell the server
        Network:Send("47phys_Spawn", {
            model = ent:GetModel(),
            collision = ent:GetCollision(),
            pos = ent:GetPosition()+stackerRef.offset,
            ang = ent:GetAngle()
        })
    else
        -- Tell the client they can't stack this entity
        Chat:Print("Can't stack this entity!", Color(255, 0, 0, 255))
    end
end
function stackerToolReference()
    local oTrace = LocalPlayer:GetAimTarget()

    -- Attempt to grab an entity
    local ent = oTrace.entity
    if ent then
        if stackerOffsetObject then
            -- Store the offsets
            stackerRef.offset = ent:GetPosition() - stackerOffsetObject:GetPosition()

            -- Tell the user it worked
            Chat:Print("Offset calculated!", Color(255, 0, 0, 255))

            -- Reset stackerOffsetObject
            stackerOffsetObject = nil
        else
            -- Store the ent
            stackerOffsetObject = ent

            -- Tell the user what to do
            Chat:Print("Right click another target to set offsets", Color(255, 0, 0, 255))
        end
    end
end

local dupRef
function duplicatorTool()
    -- Check if we have something selected
    if dupRef then
        -- Tell the server
        Network:Send("47phys_Spawn", {
            model = dupRef.model,
            collision = dupRef.collision,
            ang = dupRef.angle
        })
    else
        -- Give error
        Chat:Print("Right click something first", Color(255, 0, 0, 255))
    end
end

function duplicatorToolReference()
    local oTrace = LocalPlayer:GetAimTarget()

    -- Attempt to grab an entity
    local ent = oTrace.entity
    if ent then
        if isStaticObject(ent) then
            dupRef = {
                model = ent:GetModel(),
                collision = ent:GetCollision(),
                angle = ent:GetAngle()
            }
        else
            -- Give error
            Chat:Print("Can only duplicator static objects", Color(255, 0, 0, 255))
        end
    end
end

function useTool(pressed, secondary)
    -- Grab the tool
    local tool = toolList[currentTool]

    if secondary then
        -- Check if it has a press function
        if pressed and tool.pressed2 then
            -- Run the press function
            tool.pressed2()
        end

        -- Check if it has a use function
        if tool.use2 then
            -- Run the use function
            tool.use2()
        end
    else
        -- Check if it has a press function
        if pressed and tool.pressed then
            -- Run the press function
            tool.pressed()
        end

        -- Check if it has a use function
        if tool.use then
            -- Run the use function
            tool.use()
        end
    end
end

-- Hook key pressed
Events:Subscribe("KeyDown", function(args)
    if physEnabled then
        if hGrabbed then
            -- Rotation
            if args.key == string.byte("E") then
                -- Start rotating
                bRotating = true

                -- Store the angle of the camera
                aCamAng = Camera:GetAngle()
                vCamPos = Camera:GetPosition()
            end
        end

        -- Spawn menu
        if args.key == string.byte("Q") then
            -- Enable mouse cursor
            Mouse:SetVisible(true)

            -- We are now in a menu
            inMenu = true

            -- Check if we have a spawn menu
            if spawnMenu then
                -- Don't bother remaking it
                spawnMenu:SetVisible(true)
                toolMenu:SetVisible(true)
                return
            end

            -- Create the spawn menu
            spawnMenu = Window.Create()
            spawnMenu:SetSizeRel(Vector2(0.3, 0.9))
            spawnMenu:SetPosition(Vector2(0, Render.Height*0.05))
            spawnMenu:SetVisible(true)
            spawnMenu:SetTitle('Model Viewer')

            local treeview = Tree.Create(spawnMenu)
            treeview:SetDock(GwenPosition.Fill)

            local rootNodes = {}

            -- Add models
            for k, v in ipairs(models) do
                local parts = split(v.name, "\\")
                local root = rootNodes[parts[1]] or treeview:AddNode(parts[1])
                rootNodes[parts[1]] = root

                local sub = rootNodes[parts[1].."\\"..parts[2]] or root:AddNode(parts[2])
                rootNodes[parts[1].."\\"..parts[2]] = sub

                local node = sub:AddNode(v.name)

                for k2, v2 in ipairs(v.files) do
                    child_node = node:AddNode(v2.model)
                    child_node:Subscribe("Select", self, spawnObjectFromMenu)
                end
            end

            -- Create tool menu
            toolMenu = Window.Create()
            toolMenu:SetSizeRel(Vector2(0.1, 0.9))
            toolMenu:SetPosition(Vector2(Render.Width - toolMenu:GetWidth(), Render.Height*0.05))
            toolMenu:SetVisible(true)
            toolMenu:SetTitle('Tool Menu - '..toolList[currentTool].name)

            treeview = Tree.Create(toolMenu)
            treeview:SetDock(GwenPosition.Fill)

            -- Add tools
            for k,v in ipairs(toolList) do
                local node = treeview:AddNode(v.name)
                node:Subscribe("Select", self, changeToolFromMenu)
            end
        end

        -- Undo
        if args.key == string.byte("Z") then
            Network:Send("47phys_Undo")
        end
    end
end)

Events:Subscribe("KeyUp", function(args)
    if physEnabled then
        -- If we have something grabbed
        if hGrabbed then
            -- Stop rotating
            if args.key == string.byte("E") then
                bRotating = false
            end
        end

        -- Spawn Menu
        if args.key == string.byte("Q") then
            -- Check if we have a spawn menu
            if spawnMenu then
                -- Hide the spawn menu
                spawnMenu:SetVisible(false)

                -- Hide the tool menu
                toolMenu:SetVisible(false)

                -- Hide the cursor
                Mouse:SetVisible(false)

                -- We are no longer in a menu
                inMenu = false
            end
        end
    end
end)

-- Hook mouse scroll
Events:Subscribe("MouseScroll", function(args)
    if physEnabled then
        -- Check if we have something grabbed
        if hGrabbed then
            Network:Send("47phys_Zoom", args.delta)
        end
    end
end)

-- Send rotational info to server
Events:Subscribe("PostTick", function()
    -- Check if we have an object grabbed
    if physEnabled and hGrabbed then
        -- Check if it's time to send an update
        if Client:GetElapsedSeconds() > nNextThink then
            -- Check if we've stopped firing
            local nLastFire = Client:GetElapsedSeconds()-nLastFire
            if nLastFire > 0.05 then
                -- Drop the item
                dropEntity()
                return
            end

            -- Delay the next update
            nNextThink = Client:GetElapsedSeconds() + nUpdateTime

            -- Start to build data
            local data = {
                a = Camera:GetAngle()
            }

            -- Check if there was any rotation
            if bRotating then
                data.r = true

                if vRot.x ~= 0 then
                    data.x = vRot.x * nRotationFactor
                end
                if vRot.y ~= 0 then
                    data.y = vRot.y * nRotationFactor
                end

                -- Left shift (constant is a little broken atm)
                if Key:IsDown(160) then
                    data.s = true
                end
            end

            -- Send the update
            Network:Send("47phys_Update", data)

            -- Reset rotations
            vRot = Vector2(0, 0)
        end
    end
end)

-- Stop getting into the car, and hook camera rotations
Events:Subscribe("LocalPlayerInput", function(args)
    -- Check if the physgun is enabled
    if physEnabled then
        -- Stop primary fire
        if args.input == Action.FireRight then
            -- Only use a tool if we're not in a menu
            if not inMenu then
                -- Stop the tool from firing over and over
                if Client:GetElapsedSeconds()-nLastFire > 0.1 then
                    -- Use a tool
                    useTool(true)
                else
                    -- The tool is being held
                    useTool(false)
                end

                -- Store the last time we fired the event
                nLastFire = Client:GetElapsedSeconds()
            end

            -- Don't shoot
            return false
        end

        -- Stop 2ndary fire
        if args.input == Action.FireLeft then
            -- Only use a tool if we're not in a menu
            if not inMenu then
                -- Stop the tool from firing over and over
                if Client:GetElapsedSeconds()-nLastFire2 > 0.1 then
                    -- Use a tool
                    useTool(true, true)
                else
                    -- The tool is being held
                    useTool(false, true)
                end

                -- Store the last time we fired the event
                nLastFire2 = Client:GetElapsedSeconds()
            end

            -- Don't shoot
            return false
        end

        -- Stop Q attack
        if args.input == Action.Kick then
            return false
        end

        -- Stop rotation if we are in a menu
        if inMenu then
            if args.input == Action.LookRight or args.input == Action.LookLeft or args.input == Action.LookUp or args.input == Action.LookDown then
                return false
            end
        end

        -- Prevent weapon switching while in physgun mode
        if (args.input == Action.SwitchWeapon) or (args.input == Action.NextWeapon) or (args.input == Action.PrevWeapon) then
            return false
        end

        -- Only do this if we have something grabbed
        if not hGrabbed then return end

        if args.input == Action.UseItem then
            return false
        end

        -- Rotation
        if not bRotating then return end

        if args.input == Action.LookRight then
            vRot.x = vRot.x + 1
            return false
        end

        if args.input == Action.LookLeft then
            vRot.x = vRot.x - 1
            return false
        end

        if args.input == Action.LookUp then
            vRot.y = vRot.y - 1
            return false
        end

        if args.input == Action.LookDown then
            vRot.y = vRot.y + 1
            return false
        end
    end
end)

-- Add /rotspeed command
Events:Subscribe("LocalPlayerChat", function(args)
    local cmd = args.text:split(" ")

    -- Rotational speed command
    if cmd[1]:lower() == commandPhysgunRotSpeed then
        if #cmd ~= 2 then
            Chat:Print("/rotspeed [speed]", Color(255, 0, 0, 255))
            Chat:Print("Note: The higher the number, the slower it rotates", Color(255, 0, 0, 255))
            return false
        end

        -- Update rotation speed
        nRotationFactor = 1 / tonumber(cmd[2])
        return false
    end

    -- Toggle Physgun command
    if cmd[1]:lower() == commandPhysgunToggle then
        -- Toggle the physgun state
        physEnabled = not physEnabled

        if physEnabled then
            Chat:Print("Physgun Enabled", Color(255, 0, 0, 255))
        else
            Chat:Print("Physgun Disabled", Color(255, 0, 0, 255))

            -- Check if we had an entity grabbed
            if hGrabbed then
                -- Drop said entity
                dropEntity()
            end
        end
        return false
    end
end)

function basename(path, dirsep)
    local i = string.len(path)

    while string.sub(path, i, i) == dirsep and i > 0 do
        path = string.sub(path, 1, i - 1)
        i = i - 1
    end
    while i > 0 do
        if string.sub(path, i, i) == dirsep then
            break
        end
        i = i - 1
    end
    if i > 0 then
        path = string.sub(path, i + 1, -1)
    end
    if path == "" then
        path = dirsep
    end

    return path
end

function spawnObjectFromMenu(e)
    local lod = e:GetText()
    local archive = e:GetParent():GetText()
    local physics = ""

    -- Dirty++
    for k, v in ipairs(models) do
        if v.name == archive then
            for k2, v2 in pairs(v.files) do
                if v2.model == lod then
                    physics = v2.physics
                    break
                end
            end
        end
    end

    -- Workout actual archive
    local arch = basename(archive, '\\')

    -- Tell the server
    Network:Send("47phys_Spawn", {
        model = arch.."/"..lod,
        collision = arch.."/"..physics
    })
end

function changeToolFromMenu(e)
    -- Grab the tool they selected
    local newTool = e:GetText()

    -- Find the tool
    for k,v in pairs(toolList) do
        if v.name == newTool then
            -- Change to this tool
            currentTool = k
            break
        end
    end

    -- Change the title of the menu
    toolMenu:SetTitle('Tool Menu - '..toolList[currentTool].name)
end

Events:Subscribe("Render", function()
    if physEnabled then
        local txt = toolList[currentTool].name
        local col = Color(255, 255, 255, 255)
        local txtSize = TextSize.Large

        local pos = Vector2(190/2560*Render.Width - Render:GetTextWidth(txt, txtSize)/2, 345/1440 * Render.Height)

        Render:DrawText(pos, txt, col, txtSize)
    end
end)

-- Add help item on load
Events:Subscribe( "ModuleLoad", function()
    if addHelpItem then
        Events:Fire("HelpAddItem",{
            name = helpItemName,
            text = helpItemText
        })
    end
end)

-- Remove help item on unload
Events:Subscribe( "ModuleUnload", function()
    if addHelpItem then
        Events:Fire( "HelpRemoveItem",{
            name = helpItemName
        })
    end
end)

function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

-- Build the toollist
buildToolList()
