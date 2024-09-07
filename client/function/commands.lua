local QBCore = exports['qb-core']:GetCoreObject()

-- Define the HasAccess() function (TO DO: implement access checking logic)
local function HasAccess()
    -- TO DO: implement access checking logic
    return true
end

-- Consistent access checking and error handling
local function checkAccess()
    if not HasAccess() then
        print("You don't have access to this command.")
        return false
    end
    return true
end

-- Helper function to get vehicle entity
    local cache = {}
    local function getVehicleEntity()
        local vehicle = GetVehiclePedIsUsing(cache.ped)
        local ent = QBCore.Functions.GetVehicle(vehicle)
        if not ent then
            print("Failed to get vehicle entity.")
            return nil
        end
        return ent
    end

-- Define a function to handle access checking and command execution
local function handleCommand(func)
    return function()
        if checkAccess() then
            func()
        end
    end
end

-- Define vehicle-related functions
local function Repair()
    -- TO DO: implement repair logic
    print("Vehicle repaired.")
end

-- Register commands
exports.qbcore.Commands:RegisterCommand('repair', 'Repair Command', {}, function(source)
    handleCommand(Repair)
end)

exports.qbcore.Commands:RegisterCommand('upgrades', 'Upgrade Command', {}, function(source)
    -- TO DO: implement upgrade logic
    print("Vehicle upgraded.")
end)

exports.qbcore.Commands:RegisterCommand('checkvehicle', 'Check Vehicle Command', {}, function(source, args)
    CheckVehicle(true)
end)

if config.debug then
    -- /setmileage command
    exports.qbcore.Commands:RegisterCommand("setmileage", "Set Mileage Command", {{
        name = "mileage",
        help = "Mileage value",
        type = "number"
    }}, function(source, args)
        -- Check access and exit early if not allowed
        if not checkAccess() then
            print("Access denied.")
            return
        end
        local mileage = tonumber(args[1])
        if mileage then
            local ent = getVehicleEntity()
            if ent then
                -- Set mileage and print success message
                QBCore.Functions.SetVehicleProperty('mileage', mileage, true)
                print("Mileage set to " .. mileage)
            else
                print("You are not in a vehicle.")
            end
        else
            print("Invalid mileage value.")
        end
    end)
end

    -- /setfuel command
    exports.qbcore.Commands:RegisterCommand('setfuel', 'Set Fuel Command', {{'fuel', 0, 'Fuel value'}}, function(source, args)
        -- Check access and arguments
        if not checkAccess() then
            print("Access denied.")
            return
        end

        -- Validate and set fuel
        local fuel = tonumber(args[1])
        if not fuel or fuel < 0 then
            print("Invalid fuel value. Please enter a non-negative number.")
            return
        end

        -- Get the vehicle entity
        local ent = getVehicleEntity()
        if not ent then
            print("No vehicle entity found.")
            return
        end

        QBCore.Functions.SetVehicleProperty('fuel', fuel, true)
        print(string.format("Fuel set to %.2f", fuel))
    end)

    -- /sethandling command
    exports.qbcore.Commands:RegisterCommand('sethandling', 'Set Handling Command', {{'handling', 0, 'Handling value'}}, function(source, args)
        -- Check access and return if not authorized
        if not checkAccess() then return end

        -- Check if handling value is provided
        if not args[1] then
            print("Usage: /sethandling <handling>")
            return
        end


        -- Get the vehicle entity
        local ent = getVehicleEntity()
        if not ent then return end

        -- Validate and set handling
        local handling = tonumber(args[1])
        if not handling then
            print("Invalid handling value.")
            return
        end

        -- Set the handling for each engine part
        for _, part in ipairs(config.engineparts) do
            print("part.item:", part.item)  -- Add this line to verify the value of part.item
            QBCore.Functions.SetVehicleProperty(part.item, handling, true)
            print(string.format("New value for %s set to %d", part.item, handling))
        end
    end)

    -- Define a function to check access and get the current vehicle
        local function getVehicle()
            if not checkAccess() then return end
            return GetVehiclePedIsUsing(cache.ped)
        end

    -- Register commands with improved handling
    exports.qbcore.Commands:RegisterCommand('manualgear', 'Manual Gear Command', {}, function(source)
        local vehicle = getVehicle()
        local gear = 1 -- define the gear value here (e.g. 1, 2, 3, etc.)
        if vehicle then
            -- you'll need to find an alternative way to set the transmission gear here
            print("Manual gear command triggered, but no gear setting function available.")
        end
    end)
    
    exports.qbcore.Commands:RegisterCommand('autogear', 'Auto Gear Command', {{'eco', 0, 'Eco mode'}}, function(source, args)
        local vehicle = getVehicle()
        if vehicle then
            local eco = args[1] and true or false
            local autoGearMode = eco -- set the auto gear mode state
            -- you'll need to implement the logic to control the vehicle's behavior based on the autoGearMode variable
            print("Auto gear mode set to " .. (autoGearMode and "on" or "off"))
        end
    end)
    
    exports.qbcore.Commands:RegisterCommand('tuning', 'Tuning Command', {}, function(source)
        if getVehicle() then TuningMenu() end
    end)