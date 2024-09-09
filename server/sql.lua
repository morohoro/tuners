-- sql.lua

-- MySQL Connection
MySQL = {}

MySQL.ready = false

MySQL.query = function(query, values)
    local query = MySQL.format(query, values)
    local callback = promise.new()
    MySQL.Async.fetchAll(query, function(results)
        callback(resolve, results)
    end)
    return Citizen.Await(callback)
end

MySQL.scalar = function(query, values)
    local query = MySQL.format(query, values)
    local callback = promise.new()
    MySQL.Async.fetchScalar(query, function(result)
        callback(resolve, result)
    end)
    return Citizen.Await(callback)
end

MySQL.update = function(query, values)
    local query = MySQL.format(query, values)
    local callback = promise.new()
    MySQL.Async.execute(query, function(result)
        callback(resolve, result)
    end)
    return Citizen.Await(callback)
end

MySQL.insert = function(query, values)
    local query = MySQL.format(query, values)
    local callback = promise.new()
    MySQL.Async.execute(query, function(result)
        callback(resolve, result)
    end)
    return Citizen.Await(callback)
end

MySQL.format = function(query, values)
    if values then
        for i, value in ipairs(values) do
            query = query:gsub('?', MySQL.escape(value))
        end
    end
    return query
end

MySQL.escape = function(value)
    if type(value) == 'string' then
        return "'" .. value .. "'"
    elseif type(value) == 'number' then
        return tostring(value)
    else
        error('Unsupported type: ' .. type(value))
    end
end

-- Create renzu_tuner table if it doesn't exist
Citizen.CreateThreadNow(function()
    local success, result = pcall(MySQL.scalar.await, 'SELECT 1 FROM renzu_tuner')
    if not success then
        MySQL.query.await([[CREATE TABLE `renzu_tuner` (
            `id` int NOT NULL AUTO_INCREMENT KEY,
            `plate` varchar(60) DEFAULT NULL,
            `mileages` int DEFAULT 0,
            `vehiclestats` longtext DEFAULT NULL,
            `defaulthandling` longtext DEFAULT NULL,
            `vehicleupgrades` longtext DEFAULT NULL,
            `vehicletires` longtext DEFAULT NULL,
            `drivetrain` varchar(60) DEFAULT NULL,
            `advancedflags` longtext DEFAULT NULL,
            `ecu` longtext DEFAULT NULL,
            `nodegrade` int DEFAULT 0,
            `currentengine` varchar(60) DEFAULT NULL,
            `damage` longtext DEFAULT NULL
        )]])
        print("^2SQL INSTALL SUCCESSFULLY, dont forget to install the items. /install/ folder ^0")
    end
    -- Add new columns to existing table
    pcall(MySQL.query.await, 'ALTER TABLE `renzu_tuner` ADD COLUMN `advancedflags` longtext DEFAULT NULL')
    pcall(MySQL.query.await, 'ALTER TABLE `renzu_tuner` ADD COLUMN `ecu` longtext DEFAULT NULL')
    pcall(MySQL.query.await, 'ALTER TABLE `renzu_tuner` ADD COLUMN `drivetrain` varchar(60) DEFAULT NULL')
    pcall(MySQL.query.await, 'ALTER TABLE `renzu_tuner` ADD COLUMN `vehicletires` longtext DEFAULT NULL')
    pcall(MySQL.query.await, 'ALTER TABLE `renzu_tuner` ADD COLUMN `damage` longtext DEFAULT NULL')
end)

-- Update vehiclestats column
self.update = function(column, where, string, data)
    local str = 'UPDATE %s SET %s = ? WHERE %s = ?'
    return MySQL.update(str:format('renzu_tuner', column, where), {data, string})
end

-- Add new query to update current engine data
self.updateCurrentEngine = function(plate, currentengine)
    local str = 'UPDATE %s SET %s = ? WHERE %s = ?'
    return MySQL.update(str:format('renzu_tuner', 'currentengine', 'plate'), {currentengine, plate})
end

-- Add new query to update advanced flags data
self.updateAdvancedFlags = function(plate, advancedflags)
    local str = 'UPDATE %s SET %s = ? WHERE %s = ?'
    return MySQL.update(str:format('renzu_tuner', 'advancedflags', 'plate'), {advancedflags, plate})
end

-- Add new query to update ECU data
self.updateECU = function(plate, ecu)
    local str = 'UPDATE %s SET %s = ? WHERE %s = ?'
    return MySQL.update(str:format('renzu_tuner', 'ecu', 'plate'), {ecu, plate})
end