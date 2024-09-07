local QBCore = exports['qb-core']:GetCoreObject()

GetInventoryItems = function(items)
    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:Search('slots', items)
    elseif GetResourceState('qb-core') == 'started' then
        local data = {}
        local itemdata = {}
        local playerData = QBCore.Functions.GetPlayerData()
        for _, item in pairs(playerData.items) do
            for k,v in pairs(items) do
                if v == item.name then
                    item.count = item.amount
                    if not itemdata[item.name] then 
                        itemdata[item.name] = item 
                    else
                        local count = itemdata[item.name].count
                    end
                    table.insert(data,itemdata)
                end
            end
        end
        return data
    end
end

-- ox item export
exports('useItem', function(data, slot)
    local closestvehicle = GetClosestVehicle(GetEntityCoords(cache.ped), 10.0)
    if DoesEntityExist(closestvehicle) then
        exports.ox_inventory:useItem(data, function(data)
            if data then
				ItemFunction(closestvehicle,data)
            end
        end)
    else
        lib.notify({type = 'error', description = 'There is no vehicle nearby'})
    end
end)

-- this export is made for ox_inventory
-- but you can adapt any inventory by triggering this client event from server ex. when item is used
RegisterNetEvent('useItem', function(...)
    return ItemFunction(...)
end)
-- TriggerClientEvent('useItem', source, NetworkGetNetworkIdFromEntity(vehicle),{name = 'oem_suspension', label = 'OEM Suspension'})