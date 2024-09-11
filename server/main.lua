local QBCore = exports['qb-core']:GetCoreObject()

local sql = exports['sql']
local oxmysql = exports['oxmysql']
local json = require('json')

-- Define the lib table only once
local lib = {}

-- Define the db object
local db = oxmysql

-- Initialize the db object
local db = {}

-- Function to get vehicle server states
local vehiclestats = {}
function GetVehicleServerStates(plate, cb)
    -- retrieve the vehicle server states from the server-side database or data storage
    local state = vehiclestats[plate] -- Assuming vehiclestats is the correct table to get the state from
    cb(state)
end

-- Ensure `lib.callback` is not nil before using it
    QBCore.Functions.CreateCallback('renzu_tuners:CheckDyno', function(source, cb, dynamometer, index)
        -- Your code here
    end)

    print('lib.callback is nil')

-- Define the saveall function
function db.saveall(data)
	-- Your code to save the data goes here
	print("Saving all data:", data)
	-- Example of how to call the save function from sql.lua
	oxmysql:execute("INSERT INTO all_data (data) VALUES (?)", {data})
end

-- Define the SpawnDyno function
lib.SpawnDyno = function(index)
	-- Your existing code goes here
	-- ...

	-- Call the saveall function to save the data
	db.saveall(vehiclestats)
end


local function errorHandler(err)
    print("Error: " .. err)
    -- Log the error using QB Core's logging system
    QBCore.Logger.error(err)
end

-- Wrap the entire script in a pcall block
pcall(function()
    -- Script code here
    -- ...
    -- Your script code goes here
    -- ...
end, errorHandler)

local defaulthandling = {}
local controller = { enabled = true, settings = {} }
local vehicleupgrades = {}
local vehicletires = {}
local mileages = {}
local drivetrain = {}
local advancedflags = {}
local ecu = {}
local currentengine = {}
local dyno_net = {}
local config = {} -- Assuming the config table is defined elsewhere
local rampmodel = config.dynoprop
local db = oxmysql

SpawnDyno = function(index)
    if config.useMlo then
        return
    end
    
    -- Ensure config and config.dynopoints are properly initialized
    config = config or {}  -- Initialize config if it is nil
    config.dynopoints = config.dynopoints or {}  -- Initialize config.dynopoints if it is nil

    -- Check if config.dynopoints is a table before iterating
    if config.dynopoints and type(config.dynopoints) == 'table' then
        for k, v in ipairs(config.dynopoints) do
			print(v)  -- Add some code here to fix the "Empty block" issue
		end
    else
        print("config.dynopoints is not defined or not a table")
        return -- Exit function if dynopoints is not a table
    end

    local rampmodel = config.dynoprop
    for k, v in ipairs(config.dynopoints) do
		-- Use the existing currentengine table
		currentengine = {}
		print(v)
	end
