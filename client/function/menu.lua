local QBCore = exports['qb-core']:GetCoreObject()
data = {}
UpgradePackage = function(data,shop,job)
	local options = {}
	local vehicle = GetClosestVehicle(GetEntityCoords(cache.ped), 10.0)
	if not DoesEntityExist(vehicle) then 
		lib.notify({
			description = 'No nearby vehicle', 
			type = 'error'
		})
		return 
	end
	local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()
	local menu = menu
	for k,enable in pairs(config.upgradevariation) do
		if enable then
			table.insert(options,{icon = 'box', label = k:gsub("^%l", string.upper)..' Package', description = 'Install Package of '..k, args = k})
		end
	end

	local function UpgradePackageMenu()
		local options = {}
		for k, v in pairs(config.engineupgrades) do
			table.insert(options, {
				label = v.label,
				value = v.item,
				description = 'Upgrade your engine to ' .. v.label
			})
		end
	
		lib.registerMenu({
			id = 'upgradepackage',
			title = 'Upgrade Package',
			position = 'top-right',
			options = options,
		}, function(selected, scrollIndex, args)
			for k, v in pairs(config.engineupgrades) do
				if v.category == args:lower() then
					local hasitem = lib.callback.await('renzu_tuners:checkitem', false, v.item)
					if config.freeupgrade or hasitem then
						ItemFunction(vehicle, {
							name = v.item,
							label = v.label,
						}, config.upgradepackageAnimation)
					else
						local required = config.purchasableUpgrade and 'money' or 'item'
						lib.notify({
							description = 'You don\'t have the ' .. required,
							type = 'error'
						})
					end
				end
			end
			CheckVehicle(HasAccess() or type, shop)
		end)
	
		lib.showMenu('upgradepackage')
	end
	
	RegisterNetEvent('renzu_tuners:upgradepackage')
	AddEventHandler('renzu_tuners:upgradepackage', function()
		UpgradePackageMenu()
	end)
end

local function AddOption(options, icon, label, description, args, colorScheme, checked)
    table.insert(options, {
        icon = imagepath .. icon .. '.png',
        label = label,
        description = description,
        args = args,
        colorScheme = colorScheme,
        checked = checked
    })
end

Options = function(shop, job)
    local options = {}
    local PlayerData = QBCore.Functions.GetPlayerData()
    local vehicle = QBCore.Functions.GetClosestVehicle()
    local plate = QBCore.Functions.GetPlate(vehicle)

    local function AddUpgradeOptions(configTable, installText)
        for _, v in pairs(configTable) do
            local desc = installText .. v.label
            if config.purchasableUpgrade then
                desc = 'Cost: $' .. (v.cost or 100000)
            end
            AddOption(options, v.item, v.label, desc, v.item, nil, v.item == data.type)
        end
    end

    if data.tires then
        AddUpgradeOptions(config.tires, 'Upgrade tires to ')
    elseif data.drivetrain then
        AddUpgradeOptions(config.drivetrain, 'Swap Drivetrain to ')
    elseif data.extras then
        AddUpgradeOptions(config.extras, 'Install ')
    elseif data.turbo then
        AddUpgradeOptions(QBCore.Shared.Vehicles.Turbos, 'Install ')
    elseif data.nitro then
        AddUpgradeOptions(exports.renzu_nitro:nitros(), 'Install ')
    elseif data.localengine or data.customengine then
        local engineData = data.localengine and data.value or data.customengine and data.value
        for _, v in pairs(engineData) do
            local desc = 'Install Engine ' .. (v.label or '')
            if config.purchasableUpgrade then
                desc = 'Cost: $' .. (v.cost or 100000)
            end
            AddOption(options, 'engine', v.name or v.label or 'engine', desc, v.name, 'blue')
        end
    elseif job and not data.ecu and not data.mileage then
        local desc = data.state == data.installed and 'Repair ' or 'Replace '
        desc = desc .. data.label
        if config.purchasableUpgrade then
            desc = 'Cost: $25000'
        end
        
        AddOption(options, data.state, 
            data.state == data.installed and 'Repair ' .. data.label or 'Install OEM',
            desc,
            data.state == data.installed and {name = 'repairparts', part = data.installed} or data.state
        )

        for _, v in pairs(config.engineupgrades) do
            if config.upgradevariation[v.category] and data.part ~= v.item and v.state == data.state then
                local isRepair = v.item == data.installed
                local desc = isRepair and 'Repair ' .. v.label or 'Upgrade with ' .. v.label
                if config.purchasableUpgrade then
                    desc = 'Cost: $' .. v.cost
                end
                
                AddOption(options, v.state,
                    isRepair and 'Repair ' .. v.label or 'Install to ' .. v.label,
                    desc,
                    isRepair and {name = 'repairparts', part = data.installed, state = v.state} or v.item
                )
            end
        end
    elseif job and not data.ecu then
        options = {{
            icon = imagepath .. data.part .. '.png',
            label = 'Change Oil',
            description = 'Restore to 0 Mileage',
            args = data.part
        }}
     local menu = true
    end

    if job and type(data.ecu) == 'table' then
       local menu = true
        local tune_profiles = data.ecu[plate] or {}
        
        if ecu[plate] then
            AddOption(options, 'engine', 'New Profile', 'Create New Tuning Profile', {tune = true, profile = 'new'}, 'blue')
            
            for name, tuning in pairs(tune_profiles) do
                if name ~= 'active' then
                    AddOption(options, 'engine', name, 'Load Profile ' .. name, {tune = true, profile = name, data = tuning}, 'blue')
                end
            end
        else
            AddOption(options, 'engine', 'Programable ECU', 'Install Programable ECU', data.part, 'blue')
        end
    end

    if menu then
        local playerJob = QBCore.Functions.GetPlayerData().job
        local jobMoney = playerJob and lib.callback.await('renzu_tuners:getJobMoney', false, playerJob.name) or 0
    end

    return options
