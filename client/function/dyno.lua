local QBCore = exports['qb-core']:GetCoreObject()

-- Define constants and variables
local eco = false -- Example value, replace with actual value
local plate = ... -- Assuming plate is passed as an argument

-- Check if GetEcu is defined before calling it
local ecu = GetEcu and GetEcu(plate) or nil
if ecu then
    print("GetEcu returned:", ecu)
else
    print("Error: GetEcu returned nil or is not defined")
end

local tune = ecu and type(ecu) == 'table' and ecu.tuning or {}

-- Group related functions together
local vehicleFunctions = {
    GetClosestVehicle = GetClosestVehicle,
    GetPedInVehicleSeat = GetPedInVehicleSeat,
    GetVehiclePedIsIn = GetVehiclePedIsIn,
    GetVehicleCurrentRpm = GetVehicleCurrentRpm,
    SetVehicleCurrentRpm = SetVehicleCurrentRpm,
    GetEntitySpeed = GetEntitySpeed,
    GetControlNormal = GetControlNormal,
}

local vehicleHandlingFunctions = {
    SetVehicleHandlingFloat = SetVehicleHandlingFloat,
    SetVehicleHandlingInt = SetVehicleHandlingInt,
    SetVehicleHighGear = SetVehicleHighGear,
    SetVehicleOnGroundProperly = SetVehicleOnGroundProperly,
    SetEntityCollision = SetEntityCollision,
    SetEntityAsMissionEntity = SetEntityAsMissionEntity,
}

local vehiclePerformanceFunctions = {
    SetVehicleCheatPowerIncrease = SetVehicleCheatPowerIncrease,
    ModifyVehicleTopSpeed = ModifyVehicleTopSpeed,
    SetVehicleHandbrake = SetVehicleHandbrake,
    SetEntityMaxSpeed = SetEntityMaxSpeed,
    SetVehicleMaxSpeed = SetVehicleMaxSpeed,
    SetVehicleGravity = SetVehicleGravity,
    SetEntityHasGravity = SetEntityHasGravity,
}

local entityFunctions = {
    DetachEntity = DetachEntity,
    FreezeEntityPosition = FreezeEntityPosition,
    Wait = Wait,
    GetGameTimer = GetGameTimer,
    SetEntityControlable = SetEntityControlable,
}

-- Use the corrected variables and functions
local vehicle = vehicleFunctions.GetClosestVehicle(vehicle, 2.0)
local driver = vehicleFunctions.GetVehiclePedIsIn(vehicle, -1)

-- Define the dynoprop variable
local dynoprop = {}

-- Call the CheckDyno function with the dynoprop variable
-- Corrected function name
local function GetEntityDynoState(vehicle)
    -- Implementation of GetEntityDynoState function
end

