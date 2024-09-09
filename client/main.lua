local QBCore = exports['qb-core']:GetCoreObject()

AddEventHandler('QBCore:Client:OnPlayerVehicleEnter', function(vehicle)
	OnVehicle(vehicle)
  end)
  
  OnVehicle = function(vehicle)
	local invehicle = vehicle
	if not DoesEntityExist(vehicle) then return end
	local isdriver = GetPedInVehicleSeat(vehicle, -1) == cache.ped
	if not isdriver then return end
	local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
	local state = QBCore.Functions.GetVehicleServerStates(plate) -- Update: Use QBCore's GetVehicleServerStates function
	if not DoesEntityExist(vehicle) then return end
	
    -- local vehiclestats = GlobalState.vehiclestats
	local coord = GetEntityCoords(vehicle)
	local lastcoord = nil
	local ent = vehicle and Entity(vehicle).state
	local turbo = ent.turbo and ent.turbo -- renzu_turbo states bag
	local ecu_state = ecu
	local turbopower = 1.0
	local turboinstall = GetResourceState('renzu_turbo') == 'started'
	if vehicle then
	  DefaultSetting(vehicle)
	  plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
	  LoadVehicleSetup(vehicle, ent, vehiclestats)
	  ent:set('vehicle_loaded', true, true)
	  
      -- print("setup", vehicle ~= 0, tonumber(vehicle), ecu, invehicle)
	  -- ecu = ecu_state[plate] and ecu_state[plate].active?.boostpergear
	  Citizen.CreateThreadNow(function()
		local lockspeed = 0
		local driveforce = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce')
		local hasracingcam = ent['racing_camshaft']
		upgrade, stats = RenzuTuners.GetEngineUpgrades(vehicle) -- Update: Use RenzuTuners' GetEngineUpgrades function
		tune = RenzuTuners.RenzuTuners.GetTuningData(plate) -- Update: Use RenzuTuners' RenzuTuners.GetTuningData function
		while invehicle do
		  local sleep = 200
		  local Speed = GetEntitySpeed(vehicle)
		  turbopower = GetVehicleCheatPowerIncrease(vehicle)
		  efficiency = EngineEfficiency(vehicle, stats, tune, turbopower)
		  local gear = GetVehicleCurrentGear(vehicle) + 1
		  if ecu and ecu[gear - 1] and not indyno and turboinstall then
			exports.renzu_turbo:BoostPerGear(ecu[gear - 1] or 1.0)
		  end
		  local rpm = GetVehicleCurrentRpm(vehicle)
		  if hasracingcam then
			if rpm >= 0.61 then -- activate high cam lobe
			  SetVehicleHandlingField(vehicle, 'CHandlingData', 'fInitialDriveForce', driveforce + (1.00 / gear))
			else
			  SetVehicleHandlingField(vehicle, 'CHandlingData', 'fInitialDriveForce', driveforce + 0.0)
			end
		  end
		  Wait(sleep)
		end
	  end)
	end
  end
  RegisterNetEvent('renzu_tuners:dynoTestStarted')
  AddEventHandler('renzu_tuners:dynoTestStarted', function(vehicle, testId)
      -- Call the StartDynoTest function
      SendNUIMessage({ action = 'DynoTest:StartDynoTest', vehicle = vehicle, testId = testId })
  end)
  
  RegisterNetEvent('renzu_tuners:dynoTestStopped')
  AddEventHandler('renzu_tuners:dynoTestStopped', function(testId)
      -- Call the StopDynoTest function
      SendNUIMessage({ action = 'DynoTest:StopDynoTest', testId = testId })
  end)

  Citizen.CreateThread(function()
	  if not config.enableDegration then return end
	  if QBCore ~= nil and QBCore.Shared ~= nil and QBCore.Shared.Plates ~= nil and QBCore.Shared.Plates[plate] ~= nil and QBCore.Shared.Plates[plate].NoDegradePlate == 1 then
		  warn('this vehicle is excluded in degration mode')
		  return
	  end
	  local tune = RenzuTuners.RenzuTuners.GetTuningData(plate)
	  local upgraded = {}
	  for k,v in pairs(config.engineupgrades) do -- create a list of upgraded states
		  if ent and ent[v.item] then
			  upgraded[v.state] = true
		  end
	  end
  
	  local synctimer = 0
	  while invehicle do
		  local ent = ent
		  local sleep = ent.nitroenable and 200 or config.degradetick or 3000
		  local rpm = GetVehicleCurrentRpm(value)
		  if rpm > 0.5 then -- start degrading states if its above 0.5 RPM
			  local mileage = ent.mileage or 0
			  local update = false
			  -- Add your degradation logic here
			  -- ...
			  -- Update the NoDegradePlate property in QBCore.Shared.Plates
			  if QBCore ~= nil and QBCore.Shared ~= nil and QBCore.Shared.Plates ~= nil then
				  QBCore.Shared.Plates[plate].NoDegradePlate = mileage
			  end
		  end
		  Wait(sleep)
	  end
  end)

    local synctimer = 0
    while invehicle do
        local ent = ent
        local sleep = ent.nitroenable and 200 or config.degradetick or 3000
        local rpm = GetVehicleCurrentRpm(value)
        if rpm > 0.5 then -- start degrading states if its above 0.5 RPM
            local mileage = ent.mileage or 0
            local update = false
            local nitro = ent.nitroenable -- renzu_nitro states bag if nitro is being used
            local turbodeduct = 1.0
            local nitrodeduct = 1.0
            local chance = nitro and (config.chancedegradenitro or 11) or (config.chancedegrade or 2)
            if turbo then
                turbodeduct = turbopower
            end
            if nitro then
                nitrodeduct = turbopower * ( 2.0 - efficiency) -- fix degration for now when using NOS
            end
            synctimer = synctimer + 1
            local chance_degrade = {}
            local resettimer = false
            for _,v2 in pairs(config.engineparts) do
                local stock = not upgraded[v2.item]
                if chance_degrade[v2.item] == nil then
                    chance_degrade[v2.item] = math.random(1,100) < (chance * ( 2.0 - efficiency))
                end
                for k,v in ipairs(config.degrade) do
                    local mileage_degration = mileage >= v.min
                    local candegrade = mileage_degration and chance_degrade[v2.item] -- chances of degration and conditions
                    for k,handlingname in pairs(v2.handling) do
                        if candegrade or (tune[handlingname] or 1.0) > 1.0 and chance_degrade[v2.item] and mileage_degration or turbo and chance_degrade[v2.item] and mileage_degration or nitro and mileage_degration and chance_degrade[v2.item] then
                            local efficiency_degrade = 1.0 + (1.0 - efficiency)
                            local stock_degrade = stock and 1.5 or efficiency_degrade -- if parts are stock degration is higher when using turbos, nitros and ECU over tunes.
                            local upgraded_degrade = stock and 1.0 or (efficiency_degrade * 0.9) -- if parts are upgraded degration is lower compared to stock when using turbos, nitros and ECU over tunes.
                            local degrade = ((((v.degrade * upgraded_degrade) * (turbodeduct * stock_degrade)) * (nitrodeduct * stock_degrade)) * (efficiency_degrade * stock_degrade) * rpm) or 1.0
                            local value = ent[v2.item] and ent[v2.item] - degrade or QBCore.Functions.GetVehicleProperty(plate, v2.item) and QBCore.Functions.GetVehicleProperty(plate, v2.item) - degrade or 100 - degrade
                            ent:set(v2.item, value, synctimer > 20) -- set local state bag
                            resettimer = true
                            break
                        end
                    end
                end
            end
        end
        Citizen.Wait(sleep)
    end

