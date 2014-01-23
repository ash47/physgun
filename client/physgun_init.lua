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
    --[[-- Spawn Stuff
    if args.key == string.byte("P") then
        -- Tell the server
        Network:Send("47phys_Spawn", {})
    end]]

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
end)

Events:Subscribe("KeyUp", function(args)
    -- If we have something grabbed
    if hGrabbed then
        -- Stop rotating
        if args.key == string.byte("E") then
            bRotating = false
        end
    end
end)

-- Hook mouse scroll
Events:Subscribe("MouseScroll", function(args)
    if hGrabbed then
        Network:Send("47phys_Zoom", args.delta)
    end
end)

-- Send rotational info to server
Events:Subscribe("PostTick", function()
    -- Check if we have an object grabbed
    if hGrabbed then
        -- Check if it's time to send an update
        if Client:GetElapsedSeconds() > nNextThink then
            -- Check if we've stopped firing
            local nLastFire = Client:GetElapsedSeconds()-nLastFire
            if nLastFire > 0.25 then
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
        end
        return false
    end
end)
