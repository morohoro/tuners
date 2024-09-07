local QBCore = exports['qb-core']:GetCoreObject()

lib.onCache('vehicle', function(value)
	if config.sandboxmode then
		Sandbox(value)
	else
		return OnVehicle(value)
	end
end)

OnVehicle = function(value)
	local invehicle = value

	if not DoesEntityExist(value) then return end

	local isdriver = GetPedInVehicleSeat(value, -1) == cache.ped
	if not isdriver then return end

	local plate = string.gsub(GetVehicleNumberPlateText(value), '^%s*(.-)%s*$', '%1'):upper()
	local state = GetVehicleServerStates(plate)
	if not DoesEntityExist(value) then return end

	local coord = GetEntityCoords(value)
	local lastcoord = nil
	local ent = value and Entity(value).state
	local turbo = ent.turbo and ent.turbo.turbo
	local ecu_state = ecu
	local turbopower = 1.0
	local turboinstall = GetResourceState('renzu_turbo') == 'started'

	if value then
		DefaultSetting(value)
		LoadVehicleSetup(value, ent, vehiclestats)
		QBCore.Functions.SetVehicleProperty('vehicle_loaded', true, true)

		Citizen.CreateThreadNow(function()
			local lockspeed = 0
			local driveforce = GetVehicleHandlingFloat(value, 'CHandlingData', 'fInitialDriveForce')
			local hasracingcam = ent['racing_camshaft']
		end)
	end
end

Citizen.CreateThreadNow(function()
	if not config.enableDegration then return end
	local tune = GetTuningData(plate)
	local upgraded = {}
	for k,v in pairs(config.engineupgrades) do
		if ent and ent[v.item] then
			upgraded[v.state] = true
		end
	end
	local synctimer = 0
	while invehicle do
		local ent = ent
		local sleep = ent.nitroenable and 200 or 3000
		local rpm = GetVehicleCurrentRpm(value)
		if rpm > 0.5 then
			local mileage = ent.mileage or 0
			local update = false
			local nitro = ent.nitroenable
			local turbodeduct = 1.0
			local nitrodeduct = 1.0
			local chance = nitro and 7 or 15
			if turbo then
				turbodeduct = turbopower
			end
			if nitro then
				nitrodeduct = turbopower
			end
			local chance_degrade = math.random(1,100) < (chance * ( 2.0 - efficiency))
			synctimer = synctimer + 1
			local resettimer = false
			for _,v2 in pairs(config.engineparts) do
				local stock = not upgraded[v2.item]
				for k,v in ipairs(config.degrade) do
					local mileage_degration = mileage >= v.min
					local candegrade = mileage_degration and chance_degrade
					for k,handlingname in pairs(v2.handling) do
						if candegrade or (tune[handlingname] or 1.0) > 1.0 and chance_degrade and mileage_degration or turbo and chance_degrade and mileage_degration or nitro and mileage_degration and chance_degrade then
							local efficiency_degrade = 1.0 + (1.0 - efficiency)
							local stock_degrade = stock and 1.5 or efficiency_degrade
							local upgraded_degrade = stock and 1.0 or (efficiency_degrade * 0.9)
							local degrade = ((((v.degrade * upgraded_degrade) * (turbodeduct * stock_degrade)) * (nitrodeduct * stock_degrade)) * (efficiency_degrade * stock_degrade) * rpm) or 1.0
							local value = ent[v2.item] and ent[v2.item] - degrade or vehiclestats[plate] and vehiclestats[plate][v2.item] and vehiclestats[plate][v2.item] - degrade or 100 - degrade
							QBCore.Functions.SetVehicleProperty(v2.item, value, synctimer > 20) -- set local state bag
							resettimer = true
							break
						end
					end
				end
			end
			if synctimer > 20 and resettimer then
				synctimer = 0
				resettimer = false
			end
		end
		Wait(sleep)
		if cache.vehicle ~= value then
			break
		end
	end
	-- on vehicle out
	for _,v2 in pairs(config.engineparts) do
		QBCore.Functions.SetVehicleProperty(v2.item, ent[v2.item] and ent[v2.item]+0.01, true) -- sync local state bag to server
	end
end)
