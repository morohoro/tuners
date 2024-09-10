-- Import required libraries
local oxmysql = exports.oxmysql

-- Define the MySQL table
local MySQL = {}

-- Define the MySQL.scalar function
function MySQL.scalar(query, values)
    local formattedQuery = oxmysql.format(query, values)
    local result = oxmysql.scalarSync(formattedQuery)
    return result
end

-- Define the MySQL.query function
function MySQL.query(query, values)
    local formattedQuery = oxmysql.format(query, values)
    local result = oxmysql.fetchSync(formattedQuery)
    return result
end

-- Define the MySQL.update function
function MySQL.update(query, values)
    local formattedQuery = oxmysql.format(query, values)
    local result = oxmysql.executeSync(formattedQuery)
    return result
end

-- Define the MySQL.format function
function MySQL.format(query, values)
    return oxmysql.format(query, values)
end

-- Define the MySQL.escape function
function MySQL.escape(value)
    return oxmysql.escape(value)
end

-- Example usage
local plate = "ABC123"
local query = "SELECT * FROM vehicles WHERE plate = ?"
local result = MySQL.query(query, { plate })
local scalarResult = MySQL.scalar(query, { plate })

-- Create renzu_tuner table if it doesn't exist
Citizen.CreateThreadNow(function()
    local result = MySQL.scalar('SELECT 1 FROM renzu_tuner')
    if result == nil then
        local query = [[
            CREATE TABLE IF NOT EXISTS `renzu_tuner` (
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
            )
        ]]
        MySQL.query(query)
        print("^2SQL INSTALL SUCCESSFULLY, don't forget to install the items. /install/ folder ^0")
    end
    -- Add new columns to existing table
    MySQL.query('ALTER TABLE `renzu_tuner` ADD COLUMN `advancedflags` longtext DEFAULT NULL')
    MySQL.query('ALTER TABLE `renzu_tuner` ADD COLUMN `ecu` longtext DEFAULT NULL')
    MySQL.query('ALTER TABLE `renzu_tuner` ADD COLUMN `drivetrain` varchar(60) DEFAULT NULL')
    MySQL.query('ALTER TABLE `renzu_tuner` ADD COLUMN `vehicletires` longtext DEFAULT NULL')
    MySQL.query('ALTER TABLE `renzu_tuner` ADD COLUMN `damage` longtext DEFAULT NULL')
end)

-- Expose the functions
db = {}
db.fetchAll = MySQL.query
db.fetchScalar = MySQL.scalar
db.update = MySQL.update

-- Return the MySQL table
return MySQL