end
	
local function UpgradeMenu()
    local options = Options(data, shop, job)
    exports['qb-menu']:openMenu({
        {
            header = config.purchasableUpgrade and config.jobmanagemoney and 'Job Money: '..(jobMoney or 0) or 'Parts Options',
            isMenuHeader = true
        },
        table.unpack(options),
        {
            header = 'Close',
            txt = 'Close the menu',
            params = {
                event = 'qb-menu:client:closeMenu',
                args = {}
            }
        }
    })
end

RegisterNetEvent('qb-menu:client:closeMenu')
AddEventHandler('qb-menu:client:closeMenu', function()
    CheckVehicle(job, shop)
end)

UpgradeMenu()

RegisterNetEvent('qb-menu:client:menuSelected')
AddEventHandler('qb-menu:client:menuSelected', function(selected)
    if selected.id == 'upgrade_options' then
        UpgradeMenu()
    end
end)

RegisterNetEvent('renzu_tuners:createTuningProfile')
AddEventHandler('renzu_tuners:createTuningProfile', function(source, cb, ...)
    local vehicleNetId = ...
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    local hasturbo = Entity(vehicle).state.turbo
    local totalgears = GetVehicleHighGear(vehicle)
    local maxgear = GetVehicleHighGear(vehicle)

    local options = {
        {name = 'profileName', text = 'Profile Name', type = 'text', isRequired = true},
        {name = 'ignitionTiming', text = 'Ignition Timing', type = 'range', min = -0.5, max = 1.5, step = 0.001, default = 1.0},
        {name = 'fuelTable', text = 'Fuel Table', type = 'range', min = -0.5, max = 1.5, step = 0.001, default = 1.0},
        {name = 'gearResponse', text = 'Gear Response', type = 'range', min = -0.5, max = 1.5, step = 0.01, default = 1.0},
        {name = 'finalDriveGear', text = 'Final Drive Gear', type = 'range', min = -0.5, max = 1.5, step = 0.01, default = 1.0},
    }

    if hasturbo then
        for i = 1, totalgears do
            table.insert(options, {name = 'gearBoost'..i, text = 'Gear '..i..' Boost', type = 'range', min = -0.5, max = 1.5, step = 0.01, default = 1.0})
        end
    end

    for i = 1, totalgears do
        table.insert(options, {name = 'gearRatio'..i, text = 'Gear '..i..' Ratio', type = 'text', default = tostring(config.gears[maxgear][i])})
    end

    local dialog = exports['qb-input']:ShowInput({
        header = "New Tuning Profile",
        submitText = "Create Profile",
        inputs = options
    })

    if dialog then
        local profileName = dialog.profileName
        local boostpergear = {}
        local gear_ratio = {}

        for i = 1, totalgears do
            boostpergear[i] = hasturbo and dialog['gearBoost'..i] or 1.0
            gear_ratio[i] = tonumber(dialog['gearRatio'..i])
        end

        local tuneData = {
            vehicle = vehicleNetId,
            profile = profileName,
            tune = {
                acceleration = dialog.ignitionTiming,
                topspeed = dialog.finalDriveGear,
                engineresponse = dialog.fuelTable,
                gear_response = dialog.gearResponse,
                boostpergear = boostpergear,
                gear_ratio = gear_ratio
            }
        }

        TriggerServerEvent('renzu_tuners:SaveTuneProfile', tuneData)
        QBCore.Functions.Notify('Tune has been applied and saved to '..profileName..' Profile', 'success')
        
        cb(true)
    else
        QBCore.Functions.Notify('Tune is not saved', 'error')
        cb(false)
    end
end)
QBCore.Functions.CreateCallback('renzu_tuners:modifyTuningProfile', function(source, cb, data)
    local vehicle = NetworkGetEntityFromNetworkId(data.vehicleNetId)
    local hasturbo = Entity(vehicle).state.turbo
    local totalgears = GetVehicleHighGear(vehicle)
    local maxgear = GetVehicleHighGear(vehicle)

    local options = {
        {name = 'ignitionTiming', text = 'Ignition Timing', type = 'range', min = -0.5, max = 1.5, step = 0.001, default = data.acceleration},
        {name = 'fuelTable', text = 'Fuel Table', type = 'range', min = -0.5, max = 1.5, step = 0.001, default = data.engineresponse},
        {name = 'gearResponse', text = 'Gear Response', type = 'range', min = -0.5, max = 1.5, step = 0.01, default = data.gear_response},
        {name = 'finalDriveGear', text = 'Final Drive Gear', type = 'range', min = -0.5, max = 1.5, step = 0.01, default = data.topspeed},
    }

    if hasturbo then
        for i = 1, totalgears do
            table.insert(options, {name = 'gearBoost'..i, text = 'Gear '..i..' Boost', type = 'range', min = -0.5, max = 1.5, step = 0.01, default = data.boostpergear[i] or 1.0})
        end
    end

    for i = 1, totalgears do
        table.insert(options, {name = 'gearRatio'..i, text = 'Gear '..i..' Ratio', type = 'text', default = tostring(data.gear_ratio[i] or config.gears[maxgear][i])})
    end

    local dialog = exports['qb-input']:ShowInput({
        header = "Modify Profile: " .. data.profile,
        submitText = "Save Changes",
        inputs = options
    })

    if dialog then
        local boostpergear = {}
        local gear_ratio = {}

        for i = 1, totalgears do
            boostpergear[i] = hasturbo and dialog['gearBoost'..i] or 1.0
            gear_ratio[i] = tonumber(dialog['gearRatio'..i])
        end

        local tuneData = {
            vehicle = data.vehicleNetId,
            profile = data.profile,
            tune = {
                acceleration = dialog.ignitionTiming,
                topspeed = dialog.finalDriveGear,
                engineresponse = dialog.fuelTable,
                gear_response = dialog.gearResponse,
                boostpergear = boostpergear,
                gear_ratio = gear_ratio
            }
        }

        TriggerServerEvent('renzu_tuners:UpdateTuneProfile', tuneData)
        QBCore.Functions.Notify('Tune has been applied and saved to '..data.profile..' Profile', 'success')
        cb(true)
    else
        QBCore.Functions.Notify('Tune modification cancelled', 'error')
        cb(false)
    end
end)
QBCore.Functions.CreateCallback('renzu_tuners:applyTune', function(source, cb, data)
    local success = TriggerServerEvent('renzu_tuners:Tune', data)
    if success then
        Wait(200)
        HandleEngineDegration(data.vehicle, Entity(data.vehicle).state, data.plate)
        local plate = QBCore.Functions.GetPlate(GetVehiclePedIsIn(PlayerPedId()))
        local vehicleData = QBCore.Functions.TriggerCallback('renzu_tuners:vehiclestats', plate)
        cb(vehicleData)
    else
        QBCore.Functions.Notify('Tune is not saved', 'error')
        cb(false)
    end
end)

