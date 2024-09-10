-- Import required libraries
local oxmysql = exports.oxmysql
local promise = require("promise")

-- Define the MySQL table
local MySQL = {}

-- Define the MySQL.scalar function
function MySQL.scalar(query, values)
  local formattedQuery = query
  for k, v in pairs(values) do
    formattedQuery = formattedQuery:gsub(":" .. k, oxmysql.escape(v))
  end
  local results = oxmysql:scalar(formattedQuery)
  return results
end

-- Define the MySQL.query function
  function MySQL.query(query, values)
    local formattedQuery = oxmysql.format(query, values)
    local results = oxmysql:fetch(formattedQuery)
    return results
  end
  
  -- Define the MySQL.scalar function
  function MySQL.scalar(query, values)
    local formattedQuery = oxmysql.format(query, values)
    local callback = promise.new()
    oxmysql:query(formattedQuery, function(result)
      if result then
        callback:resolve(result[1])
      else
        callback:reject("Error executing query")
      end
    end)
    return Citizen.Await(callback)
  end
  
  -- Define the MySQL.update function
  function MySQL.update(query, values)
    local formattedQuery = oxmysql.format(query, values)
    local callback = promise.new()
    oxmysql:query(formattedQuery, function(result)
      if result then
        callback:resolve(result.affectedRows)
      else
        callback:reject("Error executing query")
      end
    end)
    return Citizen.Await(callback)
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
  local query = "SELECT * FROM vehicles WHERE plate = '%s'"
  local result = MySQL.query(query, { plate })
  local scalarResult = MySQL.scalar(query, { plate })
  
  

-- Create renzu_tuner table if it doesn't exist
Citizen.CreateThreadNow(function()
  result = db.fetchScalar('SELECT 1 FROM renzu_tuner')
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
    db.query(query)
    print("^2SQL INSTALL SUCCESSFULLY, don't forget to install the items. /install/ folder ^0")
  end
  -- Add new columns to existing table
  MySQL.query('ALTER TABLE `renzu_tuner` ADD COLUMN `advancedflags` longtext DEFAULT NULL')
  MySQL.query('ALTER TABLE `renzu_tuner` ADD COLUMN `ecu` longtext DEFAULT NULL')
  MySQL.query('ALTER TABLE `renzu_tuner` ADD COLUMN `drivetrain` varchar(60) DEFAULT NULL')
  MySQL.query('ALTER TABLE `renzu_tuner` ADD COLUMN `vehicletires` longtext DEFAULT NULL')
  MySQL.query('ALTER TABLE `renzu_tuner` ADD COLUMN `damage` longtext DEFAULT NULL')
end)

local oxmysql = exports.oxmysql

function escapeQuery(query, values)
    if values then
        for i, value in ipairs(values) do
            query = query:gsub('?', oxmysql.escape(value))
        end
    end
    return query
end

function fetchAll(query, values)
    query = escapeQuery(query, values)
    return oxmysql.fetchAll(query)
end

function fetchScalar(query, values)
    query = escapeQuery(query, values)
    return oxmysql.fetchScalar(query)
end

function fetch(query, values)
    query = escapeQuery(query, values)
    return oxmysql.fetch(query)
end

-- Add new query to update advanced flags data
function updateAdvancedFlags(plate, advancedflags)
    local query = 'UPDATE renzu_tuner SET advancedflags = ? WHERE plate = ?'
    return fetch(query, {advancedflags, plate})
end

-- Add new query to update ECU data
function updateECU(plate, ecu)
    local query = 'UPDATE renzu_tuner SET ecu = ? WHERE plate = ?'
    return fetch(query, {ecu, plate})
end

-- Expose the functions
db = {}
db.fetchAll = fetchAll
db.fetchScalar = fetchScalar
db.fetch = fetch
db.updateAdvancedFlags = updateAdvancedFlags
db.updateECU = updateECU

-- Return the MySQL table
return MySQL
