local QBCore = exports['qb-core']:GetCoreObject()

local dyno, err = pcall(require, "dyno")
if not dyno then
    error("Failed to load dyno module: " .. tostring(err))
end
local rpm = rawget(dyno, "rpm")
if rpm then
    assert(rpm, "rpm variable is nil")
else
    error("dyno.rpm is nil")
end




local function calculateEngineStats(stats, tune, turboTorque)
    local engineStats = {}
    -- Initialize engineStats with default values
    for k, v in pairs(config.enginestat_default) do
        engineStats[k] = v
    end
    -- Update engineStats based on input stats
    for k, v in pairs(stats) do
        if k == 'duration' then
            engineStats['compression'] = engineStats['compression'] - v
        elseif k == 'fuelpressure' then
            engineStats[k] = engineStats[k] + v * rpm
            turboTorque = turboTorque - (v * 0.1)
        elseif k == 'ignition' then
            engineStats[k] = engineStats[k] + v * rpm
        else
            engineStats[k] = engineStats[k] + v
        end
    end
    return engineStats
end

local function calculateEfficiencyFactors(engineStats, tune, turboTorque)
    local fuel = engineStats.fuelpressure / 100
    local ignition = engineStats.ignition / 100
    local turbopower = turboTorque > 1.0 and turboTorque - 1.0 or 1.0
    local compression = engineStats.compression / 100 * ignition
    local combustionChamber = compression * (ignition / fuel)
    local Fuel_Air_Volume = ignition > fuel and (13.5 * ignition) * combustionChamber or ((13.5 / fuel) * ignition) * combustionChamber
    local maxafr = Fuel_Air_Volume + (turboTorque > 1.0 and turboTorque * compression or 0.0) * combustionChamber + (turboTorque > 1.0 and turboTorque or 0.0)
    local total = 1.0 * (maxafr > 13.5 and 13.5 / maxafr or maxafr / 13.5)
    return total, Fuel_Air_Volume, maxafr, combustionChamber
end

function EngineEfficiency(vehicle, stats, tune, turboTorque)
    local engineStats = calculateEngineStats(stats, tune, turboTorque)
    local total, Fuel_Air_Volume, maxafr, combustionChamber = calculateEfficiencyFactors(engineStats, tune, turboTorque)
    local totalpower = total > 1.0 and 1.0 or total
    local effective_power = totalpower < 1.0 and totalpower or totalpower * combustionChamber
    return totalpower, Fuel_Air_Volume, maxafr
end

local sandbox_mode = config.sandboxmode
local ENGINE_PARTS = config.engineparts

-- Declare handling as a local variable
local handling = {}

-- Get current entity and its default handling
local vehicle = QBCore.Functions.GetVehicle(vehicle)
local statehandling = vehicle.defaulthandling
local plate = plate

-- Get current upgraded parts and tuned data
local upgrades, stats = QBCore.Functions.GetVehicle(vehicle).state(vehicle)
local tune = GetTuningData(plate)

-- Function to update handling value
UpdateHandlingValue = function(name, statehandling, upgrades, tune, efficiency)
    local newval = statehandling[name] * (upgrades[name] or 1.0) * (tune[name] or 1.0) * efficiency
    handling[name] = newval
end

-- Update handling values for each engine part
local efficiency = 1.0 -- define efficiency as a local variable
for k, v in ipairs(ENGINE_PARTS) do
    UpdateHandlingValue(v, statehandling, upgrades, tune, efficiency)
end

    local TURBO_STREET = 'Street'
local TURBO_SPORTS = 'Sports'
local TURBO_RACING = 'Racing'
local TURBO_ULTIMATE = 'Ultimate'

GetTurboDeduction = function(turbo)
    if turbo == TURBO_STREET then return 1.05
    elseif turbo == TURBO_SPORTS then return 1.15
    elseif turbo == TURBO_RACING then return 1.25
    elseif turbo == TURBO_ULTIMATE then return 1.3
    else return 1.0
    end
end

    -- Calculate RPM multiplier
    local rpm = 1.0 + (GetVehicleCurrentRpm(vehicle) * 0.2)


    -- Update vehicle top speed and engine power
    ModifyVehicleTopSpeed(vehicle, 1.0)
    SetVehicleEnginePowerMultiplier(vehicle, 1.0)

    -- Handle tires
    HandleTires(vehicle, QBCore.Functions.GetVehicleProperties(vehicle).plate, statehandling, vehicle)


-- Helper function to calculate turbo deduction
GetTurboDeduction = function(turbo)
    if turbo == 'Street' then return 1.05
    elseif turbo == 'Sports' then return 1.15
    elseif turbo == 'Racing' then return 1.25
    elseif turbo == 'Ultimate' then return 1.3
    else return 1.0
    end
end