QBCore.Functions.CreateCallback('renzu_tuners:repairPart', function(source, cb, data)
    local vehicle = NetworkGetEntityFromNetworkId(data.vehicleNetId)
    local ent = Entity(vehicle).state
    local state = data.state or data.part
    local oldvalue = state and ent[state] or 50
    local percent = data.percent or 100

    local success = QBCore.Functions.TriggerCallback('renzu_tuners:RepairPart', percent, data.isMetadataSupport == false)
    if success == 'item' then
        QBCore.Functions.Notify('Failed to repair. You don\'t have a repair item', 'error')
        cb(false)
        return
    end

    if success then
        QBCore.Functions.Progressbar("repair_part", "Repairing...", 2000, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {
            animDict = "mini@repair",
            anim = "fixing_a_player",
            flags = 49,
        }, {}, {}, function() -- Done
            local newvalue = math.min(oldvalue + percent, 100)
            ent:set(state, newvalue, true)
            QBCore.Functions.Notify('Repair Success. Repair kit Durability is '..success, 'success')
            cb(true)
        end)
    else
        QBCore.Functions.Notify('Failed to repair. The current repair parts cannot repair this percentage', 'error')
        cb(false)
    end
end)

local upgrades_data = {}
for k,v in pairs(config.engineupgrades) do
	upgrades_data[v.item] = v
