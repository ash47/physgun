print(models)

-- How often to update the physguned object (in seconds)
local nUpdateTime = 0.1

-- A multiplier for the rotation speed, smaller means slower rotation
local nRotationFactor = 1/50

-- variables that need global plugin scope
local hGrabbed
local bRotating = false
local aCamAng
local vCamPos
local nNextThink = 0
local vRot = Vector2(0, 0)
local nLastFire = 0

-- Physgun is disabled by default
local physEnabled = false

-- Container for the spawn menu
local spawnMenu
local inMenu = false

local function pickupEntity()
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
                plyAngle = Camera:GetAngle()
            })

            return
        end
    end
end

local function dropEntity()
    hGrabbed = nil
    bRotating = false
    Network:Send("47phys_Drop")
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
                return
            end

            -- Create the menu
            spawnMenu = Window.Create()
            spawnMenu:SetSizeRel(Vector2(0.3, 1))
            spawnMenu:SetPosition(Vector2(Render.Width - spawnMenu:GetWidth(), 0))
            spawnMenu:SetVisible(true)
            spawnMenu:SetTitle('Model Viewer')

            local treeview = Tree.Create(spawnMenu)
            treeview:SetDock(GwenPosition.Fill)

            for k, v in ipairs(models) do
                node = treeview:AddNode(v.name)

                for k2, v2 in ipairs(v.files) do
                    child_node = node:AddNode(v2.model)
                    child_node:Subscribe("Select", self, spawnObjectFromMenu)
                end
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
                -- Remove the spawn menu
                spawnMenu:SetVisible(false)

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
    if physEnabled and hGrabbed then
        Network:Send("47phys_Zoom", args.delta)
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
            if vRot.x ~= 0 then
                data.x = vRot.x * nRotationFactor
            end
            if vRot.y ~= 0 then
                data.y = vRot.y * nRotationFactor
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
            -- Store the last time we fired the event
            nLastFire = Client:GetElapsedSeconds()

            -- Attempt to pickup an entity
            pickupEntity()
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

        -- Only do this if we have something grabbed
        if not hGrabbed then return end

    	-- Prevent weapon switching while holding something
    	if (args.input == Action.SwitchWeapon) or (args.input == Action.NextWeapon) or (args.input == Action.PrevWeapon) then
    		return false
    	end

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
    if cmd[1] == "/rotspeed" then
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
    if cmd[1] == "/phys" then
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

    -- Tell the server
    Network:Send("47phys_Spawn", {
        archive = basename(archive, '\\'),
        lod = lod,
        physics = physics
    })
end