RegisterServerEvent('renzu_tuners:getInventory')
AddEventHandler('renzu_tuners:getInventory', function()
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)

    if xPlayer == nil then
        print('Error: Player not found')
        return
    end

    local inventory = {}

    -- Retrieve inventory data from database
    local inventoryData = MySQL.Sync.fetchAll('SELECT * FROM player_inventories WHERE citizenid = ?', {xPlayer.PlayerData.citizenid})

    if inventoryData == nil then
        print('Error: Inventory data not found')
        return
    end

    -- Populate inventory array
    for _, item in pairs(inventoryData) do
        table.insert(inventory, {
            item = item.item,
            amount = item.amount
        })
    end

    TriggerClientEvent('renzu_tuners:sendInventory', src, inventory)
end)