end

CheckVehicle = function(menu, shop)
    local playerPed = PlayerPedId()
    local vehicle = QBCore.Functions.GetClosestVehicle(GetEntityCoords(playerPed))

    if not DoesEntityExist(vehicle) then
        QBCore.Functions.Notify('No nearby vehicle', 'error')
        return
    end

    local plate = QBCore.Functions.GetPlate(vehicle)
    local vehicleState = Entity(vehicle).state
    
    while not vehicleState.vehicle_loaded do Wait(11) end

    local default_perf = GetEnginePerformance(vehicle, plate)
    HandleTires(vehicle, plate, default_perf, vehicleState)

    local options = {}
    vehicleState:set('mileage', vehicleState.mileage or 0, true)

    table.insert(options, {
        icon = 'road',
        label = 'Mileage',
        description = 'Current Mileage of the vehicle engine',
        progress = 50,  -- calculated from vehicleState.mileage
        colorScheme = 'blue',
        args = {
            part = 'mileage',
            label = 'Mileage',
            value = 5000
        }
    })

    local vehiclestat = vehiclestats[plate] or vehicleState or {}
    local unique = {}
    local upgrades = {}
    local racing = {}

    for k, v in pairs(config.engineupgrades) do
        if string.find(v.item, 'racing') then
            racing[v.state] = v.item
        end
        if vehicleState[v.item] and not unique[v.state] then
            unique[v.state] = true
            upgrades[v.item] = true
            local parts = upgrades_data[v.item].label
            local durability = vehicleState[v.state] or 100
            table.insert(options, {
                icon = imagepath .. v.state .. '.png',
                label = parts,
                description = parts .. ' Durability: ' .. durability,
                progress = durability,
                colorScheme = 'blue',
                args = {installed = v.item, state = v.state, label = v.label}
            })
        end
    end

    for k, v in pairs(config.engineparts) do
        if not unique[v.item] then
            vehicleState:set(v.item, tonumber(vehiclestat[v.item]) or 100, true)
            local durability = vehicleState[v.item] or 100
            table.insert(options, {
                icon = imagepath .. v.item .. '.png',
                label = v.label,
                description = v.label .. ' Durability: ' .. durability .. '%',
                progress = durability,
                colorScheme = 'blue',
                args = {installed = v.item, state = v.item, label = v.label}
            })
        end
    end

    if menu then
        local drivetrain = vehicleState.drivetrain or GetVehicleHandlingFloat(vehicle, "CHandlingData", "fDriveBiasFront")
        local drivetraintype = drivetrain == 0.0 and 'RWD' or drivetrain == 1.0 and 'FWD' or 'AWD'
        -- Additional menu-specific logic can be added here
    end

    -- Return or use the options as needed
end

local tireType = vehicleState.tires and vehicleState.tires.type or 'Default'

if GetResourceState('renzu_turbo') == 'started' then
	local turboStatus = vehicleState['turbo'] and vehicleState['turbo'].turbo or 'Not Installed'
	local turboDurability = vehicleState['turbo'] and vehicleState['turbo'].durability or 100
	
	table.insert(options, {
		icon = imagepath .. 'turbostreet.png',
		label = 'Forced Induction (' .. turboStatus .. ')',
		description = 'Installed Custom Turbine',
		progress = turboDurability,
		args = {
			turbo = true,
			label = 'Forced Induction',
			value = { 'turbostreet', 'turbosports', 'turboracing', 'turboultimate' }
		}
	})

	if GetResourceState('renzu_nitro') == 'started' then
		table.insert(options, {
			icon = imagepath .. 'nitro50shot.png',
			label = 'Nitros Oxide System',
			description = 'Installed Nitros',
			args = {
				nitro = true,
				label = 'Nitro',
				value = { 'nitro50shot', 'nitro100shot', 'nitro200shot' }
			}
		})
	end
end

local tireHealth = vehicleState.tires and vehicleState.tires.tirehealth and vehicleState.tires.tirehealth[1] or 100

table.insert(options, {
	icon = imagepath .. 'street_tires.png',
	label = 'Tires ' .. tireType,
	description = 'Current Tires Health of the vehicle',
	progress = tireHealth,
	args = { tires = true, label = 'Tires', type = tireType }
})

-- Add other options similarly...