-- Corrected function name
	local function CheckDyno(dynoprop, index)
		local vehicle = vehicleFunctions.GetClosestVehicle(config.dyno.platform + config.dyno.offsets, 2.0)
		local taken = DoesEntityExist(vehicle)
		local state = taken and GetEntityDynoState(vehicle) -- corrected function name
		local driver = vehicleFunctions.GetPedInVehicleSeat(vehicleFunctions.GetVehiclePedIsIn(cache.ped), -1) == cache.ped
	
		if not taken and not driver then
			return true
		end
	
		lib.notify({
			title = 'Dynamometer is being used',
			type = 'error'
		})
		return false
	end
	
	local function SetVehicleGear(vehicle, gear, maxspeed, dyno)
		if dyno then
			return
		end
		ForceVehicleGear(vehicle, gear)
		vehicleHandlingFunctions.SetVehicleHighGear(vehicle, gear)
		vehiclePerformanceFunctions.SetEntityMaxSpeed(vehicle, maxspeed)
		vehiclePerformanceFunctions.SetVehicleMaxSpeed(vehicle, maxspeed)
		vehiclePerformanceFunctions.ModifyVehicleTopSpeed(vehicle, 0.999)
	end
	
	local function SetVehicleManualGears(vehicle, dyno)
		local maxGear = 5
		local gear = 1
		local switching = false
		local manual = true
		local inertia = 0.1
		local tuningInertia = 0.1
		local maxSpeed = 100.0
		local initialDriveMaxFlatVel = 100.0
		local initialDriveForce = 100.0
		local driveInertia = 0.1
		local initialDriveGears = 1
		local vehicleFlags = vehicleHandlingFunctions.GetVehicleHandlingInt(vehicle, 'CCarHandlingData', 'strAdvancedFlags')
		local handBrakeForce = vehicleHandlingFunctions.GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fHandBrakeForce')
		local boostPerGear = {1.0, 1.1, 1.2, 1.3, 1.4}
		local vehicleGearRatio = {
			[1] = {1.0, 2.0, 3.0, 4.0, 5.0},
			[2] = {1.5, 2.5, 3.5, 4.5, 5.5},
			[3] = {2.0, 3.0, 4.0, 5.0, 6.0},
			[4] = {2.5, 3.5, 4.5, 5.5, 6.5},
			[5] = {3.0, 4.0, 5.0, 6.0, 7.0},
		}
		
		local eco = true
		local auto = true
		local gearMaxSpeed = ((maxSpeed * 1.32) / 3.6) / vehicleGearRatio[maxGear][gear]
		local ent = Entity(vehicle)
		local speed = 0.0
		local rpm = 0.0
		local wheelSpeed = 0.0
		local nextGearSpeed = 0.0
		local lastInertia = 0.0
		local turboPower = 1.0
	
		local function getGearInertia(gearRatio)
			return inertia / gearRatio
		end
	
		local function forceVehicleSingleGear(vehicle, speed, dyno)
			if dyno then
				SetVehicleForwardSpeed(vehicle, speed)
			else
				SetVehicleCurrentRpm(vehicle, speed / gearMaxSpeed)
			end
		end
	end
	-- Wait until the player is in the vehicle
    local inVehicle = false
    while not inVehicle do
        Citizen.Wait(0)
        inVehicle = IsPedInAnyVehicle(cache.ped, false)
    end
    
    if manual then
        return
    end
    
    local vehicle = vehicleFunctions.GetClosestVehicle(GetEntityCoords(cache.ped), 10.0)
    
    if manual and DoesEntityExist(vehicle) then
        -- Additional logic for manual mode can be added here
    end
    
    -- Get the state of the vehicle
    local ent = Entity(vehicle).state

-- Get ECU data
local ecu = GetEcu(plate)
local tune = nil
if ecu and type(ecu) == 'table' then
    tune = ecu.tuning or {}
else
    print("No nearby vehicle found or ECU is not available.")
end

-- Initialize vehicle parameters
local maxGear = ent and ent.vehicle and ent.vehicle.nInitialDriveGears or 1
local gearRatio = ecu[plate] and ecu[plate].active and ecu[plate].active.gear_ratio or config.gears
local gear = 1
local vehicleFlags = vehicleHandlingFunctions.GetVehicleHandlingInt(vehicle, 'CCarHandlingData', 'strAdvancedFlags')
local handBrakeForce = vehicleHandlingFunctions.GetVehicleHandlingInt(vehicle, 'CHandlingData', 'fHandBrakeForce')
local maxSpeed = vehicleHandlingFunctions.GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel')
local driveForce = vehicleHandlingFunctions.GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce')
local fDriveInertia = vehicleHandlingFunctions.GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fDriveInertia')
local defaultDriveInertia = fDriveInertia
local gearMaxSpeed = 0
local rpm = 0.1
local currentSpeed = 0
local clutch = false
local reverse = false
local speed = 0.0
local switch = true
local currentMaxGear = maxGear

	-- Set vehicle handling flags
SetVehicleHandlingInt(vehicle, "CCarHandlingData", "strAdvancedFlags", vehicleFlags + 0x20000 + 0x200 + 0x1000 + 0x10 + 0x40)
manual = true
local turbopower = 1.0

-- Function to calculate horsepower and torque
local calculateHorsepower = function(rpm)
    local power = ((((maxSpeed * 3.6) * driveForce * turbopower) * (rpm / 10000)) * (gear / maxGear))
    local torque = ((power * 5252) / rpm)
    local horsepower = power * (rpm / 10000)
    return horsepower, torque
end

local rawTurbopower = 1.0
local upgrade, stats = QBCore.Functions.GetVehicle(vehicle).state(vehicle)
local tune = GetTuningData(plate)
local boostPerGear = tune and tune.boostPerGear or {}
local engineStats, fuelAirVolume, maxAfr = EngineEfficiency(vehicle, stats, tune, rawTurbopower)
local afr = 14.0
local explode = false
local switching = false
local lastGear = 1
local flatSpeed = maxSpeed

