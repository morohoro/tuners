GetInventoryItems = function(items)
    if GetResourceState('qb-inventory') == 'started' then
        local data = {}
        for _, item in pairs(QB.Inventory.GetPlayerInventory()) do
            for k,v in pairs(items) do
                if v == item.name then
                    local itemInfo = { name = item.name, amount = item.amount }
                    table.insert(data, itemInfo)
                end
            end
        end
        return data
    else
        -- You can add other inventory system checks here, or return an error message
        return nil
    end
end

-- qb-inventory item use export
exports('useItem', function(data, slot)
    if data then
        local closestvehicle = GetClosestVehicle(GetEntityCoords(cache.ped), 10.0)
        if DoesEntityExist(closestvehicle) then
            QB.Inventory.UseItem(data, function(result)
                if result then
                    ItemFunction(closestvehicle, data)
                else
                    lib.notify({type = 'error', description = 'Failed to use item'})
                end
            end)
        else
            lib.notify({type = 'error', description = 'There is no vehicle nearby'})
        end
    else
        lib.notify({type = 'error', description = 'Invalid item data'})
    end
end)

-- Register client event for qb-inventory
RegisterNetEvent('useItem', function(...)
    return ItemFunction(...)
end)