if GetResourceState('renzu_engine') == 'started' then
	local engine = vehicleState['engine'] or 'Default'
	table.insert(options, {
		icon = imagepath .. 'engine.png',
		label = 'Engine (Locals) (current: ' .. engine .. ')',
		description = 'Installed Engines',
		args = { localengine = true, label = 'Engine Swap', value = exports.renzu_engine:Engines().Locals }
	})
	table.insert(options, {
		icon = imagepath .. 'engine.png',
		label = 'Engine (Customs) (current: ' .. engine .. ')',
		description = 'Installed Engines',
		args = { customengine = true, label = 'Engine Swap', value = exports.renzu_engine:Engines().Custom }
	})
end

-- Use QB-Core menu system
exports['qb-menu']:openMenu({
	{
		header = menu and '🛠️ Upgrade Vehicle' or 'Engine Status',
		isMenuHeader = true
	},
	-- Add menu items based on the options table
})

-- Handle menu selection
RegisterNetEvent('qb-menu:client:menuSelected')
AddEventHandler('qb-menu:client:menuSelected', function(selected)
	Options(options[selected].args, shop, menu)
end)

-- Freeze/unfreeze vehicle
local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
FreezeEntityPosition(vehicle, true)

RegisterNetEvent('qb-menu:client:closeMenu')
AddEventHandler('qb-menu:client:closeMenu', function()
	if not indyno then
		FreezeEntityPosition(vehicle, false)
	end
end)


function CheckPerformance()
    local playerPed = PlayerPedId()
    local vehicle = QBCore.Functions.GetClosestVehicle(GetEntityCoords(playerPed))

    if not DoesEntityExist(vehicle) then
        QBCore.Functions.Notify('No nearby vehicle', 'error')
        return
    end

    local vehicleState = Entity(vehicle).state
    while not vehicleState.vehicle_loaded do Wait(11) end

    local options = {}
    local plate = QBCore.Functions.GetPlate(vehicle)
    local default_perf = GetEnginePerformance(vehicle, plate)
    HandleEngineDegration(vehicle, vehicleState, plate)

    local unique = {}
    for k, v in pairs(GetAvailableHandlings()) do
        if localhandling[v.handling] and default_perf[v.handling] and not unique[v.affects] then
            local prog = (localhandling[v.handling] / default_perf[v.handling] + 0.0) * 100.0
            unique[v.affects] = true
            table.insert(options, {
                header = v.affects,
                txt = 'Current performance of ' .. v.affects,
                params = {
                    isServer = false,
                    event = 'qb-menu:client:updateProgress',
                    args = {
                        id = v.affects,
                        progress = prog or 100
                    }
                }
            })
        end
    end

    exports['qb-menu']:openMenu(options)
end

RegisterNetEvent('qb-menu:client:updateProgress')
AddEventHandler('qb-menu:client:updateProgress', function(data)
    -- Handle progress update if needed
end)
TuningMenu = function()
    local playerPed = PlayerPedId()
    local vehicle = QBCore.Functions.GetClosestVehicle(GetEntityCoords(playerPed))

    if not DoesEntityExist(vehicle) then
        QBCore.Functions.Notify('No nearby vehicle', 'error')
        return
    end

    local default = GetDefaultHandling(vehicle)
    local vehicleState = Entity(vehicle).state
    local options = {}
    local plate = QBCore.Functions.GetPlate(vehicle)
    local activeprofile = ecu[plate] and ecu[plate].active

    if not activeprofile and not config.sandboxmode then
        QBCore.Functions.Notify('No Programmable ECU Installed', 'error')
        return
    end
	HandleEngineDegration(vehicle, vehicleState, plate)

local menuItems = {}
for k, v in ipairs(config.tuningmenu) do
    table.insert(menuItems, {
        header = v.label,
        txt = v.description,
        params = {
            event = "renzu_tuners:openSubMenu",
            args = {
                handling = v.handlingname,
                label = v.label,
                type = v.type,
                min = v.min,
                max = v.max,
                attributes = v.attributes
            }
        }
    })
end

local totalgears = GetVehicleHighGear(vehicle)
local maxgear = GetVehicleHighGear(vehicle)

exports['qb-menu']:openMenu(menuItems)

