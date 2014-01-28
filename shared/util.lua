function isPlayer(ent)
    return class_info(ent).name == "Player"
end

function isVehicle(ent)
    return class_info(ent).name == "Vehicle"
end

function isStaticObject(ent)
    return class_info(ent).name == "StaticObject"
end

-- Checks if two entities are the same
function areSameEnt(ent1, ent2)
    if class_info(ent1).name == class_info(ent2).name then
        if ent1 == ent2 then
            return true
        end
    end

    return false
end
