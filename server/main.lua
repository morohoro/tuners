local QBCore = exports['qb-core']:GetCoreObject()

local defaulthandling = {}
local controller = {}
local vehicleupgrades = {}
local vehicletires = {}
local mileages = {}
local drivetrain = {}
local advancedflags = {}
local ecu = {}
local currentengine = {}
local nodegrade = {}
local dyno_net = {}
local ramp = {}
local db = sql()

local function SpawnDyno(index)
    if config.useMlo then return end
    local rampmodel = config.dynoprop

    for k, v in ipairs(config.dynopoints) do
        local object = CreateObjectNoOffset(rampmodel, v.platform.x, v.platform.y, v.platform.z-1.2, true, true)
        
        local timeoutCounter = 0
        while not DoesEntityExist(object) and timeoutCounter < 100 do
            Wait(1)
            timeoutCounter = timeoutCounter + 1
        end
        if timeoutCounter >= 100 then
            print("Failed to create dyno object")
            return
        end

        SetEntityRoutingBucket(object, config.routingbucket)
        Wait(100)
        FreezeEntityPosition(object, true)
        SetEntityHeading(object, v.platform.w)
        dyno_net[k] = NetworkGetNetworkIdFromEntity(object)
        ramp[k] = object
        Wait(100)
        Entity(object).state:set('ramp', {ts = os.time(), heading = v.platform.w}, true)
    end
end

QBCore.Functions.CreateCallback('renzu_tuners:CheckDyno', function(source, cb, dynamometer, index)
    local dyno = not config.useMlo and NetworkGetEntityFromNetworkId(dyno_net[index])
    if not config.useMlo and (not DoesEntityExist(dyno) or not dynamometer) then
    SpawnDyno(index)
    cb(true)
else
    cb(true)
end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        for k,v in pairs(ramp) do
            if DoesEntityExist(v) then
                DeleteEntity(v)
            end
        end
    end
end)

CreateThread(SpawnDyno)

if config.sandboxmode then return end

QBCore.Functions.CreateCallback('renzu_tuners:vehiclestats', function(source, cb, plate)
    local stats = {[plate] = vehiclestats[plate] or {}}
    local tires = {[plate] = vehicletires[plate] or {}}
    local mileage = {[plate] = mileages[plate] or 0}
    local tune = {[plate] = ecu[plate]}
    cb(stats, tires, mileage, tune)
end)

CreateThread(function()
    Wait(2000)
    local cache = db.fetchAll()
    local stats = {}
    for k,v in pairs(cache.vehiclestats or {}) do
        if isPlateOwned(k) then
            v.active = false
            stats[k] = v
        end
    end
	
	vehiclestats = stats

	vehicletires = cache.vehicletires or {}

	defaulthandling = cache.defaulthandling or {}

	vehicleupgrades = cache.vehicleupgrades or {}

	mileages = cache.mileages or {}

	drivetrain = cache.drivetrain or {}

	advancedflags = cache.advancedflags or {}

	GlobalState.ecu = cache.ecu or {}
	ecu = cache.ecu or {}

	currentengine = cache.currentengine or {}

    local vehicles = GetAllVehicles()
    for k,v in pairs(vehicles) do
		Wait(0)
		if DoesEntityExist(v) and GetEntityPopulationType(v) == 7 then
			local plate = string.gsub(GetVehicleNumberPlateText(v), '^%s*(.-)%s*$', '%1'):upper()
			if isPlateOwned(plate) or config.debug then
				if not vehiclestats[plate] then vehiclestats[plate] = {} end
				local ent = Entity(v).state
				vehiclestats[plate].active = true
				vehiclestats[plate].plate = plate
				for k,v2 in pairs(config.engineparts) do
					Wait(100)
					ent:set(v2.item, tonumber(vehiclestats[plate][v2.item] or 100), true)
				end
				if ent.defaulthandling then
					defaulthandling[plate] = ent.defaulthandling
				end
				if mileages[plate] and DoesEntityExist(v) then
					local ent = Entity(v).state
					ent:set('mileage', tonumber(mileages[plate]), true)
				end
			end
		end
    end
    while true do
        Wait(60000)
		for k,v in pairs(defaulthandling) do
			if not isPlateOwned(k) and not config.debug then
				defaulthandling[k] = nil
			end
		end
		local datas = {
			vehiclestats = vehiclestats,
			defaulthandling = defaulthandling,
			vehicleupgrades = vehicleupgrades,
			mileages = mileages
		}
		GlobalState.mileages = mileages
		db.saveall(datas)
    end
end)

CurrentEngine = function(value,bagName)
	if not value then return end
    local net = tonumber(bagName:gsub('entity:', ''), 10)
	local vehicle = NetworkGetEntityFromNetworkId(net)
	local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
	if DoesEntityExist(vehicle) and isPlateOwned(plate) or config.debug then
		currentengine[plate] = value
		db.save('currentengine','plate',plate,value)
	end