RegisterNetEvent('renzu_tuners:openSubMenu')
AddEventHandler('renzu_tuners:openSubMenu', function(args)
    local subMenuItems = {}
    local type = args.type
    local data = {}

    if not config.sandboxmode then
        if not activeprofile.gear_ratio then
            activeprofile.gear_ratio = config.gears[maxgear]
        end
        if not activeprofile.boostpergear then
            activeprofile.boostpergear = {}
            for i = 1, totalgears do
                activeprofile.boostpergear[i] = 1.0
            end
        end
        if not activeprofile.suspension then
            activeprofile.suspension = {}
            for k, v in ipairs(config.tuningmenu[4].attributes) do
                activeprofile.suspension[v.label] = 1.0
            end
        end

        if args.type == 'engine' then
            for k, v in ipairs(args.attributes) do
                table.insert(subMenuItems, {
                    header = v.label,
                    txt = "Min: " .. v.min .. " Max: " .. v.max,
                    params = {
                        event = "renzu_tuners:adjustValue",
                        args = {
                            type = v.type,
                            name = v.name,
                            min = v.min,
                            max = v.max,
                            step = v.step,
                            default = activeprofile[v.name] or v.default
                        }
                    }
                })
            end
        elseif args.type == 'turbo' then
            for i = 1, totalgears do
                table.insert(subMenuItems, {
                    header = "Gear " .. i .. " Boost",
                    txt = "Current: " .. (activeprofile.boostpergear[i] or 1.0),
                    params = {
                        event = "renzu_tuners:adjustValue",
                        args = {
                            type = "slider",
                            name = "boostpergear_" .. i,
                            min = -0.5,
                            max = 1.5,
                            step = 0.01,
                            default = activeprofile.boostpergear[i] or 1.0
                        }
                    }
                })
            end
        elseif args.type == 'gearratio' then
            for i = 1, totalgears do
                table.insert(subMenuItems, {
                    header = "Gear " .. i .. " Ratio",
                    txt = "Current: " .. (activeprofile.gear_ratio[i] or "Default"),
                    params = {
                        event = "renzu_tuners:adjustValue",
                        args = {
                            type = "input",
                            name = "gear_ratio_" .. i,
                            default = activeprofile.gear_ratio[i]
                        }
                    }
                })
            end
        end
    end

    exports['qb-menu']:openMenu(subMenuItems)
end)

RegisterNetEvent('renzu_tuners:adjustValue')
AddEventHandler('renzu_tuners:adjustValue', function(data)
end)
if args.type == 'suspension' then
    for k, v in ipairs(args.attributes) do
        table.insert(subMenuItems, {
            header = v.label,
            txt = "Current: " .. (activeprofile.suspension[v.label] or 1.0),
            params = {
                event = "renzu_tuners:adjustValue",
                args = {
                    type = v.type,
                    name = "suspension_" .. v.label,
                    min = v.min,
                    max = v.max,
                    step = v.step,
                    default = activeprofile.suspension[v.label] or 1.0
                }
            }
        })
    end
else
    -- Sandbox mode handling
    local HandlingGetter = function(type, handling, name)
        if type == 'number' then
            return GetVehicleHandlingInt(vehicle, handling, name)
        elseif type == 'input' then
            if name == 'fDriveInertia' and tuning_inertia == nil then
                tuning_inertia = vehicleState.defaulthandling.fDriveInertia
            end
            return name == 'fDriveInertia' and tuning_inertia or GetVehicleHandlingFloat(vehicle, handling, name)
        else
            local vec = GetVehicleHandlingVector(vehicle, handling, name)
            return table.concat({vec.x, vec.y, vec.z}, ',')
        end
    end

    for k, v in ipairs(args.attributes) do
        table.insert(subMenuItems, {
            header = v.label,
            txt = v.description,
            params = {
                event = "renzu_tuners:adjustValue",
                args = {
                    type = v.type,
                    name = v.label,
                    handling = args.handling,
                    default = HandlingGetter(v.type, args.handling, v.label)
                }
            }
        })
    end
end

exports['qb-menu']:openMenu(subMenuItems)

-- Handle value adjustments
RegisterNetEvent('renzu_tuners:adjustValue')
AddEventHandler('renzu_tuners:adjustValue', function(data)
    local input = exports['qb-input']:ShowInput({
        header = data.name,
        submitText = "Apply",
        inputs = {
            {
                type = data.type,
                name = "value",
                text = "Enter value",
                default = data.default,
                min = data.min,
                max = data.max
            }
        }
    })

    if input then
        local value = input.value
        if not config.sandboxmode then
            if data.name:find("suspension_") then
                activeprofile.suspension[data.name:gsub("suspension_", "")] = value
            elseif data.type == 'engine' then
                activeprofile[data.name] = value
            elseif data.type == 'turbo' then
                activeprofile.boostpergear[tonumber(data.name:match("%d+"))] = value
            elseif data.type == 'gearratio' then
                activeprofile.gear_ratio[tonumber(data.name:match("%d+"))] = value
            end

            TriggerServerEvent('renzu_tuners:UpdateTune', {
                vehicle = NetworkGetNetworkIdFromEntity(vehicle),
                profile = activeprofile.profile,
                tune = activeprofile
            })
        else
            -- Sandbox mode handling
            if data.type == 'number' then
                SetVehicleHandlingInt(vehicle, data.handling, data.name, tonumber(value))
            elseif data.type == 'input' then
                if data.name == 'fDriveInertia' then
                    tuning_inertia = tonumber(value)
                end
                SetVehicleHandlingFloat(vehicle, data.handling, data.name, tonumber(value))
            else
                local x, y, z = value:match("([^,]+),([^,]+),([^,]+)")
                SetVehicleHandlingVector(vehicle, data.handling, data.name, vector3(tonumber(x), tonumber(y), tonumber(z)))
            end
            ModifyVehicleTopSpeed(vehicle, 1.0)
            SetVehicleCheatPowerIncrease(vehicle, 1.0)
        end
        QBCore.Functions.Notify('Tuning applied successfully', 'success')
    end
end)