local chance_degrade = {}

-- Main loop
while true do
    -- Check if sync timer has exceeded 20 seconds and reset timer is true
    if synctimer > 20 and resettimer then
      local  synctimer = 0
      local  resettimer = false
    end

    -- Handle engine degradation
    HandleEngineDegration(value, ent, plate)

    -- Wait for a short period of time before checking again
    Wait(sleep)

    -- Check if the vehicle has changed
    if cache.vehicle ~= value then
        break
    end
end

-- On vehicle exit
for _, v2 in pairs(config.engineparts) do
    -- Sync local state bag to server
    QBCore.Functions.SetVehicleProperty(plate, v2.item, ent[v2.item] and ent[v2.item] + 0.01)
end
	

local lastcoord = nil

-- Create a thread to update mileage
Citizen.CreateThreadNow(function()
    -- Initialize update state
    local updatestate = 0

    -- Loop while the player is in the vehicle
    while invehicle and GetPedInVehicleSeat(value, -1) == cache.ped do
        -- Get current coordinates
        local coord = GetEntityCoords(value)

        -- Check if the vehicle has moved more than 10 units or if this is the first update
        if lastcoord and #(coord - lastcoord) > 10 or lastcoord == nil then
            -- Get vehicle entity and plate
            local ent = Entity(value).state
            local plate = string.gsub(GetVehicleNumberPlateText(value), '^%s*(.-)%s*$', '%1'):upper()

            -- Update mileage
            if ent.mileage then
                updateState = updateState + 1
                if updatestate > 10 then
                    ent.mileage = ent.mileage + 10
                    QBCore.Functions.SetVehicleProperty(plate, 'mileage', ent.mileage)
                    updatestate = 0
                end
            elseif mileages[plate] then
                ent.mileage = tonumber(mileages[plate])
            else
                ent.mileage = 0
            end
        end

        -- Update last coordinate
        lastcoord = coord

        -- Wait for 4000 ticks (default)
        Wait(4000)

        -- Check if the vehicle has changed
        if cache.vehicle ~= value then
            break
        end
    end
end)

Citizen.CreateThreadNow(function()
    -- Function to setup points
    local function setupPoints(points, setupFunction)
        if points then
            for k, v in pairs(points) do
                if setupFunction then
                    setupFunction(v, k)
                else
                    print("Error: setupFunction is nil")
                end
            end
        else
            print("Error: points is nil")
        end
    end

    -- Function to initialize vehicle
    local function initializeVehicle()
        local vehicle = GetVehiclePedIsIn(cache.ped)
        local isturbostarted = GetResourceState('renzu_turbo') == 'started'
        if isturbostarted then
         turboconfig = exports.renzu_turbo:turbos()
        end
        if vehicle and GetPedInVehicleSeat(vehicle, -1) == cache.ped then
            if config.sandboxmode then
                Sandbox(vehicle)
            else
                OnVehicle(vehicle)
            end
        end
    end

    -- Main loop
    local function mainLoop()
        -- Setup upgrade points
        if config.enablemarkers then
            setupPoints(config.points, SetupUpgradePoints)
        end

        -- Wait for 2 seconds
        Wait(2000)

        -- Setup dyno points
        setupPoints(config.dynopoints, SetupDynoPoints)

        -- Wait for 1 second
        Wait(1000)

        -- Setup repair points
        if config.enablemarkers then
            setupPoints(config.repairpoints, SetupRepairPoints)
        end

        -- Wait for 1 second
        Wait(1000)

        -- Initialize vehicle
        initializeVehicle()
    end

    -- Run the main loop in a loop with error handling
    while true do
        pcall(mainLoop)
        Wait(1000)
    end
end)