end

AddStateBagChangeHandler('currentengine' --[[key filter]], nil --[[bag filter]], function(bagName, key, value, _unused, replicated)
    Wait(0)
    CurrentEngine(value,bagName)
end)

AddStateBagChangeHandler('engine' --[[key filter]], nil --[[bag filter]], function(bagName, key, value, _unused, replicated)
    Wait(0)
    CurrentEngine(value,bagName)
end)

AddStateBagChangeHandler('drivetrain' --[[key filter]], nil --[[bag filter]], function(bagName, key, value, _unused, replicated)
    Wait(0)
    if not value then return end
    local net = tonumber(bagName:gsub('entity:', ''), 10)
	local vehicle = NetworkGetEntityFromNetworkId(net)
	if DoesEntityExist(vehicle) then
		local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
		drivetrain[plate] = value
		db.save('drivetrain','plate',plate,value)
	end
end)

AddStateBagChangeHandler('advancedflags' --[[key filter]], '' --[[bag filter]], function(bagName, key, value, _unused, replicated)
	Wait(0)
	if not value then return end
	local net = tonumber(bagName:gsub('entity:', ''), 10)
	local vehicle = NetworkGetEntityFromNetworkId(net)
	if DoesEntityExist(vehicle) then
		local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
		advancedflags[plate] = advancedflags[plate] or {} -- Initialize with an empty table if it's nil
		advancedflags[plate] = value
		db.save('advancedflags','plate',plate,json.encode(advancedflags[plate]))
	end
end)

AddStateBagChangeHandler('mileage' --[[key filter]], '' --[[bag filter]], function(bagName, key, value, _unused, replicated)
    Wait(0)
    if not value then return end
    local net = tonumber(bagName:gsub('entity:', ''), 10)
	local vehicle = NetworkGetEntityFromNetworkId(net)
	if DoesEntityExist(vehicle) then
		local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
		if isPlateOwned(plate) or config.debug then
			mileages[plate] = value
			vehiclestats[plate].active = true
		end
	end
end)

if not config.engineparts then
    config.engineparts = {}
end
for k,v in pairs(config.engineparts) do
	local name = v.item
	AddStateBagChangeHandler(name --[[key filter]], '' --[[bag filter]], function(bagName, key, value, _unused, replicated)
		Wait(0)
		if not value then return end
		local net = tonumber(bagName:gsub('entity:', ''), 10)
		local vehicle = NetworkGetEntityFromNetworkId(net)
		if DoesEntityExist(vehicle) then
			local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
			if isPlateOwned(plate) or config.debug then
				if not vehiclestats[plate] then vehiclestats[plate] = {} end
				vehiclestats[plate][name] = value
				vehiclestats[plate].plate = plate
				vehiclestats[plate].active = true
			end
		end
	end)
end

if not config.engineupgrades then
	config.engineupgrades = {}
end

for k,v in pairs(config.engineupgrades) do
	local name = v.item
	AddStateBagChangeHandler(name --[[key filter]], '' --[[bag filter]], function(bagName, key, value, _unused, replicated)
		Wait(0)
		if value == nil then return end
		local net = tonumber(bagName:gsub('entity:', ''), 10)
		local vehicle = NetworkGetEntityFromNetworkId(net)
		if DoesEntityExist(vehicle) then
			local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
			if not isPlateOwned(plate) and not config.debug then return end
			if not vehicleupgrades[plate] then vehicleupgrades[plate] = {} end
			vehicleupgrades[plate][name] = value
			db.save('vehicleupgrades','plate',plate,json.encode(vehicleupgrades[plate]))
		end
	end)
end

AddStateBagChangeHandler('defaulthandling' --[[key filter]], '' --[[bag filter]], function(bagName, key, value, _unused, replicated)
	Wait(0)
	if not value then return end
	local net = tonumber(bagName:gsub('entity:', ''), 10)
	local vehicle = NetworkGetEntityFromNetworkId(net)
	if DoesEntityExist(vehicle) then
		local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
		if isPlateOwned(plate) or config.debug then
			if not vehiclestats[plate] then vehiclestats[plate] = {} end
			defaulthandling[plate] = value
			vehiclestats[plate].active = true
		end
	end
end)

AddStateBagChangeHandler('tires' --[[key filter]], '' --[[bag filter]], function(bagName, key, value, _unused, replicated)
	Wait(0)
	if not value then return end
	local net = tonumber(bagName:gsub('entity:', ''), 10)
	local vehicle = NetworkGetEntityFromNetworkId(net)
	local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
	if DoesEntityExist(vehicle) and isPlateOwned(plate) or config.debug then
		vehicletires[plate] = value
		--db.save('vehicletires','plate',plate,json.encode(vehicletires[plate]))
		vehiclestats[plate].active = true
	end
end)

