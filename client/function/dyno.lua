Dyno = function(data, index)
    local dynoprop = not config.useMlo and DoesEntityExist(ramp) and GetEntityModel(ramp) == config.dynoprop or config.useMlo
    local vehicle = GetClosestVehicle(vec3(data.platform.x, data.platform.y, data.platform.z), 2.0)
    local candyno = lib.callback.await('renzu_tuners:CheckDyno', false, dynoprop, index)
    local dynotaken = DoesEntityExist(vehicle)
    local dynostate = dynotaken and Entity(vehicle).state and Entity(vehicle).state.dyno
    local dynodriver = GetPedInVehicleSeat(GetVehiclePedIsIn(cache.ped), -1) == cache.ped

    -- Trigger the SpawnDyno event on the server-side
    TriggerServerEvent('renzu_tuners:SpawnDyno', index)

    if candyno and not dynotaken then
        indyno = true
        lib.notify({
            title = 'Dynamometer Mode',
            type = 'success'
        })
        lib.showTextUI('[ARROW UP] - Gear Up  \n [ARROW DOWN] - Gear Down  \n [G] Stop Dyno', { icon = 'gamepad', position = "top-center" })

        if manual then manual = false Wait(2000) end
        local vehicle = GetVehiclePedIsIn(cache.ped)
        local coord = GetEntityCoords(vehicle) + vec3(0.0, 0.0, 0.2)
        zoffset = { coord = data.platform, offsets = data.offsets }
        DisableVehicleWorldCollision(vehicle)
        FreezeEntityPosition(vehicle, true)
        SetVehicleManualGears(vehicle, true)
    elseif not dynotaken and not dynodriver then
        lib.notify({
            title = 'Dynamometer is being used',
            type = 'error'
        })
    end
end

local DynoTest = {}

DynoTest.StartDynoTest = function(self, vehicle)
    -- Start dyno test
    -- This function should start the dyno test and return a unique test ID
    local testId = math.random(1000, 9999)
    TriggerEvent("renzu_tuners:dynoTestStarted", vehicle, testId)
    return testId
end

DynoTest.StopDynoTest = function(self, testId)
    -- Stop dyno test
    -- This function should stop the dyno test and return the results
    TriggerEvent("renzu_tuners:dynoTestStopped", testId)
end

DynoTest.GetDynoResults = function(self, testId)
    -- Get dyno test results
    -- This function should return the results of the dyno test
    local results = {}
    -- Calculate dyno test results based on vehicle data
    -- For example:
    results.power = math.random(100, 500)
    results.torque = math.random(100, 500)
    results.acceleration = math.random(0, 10)
    return results
end

ForceVehicleSingleGear = function(vehicle, gearmaxspeed, dyno)
    if dyno then return end
    -- Set the vehicle's gear and speed
    ForceVehicleGear(vehicle, 1)
    SetVehicleHighGear(vehicle, 1)
    SetEntityMaxSpeed(vehicle, gearmaxspeed)
    SetVehicleMaxSpeed(vehicle, gearmaxspeed)
    ModifyVehicleTopSpeed(vehicle, 0.999)
end

SetVehicleManualGears = function(vehicle, dyno, auto, eco)
    while not invehicle do Wait(1) end
    if manual then return end
    local dyno = dyno
    indyno = dyno
    local ent = invehicle and Entity(invehicle).state
    fInitialDriveMaxFlatVel = nil
    fDriveInertia = nil
    fInitialDriveForce = nil
    if not DoesEntityExist(vehicle) then return end
    nInitialDriveGears = nil
    LoadVehicleSetup(vehicle, ent)
    local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
    while fInitialDriveMaxFlatVel == nil or fDriveInertia == nil or nInitialDriveGears == nil or fInitialDriveForce == nil do Wait(1) end
    local maxgear = nInitialDriveGears or 1
    local inertia = fDriveInertia
    local gear = 1
    local vehicle_gear_ratio = {}
    local gears = config.gears
    local customgears = nil
    local ecu_gears = (ecu[plate] and ecu[plate].active and ecu[plate].active.gear_ratio) or nil

    -- Check if the vehicle is in single gear mode (forced by the server)
    local isSingleGear = false
    if ForceVehicleSingleGear then
        isSingleGear = true
        -- Use QBCore's SetVehicleGear function to set the gear
        SetVehicleGear(vehicle, 1)
        maxgear = 1
    end

    if ecu_gears then
        customgears = {}
        customgears[maxgear] = ecu_gears
    end
	
	local vehicleflags = GetVehicleHandlingInt(vehicle, 'CCarHandlingData', 'strAdvancedFlags')