CheckWheels = function()
    local playerPed = PlayerPedId()
    local vehicle = QBCore.Functions.GetClosestVehicle(GetEntityCoords(playerPed))

    if not DoesEntityExist(vehicle) then
        QBCore.Functions.Notify('No nearby vehicle', 'error')
        return
    end

    local vehicleState = Entity(vehicle).state
    while not vehicleState.vehicle_loaded do Wait(11) end

    local plate = QBCore.Functions.GetPlate(vehicle)
    local default_perf = GetEnginePerformance(vehicle, plate)
    HandleTires(vehicle, plate, default_perf, vehicleState)

    local menuItems = {}
    for k, v in pairs(GetWheelHandling(vehicle)) do
        table.insert(menuItems, {
            header = v.label,
            txt = 'Current health: ' .. (v.health or 100) .. '%',
            params = {
                event = 'renzu_tuners:wheelInfo',
                args = {
                    label = v.label,
                    health = v.health or 100
                }
            }
        })
    end

    local wheeltype = (vehicleState.tires and vehicleState.tires.type) or 'Default OEM'
    exports['qb-menu']:openMenu({
        {
            header = 'Wheel Status (' .. wheeltype .. ')',
            isMenuHeader = true
        },
        table.unpack(menuItems)
    })
end

RegisterNetEvent('renzu_tuners:wheelInfo')
AddEventHandler('renzu_tuners:wheelInfo', function(data)
    QBCore.Functions.Notify(data.label .. ' health: ' .. data.health .. '%', 'primary')
end)

ContextMenuOptions = function(stash, entity, vehicle)
    Wait(1000)
    if GetResourceState('renzu_engine') ~= 'started' then return end

    local playerPed = PlayerPedId()
    if #(GetEntityCoords(vehicle) - GetEntityCoords(playerPed)) > 3 then
        QBCore.Functions.Notify('You are not near to the vehicle', 'error')
        return
    end

    TaskTurnPedToFaceEntity(playerPed, vehicle, 5000)
    SetEntityNoCollisionEntity(entity, vehicle, true, false)
    
    local vehicleState = Entity(vehicle).state
    
    QBCore.Functions.TriggerCallback('renzu_tuners:GetEngineStorage', function(items)
        local options = {}
        for k, v in pairs(items) do
            local name = (v.metadata and v.metadata.label) or 'Engine'
            local engine = v.metadata.engine
            local metadata = {}
            for k, v in pairs(v.metadata) do
                if type(v) == 'table' then
                    table.insert(metadata, v.part .. ' - ' .. tostring(v.durability))
                end
            end
            
            -- Continue building options here
        end
        
        -- Use QB-Core menu system to display options
        exports['qb-menu']:openMenu(options)
    end, stash)
end
table.insert(options, {
	header = 'Install ' .. name,
	txt = 'Install this engine to nearby vehicle',
	params = {
		event = 'renzu_tuners:installEngine',
		args = {
			vehicle = vehicle,
			engine = engine,
			metadata = v.metadata,
			stash = stash,
			name = v.name,
			slot = v.slot
		}
	}
})
end

exports['qb-menu']:openMenu(options)

