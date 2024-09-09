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

while not QBCore do
    Citizen.Wait(0)
end

function setupNUIHandlers()
    -- Add NUI message handlers
    local function addEventHandler(eventName, handler)
        local success, error = pcall(AddEventHandler, eventName, handler)
        if not success then
            print("Error adding event handler for " .. eventName .. ": " .. error)
        end
    end

    addEventHandler('DynoTest:StartDynoTest', function()
        -- Handle start dyno test event
    end)

    addEventHandler('DynoTest:StopDynoTest', function()
        -- Handle stop dyno test event
    end)

    addEventHandler('DynoTest:GetDynoResults', function()
        -- Handle get dyno results event
    end)
end

local function registerEvents()
    -- Register server-side event handlers
    RegisterServerEvent('renzu_tuners:CheckDyno')
    AddEventHandler('renzu_tuners:CheckDyno', function(source, dynoprop, index)
        -- Server-side logic to check if the dyno is available
        local candyno = true -- Replace with actual logic
        TriggerClientEvent('renzu_tuners:CheckDynoResponse', source, candyno)
    end)

    RegisterServerEvent('renzu_tuners:SetManualGears')
    AddEventHandler('renzu_tuners:SetManualGears', function(source, vehicle)
        -- Server-side logic to set manual gears for the vehicle
        -- Replace with actual logic
    end)

    RegisterServerEvent('renzu_tuners:SpawnDyno')
    AddEventHandler('renzu_tuners:SpawnDyno', function(source, index)
        SpawnDyno(index)
    end)

    -- Add event listeners for dyno test started and stopped
    RegisterServerEvent('renzu_tuners:dynoTestStarted')
    AddEventHandler('renzu_tuners:dynoTestStarted', function(vehicle, testId)
        -- Call the StartDynoTest function
        local dynoTest = DynoTest.StartDynoTest(vehicle)
        -- ... other logic ...
    end)

    RegisterServerEvent('renzu_tuners:dynoTestStopped')
    AddEventHandler('renzu_tuners:dynoTestStopped', function(testId)
        -- Call the StopDynoTest function
        local results = DynoTest.StopDynoTest(testId)
        -- ... other logic ...
    end)
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        setupNUIHandlers()
        registerEvents()
    end
end)

registerEvents()

