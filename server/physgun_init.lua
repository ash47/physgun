-- Allow client's to send where they think the vehicles are? (def: true)
local trustClients = true
local useZED = false -- Permissions: pickup_vehicles to pickup vehicles and pickup_players to pickup players.

-- This function determins if a player can use this plugin or not
local whiteList = {
    ["STEAM_0:0:14045128"] = true,  -- Ash47
    ["STEAM_0:0:X4045121"] = true,  -- No one
    ["STEAM_0:0:Z4045122"] = true,  -- Another Example
}

function AllowedToPickupVehicle(ply, veh)
    if useZED then
        -- Check if this player has the permissions
        return not Events:Fire("ZEDPlayerHasPermission", {player=ply, permission="pickup_vehicles"}) -- returns false if the player has the permission, true if not
    else
       -- Check if this player is on our whitelist
        return whiteList[ply:GetSteamId().string] -- returns true if the player is in the whitelist, nil if not
    end
end
function AllowedToPickupPlayer(ply, otherPly)
    if useZED then
        -- Check if this player has the permissions
        return not Events:Fire("ZEDPlayerHasPermission", {player=ply, permission="pickup_players"}) -- returns false if the player has the permission, true if not
    else
       -- Check if this player is on our whitelist
        return whiteList[ply:GetSteamId().string] -- returns true if the player is in the whitelist, nil if not
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
    -- Grab the vehicle they parsed
    local veh = args.veh
    if veh and AllowedToPickupVehicle(ply, veh) then
        -- Check if someone else is already grabbing this car
        if canPickup(ply, veh) then
            -- If we don't trust the clients, use server values
            if not trustClients then
                args.pos = veh:GetPosition()
                args.ang = veh:GetAngle()
            end

            local dist = ply:GetPosition():Distance(args.pos)
            local offset = args.pos - (ply:GetPosition() + (args.plyAngle * Vector3(0,0,-dist)))

            -- Store what is picked up
            addPickup({
                ply = ply,
                veh = veh,
                offset = offset,
                dist = dist
            })

            -- Update the vehicle
            veh:SetAngle(args.ang)
            veh:SetPosition(args.pos)
        end
    end

    local otherPly = args.otherPly
    if otherPly and AllowedToPickupPlayer(ply, otherPly) then
        -- Check if someone else is already grabbing this car
        if canPickup(ply, otherPly) then
            -- If we don't trust the clients, use server values
            if not trustClients then
                args.pos = otherPly:GetPosition()
                args.ang = otherPly:GetAngle()
            end

            local dist = ply:GetPosition():Distance(args.pos)
            local offset = args.pos - (ply:GetPosition() + (args.plyAngle * Vector3(0,0,-dist)))

            -- Store what is picked up
            addPickup({
                ply = ply,
                otherPly = otherPly,
                offset = offset,
                dist = dist
            })

            -- Update the vehicle
            otherPly:SetAngle(args.ang)
            otherPly:SetPosition(args.pos)
        end
    end
end)

-- Player is sending updated rotational data
Network:Subscribe("47phys_Update", function(args, ply)
    local pickup = getPickup(ply)

    -- Check if hte player has something picked up
    if pickup then
        -- Grab vars
        local veh = pickup.veh
        local toMove = veh or pickup.otherPly

        -- Check if what we want to move is still valid
        if toMove then
            -- Grab offsets
            local offset = pickup.offset
            local dist = pickup.dist

            -- Move Pickup
            toMove:SetPosition((ply:GetPosition() + (args.a * Vector3(0,0,-dist))) + offset)

            -- Workout rotations
            local rx = -toMove:GetAngle() * Vector3(0, 1, 0)
            local ry = -toMove:GetAngle() * Vector3(-math.cos(args.a.yaw), 0, math.sin(args.a.yaw))

            local rotx = Angle.AngleAxis((args.x or 0), rx)
            local roty = Angle.AngleAxis((args.y or 0), ry)

            -- Apply rotation
            toMove:SetAngle(toMove:GetAngle() * rotx * roty)
        end

        -- Check if we picked up a vehicle
        if veh then
            -- Stop it from falling
            veh:SetLinearVelocity(Vector3(0, 0, 0))
            veh:SetAngularVelocity(Vector3(0, 0, 0))
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