-- New event handler for engine installation
RegisterNetEvent('renzu_tuners:installEngine')
AddEventHandler('renzu_tuners:installEngine', function(data)
local playerPed = PlayerPedId()
local vehicle = data.vehicle
local engine = data.engine

RetrieveOldEngine(vehicle, engine)
TaskTurnPedToFaceEntity(playerPed, vehicle, 5000)
Wait(2000)
FreezeEntityPosition(playerPed, true)

local d21 = GetModelDimensions(GetEntityModel(data.vehicle))
local stand = GetOffsetFromEntityInWorldCoords(data.vehicle, 0.0, d21.y + 0.2, 0.0)
local z = 1.45

RequestModel('prop_car_engine_01')
while not HasModelLoaded('prop_car_engine_01') do Wait(1) end

local enginemodel = CreateObject('prop_car_engine_01', stand.x + 0.27, stand.y - 0.2, stand.z + z, true, true, true)
while not DoesEntityExist(enginemodel) do Wait(1) end

SetEntityCompletelyDisableCollision(enginemodel, true, false)
AttachEntityToEntity(enginemodel, data.vehicle, 0, 0.0, -1.25, z, 0.0, 90.0, 0.0, true, false, false, false, 70, true)

while z > 0.2 and DoesEntityExist(enginemodel) do
	Wait(1)
	z = z - 0.003
	AttachEntityToEntity(enginemodel, data.vehicle, 0, 0.0, -1.25, z, 0.0, 90.0, 0.0, true, false, false, false, 70, true)
end

QBCore.Functions.Progressbar("install_engine", "Installing Engine", 8000, false, true, {
	disableMovement = true,
	disableCarMovement = true,
	disableMouse = false,
	disableCombat = true,
}, {
	animDict = "mini@repair",
	anim = "fixing_a_player",
	flags = 49,
}, {}, {}, function() -- Done
	DeleteEntity(enginemodel)
	TriggerServerEvent('renzu_engine:EngineSwap', NetworkGetNetworkIdFromEntity(vehicle), engine)

	local vehicleState = Entity(vehicle).state
	for _, metaItem in pairs(data.metadata) do
		if type(metaItem) == 'table' then
			local state = GetItemState(metaItem.part)
			RemoveDuplicatePart(vehicle, state)
			vehicleState:set(metaItem.part, true, true)
			vehicleState:set(state, metaItem.durability, true)
		end
	end

	QBCore.Functions.TriggerCallback('renzu_tuners:RemoveEngineStorage', function(result)
		FreezeEntityPosition(playerPed, false)
		QBCore.Functions.Notify('Engine has been installed', 'success')
	end, {stash = data.stash, name = data.name, slot = data.slot, metadata = data.metadata})
end)
end)

CraftOption = function(items, craft, label)
    local options = {}

    for k2, item in pairs(items) do
        local materials = {'Requirements: '}
        local requires = {}
        local requiredata = {}
        local metadata = {}

        for reqItem, amount in pairs(item.requires) do
            table.insert(materials, reqItem .. ' x' .. amount)
            local state = GetItemState(reqItem)
            local material = config.metadata and state or reqItem

            if config.metadata and state ~= reqItem then
                metadata[material] = reqItem
            end

            table.insert(requires, material)
            requiredata[material] = amount
        end

        table.insert(options, {
            header = item.label,
            txt = table.concat(materials, ', '),
            params = {
                event = 'renzu_tuners:craftItem',
                args = {
                    item = item,
                    craft = craft,
                    label = label,
                    requires = requires,
                    requiredata = requiredata,
                    metadata = metadata
                }
            }
        })
    end

    exports['qb-menu']:openMenu(options)
end

RegisterNetEvent('renzu_tuners:craftItem')
AddEventHandler('renzu_tuners:craftItem', function(data)
end)
local chance = item.chance or 100
table.insert(materials, 'Chances: ' .. chance .. '%')

table.insert(options, {
    header = item.label,
    txt = table.concat(materials, '<br>'),
    icon = craft == 'engine' and 'engine' or item.name,
    params = {
        event = 'renzu_tuners:craftItem',
        args = {
            item = item,
            craft = craft,
            requires = requires,
            metadata = metadata
        }
    }
})

RegisterNetEvent('renzu_tuners:craftItem')
AddEventHandler('renzu_tuners:craftItem', function(data)
    local hasItems, missingItems = QBCore.Functions.HasItem(data.requires)
    
    if hasItems then
        QBCore.Functions.Progressbar("craft_item", "Crafting " .. data.item.name, 5000, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {
            animDict = "mini@repair",
            anim = "fixing_a_player",
            flags = 49,
        }, {}, {}, function() -- Done
            TriggerServerEvent('renzu_tuners:craftItem', data.item, data.craft)
        end)
    else
        QBCore.Functions.Notify('Missing items: ' .. table.concat(missingItems, ', '), 'error')
    end
end)
					local success = QBCore.Functions.TriggerCallback('renzu_tuners:Craft', function(result)
						if result then 
							QBCore.Functions.Notify(item.name.. ' Has been crafted successfully', 'success')

						else
							QBCore.Functions.Notify('Crafting Failed', 'error')
						end
						
						if missingitems ~= "" then
							QBCore.Functions.Notify('Missing items: '..missingitems, 'error')
						end
						
						exports['qb-menu']:openMenu({
							{
								header = label,
								isMenuHeader = true
							},
							table.unpack(options)
						})
					end, slots, requiredata, item, craft == 'engine' and item)