local fHandBrakeForce = GetVehicleHandlingInt(vehicle, 'CHandlingData', 'fHandBrakeForce')
local maxspeed = fInitialDriveMaxFlatVel
local driveforce = fInitialDriveForce
local default_fDriveInertia = fDriveInertia
local gearmaxspeed = 0
local rpm = 0.1
local currentspeed = 0
local gear_ratio = nil
local clutch = false
local reverse = false
local speed = 0.0
local switch = true
local currentmaxgear = maxgear
SetVehicleHandlingInt(vehicle , "CCarHandlingData", "strAdvancedFlags", vehicleflags+0x20000+0x200+0x1000+0x10+0x40)
manual = true
local turbopower = 1.0
local calculate_horsepower = function(rpm)
    local power = ((((fInitialDriveMaxFlatVel * 3.6) * fInitialDriveForce * turbopower) * (rpm / 10000)) * (gear / maxgear))
    local torque = ((power * 5252) / rpm)
    local horsepower = power * (rpm / 10000)
    return horsepower, torque
end
local rawturbopower = 1.0
upgrade, stats = GetEngineUpgrades(vehicle) -- get current upgraded parts
tune = RenzuTuners.GetTuningData(plate) -- get current tuned data
boostpergear = ecu[plate] and ecu[plate].active and ecu[plate].active.boostpergear or {}
efficiency, Fuel_Air_Volume, maxafr = EngineEfficiency(vehicle,stats,tune,rawturbopower)
local afr = 14.0
local explode = false
local switching = false
local lastgear = 1
local flatspeed = maxspeed
local GetGearInertia = function(ratio_)
    local dyno_inertia = (default_fDriveInertia / maxgear)
    local new_inertia = (dyno_inertia * turbopower) - ((dyno_inertia * turbopower) / ratio_)
    return new_inertia
end
local customgears = QBCore.Functions.GetVehicleCustomGears(vehicle)
local gears = QBCore.Functions.GetVehicleGears(vehicle)
local vehicle_gear_ratio = customgears or gears

Citizen.CreateThreadNow(function()
    while dyno do
        local data = ecu
        if data and data[plate] then
            boostpergear = data[plate].active and data[plate].active.boostpergear or {}
            vehicle_gear_ratio[maxgear] = data[plate].active and data[plate].active.gear_ratio or gears[maxgear]
        else
            print("Error: Invalid data or plate")
        end

        local upgrade, stats = GetEngineUpgrades(vehicle)
        if upgrade and stats then
            local tune = RenzuTuners.GetTuningData(plate)
            if tune then
                -- Update EngineEfficiency function to match latest implementation in server/main.lua
                local efficiency, Fuel_Air_Volume, maxafr = EngineEfficiency(vehicle, stats, tune, rawturbopower, GetVehicleEngineType(vehicle))
                if efficiency and Fuel_Air_Volume and maxafr then
                    afr = (Fuel_Air_Volume + 0.5) + ((maxafr - Fuel_Air_Volume) * rpm) - (0.5 * rpm)
                else
                    print("Error: Invalid engine efficiency or fuel-air volume")
                end
            else
                print("Error: Invalid tuning data")
            end
        else
            print("Error: Invalid engine upgrades or stats")
        end

        Wait(1000)
    end
end)

Citizen.CreateThreadNow(function()
    if dyno then
        SetDisableVehicleEngineFires(vehicle, false)
        SendNuiMessage(json.encode({ dyno = true }))
    end

    while invehicle and dyno do
        Wait(155)
        local currentspeed = dyno and math.floor(((flatspeed * 1.2) / 0.9) * rpm) or math.floor(speed)
        local hp, torque = calculate_horsepower(rpm * 10000)
        if hp and torque then
            if GetIsVehicleEngineRunning(vehicle) then
                -- Review gauge updates to ensure consistency with client/main.lua
                SendNUIMessage({
                    stat = {
                        rpm = math.floor(rpm * 10000),
                        gear = gear,
                        speed = currentspeed,
                        hp = math.floor(hp * efficiency),
                        torque = math.floor(torque * efficiency),
                        maxgear = maxgear,
                        gauges = {
                            oiltemp = GetVehicleDashboardOilTemp(vehicle),
                            watertemp = round(GetVehicleEngineTemperature(vehicle)),
                            oilpressure = GetVehicleDashboardOilPressure(vehicle),
                            efficiency = efficiency * 100.0,
                            afr = afr,
                            map = round(turbopower) + 0.0 or 1.0
                        }
                    }
                })
            end
        else
            print("Error: Invalid horsepower or torque")
        end
    end
end)