-- Helper function to update handling values
    local enginePartsCache = {} -- cache engine parts for faster lookup
    local handlingCache = {} -- cache handling values for faster lookup
    local handlingCacheByItem = {} -- cache table
    
    for k, v in ipairs(config.engineparts) do
        enginePartsCache[v.item] = v
        handlingCache[v.item] = {}
        for name, _ in pairs(v.handling) do
            handlingCache[v.item][name] = true
        end
    end
    
    local function round(value)
        -- implementation of the round function
    end
    
    local function updateHandlingField(vehicle, name, value)
        if name == 'nInitialDriveGears' then
            if type(value) == 'number' then
                local maxgears = math.min(round(value), 9)
                SetVehicleHandlingInt(vehicle, 'CHandlingData', name, maxgears)
                SetVehicleHighGear(vehicle, maxgears)
            end
        elseif name == 'fInitialDriveMaxFlatVel' then
            if type(value) == 'number' then
                local topSpeed = (value * 1.3) / 3.6
                SetEntityMaxSpeed(vehicle, topSpeed)
                SetVehicleMaxSpeed(vehicle, 0.0)
                SetVehicleHandlingField(vehicle, 'CHandlingData', name, value)
            end
        else
            SetVehicleHandlingField(vehicle, 'CHandlingData', name, value)
        end
    end
    local function calculateHandlingValue(statehandling, name, upgrades, tune, efficiency, deduct)
        local value = statehandling[name]
        local newval = (value * (upgrades[name] or 1.0)) * (tune[name] or 1.0) * efficiency
        local upgradevalue = value == 0.0 and (((value + 1.0) * (upgrades[name] or 1.0) * (tune[name] or 1.0) - 1.0) * efficiency) or newval
        return upgradevalue - deduct
    end
    
    -- Helper function to update a single handling value
    local function updateHandlingValue(statehandling, name, upgrades, tune, efficiency, deduct, vehicle, fInitialDriveForce)
        local value = calculateHandlingValue(statehandling, name, upgrades, tune, efficiency, deduct)
        updateHandlingField(vehicle, name, value)
        if name == 'fDriveInertia' then
            local fDriveInertia = value
        end
        if name == 'fInitialDriveForce' then
            fInitialDriveForce = value
        end
    end
    
    UpdateHandlingValues = function(ent, statehandling, upgrades, tune, turbodeduct, rpm, vehicle, efficiency)
        local fInitialDriveForce = 0 -- Initialize the variable if needed
        for _, enginePart in pairs(enginePartsCache) do
            local item = enginePart.item
            local handling = handlingCacheByItem[item]
            if not handling then
                handling = handlingCache[item]
                handlingCacheByItem[item] = handling
            end
            for name, _ in pairs(handling) do
                updateHandlingValue(statehandling, name, upgrades, tune, efficiency, 0, vehicle, fInitialDriveForce)
            end
        end
    end
	
	local function myFunction(vehicle, plate, handlings, ent)
        ModifyVehicleTopSpeed(vehicle,1.0)
        SetVehicleEnginePowerMultiplier(vehicle, 1.0) -- do not remove this, its a trick for flatvel
        SetVehicleCheatPowerIncrease(vehicle,1.0)
        HandleTires(vehicle,plate,handlings,ent)
        local local_handling = handlings
    end

QBCore.Functions.GetVehicle(vehicle).state = function(vehicle, name)
    local upgrades = {}
    local stats = {}
    local ent = QBCore.Functions.GetVehicle
    for k,v in pairs(config.engineupgrades) do
        for k,name in pairs(v.handling) do
            if not upgrades[name] then upgrades[name] = 1.0 end
            if ent[v.item] then
                for k,v in pairs(v.stat or {}) do
                    if not stats[k] then stats[k] = 0.0 end
                    stats[k] = stats[k] + v
                end
                upgrades[name] = upgrades[name] * (not config.tunableonly[name] and v.add or 1.0)
            end
        end
    end
    return upgrades,stats
end

GetTuningData = function(plate)
    local tunes = ecu
    local data = {
        ['fInitialDriveMaxFlatVel'] = 1.0,
        ['fDriveInertia'] = 1.0,
        ['fInitialDriveForce'] = 1.0,
        ['fClutchChangeRateScaleUpShift'] = 1.0,
        ['fClutchChangeRateScaleDownShift'] = 1.0,
    }
    if tunes and tunes[plate] then
        for k,v in pairs(tunes[plate].active or {}) do
            if k == 'topspeed' then
                data['fInitialDriveMaxFlatVel'] = v
            end
            if k == 'engineresponse' then
                data['fDriveInertia'] = v
            end
            if k == 'acceleration' then
                data['fInitialDriveForce'] = v
            end
            if k == 'gear_response' then
                data['fClutchChangeRateScaleUpShift'] = v
                data['fClutchChangeRateScaleDownShift'] = v
            end
        end
    end
    return data
end

RetrieveOldEngine = function(vehicle, engine)
    local engines = exports.renzu_engine:Engines().Locals
    local custom_engine = exports.renzu_engine:Engines().Custom
    for k,v in pairs(custom_engine) do
        v.model = v.soundname
        v.name = v.label
        engines[k] = v
    end
end
	local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
	local model = QBCore.Functions.GetVehicleProperties(vehicle).engine ~= 'default' and QBCore.Functions.GetVehicleProperties(vehicle).engine or GetEntityModel(vehicle)
	local label = 'Engine'
	for k,v in pairs(engines) do
		if QBCore.Functions.GetVehicleProperties(vehicle).engine == 'default' and joaat(v.model) == model or QBCore.Functions.GetVehicleProperties(vehicle).engine ~= 'default' and v.model == model then
			model = v.model
			label = v.name
			break
		end
	end
	QBCore.Functions.TriggerCallback('renzu_tuners:OldEngine',false,label,model,plate,NetworkGetNetworkIdFromEntity(vehicle))
	QBCore.Functions.SetVehicleProperty('currentengine',engine,true)
	
	RegisterNetEvent('renzu_engine:OnEngineChange', function(engine) -- repair current parts when installing new engines
        local vehicle = GetClosestVehicle(GetEntityCoords(cache.ped), 10.0)
        -- Use the vehicle variable here if needed
        for k,v in pairs(config.engineparts) do
            QBCore.Functions.SetVehicleProperty(v.item, 99.97, true)
        end
    end)