-- Function to calculate gear inertia
local getGearInertia = function(ratio)
    local inertia = default_fDriveInertia / maxGear
    return inertia * turbopower - inertia * turbopower / ratio
end

-- Create a thread for dyno testing
Citizen.CreateThread(function()
    if dyno then
        -- Check if the vehicle variable is valid before using it
        if vehicle and IsEntityAVehicle(vehicle) then
            SetDisableVehicleEngineFires(vehicle, false)
        end
        -- Use a more robust way to send a message to the NUI
        SendNUIMessage({ dyno = true })
    end
end)

local timer = 0
while inVehicle and dyno do
    timer = timer + 1
    if timer >= 155 then
        local currentSpeed = dyno and math.floor(flatSpeed * turbopower * rpm) or math.floor(speed)
        local hp, torque = calculateHorsepower(rpm * 10000)
        timer = 0
    end
    Citizen.Wait(1)
end

        if GetIsVehicleEngineRunning(vehicle) then
            SendNUIMessage({
                stat = {
                    rpm = math.floor(rpm * 10000),
                    gear = gear,
                    speed = currentSpeed,
                    hp = math.floor(hp * efficiency),
                    torque = math.floor(torque * efficiency),
                    maxGear = maxGear,
                    gauges = {
                        oilTemp = GetVehicleDashboardOilTemp(vehicle),
                        waterTemp = round(GetVehicleEngineTemperature(vehicle)),
                        oilPressure = GetVehicleDashboardOilPressure(vehicle),
                        efficiency = efficiency * 100.0,
                        afr = afr,
                        map = round(turbopower) + 0.0 or 1.0
                    }
                }
            })
        end

local temp = GetVehicleEngineTemperature(vehicle)
local engineLocation = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, 'bonnet'))
local engineHealth = GetVehicleEngineHealth(vehicle)
local engineLife = engineHealth * (120 / temp)

-- Calculate Air-Fuel Ratio (AFR)
afr = (fuelAirVolume + 0.5) + ((maxAfr - fuelAirVolume) * rpm) - (0.5 * rpm)

-- Check engine life and handle potential explosion
if engineLife < 100.0 and not explode then
    explode = true
    local soundId = GetSoundId()
    PlaySoundFromEntity(soundId, 'Trevor_4_747_Carsplosion', vehicle, 0, 0, 0)

    -- Create explosions at the engine location
    AddExplosion(engineLocation.x, engineLocation.y, engineLocation.z, 19, 0.1, true, false, true)
    AddExplosion(engineLocation.x, engineLocation.y, engineLocation.z, 78, 0.0, true, false, true)
    AddExplosion(engineLocation.x, engineLocation.y, engineLocation.z, 79, 0.0, true, false, true)
    AddExplosion(engineLocation.x, engineLocation.y, engineLocation.z, 69, 0.0, true, false, true)

    Wait(2000) -- Wait before adding another explosion
    AddExplosion(engineLocation.x, engineLocation.y, engineLocation.z, 3, 0.01, true, false, true)
end

-- If the vehicle has exploded, disable the engine
if explode then
    SetVehicleEngineOn(vehicle, false, true, false)
    SetVehicleCurrentRpm(vehicle, 0.0)
    SetVehicleEngineHealth(vehicle, -1000.0)
end

-- Adjust engine temperature and health based on AFR and RPM
if afr > 14.0 and rpm > 0.5 then
    SetVehicleEngineTemperature(vehicle, temp * (1 + (1 - efficiency) * 2 * rawTurbopower))
    if temp > 120.0 then
        SetVehicleEngineHealth(vehicle, 
            (not explode and engineLife < 100.0 and 0.0) or 
            (explode and 0.0) or 
            (engineLife > 1000.0 and 1000.0) or 
            engineLife
        )
    end
end
	
local lastInertia = 0.2