end
		-- Define the CurrentEngine function
		local function CurrentEngine(value, bagName)
			if not value then return end
			local net = tonumber(bagName:gsub('entity:', ''), 10)
			local vehicle = NetworkGetEntityFromNetworkId(net)
			local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
			if DoesEntityExist(vehicle) and QBCore.Functions.IsPlateTaken(plate) or config.debug then
				currentengine[plate] = value
				db.save('currentengine', 'plate', plate, value)
			end
		end
		
		-- Use QB-Core's built-in server event for updating vehicle data
		AddEventHandler('QBCore:Server:UpdateVehicle', function(vehicle, key, value)
			local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
		
			-- Update current engine
			if key == 'currentengine' then
				CurrentEngine(value, 'entity:' .. vehicle)
			-- Update drivetrain
			elseif key == 'drivetrain' then
				if DoesEntityExist(vehicle) then
					drivetrain[plate] = value
					db.save('drivetrain', 'plate', plate, value)
				end
			-- Update advanced flags
			elseif key == 'advancedflags' then
				if DoesEntityExist(vehicle) then
					advancedflags[plate] = value
					db.save('advancedflags', 'plate', plate, json.encode(advancedflags[plate]))
				end
			-- Update mileage
			elseif key == 'mileage' then
				if DoesEntityExist(vehicle) then
					local function isPlateOwned(plate)
						return QBCore.Functions.IsPlateTaken(plate)
					end
						mileages[plate] = value
						vehiclestats[plate].active = true
					end
				end
			end
		)

		local function createRamp(v)
			local rampmodel = config.dynoprop
			if v and v.platform then
				-- Check if the model is valid and loaded
				if not IsModelValid(rampmodel) then
					print("Invalid model: " .. tostring(rampmodel))
					return
				end
		
				RequestModel(rampmodel)
				while not HasModelLoaded(rampmodel) do
					Wait(10) -- Wait until the model is loaded
				end
		
				-- Create the object
				local object = CreateObject(GetHashKey(rampmodel), v.platform.x, v.platform.y, v.platform.z - 1.2, true, true)
		
				-- Check if the object was created successfully
				if DoesEntityExist(object) then
					SetEntityHeading(object, v.platform.heading or 0)
				else
					print("Error: Failed to create object")
				end
			else
				print("Error: 'v' or 'v.platform' is not defined")
			end
		end
		
		local v = {
			platform = {
				x = 10.0,
				y = 20.0,
				z = 30.0
			}
		}
		
		local rampmodel = config.dynoprop
		if not IsModelValid(rampmodel) then
			print("Invalid model: " .. tostring(rampmodel))
			return
		end
		
		createRamp(v)
		
		RequestModel(rampmodel)
		while not HasModelLoaded(rampmodel) do
			Wait(10) -- Wait until the model is loaded
		end
		
		local object = CreateObject(GetHashKey(rampmodel), v.platform.x, v.platform.y, v.platform.z - 1.2, true, true)
		if not object then
			print("Error creating ramp")
			return
		end
		
		createRamp(v)
		while not DoesEntityExist(object) do
			Wait(1)
		end
		
		SetEntityRoutingBucket(object, config.routingbucket)
		Wait(100)
		FreezeEntityPosition(object, true)
		SetEntityHeading(object, v.platform.heading or 0)
		local k = 1
		dyno_net[k] = NetworkGetNetworkIdFromEntity(object)
		local ramp = {} -- Declare and initialize the ramp table
		ramp[k] = object
		Wait(100)
		Entity(object).state:set('ramp', {ts = os.time(), heading = v.platform.heading or 0}, true)
    

	print('Registering callback...')
	QBCore.Functions.CreateCallback('renzu_tuners:CheckDyno', function(source, cb, dynamometer, index)
		-- Your callback logic here
	end)
	print('Callback registration check complete.')
			
	local source = ... -- assuming source is defined somewhere above
	local player = QBCore.Functions.GetPlayer(source)
	if player then
		local some_value = 1 -- replace 1 with the actual value you want to use
		local index = some_value
		local dynamometer = QBCore.Functions.GetDynamometer(source) -- Replace with the actual function to get the dynamometer
		local dyno = config.useMlo and 0 or (NetworkGetEntityFromNetworkId(dyno_net[index]) or 0)
		
		if not config.useMlo or not DoesEntityExist(dyno) or not dynamometer then
			local function spawnDyno(index)
				local dyno = (config.useMlo and 0) or (NetworkGetEntityFromNetworkId(dyno_net[index]) or 0)
				if not config.useMlo or not DoesEntityExist(dyno) or not dynamometer then
					SpawnDyno(index)
					return true
				end
			end
			spawnDyno(index)
			return true
		end
	else
		print("Error: Unable to get player from source " .. source)
	end
	
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
-- send specific vehicle data to client. normaly i do check globalstate data in client. but somehow its acting weird on live enviroments and data is not getting sync if server has been up for too long, this is only a work around in state bag issue when data is large.
QBCore.Functions.CreateCallback('renzu_tuners:vehiclestats', function(src, plate) -- only the efficient way to send data to client. normaly people will just fetch sql every time player goes into vehicle. which is not performant.
	local stats = {[plate] = vehiclestats[plate] or {}}
	local tires = {[plate] = vehicletires[plate] or {}}
	local mileage = {[plate] = mileages[plate] or 0}
	local tune = {[plate] = ecu[plate]}
	return stats, tires, mileage, tune
end)

