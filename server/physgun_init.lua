-- Allow client's to send where they think the vehicles are? (def: true)
local trustClients = true

-- Do people need permission to pickup vehicles?
local pickupVehiclesRequiresPermission = false

-- Do people need permission to pickup static objects?
local pickupStaticRequiresPermission = false

-- Do people need permission to pickup players?
local pickupPlayersRequiresPermission = true

-- A whitelist to use if permission is required
local whiteList = {
    ["STEAM_0:0:14045128"] = true,  -- Ash47
    ["STEAM_0:0:X4045121"] = true,  -- No one
    ["STEAM_0:0:Z4045122"] = true,  -- Another Example
}

-- This function determines if a player can pickup a vehicle
function AllowedToPickup(ply, ent)
    -- Pretty dodgy way to tell stuff apart
    if ent.GetSteamId then
        -- Must be a player

        -- Check if we are using a whitelist for players
        if pickupPlayersRequiresPermission then
            -- Check if this player is on our whitelist
            return whiteList[ply:GetSteamId().string] or not Events:Fire("ZEDPlayerHasPermission", {player=ply, permission="pickup_players"})
        else
            -- Nope, allow them to use it
            return true
        end
    elseif ent.GetDriver then
        -- Must be a vehicle

        -- Check if we are using a whitelist
        if pickupVehiclesRequiresPermission then
            -- Check if this player is on our whitelist
            return whiteList[ply:GetSteamId().string] or not Events:Fire("ZEDPlayerHasPermission", {player=ply, permission="pickup_vehicles"})
        else
            -- Nope, allow them to use this
            return true
        end
    else
        -- Must be a static object

        -- Check if we are using a whitelist
        if pickupStaticRequiresPermission then
            -- Check if this player is on our whitelist
            return whiteList[ply:GetSteamId().string] or not Events:Fire("ZEDPlayerHasPermission", {player=ply, permission="pickup_static_object"})
        else
            -- Nope, allow them to use this
            return true
        end
    end
end

-- Table of what is picked up
local oPickedUp = {}

function canPickup(ply, veh)
    for k, v in pairs(oPickedUp) do
        --[[-- Check if this car is already physgun
        if veh == v.veh then
            return false
        end

        -- Check if this player has been picked up
        if veh == v.otherPly then
            return false
        end]]

        -- Check if this player already picked up something
        if ply == v.ply then
            return false
        end
    end

    return true
end

-- Makes a player pickup an object
function addPickup(pickup)
    table.insert(oPickedUp, pickup)
end

-- Returns what a player has picked up
function getPickup(ply)
    for k, v in pairs(oPickedUp) do
        -- Check if this player already picked up something
        if ply == v.ply then
            return v
        end
    end
end

-- Makes a player drop a given pickup
function removePickup(ply)
    for k, v in pairs(oPickedUp) do
        -- Check if this player already picked up something
        if ply == v.ply then
            -- Remove this pickup
            table.remove(oPickedUp, k)
        end
    end
end

-- A player wants to pick something up
Network:Subscribe("47phys_Pickup", function(args, ply)
    -- Grab the entity they parsed
    local ent = args.ent

    if ent and AllowedToPickup(ply, ent) then
        -- Check if someone else is already grabbing this entity
        if canPickup(ply, ent) then
            -- If we don't trust the clients, use server values
            if not trustClients then
                args.pos = ent:GetPosition()
                args.ang = ent:GetAngle()
            end

            local dist = ply:GetPosition():Distance(args.pos)
            local offset = args.pos - (ply:GetPosition() + (args.plyAngle * Vector3(0,0,-dist)))

            -- Store what is picked up
            addPickup({
                ply = ply,
                ent = ent,
                offset = offset,
                dist = dist
            })

            -- Update the entity
            ent:SetAngle(args.ang)
            ent:SetPosition(args.pos)
        end
    end
end)

-- Player is sending updated rotational data
Network:Subscribe("47phys_Update", function(args, ply)
    local pickup = getPickup(ply)

    -- Check if hte player has something picked up
    if pickup then
        -- Grab vars
        local ent = pickup.ent

        -- Check if what we want to move is still valid
        if ent then
            -- Grab offsets
            local offset = pickup.offset
            local dist = pickup.dist

            -- Move Pickup
            ent:SetPosition((ply:GetPosition() + (args.a * Vector3(0,0,-dist))) + offset)

            -- Workout rotations
            local rx = -ent:GetAngle() * Vector3(0, 1, 0)
            local ry = -ent:GetAngle() * Vector3(-math.cos(args.a.yaw), 0, math.sin(args.a.yaw))

            local rotx = Angle.AngleAxis((args.x or 0), rx)
            local roty = Angle.AngleAxis((args.y or 0), ry)

            -- Apply rotation
            ent:SetAngle(ent:GetAngle() * rotx * roty)
        end

        -- Check if we picked up a vehicle
        if ent.GetDriver then
            -- Stop it from falling
            ent:SetLinearVelocity(Vector3(0, 0, 0))
            ent:SetAngularVelocity(Vector3(0, 0, 0))
        end
    end
end)

-- Player has dropped their pickup
Network:Subscribe("47phys_Drop", function(args, ply)
    -- Remove any pickups from this player
    removePickup(ply)
end)

-- Player is scrolling
Network:Subscribe("47phys_Zoom", function(delta, ply)
    -- Check if this player has a pickup
    local pickup = getPickup(ply)
    if pickup then
        pickup.dist = pickup.dist + tonumber(delta) * 2
    end
end)

-- Player wants to spawn something
--[[Network:Subscribe("47phys_Spawn", function(args, ply)
    -- Grab where the player is looking
    local oTrace = ply:GetAimTarget()
    local pos = oTrace.position

    -- Spawn the object
    --local path = "areaset01.bl/gb084-a.lod"
    --StaticObject.Create(pos, , path)

    StaticObject.Create({
        position = pos,
        angle = Angle(0, 0, 0),
        model = "17x48.fl/go666-b.lod",
        collision = "17x48.fl/go666_lod1-b_col.pfx",
        world = ply:GetWorld()
    })

    print("spawned!")
end)]]