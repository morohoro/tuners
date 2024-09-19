local QBCore = exports['qb-core']:GetCoreObject()
function HasAccess()
    local Player = QBCore.Functions.GetPlayerData()
    return Player.job.name == 'mechanic' -- Adjust this condition as needed
end

local function SetupVehicleTargets()
    exports['qb-target']:AddGlobalVehicle({
        options = {
            {
                type = "client",
                event = "renzu_tuners:checkEngine",
                icon = "fas fa-oil-can",
                label = "Check Engine Status",
                canInteract = function(entity)
                    return GetVehicleDoorLockStatus(entity) <= 1
                end,
            },
            {
                type = "client",
                event = "renzu_tuners:checkPerformance",
                icon = "fas fa-car",
                label = "Check Engine Performance",
                canInteract = function(entity)
                    return GetVehicleDoorLockStatus(entity) <= 1
                end,
            },
            {
                type = "client",
                event = "renzu_tuners:checkWheels",
                icon = "fas fa-car",
                label = "Check Tires Status",
                canInteract = function(entity)
                    return GetVehicleDoorLockStatus(entity) <= 1
                end,
            },
            {
                type = "client",
                event = "renzu_tuners:upgradeVehicle",
                icon = "fas fa-car",
                label = "Upgrade Vehicle",
                canInteract = function(entity)
                    return GetVehicleDoorLockStatus(entity) <= 1 and HasAccess()
                end,
            },
        },
        distance = 2.5,
    })
end

local function SetupCraftingStations()
    for k, v in pairs(config.crafting) do
        exports['qb-target']:AddBoxZone(k..'_crafting', v.coord, 1.5, 1.5, {
            name = k..'_crafting',
            heading = 0,
            debugPoly = false,
            minZ = v.coord.z - 1,
            maxZ = v.coord.z + 1,
        }, {
            options = {
                {
                    type = "client",
                    event = "renzu_tuners:openCraftingMenu",
                    icon = "fas fa-hammer",
                    label = v.label,
                    craftingStation = k,
                    canInteract = HasAccess,
                },
            },
            distance = 2.0
        })
    end
end

local function SetupEngineSwapper()
    QBCore.Functions.LoadModel(config.engineswapper.model)
    for k, v in pairs(config.engineswapper.coords) do
        local engineswapper = CreateObjectNoOffset(config.engineswapper.model, v.x, v.y, v.z-0.98, false, false, true)
        SetEntityHeading(engineswapper, v.w-180)
        FreezeEntityPosition(engineswapper, true)

        exports['qb-target']:AddTargetEntity(engineswapper, {
            options = {
                {
                    type = "client",
                    event = "renzu_tuners:openEngineSwapMenu",
                    icon = "fas fa-car",
                    label = "Engine Stand",
                    canInteract = HasAccess,
                    swapperID = k,
                },
            },
            distance = 2.0
        })
    end
end

RegisterNetEvent('renzu_tuners:checkEngine', function()
    QBCore.Functions.Progressbar("check_engine", "Checking Engine...", 2000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        CheckVehicle()
    end)
end)

RegisterNetEvent('renzu_tuners:checkPerformance', function()
    QBCore.Functions.Progressbar("check_performance", "Checking Performance...", 2000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        CheckPerformance()
    end)
end)

RegisterNetEvent('renzu_tuners:checkWheels', function()
    QBCore.Functions.Progressbar("check_wheels", "Checking Wheels...", 2000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        CheckWheels()
    end)
end)

RegisterNetEvent('renzu_tuners:upgradeVehicle', function()
    QBCore.Functions.Progressbar("upgrade_vehicle", "Upgrading Vehicle...", 2000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        CheckVehicle(true)
    end)
end)

RegisterNetEvent('renzu_tuners:openCraftingMenu', function(data)
    local options = {}
    for k2, v in pairs(config.crafting[data.craftingStation].categories) do
        table.insert(options, {
            header = v.label,
            txt = 'Craft ' .. v.label,
            params = {
                event = 'renzu_tuners:craftItem',
                args = {
                    items = v.items,
                    category = data.craftingStation,
                    label = v.label
                }
            }
        })
    end
    exports['qb-menu']:openMenu(options)
end)

RegisterNetEvent('renzu_tuners:openEngineSwapMenu', function(data)
    local options = {
        {
            header = "Engine Swap",
            isMenuHeader = true
        },
        {
            header = "Select and Install Engine",
            txt = "Choose an engine from storage",
            params = {
                event = "renzu_tuners:selectEngine",
                args = {
                    swapperID = data.swapperID
                }
            }
        },
        {
            header = "Engine Storage",
            txt = "Store an engine",
            params = {
                event = "renzu_tuners:openEngineStorage",
                args = {
                    swapperID = data.swapperID
                }
            }
        }
    }
    exports['qb-menu']:openMenu(options)
end)

CreateThread(function()
    Wait(1100)
    SetupVehicleTargets()
    if config.enablecrafting then
        SetupCraftingStations()
    end
    SetupEngineSwapper()
end)
