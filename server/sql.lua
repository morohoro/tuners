local oxmysql = exports['oxmysql']

local MySQL = {}

function MySQL.scalar(query, values)
    local formattedQuery = MySQL.format(query, values)
    return oxmysql.scalar(formattedQuery, values)
end

function MySQL.query(query, values)
    local formattedQuery = MySQL.format(query, values)
    return oxmysql.execute(formattedQuery, values)
end

function MySQL.update(query, values)
    local formattedQuery = MySQL.format(query, values)
    return oxmysql.execute(formattedQuery, values)
end


function MySQL.escape(value)
    return oxmysql.escape(value)
end

-- Example usage
local plate = "ABC123"
local query = "SELECT * FROM vehicles WHERE plate = ?"
local result = MySQL.query(query, { plate })
local scalarResult = MySQL.scalar(query, { plate })

-- Create renzu_tuner table if it doesn't exist
Citizen.CreateThread(function()
    MySQL.Async.scalar('SELECT 1 FROM renzu_tuner', {}, function(exists)
        if not exists then
            local query = [[
                CREATE TABLE IF NOT EXISTS `renzu_tuner` (
                    `id` int NOT NULL AUTO_INCREMENT KEY,
                    `plate` varchar(60) DEFAULT NULL,
                    `mileages` int DEFAULT 0,
                    -- ... (other columns)
                )
            ]]
        end
            MySQL.Async.execute(query, {}, function()
                print("^2SQL INSTALL SUCCESSFULLY, don't forget to install the items. /install/ folder ^0")
            end,  function(error)
                print("Error creating table:", error)
            end)
        end
    , function(error)
        print("Error checking table existence:", error)
    end)

    -- Add new columns to existing table if needed
    MySQL.Async.execute('ALTER TABLE `renzu_tuner` ADD COLUMN `advancedflags` longtext DEFAULT NULL', {}, function()
        -- ... (handle success or error for column addition)
    end, function(error)
        print("Error adding column:", error)
    end)

    -- ... (add other column addition queries with `MySQL.Async.execute()` and callbacks)
end)
return MySQL