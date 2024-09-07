local QBCore = exports['qb-core']:GetCoreObject()

GetItemMod = function(name)
	for k,v in pairs(config.engineupgrades) do
		if v.item == name and v.mod then
			return v.mod
		end
	end
	return false
end

 ItemFunction = function(vehicle,data,menu)end -- item use handler
	if not vehicle then vehicle = GetClosestVehicle(GetEntityCoords(cache.ped), 10.0) end
	if menu then
		lib.progressCircle({
			duration = 2000,
			position = 'bottom',
			useWhileDead = false,
			canCancel = false,
			disable = {
				car = true,
				move = true,
			},
			anim = {
				dict = 'mini@repair',
				clip = 'fixing_a_player'
			},
		})
	end
	SetEntityControlable(vehicle)
	local item = data.name
	if config.metadata then
		item = data.metadata and data.metadata.upgrade or data.name
	end
	local ent = QBCore.Functions.GetVehicle
	local state, upgrade = GetItemState(item)
	local tires = GetTires(item)
	local drivetrain = GetDriveTrain(item)
	local extras = GetExtras(item)
	local isturbo = isTurbo(item)
	local isnitro = isNitro(item)
	local ECU = item == 'ecu'
	
	-- tires
	if tires then
		local tires_index = {}
		for i = 1 , GetVehicleNumberOfWheels(vehicle) do
			tires_index[i] = 100.0
		end
		QBCore.Functions.SetVehicleProperty(vehicle, 'tires', {type = tires, tirehealth = tires_index})
		QBCore.Functions.SetVehicleProperty(vehicle, 'drivetrain', drivetrain)
	elseif extras then
		SaveStateFlags(vehicle,ent,extras)
	elseif isturbo then
		QBCore.Functions.CreateCallback('renzu_turbo:AddTurbo', function(cb)
			-- handle cb
		end, {NetworkGetNetworkIdFromEntity(vehicle), item})
	elseif isnitro then
		QBCore.Functions.CreateCallback('renzu_nitro:AddNitro', function(cb)
			-- handle cb
		end, {NetworkGetNetworkIdFromEntity(vehicle), item})
	elseif data.engine then
		QBCore.Functions.CreateCallback('renzu_engine:EngineSwap', function(cb)
			-- handle cb
		end, {NetworkGetNetworkIdFromEntity(vehicle), item})
	elseif ECU then
		local boostpergear = {}
		for i = 1, GetVehicleHighGear(vehicle) do
			boostpergear[i] = 1.0
		end
		QBCore.Functions.CreateCallback('renzu_tuners:Tune', function(cb)
			-- handle cb
		end, {vehicle = NetworkGetNetworkIdFromEntity(vehicle) ,profile = 'Default', tune = {acceleration = 1.0, topspeed = 1.0, engineresponse = 1.0, gear_response = 1.0, boostpergear = boostpergear}})
		Wait(1000)
		local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
		local vehiclestats, vehicletires, mileages, ecu = QBCore.Functions.CreateCallback('renzu_tuners:vehiclestats', function(cb)
			-- handle cb
		end, 0, plate)
		-- Add tire upgrade logic here
		local tires_index = {}
		for i = 1 , GetVehicleNumberOfWheels(vehicle) do
			tires_index[i] = 100.0
		end
		QBCore.Functions.SetVehicleProperty(vehicle, 'tires', {type = 'upgraded', tirehealth = tires_index})
	else
		local oldval = ent[state]
		QBCore.Functions.SetVehicleProperty(vehicle, state, math.random(1,77))
		RemoveDuplicatePart(vehicle,state)
		if upgrade then
			QBCore.Functions.SetVehicleProperty(vehicle, upgrade, false)
		end
		while QBCore.Functions.GetVehicleProperty(vehicle, state) == oldval do Wait(1110) end
		Wait(1000)
		if upgrade then
			QBCore.Functions.SetVehicleProperty(vehicle, upgrade, true)
		end
		if state == 'engine_oil' then
			QBCore.Functions.SetVehicleProperty(vehicle, 'mileage', 0)
		end
	end
		
		local getmod = GetItemMod(item)
		if getmod then
			SetVehicleModKit(vehicle,0)
			local current = GetVehicleMod(vehicle,getmod.index)
			SetVehicleMod(vehicle,getmod.index,current+getmod.add,false)
		end
		QBCore.Functions.SetVehicleProperty(state,100,true)
		local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
		HandleEngineDegration = function(vehicle, state, plate)
			do
				SetVehicleModKit(vehicle,0)
				local current = GetVehicleMod(vehicle,getmod.index)
				SetVehicleMod(vehicle,getmod.index,current+getmod.add,false)
				end
				QBCore.Functions.SetVehicleProperty(state,100,true)
				plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
				HandleEngineDegration(vehicle, ent.state, plate)
	lib.notify({description = 'You Install '..data.label})
end
HandleEngineDegration = function(vehicle, state, plate)
	local ent = QBCore.Functions.GetVehicle(vehicle).state
end
HandleEngineDegration(vehicle, ent, plate)

GetItemState = function(name)
	local state = name
	local upgrade = nil
	for k,v in pairs(config.engineupgrades) do
		if v.item == name and v.state then
			state = v.state
			upgrade = v.item
		end
	end
	return state,upgrade
end