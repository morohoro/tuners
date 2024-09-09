RegisterServerEvent('renzu_tuners:givePlate')
AddEventHandler('renzu_tuners:givePlate', function(plate)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    local job = xPlayer.PlayerData.job.name
    local grade = xPlayer.PlayerData.job.grade

    if job == 'tuner' and grade >= 1 then
        -- Retrieve plate information from database
        local plateInfo = MySQL.Sync.fetchAll('SELECT * FROM plates WHERE plate = ?', {plate})
        if plateInfo[1] then
            -- Trigger client event with plate information
            TriggerClientEvent('renzu_tuners:givePlate', src, plateInfo[1])
        else
            -- Handle error: plate not found
            print('Error: Plate not found in database')
        end
    end
end)