local temp = GetVehicleEngineTemperature(vehicle)
local bone = 'bonnet'
local enginelocation = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, bone))
local enginehealth = GetVehicleEngineHealth(vehicle)
local enginelife = enginehealth * (120 / temp)
local efficiency = EngineEfficiency(vehicle, stats, tune, rawturbopower)
local tuningData = GetTuningData(plate) -- Add GetTuningData function call
afr = (Fuel_Air_Volume + 0.5) + ((maxafr - Fuel_Air_Volume) * rpm) - (0.5 * rpm)
if enginelife < 100.0 and not explode then
    explode = true
    PlaySoundFromEntity(GetSoundId(), 'Trevor_4_747_Carsplosion', vehicle, 0, 0, 0)
    AddExplosion(enginelocation.x, enginelocation.y, enginelocation.z, 19, 0.1, true, false, true)
    AddExplosion(enginelocation.x, enginelocation.y, enginelocation.z, 78, 0.0, true, false, true)
    AddExplosion(enginelocation.x, enginelocation.y, enginelocation.z, 79, 0.0, true, false, true)
    AddExplosion(enginelocation.x, enginelocation.y, enginelocation.z, 69, 0.0, true, false, true)
    Wait(2000)
    AddExplosion(enginelocation.x, enginelocation.y, enginelocation.z, 3, 0.01, true, false, true)
    UpdateTuningData(plate, tuningData) -- Add UpdateTuningData function call
end
if explode then
    SetVehicleEngineOn(vehicle, false, true, false)
    SetVehicleCurrentRpm(vehicle, 0.0)
    SetVehicleEngineHealth(vehicle, -1000.0)
end
if afr > 14.0 and rpm > 0.5 then
    SetVehicleEngineTemperature(vehicle, temp * 1 + ((1.0 - efficiency) * 2) * rawturbopower)
    if temp > 120.0 then
        SetVehicleEngineHealth(vehicle, not explode and enginelife < 100.0 and 0.0 or explode and 0.0 or enginelife > 1000.0 and 1000.0 or enginelife)
    end
end
	
local lastinertia = 0.2

Citizen.CreateThreadNow(function()
    if dyno then
        gear_ratio = vehicle_gear_ratio[maxgear][1] * (1/0.9)
        local ent = Entity(vehicle).state
        local new_inertia = GetGearInertia(gear_ratio)
        ent:set('dynodata',{inertia = new_inertia+0.04, gear = 1, rpm = 0.2}, true)
        ent:set('startdyno',{ts = GetGameTimer(), platform = zoffset, dyno = true, inertia = default_fDriveInertia}, true)
    else
        gear_ratio = vehicle_gear_ratio[maxgear][1] * (1/0.9)
        ent:set('gearshift',{gear = 1, gearmaxspeed = (((maxspeed * 1.32) / 3.6) / gear_ratio), flatspeed = (maxspeed / gear_ratio), driveforce = (driveforce * gear_ratio)}, true)
    end
    local gear_clutch = nil
    while invehicle and manual do
        if dyno then
            HideHudAndRadarThisFrame()
            local new_inertia = GetGearInertia(gear_ratio)
            SetVehicleHandlingFloat(vehicle , "CHandlingData", "fDriveInertia", new_inertia+0.04)
            --SetVehicleForwardSpeed(vehicle,gearmaxspeed * rpm)
        end
        local clutching = GetControlNormal(0,21)
        default_fDriveInertia = tuning_inertia or default_fDriveInertia
        maxgear = nInitialDriveGears
        driveforce = fInitialDriveForce
        maxspeed = fInitialDriveMaxFlatVel
        gear_ratio = vehicle_gear_ratio[maxgear][gear] * (1/0.9)
        gearmaxspeed = ((maxspeed * 1.32) / 3.6) / gear_ratio
        flatspeed = maxspeed / gear_ratio
        rpm = GetVehicleCurrentRpm(vehicle)
        speed = GetEntitySpeed(vehicle) * 3.6
        if switching and not dyno and clutching < 0.1 then
            gear_ratio = vehicle_gear_ratio[maxgear][gear] * (1/0.9)
            gearmaxspeed = ((maxspeed * 1.32) / 3.6) / gear_ratio
            DisableControlAction(0,71)
            SetVehicleCheatPowerIncrease(vehicle,1.0)
            ForceVehicleSingleGear(vehicle,gearmaxspeed,dyno)
            Wait(10)
            switching = false
        end
        -- Update tuning data
        local tuningData = GetTuningData(plate)
        UpdateTuningData(plate, tuningData)
    end
end)