Citizen.CreateThread(function()
    if dyno then
        local gearRatio = vehicleGearRatio[maxGear][1] * (1 / 0.9)
        local ent = QBCore.Functions.GetVehicle(vehicle) -- Ensure the vehicle is fetched correctly
        local newInertia = getGearInertia(gearRatio)

        -- Set dyno data for the vehicle
        QBCore.Functions.SetVehicleProperty('dynodata', { inertia = newInertia + 0.04, gear = 1, rpm = 0.2 }, true)
        QBCore.Functions.SetVehicleProperty('startdyno', { ts = GetGameTimer(), platform = zOffset, dyno = true, inertia = defaultFDriveInertia }, true)
    else
        local gearRatio = vehicleGearRatio[maxGear][1] * (1 / 0.9)
        
        -- Set gear shift data for the vehicle
        QBCore.Functions.SetVehicleProperty('gearshift', {
            gear = 1,
            gearmaxspeed = (maxSpeed * 1.32) / 3.6 / gearRatio,
            flatspeed = maxSpeed / gearRatio,
            driveforce = driveForce * gearRatio
        }, true)
    end
end)

local lastGear = 0

while inVehicle and manual do
    if dyno then
        HideHudAndRadarThisFrame()
        local newInertia = getGearInertia(gearRatio)
        SetVehicleHandlingFloat(vehicle, "CHandlingData", "fDriveInertia", newInertia + 0.04)
    end

    local clutching = GetControlNormal(0, 21)
    defaultFDriveInertia = tuningInertia or defaultFDriveInertia
    maxGear = nInitialDriveGears
    driveForce = fInitialDriveForce
    maxSpeed = fInitialDriveMaxFlatVel
    gearRatio = vehicleGearRatio[maxGear][gear] * (1 / 0.9)
    local gearMaxSpeed = (maxSpeed * 1.32) / 3.6 / gearRatio
    local flatSpeed = maxSpeed / gearRatio
    local rpm = GetVehicleCurrentRpm(vehicle)
    assert(rpm ~= nil, "rpm variable is nil")
    local speed = GetEntitySpeed(vehicle) * 3.6

    if switching and not dyno and clutching < 0.1 then
        gearRatio = vehicleGearRatio[maxGear][gear] * (1 / 0.9)
        gearMaxSpeed = (maxSpeed * 1.32) / 3.6 / gearRatio
        DisableControlAction(0, 71)
        SetVehicleCheatPowerIncrease(vehicle, 1.0)
        ForceVehicleSingleGear(vehicle, gearMaxSpeed, dyno)
        Wait(10)
        switching = false
    end
end

local rawTurbopower = turbopower
local throttle = GetControlNormal(0, 71)
turbopower = GetVehicleCheatPowerIncrease(vehicle) * throttle

local dyno = false
local auto = true -- or false, depending on the intended value
local customGears = true
local clutching = GetControlNormal(0, 21)
if throttle > 0.0 and not dyno and not switching and clutching < 0.1 then
    if gear > (auto and 0 or 0) and gear <= maxGear and rpm < 0.99999 or (customGears and rpm < 0.99999) then
        switch = false
        if currentMaxGear > 1 or true then
            currentMaxGear = 1
            SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel", flatSpeed)
            SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveForce", driveForce * gearRatio * throttle)
            SetVehicleHandlingInt(vehicle, "CHandlingData", "nInitialDriveGears", 1)
            SetVehicleMaxSpeed(vehicle, gearMaxSpeed + 1.0)
            ModifyVehicleTopSpeed(vehicle, 1.01)
            SetVehicleHandlingInt(vehicle, "CCarHandlingData", "strAdvancedFlags", vehicleFlags + 0x400000 + 0x20000 + 0x4000000 + 0x20000000)
            SetVehicleHandlingFloat(vehicle, "CHandlingData", "fDriveInertia", defaultFDriveInertia * throttle)
        end
    elseif not switching and not auto and gear < maxGear then
        if rpm > 0.9 then
            SetVehicleCurrentRpm(vehicle, 1.1)
        end
        switch = true
        if currentMaxGear == 1 or true then
            currentMaxGear = maxGear
            SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel", maxSpeed + 0.01)
            SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveForce", driveForce + 0.0 * throttle)
            SetVehicleHandlingInt(vehicle, "CHandlingData", "nInitialDriveGears", maxGear)
            SetVehicleHandlingFloat(vehicle, "CHandlingData", "fDriveInertia", defaultFDriveInertia * throttle)
            SetVehicleCheatPowerIncrease(vehicle, 1.0)
            ForceVehicleGear(vehicle, switch and gear or 1)
            SetVehicleHighGear(vehicle, switch and maxGear or 1)
            SetEntityMaxSpeed(vehicle, gearMaxSpeed)
            SetVehicleMaxSpeed(vehicle, gearMaxSpeed)
            ModifyVehicleTopSpeed(vehicle, 1.0)
            Wait(1)
        end
    end