QBCore.Functions.CreateCallback('renzu_tuners:Tune', function(source, data)
    local entity = NetworkGetEntityFromNetworkId(data.vehicle)
    local plate = string.gsub(GetVehicleNumberPlateText(entity), '^%s*(.-)%s*$', '%1'):upper()
    local state = Entity(entity).state
    data.tune.profile = data.profile
    state:set('ecu', data.tune)
    local tune = GlobalState.ecu
    if not tune[plate] then tune[plate] = {} end
    tune[plate][data.profile] = data.tune
    tune[plate]['active'] = data.tune
    GlobalState.ecu = tune
    if not isPlateOwned(plate) and not config.debug then return end
    db.save('ecu','plate',plate,json.encode(tune[plate]))
    ecu = tune
    vehiclestats[plate].active = true
end)

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

GetItemCosts = function(item)
	local cost = 25000 -- default if item not found
	for k,v in pairs(itemsData) do
		if v.item == item then
			cost = v.cost
			break
		end
	end
	return cost
end

QBCore.Functions.CreateCallback('renzu_tuners:checkitem', function(source, item, isShop, required)
    local hasItems = false
    local xPlayer = QBCore.Functions.GetPlayer(source)

    if not config.purchasableUpgrade then
        local itemState = GetItemState(item)
        local items = xPlayer.Functions.GetItemByName(itemState)

        if items then
            for _, v in pairs(items) do
                if v.info and v.info.upgrade == item then
                    xPlayer.Functions.RemoveItem(v.name, 1, v.info)
                    hasItems = true
                    break
                elseif not v.info then
                    xPlayer.Functions.RemoveItem(v.name, 1)
                    hasItems = true
                    break
                end
            end
        end
    elseif config.jobmanagemoney and config.job[xPlayer.PlayerData.job.name] then
        local cost = GetItemCosts(item)
        local money = xPlayer.PlayerData.job.grade.level * config.job[xPlayer.PlayerData.job.name].grade[xPlayer.PlayerData.job.grade.level].salary

        if money >= cost then
            xPlayer.Functions.RemoveMoney('job', cost)
            hasItems = true
        end
    elseif config.purchasableUpgrade then
        local cost = GetItemCosts(item)
        local money = xPlayer.PlayerData.money.cash

        if money >= cost then
            xPlayer.Functions.RemoveMoney('cash', cost)
            hasItems = true
        end
    end

    return hasItems
end)

QBCore.Functions.CreateCallback('renzu_tuners:OldEngine', function(src, name, engine, plate, net)
    local metadata = {}
    local xPlayer = QBCore.Functions.GetPlayer(src)
    local vehicle = NetworkGetEntityFromNetworkId(net)
    local ent = Entity(vehicle).state

    if vehicleupgrades[plate] then
        for k, v in pairs(vehicleupgrades[plate]) do
            for _, upgrade in pairs(config.engineupgrades) do
                if upgrade.item == k then
                    table.insert(metadata, {part = k, durability = ent[upgrade.state]})
                    break
                end
            end
        end
    end

    metadata.description = table.concat(metadata, ', ')
    metadata.label = name
    metadata.image = 'engine'
    metadata.engine = engine

    xPlayer.Functions.AddItem('enginegago', 1, metadata)

    if vehicleupgrades[plate] then
        for k, _ in pairs(vehicleupgrades[plate]) do
            ent:SetState(k, false)
        end
    end
end)

QBCore.Functions.CreateCallback('renzu_tuners:GetEngineStorage', function(src, stash)
    return QBCore.Functions.GetPlayer(src).Functions.GetItemByName(stash, 'enginegago')
end)

QBCore.Functions.CreateCallback('renzu_tuners:RemoveEngineStorage', function(src, data)
    QBCore.Functions.GetPlayer(src).Functions.RemoveItem(data.name, 1, data.info)
end)

QBCore.Functions.CreateCallback('renzu_tuners:Craft', function(src, slots, requiredItems, item, engine)
    local success = true
    local xPlayer = QBCore.Functions.GetPlayer(src)

    for _, slot in pairs(slots) do
        if not QBCore.Functions.GetPlayer(src).Functions.RemoveItem(slot.name, requiredItems[slot.name], slot.info) then
            success = false
            break
        end
    end

    if success then
        local metadata = {}

        if engine then
            metadata.label = engine.label
            metadata.description = engine.label .. ' Engine Swap'
            metadata.engine = engine.name
            metadata.image = 'engine'
        end

		local config = {}
        config.metadata = true
        if config.metadata then
            if item.type == 'upgrade' and item.name ~= 'repairparts' then
                metadata.label = item.label
                metadata.description = item.label .. ' Engine Parts'
                metadata.upgrade = item.name
                metadata.image = item.name
            elseif item.name == 'repairparts' then
                metadata.label = 'Repair Engine Parts Kit'
                metadata.description = ' Restore Parts Durability to 100%'
                metadata.upgrade = item.name
                metadata.image = item.name
                metadata.durability = 100
            end
        elseif item.name == 'repairparts' then
            metadata.label = 'Repair Engine Parts Kit'
            metadata.description = ' Restore Parts Durability to 100%'
            metadata.upgrade = item.name
            metadata.image = item.name
            metadata.durability = 100
        end

        xPlayer.Functions.AddItem(item.name, 1, metadata)
    end

    return success
end)