rawturbopower = turbopower
local throttle = GetControlNormal(0,71)
turbopower = GetVehicleCheatPowerIncrease(vehicle) * throttle
if throttle > 0.0 and not dyno and not switching and clutching < 0.1 then
    if gear > (auto and 0 or 0) and gear <= maxgear and rpm < 0.99999 or customgears and rpm < 0.99999 then
        switch = false
        if currentmaxgear > 1 or true then
            currentmaxgear = 1
            SetVehicleHandlingFloat(vehicle , "CHandlingData", "fInitialDriveMaxFlatVel", flatspeed)
            SetVehicleHandlingFloat(vehicle , "CHandlingData", "fInitialDriveForce", (driveforce * gear_ratio) * throttle) -- last multiplication for steering wheel pedals
            SetVehicleHandlingInt(vehicle , "CHandlingData", "nInitialDriveGears", 1)
            SetVehicleMaxSpeed(vehicle,gearmaxspeed+1.0)
            ModifyVehicleTopSpeed(vehicle,1.0)
            SetVehicleHandlingInt(vehicle , "CCarHandlingData", "strAdvancedFlags", vehicleflags+0x400000+0x20000+0x4000000+0x20000000)
            SetVehicleHandlingFloat(vehicle , "CHandlingData", "fDriveInertia", default_fDriveInertia * throttle)
        end
    elseif not switching and not auto and gear < maxgear then
        if rpm > 0.9 then
            SetVehicleCurrentRpm(vehicle,1.1)
        end
        switch = true
        if currentmaxgear == 1 or true then
            currentmaxgear = maxgear
            SetVehicleHandlingFloat(vehicle , "CHandlingData", "fInitialDriveMaxFlatVel", maxspeed+0.01)
            SetVehicleHandlingFloat(vehicle , "CHandlingData", "fInitialDriveForce", driveforce+0.0 * throttle)
            SetVehicleHandlingInt(vehicle , "CHandlingData", "nInitialDriveGears", maxgear)
            SetVehicleHandlingFloat(vehicle , "CHandlingData", "fDriveInertia", default_fDriveInertia * throttle)
            SetVehicleCheatPowerIncrease(vehicle,1.0)
            ForceVehicleGear(vehicle,switch and gear or 1)
            SetVehicleHighGear(vehicle,switch and maxgear or 1)
            SetEntityMaxSpeed(vehicle,gearmaxspeed)
            SetVehicleMaxSpeed(vehicle,gearmaxspeed)
            ModifyVehicleTopSpeed(vehicle,1.0)
            Wait(1)
        end
    end
    -- Update tuning data
    local tuningData = GetTuningData(plate)
    UpdateTuningData(plate, tuningData)
end
if lastgear ~= gear then
    Wait(50) -- ~ clutch delay
end
lastgear = gear

-- Update gear shifting logic
if gear == maxgear then
    SetVehicleHandlingInt(vehicle , "CCarHandlingData", "strAdvancedFlags", vehicleflags)
elseif gear == 1 then
    SetVehicleHandlingInt(vehicle , "CCarHandlingData", "strAdvancedFlags", vehicleflags+0x20000+0x200+0x1000)
end

-- Update gear shifting logic
if lastgear ~= gear then
    Wait(50) -- ~ clutch delay
end
lastgear = gear

if gear == maxgear then
    SetVehicleHandlingInt(vehicle , "CCarHandlingData", "strAdvancedFlags", vehicleflags)