CreateThread(function()
    Wait(2000)
    local cache = db.fetchAll()
    local stats = {}

    for k, v in pairs(cache.vehiclestats or {}) do
        if isPlateOwned(k) then
            v.active = false
            stats[k] = v
        end
    end

    vehiclestats = stats
    db.saveall({ vehiclestats = vehiclestats })
end)
	local vehiclestats = stats

	vehicletires = cache.vehicletires or {}

	defaulthandling = cache.defaulthandling or {}

	vehicleupgrades = cache.vehicleupgrades or {}

	mileages = cache.mileages or {}

	drivetrain = cache.drivetrain or {}

	advancedflags = cache.advancedflags or {}

	GlobalState.ecu = cache.ecu or {}
	ecu = cache.ecu or {}

	currentengine = cache.currentengine or {}
    
	local function isPlateOwned(plate)
		local vehicles = GetAllVehicles()
		if type(vehicles) ~= 'table' then
			error("GetAllVehicles() did not return a table")
		end
		for k,v in pairs(vehicles) do
			Wait(0)
			if DoesEntityExist(v) and GetEntityPopulationType(v) == 7 then
				local plate = string.gsub(GetVehicleNumberPlateText(v), '^%s*(.-)%s*$', '%1'):upper()
				if isPlateOwned(plate) or config.debug then
					if not vehiclestats[plate] then vehiclestats[plate] = {} end
					local ent = Entity(v).state
					vehiclestats[plate].active = true
					vehiclestats[plate].plate = plate
					-- ...
				end
			end
		end
	end 
					
						-- ...
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
					QBCore.Functions.SetVehicleProperty(v2.item, tonumber(vehiclestats[plate][v2.item] or 100), true)
				end
				if ent.defaulthandling then
					defaulthandling[plate] = ent.defaulthandling
				end
				if mileages[plate] and DoesEntityExist(v) then
					local vehicleData = {}
					local ent = Entity(v).state
					local mileageValue = next(mileages[plate])
					QBCore.Functions.SetVehicleProperty('mileage', tonumber(mileageValue[2]), true)
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