end

				function ForceVehicleSingleGear(vehicle, speed, dyno)
                    if dyno then
                        SetVehicleForwardSpeed(vehicle, speed)
                    else
                        SetVehicleCurrentRpm(vehicle, speed / gearMaxSpeed)
                    end
                end
                
                local nextGearSpeed = 100 -- Assign a value to nextGearSpeed
                
                -- ...
                
                ForceVehicleSingleGear(vehicle, nextGearSpeed, dyno)
                
                

                -- Corrected function name
local function GetEntityDynoState(vehicle)
    -- Implementation of GetEntityDynoState function
end

-- Corrected function name
local function CheckDyno(dynoprop, index)
    local vehicle = vehicleFunctions.GetClosestVehicle(config.dyno.platform + config.dyno.offsets, 2.0)
    local taken = DoesEntityExist(vehicle)
    local state = taken and GetEntityDynoState(vehicle) -- corrected function name
    local driver = vehicleFunctions.GetPedInVehicleSeat(vehicle, -1) == cache.ped

    if not taken and not driver then
        return true
    end

    lib.notify({
        title = 'Dynamometer is being used',
        type = 'error'
    })
    return false
end

-- Corrected function name
local function SetVehicleGear(vehicle, gear, maxspeed, dyno)
    if dyno then
        return
    end
    ForceVehicleGear(vehicle, gear)
    vehicleHandlingFunctions.SetVehicleHighGear(vehicle, gear)
    vehiclePerformanceFunctions.SetEntityMaxSpeed(vehicle, maxspeed)
    vehiclePerformanceFunctions.SetVehicleMaxSpeed(vehicle, maxspeed)
    vehiclePerformanceFunctions.ModifyVehicleTopSpeed(vehicle, 0.999)
end

-- Corrected function name
local function SetVehicleManualGears(vehicle, dyno)
    local maxGear = 5
    local gear = 1
    local switching = false
    local manual = true
    local inertia = 0.1
    local tuningInertia = 0.1
    local maxSpeed = 100.0
    local initialDriveMaxFlatVel = 100.0
    local initialDriveForce = 100.0
    local driveInertia = 0.1
    local initialDriveGears = 1
    local vehicleFlags = vehicleHandlingFunctions.GetVehicleHandlingInt(vehicle, 'CCarHandlingData', 'strAdvancedFlags')
    local handBrakeForce = vehicleHandlingFunctions.GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fHandBrakeForce')
    local boostPerGear = {1.0, 1.1, 1.2, 1.3, 1.4}
    local vehicleGearRatio = {
        [1] = {1.0, 2.0, 3.0, 4.0, 5.0},
        [2] = {1.5, 2.5, 3.5, 4.5, 5.5},
        [3] = {2.0, 3.0, 4.0, 5.0, 6.0},
        [4] = {2.5, 3.5, 4.5, 5.5, 6.5},
        [5] = {3.0, 4.0, 5.0, 6.0, 7.0},
    }

    local eco = true
    local auto = true
    local gearMaxSpeed = ((maxSpeed * 1.32) / 3.6) / vehicleGearRatio[maxGear][gear]
    local ent = Entity(vehicle)
    local speed = 0.0
    local rpm = 0.0
    local wheelSpeed = 0.0
    local nextGearSpeed = 0.0
    local lastInertia = 0.0
    local turboPower = 1.0

    local function getGearInertia(gearRatio)
        return inertia / gearRatio
    end

    local function forceVehicleSingleGear(vehicle, speed, dyno)
        if dyno then
            SetVehicleForwardSpeed(vehicle, speed)
        else
            SetVehicleCurrentRpm(vehicle, speed / gearMaxSpeed)
        end
    end
end

-- ...

-- Corrected function call
forceVehicleSingleGear(vehicle, nextGearSpeed, dyno)
return { rpm = rpm }