elseif gear == 1 then
    SetVehicleHandlingInt(vehicle , "CCarHandlingData", "strAdvancedFlags", vehicleflags+0x20000+0x200+0x1000)
end

if not dyno and GetControlNormal(0,72) < 0.1 and gear_ratio and rpm > 0.3 and clutching < 0.1 then
    local rpm = ((speed / 3.6) / gearmaxspeed) * 1.01
    switch = false

    -- Update drive inertia and initial drive force
    SetVehicleHandlingFloat(vehicle , "CHandlingData", "fDriveInertia", 0.1+ (default_fDriveInertia / gear) * (1.0 - rpm))
    SetVehicleHandlingFloat(vehicle , "CHandlingData", "fInitialDriveForce", (driveforce * (gear / maxgear)) * (1 - rpm))

    -- Update tuning data
    local tuningData = GetTuningData(plate)
    UpdateTuningData(plate, tuningData)
end
			
			-- Gear shifting and clutching logic
local inverseClutch = GetControlNormal(0, 72)
if not dyno and inverseClutch < 0.1 and clutching < 0.1 then
    SetVehicleHandlingInt(vehicle, "CHandlingData", "nInitialDriveGears", manualGear and maxgear or 1)
    ForceVehicleGear(vehicle, manualGear and gear or 1)
    SetVehicleHighGear(vehicle, manualGear and maxgear or 1)
end

-- Initial drive force adjustment
if inverseClutch > 0.4 and speed < 1 then
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveForce", driveforce + 0.0)
    while GetControlNormal(0, 72) > 0.5 do
        Wait(111)
        SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveForce", driveforce + 0.0)
    end
end

-- Dyno mode exit
if dyno and IsControlJustPressed(0, 47) then
    manual = false