-- Define the CurrentEngine function
	local function CurrentEngine(value, bagName)
		if not value then return end
		local net = tonumber(bagName:gsub('entity:', ''), 10)
		local vehicle = NetworkGetEntityFromNetworkId(net)
		local ownedPlates = {}
		
		local function isPlateOwned(plate)
			return ownedPlates[plate] ~= nil
		end
		local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
		if DoesEntityExist(vehicle) and isPlateOwned(plate) or config.debug then
			currentengine[plate] = value
			db.save('currentengine', 'plate', plate, value)
		end
	end
	
	-- Use QB-Core's built-in server event for updating vehicle data
	AddEventHandler('QBCore:Server:UpdateVehicle', function(vehicle, key, value)
		local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
	
		-- Update current engine
		if key == 'currentengine' then
			CurrentEngine(value, 'entity:' .. vehicle)
		-- Update drivetrain
		elseif key == 'drivetrain' then
			if DoesEntityExist(vehicle) then
				drivetrain[plate] = value
				db.save('drivetrain', 'plate', plate, value)
			end
		-- Update advanced flags
		elseif key == 'advancedflags' then
			if DoesEntityExist(vehicle) then
				advancedflags[plate] = value
				db.save('advancedflags', 'plate', plate, json.encode(advancedflags[plate]))
			end
		-- Update mileage
		elseif key == 'mileage' then
			if DoesEntityExist(vehicle) then
				local utils = {}
				
				function utils.isPlateOwned(plate)
					-- implementation
				end
				
				-- usage
				if utils.isPlateOwned(plate) or config.debug then
					-- ...
				end
					mileages[plate] = value
					vehiclestats[plate].active = true
				end
			end
		end)

	QBCore.Functions.CreateCallback('renzu_tuners:Tune', function(src, data)
		local entity = NetworkGetEntityFromNetworkId(data.vehicle)
		local plate = string.gsub(GetVehicleNumberPlateText(entity), '^%s*(.-)%s*$', '%1'):upper()
		local QBCore = exports['qb-core']:GetCoreObject()
		local entityNetId = NetworkGetEntityFromNetworkId(entity)
		local entityObj = QBCore.Functions.GetEntity(entityNetId)
		local state = entityObj.state
	
		data.tune.profile = data.profile
		state:set('ecu', data.tune)
	
		local ecuData = QBCore.Functions.GetItemByName('ecu').info
		if not ecuData[plate] then ecuData[plate] = {} end
		ecuData[plate][data.profile] = data.tune
		ecuData[plate]['active'] = data.tune
	
local function isPlateOwned(plate)
	for _, temp_plate in pairs(config.nosaveplate) do
		if string.find(plate, temp_plate) == 1 then
			return false
		end
	end
	return true
end


if not isPlateOwned(plate) and not config.debug then return end
		db.save('ecu', 'plate', plate, json.encode(ecuData[plate]))
		ecuData = ecuData
		vehiclestats[plate].active = true
	end)

	GetItemState = function(name)
		local QBCore = exports['qb-core']:GetCoreObject()
		local itemInfo = QBCore.Functions.GetItemByName(name)
		local state = itemInfo.info.state
		local upgrade = nil
	
		for k,v in pairs(config.engineupgrades) do
			if v.item == name and v.state then
				state = v.state
				upgrade = v.item
			end
		end
		return state, upgrade
	end
	
	GetItemCosts = function(item)
		local QBCore = exports['qb-core']:GetCoreObject()
		local itemInfo = QBCore.Functions.GetItemByName(item)
		local cost = itemInfo.info.price or 25000 -- default if item not found or price is nil
	
		return cost
	end

	QBCore.Functions.CreateCallback('renzu_tuners:checkitem', function(source, item, isShop, required)
		local hasItem = false
		local amount = 1
		local xPlayer = QBCore.Functions.GetPlayer(source)
		
		if xPlayer then
			-- code that uses the xPlayer object
			if not config.purchasableUpgrade then
				local metadata = config.metadata
				local itemState = GetItemState(item)
				local isItemMetadata = itemState ~= item
				local name = metadata and isItemMetadata and itemState or item
				local items = xPlayer.Functions.GetItemByName(name)
	
				if items then
					for k, v in pairs(items) do
						if metadata and isItemMetadata and v.info.upgrade == item or not isItemMetadata and not v.info.upgrade or not metadata then
							xPlayer.Functions.RemoveItem(v.name, amount, v.metadata, v.slot)
							hasItem = true
						end
					end
				end
			elseif config.jobmanagemoney and config.job[xPlayer.PlayerData.job.name] then
				local cost = GetItemCosts(item)
				local jobMoney = xPlayer.PlayerData.job.bank
	
				if jobMoney >= cost then
					xPlayer.Functions.RemoveMoney('job', cost)
					hasItem = true
				end
			elseif config.purchasableUpgrade then
				local cost = GetItemCosts(item)
				local playerMoney = xPlayer.PlayerData.money.cash
	
				if playerMoney >= cost then
					xPlayer.Functions.RemoveMoney('cash', cost)
					hasItem = true
				end
			end
		else
			print("Error: Unable to get player from source " .. source)
		end
	
		return hasItem
	end)

	QBCore.Functions.CreateCallback('renzu_tuners:OldEngine', function(source, name, engine, plate, net)
		local metadata = {}
		local vehicle = NetworkGetEntityFromNetworkId(net)
		local xPlayer = QBCore.Functions.GetPlayer(source)
		local data = {}
		
		if xPlayer then
			if vehicleupgrades[plate] then
				for k, v in pairs(vehicleupgrades[plate]) do
					for k2, v2 in pairs(config.engineupgrades) do
						if v2.item == k then
							table.insert(metadata, {part = k, durability = QBCore.Functions.GetVehicleProperty(vehicle, v2.state)})
						end
					end
					table.insert(data, k:gsub('_',' '):upper())
				end
			end
		
			metadata.description = table.concat(data, ', ')
			metadata.label = name
			metadata.image = 'engine'
			metadata.engine = engine
		
			xPlayer.Functions.AddItem('enginegago', 1, metadata)
		
			if vehicleupgrades[plate] then
				for k, v in pairs(vehicleupgrades[plate]) do
					QBCore.Functions.SetVehicleProperty(vehicle, k, false, true)
				end
			end
		else
			print("Error: Unable to get player from source " .. source)
		end
	end)

	QBCore.Functions.CreateCallback('renzu_tuners:GetEngineStorage', function(source, stash)
		local xPlayer = QBCore.Functions.GetPlayer(source)
		
		if xPlayer then
			return xPlayer.Functions.GetInventoryItems(stash, 'slots', 'enginegago')
		else
			print("Error: Unable to get player from source " .. source)
			return {}
		end
	end)
	
	QBCore.Functions.CreateCallback('renzu_tuners:RemoveEngineStorage', function(source, data)
		local xPlayer = QBCore.Functions.GetPlayer(source)
		if xPlayer then
			xPlayer.Functions.RemoveItem(data.name, 1, data.metadata, data.slot, data.stash)
		end
	end)

	QBCore.Functions.CreateCallback('renzu_tuners:Craft', function(source, slots, requiredata, item, engine)
		local xPlayer = QBCore.Functions.GetPlayer(source)
		if xPlayer then
			local success = true
			local reward = item.name
			local hasitems = true
			for slot, data in pairs(slots) do
				hasitems = xPlayer.Functions.RemoveItem(data.name, requiredata[data.name], data.metadata)
				if not hasitems then break end
			end
			if hasitems then
				local chance = 50 -- assign a value to chance
				if chance and math.random(1, 100) <= chance or not chance then
					success = true
					local metadata = nil
					if engine then
						metadata = {label = engine.label, description = engine.label .. ' Engine Swap', engine = engine.name, image = 'engine'}
						reward = 'enginegago'
					end
					if config.metadata then
						if item.type == 'upgrade' and item.name ~= 'repairparts' then
							reward = item.state
							metadata = {upgrade = item.name, label = item.label, description = item.label .. ' Engine Parts', image = item.name}
						end
						if item.name == 'repairparts' then
							metadata = {durability = item.durability, upgrade = item.name, label = item.label, description = item.label .. ' \n  Restore Parts Durability ', image = item.name}
						end
					elseif item.name == 'repairparts' then
						metadata = {durability = 100, upgrade = item.name, label = 'Repair Engine Parts Kit', description = ' Restore Parts Durability to 100%', image = item.name}
					end
					xPlayer.Functions.AddItem(reward, 1, metadata)
				end
			end
			return success
		end
	end)

	QBCore.Functions.CreateCallback('renzu_tuners:RepairPart', function(source, percent, noMetadata)
		local xPlayer = QBCore.Functions.GetPlayer(source)
		if xPlayer then
			local items = xPlayer.Functions.GetInventoryItems('slots', 'repairparts')
			
			if items then
				for _, item in pairs(items) do
					local durability = item.metadata and item.metadata.durability or 100
					if durability >= percent then
						local newDurability = durability - percent
						xPlayer.Functions.SetInventoryItemDurability(item.slot, newDurability, item.metadata)
						if newDurability <= 0 then
							xPlayer.Functions.RemoveItem('repairparts', 1, nil, item.slot)
						end
						return newDurability
					end
				end
				return 'item'
			end
			
			if noMetadata then
				xPlayer.Functions.RemoveItem('repairparts', 1)
			end
			return noMetadata or false
		end
	end)

	SetTunerData = function(entity)
		if DoesEntityExist(entity) and GetEntityType(entity) == 2 and GetEntityType(entity) >= 6 then
			local plate = string.gsub(GetVehicleNumberPlateText(entity), '^%s*(.-)%s*$', '%1'):upper()
			local ent = Entity(entity).state
			if vehiclestats[plate] then
				for k, v in pairs(vehiclestats[plate]) do
					if QBCore.Functions.SetVehicleProperty then
						QBCore.Functions.SetVehicleProperty(k, tonumber(v), true)
					end
				end
				vehiclestats[plate].active = true
				vehiclestats[plate].plate = plate
			end
			if vehicleupgrades[plate] then
				for k, v in pairs(vehicleupgrades[plate]) do
					if QBCore.Functions.SetVehicleProperty then
						QBCore.Functions.SetVehicleProperty(k, v, true)
					end
				end
			end
			if vehicletires[plate] then
				if QBCore.Functions.SetVehicleProperty then
					QBCore.Functions.SetVehicleProperty('tires', vehicletires[plate], true)
				end
			end
			if defaulthandling[plate] then
				if QBCore.Functions.SetVehicleProperty then
					QBCore.Functions.SetVehicleProperty('defaulthandling', defaulthandling[plate], true)
				end
			end
			if drivetrain[plate] then
				if QBCore.Functions.SetVehicleProperty then
					QBCore.Functions.SetVehicleProperty('drivetrain', drivetrain[plate], true)
				end
			end
			if advancedflags[plate] then
				if QBCore.Functions.SetVehicleProperty then
					QBCore.Functions.SetVehicleProperty('advancedflags', advancedflags[plate], true)
				end
			end
		end
	end
	
	local isPlateOwned = function(plate)
		for _, temp_plate in pairs(config.nosaveplate) do
			if string.find(plate, temp_plate) == 1 then
				return false
			end
		end
		return true
	end
    
	local state = "vehiclePropertiesState" -- or some other string value that makes sense for your code