lib.callback.register('renzu_tuners:CheckDyno', function(src,dynamometer,index)
	local dyno = not config.useMlo and NetworkGetEntityFromNetworkId(dyno_net[index])
	if not config.useMlo and not DoesEntityExist(dyno) or not config.useMlo and not dynamometer then
		SpawnDyno(index)
		return true
	end
	return true
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

CreateThread(function()
    if config.sandboxmode then return end

    -- Register callback to send specific vehicle data to client
    lib.callback.register('renzu_tuners:vehiclestats', function(src, plate)
        local stats = {[plate] = vehiclestats[plate] or {}}
        local tires = {[plate] = vehicletires[plate] or {}}
        local mileage = {[plate] = mileages[plate] or 0}
        local tune = {[plate] = ecu[plate]}
        return stats, tires, mileage, tune
    end)

    CreateThread(function()
        Wait(2000)

        -- Fetch data from database using sql.lua
        local cache = exports.sql:getAllVehicleData()

        -- Initialize tables
        local stats = {}
        local vehicletires = {}
        local mileages = {}
        local drivetrain = {}
        local advancedflags = {}
        local ecu = {}
        local nodegrade = {}
        local currentengine = {}

        -- Populate tables with data from database
        for k, v in pairs(cache.vehiclestats or {}) do
            if isPlateOwned(k) then
                v.active = false
                stats[k] = v
            end
        end
      local  vehiclestats = stats

        vehicletires = cache.vehicletires or {}

        defaulthandling = cache.defaulthandling or {}

        vehicleupgrades = cache.vehicleupgrades or {}

        mileages = cache.mileages or {}

        drivetrain = cache.drivetrain or {}

        advancedflags = cache.advancedflags or {}

        GlobalState.ecu = cache.ecu or {}
        ecu = cache.ecu or {}

        nodegrade = cache.nodegrade or {}

        GlobalState.NoDegradePlate = nodegrade or {}

        currentengine = cache.currentengine or {}
    end)
end)

CreateThread(function()
    while true do
        Wait(0)
        local vehicles = GetAllVehicles()
        for k, v in pairs(vehicles) do
            Wait(0)
            if DoesEntityExist(v) and GetEntityPopulationType(v) == 7 then
                local plate = string.gsub(GetVehicleNumberPlateText(v), '^%s*(.-)%s*$', '%1'):upper()
                if isPlateOwned(plate) or config.debug then
                    -- Fetch vehicle data from database using sql.lua
                    local vehicleData = exports.sql:getVehicleData(plate)

                    if vehicleData then
                        if not vehiclestats[plate] then vehiclestats[plate] = {} end
                        local ent = Entity(v).state
                        vehiclestats[plate].active = true
                        vehiclestats[plate].plate = plate

                        -- Update engine parts
                        for k, v2 in pairs(config.engineparts) do
                            Wait(100)
                            ent:set(v2.item, tonumber(vehiclestats[plate][v2.item] or 100), true)
                        end

                        -- Update default handling
                        if ent.defaulthandling then
                            defaulthandling[plate] = ent.defaulthandling
                        end

                        -- Update mileage
                        if mileages[plate] and DoesEntityExist(v) then
                            local ent = Entity(v).state
                            ent:set('mileage', tonumber(mileages[plate]), true)
                        end
                    end
                end
            end
        end

        -- Clean up default handling data
        Wait(20000)
        for k, v in pairs(defaulthandling) do
            if not isPlateOwned(k) and not config.debug then
                defaulthandling[k] = nil
            end
        end

        -- Update global mileage state
        GlobalState.mileages = mileages
    end
end)

CurrentEngine = function(value, bagName)
    if not value then return end
    local net = tonumber(bagName:gsub('entity:', '', 10))
    local vehicle = NetworkGetEntityFromNetworkId(net)
    local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
    if DoesEntityExist(vehicle) and isPlateOwned(plate) or config.debug then
        currentengine[plate] = value
        -- Save current engine data to database using sql.lua
        exports.sql:updateCurrentEngine(plate, value)
    end
end

AddStateBagChangeHandler('currentengine', nil, function(bagName, key, value, _unused, replicated)
    Wait(0)
    CurrentEngine(value, bagName)
end)

AddStateBagChangeHandler('engine', nil, function(bagName, key, value, _unused, replicated)
    Wait(0)
    CurrentEngine(value, bagName)
end)

AddStateBagChangeHandler('drivetrain', nil, function(bagName, key, value, _unused, replicated)
    Wait(0)
    if not value then return end
    local net = tonumber(bagName:gsub('entity:', ''), 10)
    local vehicle = NetworkGetEntityFromNetworkId(net)
    if DoesEntityExist(vehicle) then
        local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
        drivetrain[plate] = value
        -- Save drivetrain data to database using sql.lua
        exports.sql:updateDrivetrain(plate, value)
    end
end)

AddStateBagChangeHandler('advancedflags', nil, function(bagName, key, value, _unused, replicated)
    Wait(0)
    if not value then return end
    local net = tonumber(bagName:gsub('entity:', ''), 10)
    local vehicle = NetworkGetEntityFromNetworkId(net)
    if DoesEntityExist(vehicle) then
        local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
        advancedflags[plate] = value
        -- Save advanced flags data to database using sql.lua
        exports.sql:updateAdvancedFlags(plate, json.encode(value))
    end
end)

AddStateBagChangeHandler('mileage', nil, function(bagName, key, value, _unused, replicated)
    Wait(0)
    if not value then return end
    local net = tonumber(bagName:gsub('entity:', ''), 10)
    local vehicle = NetworkGetEntityFromNetworkId(net)
    if DoesEntityExist(vehicle) then
        local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
        if isPlateOwned(plate) or config.debug then
            mileages[plate] = value
            vehiclestats[plate].active = true
            -- Save mileage data to database using sql.lua
            exports.sql:updateMileage(plate, value)
        end
    end
end)

for k, v in pairs(config.engineparts) do
    local name = v.item
    AddStateBagChangeHandler(name, nil, function(bagName, key, value, _unused, replicated)
        Wait(0)
        if not value then return end
        local net = tonumber(bagName:gsub('entity:', '', 10))
        local vehicle = NetworkGetEntityFromNetworkId(net)
        if DoesEntityExist(vehicle) then
            local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
            if isPlateOwned(plate) or config.debug then
                if not vehiclestats[plate] then vehiclestats[plate] = {} end
                vehiclestats[plate][name] = value
                vehiclestats[plate].plate = plate
                vehiclestats[plate].active = true
                -- Save vehicle stats data to database using sql.lua
                exports.sql:updateVehicleStats(plate, vehiclestats[plate])
            end
        end
    end)
end

for k, v in pairs(config.engineupgrades) do
    local name = v.item
    AddStateBagChangeHandler(name, nil, function(bagName, key, value, _unused, replicated)
        Wait(0)
        if value == nil then return end
        local net = tonumber(bagName:gsub('entity:', '', 10))
        local vehicle = NetworkGetEntityFromNetworkId(net)
        if DoesEntityExist(vehicle) then
            local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
            if not isPlateOwned(plate) and not config.debug then return end
            if not vehicleupgrades[plate] then vehicleupgrades[plate] = {} end
            vehicleupgrades[plate][name] = value
            -- Save vehicle upgrades data to database using sql.lua
            exports.sql:updateVehicleUpgrades(plate, json.encode(vehicleupgrades[plate]))
        end
    end)
end

AddStateBagChangeHandler('defaulthandling', nil, function(bagName, key, value, _unused, replicated)
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
            -- Save defaulthandling data to database using sql.lua
            exports.sql:updateDefaulthandling(plate, value)
        end
    end
end)

AddStateBagChangeHandler('tires', nil, function(bagName, key, value, _unused, replicated)
    Wait(0)
    if not value then return end
    local net = tonumber(bagName:gsub('entity:', ''), 10)
    local vehicle = NetworkGetEntityFromNetworkId(net)
    local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
    if DoesEntityExist(vehicle) and isPlateOwned(plate) or config.debug then
        vehicletires[plate] = value
        -- Save vehicletires data to database using sql.lua
        exports.sql:updateVehicletires(plate, json.encode(vehicletires[plate]))
        vehiclestats[plate].active = true
    end
end)

lib.callback.register('renzu_tuners:Tune', function(src, data)
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
    -- Save ecu data to database using sql.lua
    exports.sql:updateEcu(plate, json.encode(tune[plate]))
    ecu = tune
    vehiclestats[plate].active = true
end)

GetItemState = function(name)
    local state = name
    local upgrade = nil
    for k, v in pairs(config.engineupgrades) do
        if v.item == name and v.state then
            state = v.state
            upgrade = v.item
        end
    end
    return state, upgrade
end

GetItemCosts = function(item)
    local cost = 25000 -- default if item not found
    for k, v in pairs(itemsData) do
        if v.item == item then
            cost = v.cost
            break
        end
    end
    return cost
end

lib.callback.register('renzu_tuners:checkitem', function(src, item, isShop, required)
    local hasitems = false
    local amount = 1
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not config.purchasableUpgrade then
        local metadata = config.metadata
        local itemstate = GetItemState(item)
        local isItemMetadata = itemstate ~= item
        local name = metadata and isItemMetadata and itemstate or item
        local items = xPlayer.Functions.GetItemByName(name)
        if items then
            for k, v in pairs(items) do
                if metadata and isItemMetadata and v.info.upgrade == item or not isItemMetadata and not v.info.upgrade or not metadata then
                    xPlayer.Functions.RemoveItem(v.name, amount, v.slot)
                    hasitems = true
                end
            end
        end
    elseif config.jobmanagemoney and config.job[xPlayer.PlayerData.job.name] then
        local cost = GetItemCosts(item)
        local money = xPlayer.PlayerData.job.grade.level * config.job[xPlayer.PlayerData.job.name].salary
        if money >= cost then
            xPlayer.Functions.RemoveMoney('job', cost)
            hasitems = true
        end
    elseif config.purchasableUpgrade then
        local cost = GetItemCosts(item)
        local money = xPlayer.PlayerData.money.cash
        if money >= cost then
            xPlayer.Functions.RemoveMoney('cash', cost)
            hasitems = true
        end
    end
    return hasitems
end)

lib.callback.register('renzu_tuners:OldEngine', function(src, name, engine, plate, net)
    local metadata = {}
    local vehicle = NetworkGetEntityFromNetworkId(net)
    local ent = Entity(vehicle).state
    local data = {}
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if vehicleupgrades[plate] then
        for k, v in pairs(vehicleupgrades[plate]) do
            for k2, v2 in pairs(config.engineupgrades) do
                if v2.item == k then
                    table.insert(metadata, { part = k, durability = ent[v2.state] })
                end
            end
            table.insert(data, k:gsub('_', ' '):upper())
        end
    end
    metadata.description = table.concat(data, ', ')
    metadata.label = name
    metadata.image = 'engine'
    metadata.engine = engine
    xPlayer.Functions.AddItem('enginegago', 1, metadata)
    if vehicleupgrades[plate] then
        for k, v in pairs(vehicleupgrades[plate]) do
            ent:set(k, false, true)
        end
    end
end)

lib.callback.register('renzu_tuners:GetEngineStorage', function(src, stash)
    local xPlayer = QBCore.Functions.GetPlayer(src)
    return xPlayer.Functions.GetInventoryItemsBySlot(stash, 'slots', 'enginegago')
end)

lib.callback.register('renzu_tuners:RemoveEngineStorage', function(src, data)
    local xPlayer = QBCore.Functions.GetPlayer(src)
    xPlayer.Functions.RemoveItem(data.name, 1, data.metadata, data.slot)
end)

lib.callback.register('renzu_tuners:Craft', function(src, slots, requiredata, item, engine)
    local xPlayer = QBCore.Functions.GetPlayer(src)
    local success = false
    local reward = item.name
    local hasitems = true
    for slot, data in pairs(slots) do
        hasitems = xPlayer.Functions.RemoveItem(data.name, requiredata[data.name], data.metadata)
        if not hasitems then break end
    end
    if hasitems then
        if chance and math.random(1, 100) <= chance or not chance then
            success = true
            local metadata = nil
            if engine then
                metadata = { label = engine.label, description = engine.label .. ' Engine Swap', engine = engine.name, image = 'engine' }
                reward = 'enginegago'
            end
            if config.metadata then
                if item.type == 'upgrade' and item.name ~= 'repairparts' then
                    reward = item.state
                    metadata = { upgrade = item.name, label = item.label, description = item.label .. ' Engine Parts', image = item.name }
                end
                if item.name == 'repairparts' then
                    metadata = { durability = item.durability, upgrade = item.name, label = item.label, description = item.label .. ' \n  Restore Parts Durability ', image = item.name }
                end
            elseif item.name == 'repairparts' then
                metadata = { durability = 100, upgrade = item.name, label = 'Repair Engine Parts Kit', description = ' Restore Parts Durability to 100%', image = item.name }
            end
            xPlayer.Functions.AddItem(reward, 1, metadata)
        end
    end
    return success
end)

lib.callback.register('renzu_tuners:RepairPart', function(src, percent, noMetadata)
    local src = src
    local xPlayer = QBCore.Functions.GetPlayer(src)
    local items = xPlayer.Functions.GetInventoryItemsBySlot('slots', 'repairparts')
    local hasitem = false

    if items then
        for k, v in pairs(items) do
            if v.metadata.durability == nil then
                v.metadata.durability = 100
            end

            local function getDurability(metadata)
                return metadata and metadata.durability or 0
            end

            if getDurability(v.metadata) >= percent then
                local newvalue = getDurability(v.metadata) - percent
                SetDurability(src, newvalue, v.slot, v.metadata, v.name)
                if newvalue <= 0 then
                    xPlayer.Functions.RemoveItem('repairparts', 1, v.metadata, v.slot)
                end
                return newvalue
            end
            hasitem = true
        end
    end

    if not hasitem then
        return 'item'
    end

    if noMetadata then
        xPlayer.Functions.RemoveItem('repairparts', 1)
    end

    return noMetadata ~= nil and noMetadata or false
end)

function SetDurability(src, durability, slot, metadata, name)
    local xPlayer = QBCore.Functions.GetPlayer(src)
    local vehicle = xPlayer.PlayerData.lastVehicle
    if vehicle then
        local vehicleData = QBCore.Functions.GetVehicleProperties(vehicle)
        if vehicleData then
            vehicleData.bodyHealth = durability
            vehicleData.engineHealth = durability
            vehicleData.fuelLevel = vehicleData.fuelLevel
            vehicleData.bodyDamage = {}
            vehicleData.engineDamage = {}
            TriggerClientEvent('QBCore:Client:SetVehicleProperties', src, vehicle, vehicleData)
        end
    end
end

SetTunerData = function(entity)
    if DoesEntityExist(entity) and GetEntityType(entity) == 2 and GetEntityPopulationType(entity) >= 6 then
        local plate = string.gsub(GetVehicleNumberPlateText(entity), '^%s*(.-)%s*$', '%1'):upper()
        local xPlayer = QBCore.Functions.GetPlayer(GetPlayerPed(-1))
        local vehicle = xPlayer.PlayerData.lastVehicle
        local vehicleData = QBCore.Functions.GetVehicleProperties(vehicle)
        if vehiclestats[plate] then
            for k, v in pairs(vehiclestats[plate]) do
                vehicleData[k] = tonumber(v)
            end
            vehiclestats[plate].active = true
            vehiclestats[plate].plate = plate
        end
        if vehicleupgrades[plate] then
            for k, v in pairs(vehicleupgrades[plate]) do
                vehicleData[k] = v
            end
        end
        if vehicletires[plate] then
            vehicleData.tires = vehicletires[plate]
        end
        if defaulthandling[plate] then
            vehicleData.defaulthandling = defaulthandling[plate]
        end
        if drivetrain[plate] then
            vehicleData.drivetrain = drivetrain[plate]
        end
        if advancedflags[plate] then
            vehicleData.advancedflags = advancedflags[plate]
        end
        TriggerClientEvent('QBCore:Client:SetVehicleProperties', GetPlayerPed(-1), vehicle, vehicleData)
    end
end

GetVehiclePlate = function(plate)
    local result = exports.ghmattimysql:scalarSync("SELECT 1 FROM owned_vehicles WHERE plate = @plate", { ['@plate'] = plate })
    return result ~= nil
end

IsPlateInNosave = function(plate)
    for temp_plate,_ in pairs(config.nosaveplate) do
        if string.find(plate,temp_plate) == 1 then
            return true
        end
    end
    return false
end


AddStateBagChangeHandler('VehicleProperties' --[[key filter]], nil --[[bag filter]], function(bagName, key, value, _unused, replicated)
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
			vehiclestats[plate].active = nil
			local vehicle = MySQL.query.await('SELECT plate FROM `'..vehicle_table..'` WHERE `plate` = ?', {plate})
			if vehicle and vehicle[1].plate then
				db.updateall({
					vehiclestats = json.encode(vehiclestats[plate] or {}),
					defaulthandling = json.encode(defaulthandling[plate] or {}),
					vehicleupgrades = json.encode(vehicleupgrades[plate] or {}),
					mileages = tonumber(mileages[plate]) or 0,
				},plate)
			end
		end
	end
end)


lib.addCommand('sandboxmode', {
    help = 'Enable Developer mode Tuning and Disable Engine Degration',
    params = {},
    restricted = 'group.admin'
}, function(source, args, raw)
    TriggerClientEvent('renzu_tuners:SandBoxmode',source)
end)

lib.addCommand('nodegrade', {
    help = 'Disable Degration to Current vehicle (you need to be in the vehicle)',
	params = {},
	restricted = 'group.admin'
}, function(source, args, raw)

	local vehicle = GetVehiclePedIsIn(GetPlayerPed(source))

	if not DoesEntityExist(vehicle) then 
		lib.notify(source, {
			description = 'You need to be in the vehicle', 
			type = 'error'
		})
		return 
	end

	local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()

	db.save('nodegrade','plate',plate,1)

	nodegrade[plate] = 1

	GlobalState.NoDegradePlate = nodegrade

	lib.notify(source, {
		description = 'Successfully Added this vehicle to No Degration mode', 
		type = 'success'
	})
end)