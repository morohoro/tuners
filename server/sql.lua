
-- local vehiclestats = {}

if config.sandboxmode then return end

local vehicle_table = 'player_vehicles'

local SQL = {}
SQL.__index = SQL

function SQL:new()
    local self = setmetatable({}, SQL)
    return self
end

function SQL:insert(columnName, dataValue, plate)
    local query = string.format('INSERT INTO renzu_tuner (%s, plate) VALUES(?, ?)', columnName)
    local result, error = MySQL.insert.await(query, {dataValue, plate})
    if not result then
        print(string.format('Error inserting into database: %s', error))
        return nil, error
    end
    return result
end

function SQL:update(columnName, whereClause, stringValue, dataValue)
    local query = string.format('UPDATE renzu_tuner SET %s = ? WHERE %s = ?', columnName, whereClause)
    local result, error = MySQL.update(query, {dataValue, stringValue})
    if not result then
        print(string.format('Error updating database: %s', error))
        return nil, error
    end
    return result
end

function SQL:query(columnName, whereClause, stringValue)
    local query = string.format('SELECT %s FROM renzu_tuner WHERE %s = ?', columnName, whereClause)
    local result, error = MySQL.query.await(query, {stringValue})
    if not result then
        print(string.format('Error querying database: %s', error))
        return nil, error
    end
    return result
end

function SQL:fetchAll()
    local query = 'SELECT * FROM renzu_tuner'
    local results, error = MySQL.query.await(query)
    if not results then
        print(string.format('Error fetching all data from database: %s', error))
        return nil, error
    end
    local data = {}
    for _, row in pairs(results) do
        for column, value in pairs(row) do
            if row.plate then
                if column ~= 'plate' and column ~= 'id' and value then
                    if not data[column] then data[column] = {} end
                    local success, result = pcall(json.decode, value)
                    if not success then
                        print(string.format('Error decoding JSON value for column %s: %s', column, result))
                    end
                    result = type(result) == 'nil' and value or result
                    data[column][row.plate] = result
                end
            end
        end
    end
    return data
end

local sql = SQL:new()
