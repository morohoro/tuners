local QBCore = exports['qb-core']:GetCoreObject()

if config.sandboxmode then return end
QBCore = exports['qb-core']:GetCoreObject()

GetPlayerFromId = function(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.job == nil then
        Player.job = Player.PlayerData.job
    end
    return Player
end

GetInventoryItems = function(src, method, items, metadata)
    local Player = GetPlayerFromId(src)
    local data = {}
    for _, item in pairs((Player and Player.PlayerData and Player.PlayerData.items) or {}) do
        if items == item.name then
            item.metadata = item.info
            if item.metadata and item.metadata.quality then
                item.metadata.durability = item.metadata.quality
            end
            table.insert(data, item)
        end
    end
    return data
end

GetMoney = function(src)
    local Player = GetPlayerFromId(src)
    return Player.PlayerData.money['cash']
end

RemoveMoney = function(src, amount)
    local Player = GetPlayerFromId(src)
    Player.Functions.RemoveMoney('cash', tonumber(amount))
end

RemoveInventoryItem = function(src, item, count, metadata, slot)
    return exports['qb-inventory']:RemoveItem(src, item, count, slot, metadata)
end

AddInventoryItem = function(src, item, count, metadata, slot)
    metadata.quality = metadata.durability
    return exports['qb-inventory']:AddItem(src, item, count, slot, metadata)
end

SetDurability = function(src, percent, slot, metadata, item)
    local Player = GetPlayerFromId(src)
    Player.PlayerData.items[slot].info.quality = percent
    Player.Functions.SetPlayerData("items", Player.PlayerData.items)
end



RegisterUsableItem = QBCore.Functions.CreateUseableItem

local register = function(source, item)
    local src = source
    local Player = GetPlayerFromId(src)
    local itemdata = type(item) == 'table' and item or {name = item, label = item} -- support ancient framework
    RemoveInventoryItem(src, itemdata.name, 1, itemdata.metadata, itemdata.slot)
    TriggerClientEvent("useItem", src, false, {name = itemdata.name, label = itemdata.label}, true)
end

for k, v in pairs(config.engineparts) do
    RegisterUsableItem(v.item, register)
end

for k, v in pairs(config.engineupgrades) do
    RegisterUsableItem(v.item, register)
end

for k, v in pairs(config.tires) do
    RegisterUsableItem(v.item, register)
end

for k, v in pairs(config.drivetrain) do
    RegisterUsableItem(v.item, register)
end

for k, v in pairs(config.extras) do
    RegisterUsableItem(v.item, register)
end

RegisterUsableItem('repairparts', register)