AddStateBagChangeHandler('VehicleProperties', state, function(bagName, key, value, _unused, replicated)
		Wait(0)
		local net = tonumber(bagName:gsub('entity:', ''), 10)
		if not value then return end
		local entity = NetworkGetEntityFromNetworkId(net)
		Wait(3000)
		if DoesEntityExist(entity) then
			SetTunerData(entity) 
		end
	end)
	
	local function isPlateOwned(plate)
		for _, temp_plate in pairs(config.nosaveplate) do
			if string.find(plate, temp_plate) == 1 then
				return false
			end
		end
		return true
	end
	
	AddEventHandler('entityRemoved', function(entity)
		if DoesEntityExist(entity) and GetEntityType(entity) == 2 and GetEntityPopulationType(entity) == 7 then
			local plate = string.gsub(GetVehicleNumberPlateText(entity), '^%s*(.-)%s*$', '%1'):upper()
			if vehiclestats[plate] and vehiclestats[plate].active then
				vehiclestats[plate].active = false
				vehiclestats[plate].plate = nil
			end
		end
	end)
	
-- Import required libraries
local QBCore = exports['qb-core']

-- Define the lib table
local lib = {}

-- Define the addCommand function
function lib.addCommand(name, data, callback)
	-- Add the command to the QB Core command system
	QBCore.Commands[name] = {
		description = data.help,
		parameters = data.params,
		restricted = data.restricted,
		run = callback
	}