QBCore.Functions.CreateCallback('renzu_tuners:RepairPart', function(source, percent, noMetadata)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    local items = xPlayer.Functions.GetItemByName('repairparts')
    local hasItem = false

    if items then
        for _, item in pairs(items) do
            if item.info.durability == nil then
                item.info.durability = 100
            end

            if item.info.durability and item.info.durability >= percent then
                local newDurability = item.info.durability - percent
                item.info.durability = newDurability

                if newDurability <= 0 then
                    xPlayer.Functions.RemoveItem('repairparts', 1, item.info)
                else
                    xPlayer.Functions.SetInfo('repairparts', item.slot, item.info)
                end

                return newDurability
            end

            hasItem = true
        end

        if not hasItem then
            return 'item'
        end
    end

    if noMetadata then
        xPlayer.Functions.RemoveItem('repairparts', 1)
    end

    return noMetadata or false
end)

SetTunerData = function(entity)
	if DoesEntityExist(entity) and GetEntityType(entity) == 2 and GetEntityPopulationType(entity) >= 6 then
    	local plate = string.gsub(GetVehicleNumberPlateText(entity), '^%s*(.-)%s*$', '%1'):upper()
		local ent = Entity(entity).state
		if vehiclestats[plate] then
			for k,v in pairs(vehiclestats[plate]) do
				ent:set(k,tonumber(v),true)
			end
			vehiclestats[plate].active = true
			vehiclestats[plate].plate = plate
		end
		if vehicleupgrades[plate] then
			for k,v in pairs(vehicleupgrades[plate]) do
				ent:set(k,v,true)
			end
		end
		if vehicletires[plate] then
			ent:set('tires',vehicletires[plate],true)
		end
		if defaulthandling[plate] then
			ent:set('defaulthandling',defaulthandling[plate],true)
		end
		if drivetrain[plate] then
			ent:set('drivetrain',drivetrain[plate],true)
		end
		if advancedflags[plate] then
			ent:set('advancedflags',advancedflags[plate],true)
		end
	end
end

isPlateOwned = function(plate)
    if not config.nosaveplate then
        config.nosaveplate = {}
    end
    for temp_plate,_ in pairs(config.nosaveplate) do
        if string.find(plate,temp_plate) == 1 then
            return false
        end
    end
    return true
end

AddStateBagChangeHandler('VehicleProperties' --[[key filter]], '' --[[bag filter]], function(bagName, key, value, _unused, replicated)
	Wait(0)
	local net = tonumber(bagName:gsub('entity:', ''), 10)
	if not value then return end
    local entity = NetworkGetEntityFromNetworkId(net)
    Wait(3000)
    if DoesEntityExist(entity) then
        SetTunerData(entity) -- compatibility with ESX onesync server setter vehicle spawn
    end
end)

AddEventHandler('entityCreated', function(entity)
	local entity = entity
	Wait(3000)
	SetTunerData(entity)
end)

AddEventHandler('entityRemoved', function(entity)
	local entity = entity
	if DoesEntityExist(entity) and GetEntityType(entity) == 2 and GetEntityPopulationType(entity) == 7 then
		local plate = string.gsub(GetVehicleNumberPlateText(entity), '^%s*(.-)%s*$', '%1'):upper()
		if vehiclestats[plate] and vehiclestats[plate].active then
			vehiclestats[plate].plate = nil
		end
	end
end)

RegisterNetEvent('qb-mechanicjob:server:stash', function(data)
    for k, v in pairs(config.engineswapper.coords) do
        local stashName = 'engine_storage:' .. k
        local stashLabel = 'Engine Storage'
        local stashCoords = v -- assuming v contains the stash coordinates
        local maxWeight = 1000000 -- adjust this value according to your needs
        local slots = 70 -- adjust this value according to your needs
        RegisterStash(stashName, stashLabel, slots, maxWeight, false, config.job)
    end
end)

QBCore.Commands.Add('sandboxmode', {
    description = 'Enable Developer mode Tuning and Disable Engine Degration',
    parameters = {},
    permissions = 'admin'
}, function(source, args)
    TriggerClientEvent('renzu_tuners:SandBoxmode', source)
end)