end
if clutch or clutching > 0.1 then
    -- Set vehicle clutch to 1.0
    SetVehicleClutch(vehicle, 1.0)
    
    -- Set vehicle handling data
    SetVehicleHandling(vehicle, "CHandlingData", "nInitialDriveGears", maxgear)
    ForceVehicleGear(vehicle, maxgear)
    
    -- Update vehicle handling data using QBcore's SetVehicleHandling function
    SetVehicleHandling(vehicle, "CCarHandlingData", "strAdvancedFlags", vehicleflags + 0x20000 + 0x200 + 0x1000)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fDriveInertia", default_fDriveInertia)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", 99999999.0)
    SetControlNormal(0, 76, clutching + 0.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", 99999999.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveForce", driveforce + 0.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel", maxspeed + 0.01)
    SetVehicleCheatPowerIncrease(vehicle, 1.0)
    ModifyVehicleTopSpeed(vehicle, 1.0)
    
    -- Calculate gear ratio and max speed
    gear_ratio = vehicle_gear_ratio[maxgear][gear] * (1 / 0.9)
    gearmaxspeed = ((maxspeed * 1.32) / 3.6) / gear_ratio
    ForceVehicleSingleGear(vehicle, gearmaxspeed, false)
elseif gear_clutch then
    gear = gear_clutch
    gear_clutch = nil
end
Wait(0)

-- Dyno logic
if dyno then
    Entity(vehicle).state:set('startdyno', { ts = GetGameTimer(), platform = zoffset, dyno = false, inertia = default_fDriveInertia }, true)
    dyno = false
    SetEntityHasGravity(vehicle, true)
    SetVehicleGravity(vehicle, true)
    SetEntityCollision(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)
    SendNuiMessage(json.encode({ dyno = false }))
    --while Entity(vehicle).state.startdyno.dyno do Wait(111) end
end
		-- Reset vehicle
Wait(1500)
SetVehicleCurrentRpm(vehicle, 0.2)
SetEntityAsMissionEntity(vehicle, true, true)

-- Update vehicle stats
if config.sandboxmode then
    ent:set('vehiclestatreset', {
        strAdvancedFlags = GetVehicleHandlingInt(vehicle, 'CCarHandlingData', 'strAdvancedFlags'),
        fInitialDriveMaxFlatVel = fInitialDriveMaxFlatVel,
        fInitialDriveForce = fInitialDriveForce,
        fDriveInertia = tuning_inertia or default_fDriveInertia,
        nInitialDriveGears = nInitialDriveGears
    }, true)
else
    ent:set('vehiclestatreset', {
        strAdvancedFlags = vehicleflags,
        fInitialDriveMaxFlatVel = maxspeed,
        fInitialDriveForce = driveforce,
        fDriveInertia = inertia,
        nInitialDriveGears = maxgear
    }, true)
end

-- Reset vehicle handling
SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", fHandBrakeForce + 0.0)
SetVehicleHighGear(vehicle, maxgear)
ForceVehicleGear(vehicle, 0)
SetEntityMaxSpeed(vehicle, (maxspeed * 1.3) / 3.6)
SetVehicleMaxSpeed(vehicle, 0.0)
SetVehicleCheatPowerIncrease(vehicle, GetVehicleCheatPowerIncrease(vehicle) + 0.0)
ModifyVehicleTopSpeed(vehicle, 1.01)
SetVehicleHandbrake(vehicle, false)
SetEntityCollision(vehicle, true, true)
SetEntityControlable(vehicle)
--SetVehicleGravityAmount(vehicle, 1.0)
SetEntityHasGravity(vehicle, true)
SetVehicleGravity(vehicle, true)
DetachEntity(vehicle, false, false)
FreezeEntityPosition(vehicle, false)

-- Reset dyno variables
manual = false
print('reset', (maxspeed * 1.3) / 3.6, maxspeed, maxgear, GetVehicleHighGear(vehicle), inertia, driveforce)
dyno = false
indyno = false
lib.hideTextUI()
tuning_inertia = nil
	
	-- Automatic gear shifting
 function autoGearShift()
    while invehicle do
        local speedRatio = (speed / (gearmaxspeed * 3.6))
        local switchRpm = (eco and 0.6 or 0.9)
        if rpm >= switchRpm and gear < maxgear then
            local switchSpeed = (eco and 0.65 or 0.89)
            if speedRatio > switchSpeed then
                gear = 1
                switching = true
                while switching do Wait(1) end
            end
        end
        if eco and rpm > 0.75 and gear == maxgear then
            SetVehicleCurrentRpm(vehicle, 0.75)
        end
        if speedRatio < 0.6 and GetControlNormal(0, 71) < 0.1 and gear > 1 then
            gear = gear - 1
            Wait(100)
        end
        Wait(0)
    end
end

-- Upshift function
 function upshift()
    if manual and gear + 1 <= maxgear then
        switching = true
        local nextGearRatio = vehicle_gear_ratio[maxgear][gear + 1] * (1 / 0.9)
        local nextGearSpeed = ((maxspeed * 1.32) / 3.6) / nextGearRatio
        gear = gear - 1
        wheelspeed = dyno and math.floor(gearmaxspeed * rpm) or math.floor((GetEntitySpeed(vehicle) * 4.2))
        local newInertia = GetGearInertia(nextGearRatio)
        lastinertia = newInertia
        if dyno then
            local rpm = (wheelspeed / nextGearSpeed)
            ent:set('dynodata', { inertia = newInertia + 0.04, gear = gear, rpm = rpm }, true)
            Wait(1)
            SetVehicleHandlingFloat(vehicle, "CHandlingData", "fDriveInertia", newInertia + 0.04)
            SetVehicleForwardSpeed(vehicle, nextGearSpeed)
        else
            ent:set('gearshift', { gear = gear, gearmaxspeed = gearmaxspeed, flatspeed = (maxspeed / nextGearRatio), driveforce = (driveforce * nextGearRatio) }, true)
        end
        SetVehicleHandlingInt(vehicle, "CCarHandlingData", "strAdvancedFlags", vehicleflags + 0x20000 + 0x200 + 0x1000)
        SetVehicleCheatPowerIncrease(vehicle, turbopower + 0.0)
        ForceVehicleSingleGear(vehicle, nextGearSpeed, dyno)
        if GetResourceState('renzu_turbo') == 'started' then
            exports.renzu_turbo:BoostPerGear(boostpergear[gear] or 1.0)
        end
        Wait(50)
        switching = false
    end
end

 -- Downshift function
 function downshift()
    if manual and vehicle_gear_ratio[maxgear][gear - 1] then
        switching = true
        gear = gear - 1
        local nextGearRatio = vehicle_gear_ratio[maxgear][gear > 1 and gear or 1] * (1 / 0.9)
        local nextGearSpeed = ((maxspeed * 1.32) / 3.6) / nextGearRatio
        wheelspeed = dyno and math.floor(gearmaxspeed * rpm) or math.floor((GetEntitySpeed(vehicle) * 4.2))
        local newInertia = GetGearInertia(nextGearRatio)
        lastinertia = newInertia

        -- Calculate RPM
        local rpm
        if dyno then
            rpm = (wheelspeed / nextGearSpeed)
        elseif GetEntitySpeed(vehicle) >= nextGearSpeed then
            rpm = GetEntitySpeed(vehicle) / nextGearSpeed
        end

        -- Update vehicle settings
        if dyno then
            SetVehicleCurrentRpm(vehicle, rpm <= 0.0 and 1.1)
            SetVehicleHandlingFloat(vehicle, "CHandlingData", "fDriveInertia", newInertia + 0.04)
            ent:set('dynodata', { inertia = newInertia + 0.04, gear = gear, rpm = rpm }, true)
        elseif GetEntitySpeed(vehicle) >= nextGearSpeed then
            SetVehicleForwardSpeed(vehicle, nextGearSpeed)
            SetVehicleCurrentRpm(vehicle, rpm >= 1.0 and 1.5 or rpm)
        end

        -- Update gear settings
        SetVehicleHandlingInt(vehicle, "CCarHandlingData", "strAdvancedFlags", vehicleflags + 0x20000 + 0x200 + 0x1000)
        SetVehicleCheatPowerIncrease(vehicle, turbopower + 0.0)
        ForceVehicleSingleGear(vehicle, nextGearSpeed, dyno)
        ent:set('gearshift', { gear = gear, gearmaxspeed = nextGearSpeed, flatspeed = (maxspeed / nextGearRatio), driveforce = (driveforce * nextGearRatio) }, true)

        -- Check for turbo boost
        if GetResourceState('renzu_turbo') == 'started' then
            exports.renzu_turbo:BoostPerGear(boostpergear[gear] or 1.0)
        end

        Wait(50)
        switching = false
    end
end

	-- Exported Gear function
exports('Gear', function(gear)
    -- Check for invalid gear inputs
    if gear == 0 then
        print(clutch)
        clutch = true
        return
    end
    if gear > maxgear then
        reverse = true
        return
    end
    if GetControlNormal(0, 21) < 0.3 then
        return
    end

    -- Update gear settings
    switching = true
    reverse = false
    gear = gear
    clutch = false
    local nextGearRatio = vehicle_gear_ratio[maxgear][gear] * (1 / 0.9)
    local nextGearSpeed = ((maxspeed * 1.32) / 3.6) / nextGearRatio

    -- Update RPM if downshifting
    if lastshift > gear then
        SetVehicleCurrentRpm(vehicle, GetEntitySpeed(vehicle) / nextGearSpeed)
    end
    lastshift = gear

    -- Update vehicle settings
    SetVehicleHandlingInt(vehicle, "CCarHandlingData", "strAdvancedFlags", vehicleflags + 0x20000 + 0x200 + 0x1000)
    SetVehicleCheatPowerIncrease(vehicle, turbopower + 0.0)
    ForceVehicleSingleGear(vehicle, nextGearSpeed, dyno)
    ent:set('gearshift', { gear = gear, gearmaxspeed = gearmaxspeed, flatspeed = (maxspeed / nextGearRatio), driveforce = (driveforce * nextGearRatio) }, true)

    -- Check for turbo boost
    if GetResourceState('renzu_turbo') == 'started' then
        exports.renzu_turbo:BoostPerGear(boostpergear[gear] or 1.0)
    end

    Wait(50)
    switching = false
end)

-- ManualOff function
local function ManualOff()
    -- Disable manual mode
    FreezeEntityPosition(vehicle, false)
    DetachEntity(vehicle, false, true)
    manual = false
end

local commandPrefix = "manualgear_"

local commandString = math.random(1, 999)
RegisterCommand(commandPrefix .. "upshift" .. commandString, Upshift)
RegisterCommand(commandPrefix .. "downshift" .. commandString, DownShift)
RegisterKeyMapping(commandPrefix .. "upshift" .. commandString, 'Manual Gear Upshift', 'keyboard', 'UP')
RegisterKeyMapping(commandPrefix .. "downshift" .. commandString, 'Manual Gear Downshift', 'keyboard', 'DOWN')
RegisterCommand(commandPrefix .. "manualoff", ManualOff)

return maxgear, vehicleflags end