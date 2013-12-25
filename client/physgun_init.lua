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

-- Hook key pressed
Events:Subscribe("KeyDown", function(args)
    if hGrabbed then
        -- Rotation
        if args.key == string.byte("E") then
            -- Start rotating
            bRotating = true

            -- Store the angle of the camera
            aCamAng = Camera:GetAngle()
            vCamPos = Camera:GetPosition()
        end
    else
        -- Trying to grab something
        if args.key == string.byte("G") then
            local oTrace = LocalPlayer:GetAimTarget()

            -- Attempt to grab a car
            local veh = oTrace.vehicle
            if veh then
                -- Store this as our grabbed entity
                hGrabbed = veh
                bRotating = false

                -- Tell the server
                Network:Send("47phys_Pickup", {
                    veh = veh,
                    pos = veh:GetPosition(),
                    ang = veh:GetAngle(),
                    plyAngle = Camera:GetAngle()
                })

                return
            end

            -- Attempt to grab a player
            local player = oTrace.player
            if player then
                -- Store this as our grabbed entity
                hGrabbed = player
                bRotating = false

                -- Tell the server
                Network:Send("47phys_Pickup", {
                    otherPly = player,
                    pos = player:GetPosition(),
                    ang = player:GetAngle(),
                    plyAngle = Camera:GetAngle()
                })

                return
            end
        end
    end
end)

Events:Subscribe("KeyUp", function(args)
    -- If we have something grabbed
    if hGrabbed then
        -- Stop grabbing something
        if args.key == string.byte("G") then
            hGrabbed = nil
            bRotating = false
            Network:Send("47phys_Drop")
        end

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
end)

-- Add /rotspeed command
Events:Subscribe("LocalPlayerChat", function(args)
    local cmd = args.text:split(" ")
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
end)