end

-- Define the addEventHandler function
function lib.addEventHandler(name, callback)
	-- Add the event handler to the QB Core event system
	QBCore.Events:On(name, callback)
end

-- Define the addStateBagChangeHandler function
function lib.addStateBagChangeHandler(name, key, callback)
	-- Add the state bag change handler to the QB Core state bag system
	QBCore.StateBags:On(name, key, callback)
end

-- Define the addCallback function
 lib.addCallback(name, callback)
	-- Add the callback to the QB Core callback system
	if QBCore.Callbacks then
		QBCore.Callbacks[name] = callback
	end

-- Define the addCommand alias
lib.command = lib.addCommand

-- Define the addEvent alias
lib.event = lib.addEventHandler

-- Define the addStateBagChangeHandler alias
lib.stateBagChange = lib.addStateBagChangeHandler


-- Rest of the server main.lua code goes here...

-- Import required libraries
local QBCore = exports['qb-core']



-- Define the addCommand function
function lib.addCommand(name, data, callback)
    -- Add the command to the QB Core command system
    QBCore.Commands[name] = {
        description = data.help,
        parameters = data.params,
        restricted = data.restricted,
        run = callback
    }
end

lib.addCommand('sandboxmode', {
    help = 'Enable Developer mode Tuning and Disable Engine Degration',
    params = {},
    restricted = {job = 'admin'} -- updated to use QB Core's job system
}, function(source, args, raw)
    TriggerClientEvent('renzu_tuners:SandBoxmode', source)
end)

QBCore.Commands.sandboxmode = {
    description = 'Enable Developer mode Tuning and Disable Engine Degration',
    parameters = {},
    restricted = {job = 'admin'} -- updated to use QB Core's job system
}

QBCore.Commands.sandboxmode.run = function(source, args, raw)
    TriggerClientEvent('renzu_tuners:SandBoxmode', source)
end