vehiclestats = {}

if config.sandboxmode then return end
vehicle_table = ESX and 'owned_vehicles' or 'player_vehicles'
sql = setmetatable({},{
	__call = function(self)

		self.insert = function(column, data, plate)
			if not column or not data or not plate then
				error("Invalid input data")
			end
		
			local query = MySQL.insert.await("INSERT INTO renzu_tuner ("..column..", plate) VALUES (?, ?)", {data, plate})
			if not query then
				error("Failed to execute query")
			end
			return query
		end
		
		self.update = function(column, where, string, data)
			if not column or not where or not string or not data then
				error("Invalid input data")
			end
		
			local query = MySQL.update("UPDATE renzu_tuner SET "..column.." = ? WHERE "..where.." = ?", {data, string})
			if not query then
				error("Failed to execute query")
			end
			return query
		end
		
		self.query = function(column, where, string)
			if not column or not where or not string then
				error("Invalid input data")
			end
		
			local str = 'SELECT %s FROM %s WHERE %s = ?'
			local query = MySQL.query.await(str:format(column,'renzu_tuner',where),{string})
			if not query then
				error("Failed to execute query")
			end
			return query
		end
		
		self.fetchAll = function()
			local str = 'SELECT * FROM renzu_tuner'
			local query = MySQL.query.await(str)
			if not query then
				error("Failed to execute query")
			end
		
			local data = {}
			for k,v in pairs(query) do
				for column, value in pairs(v) do
					if v.plate then
						if column ~= 'plate' and column ~= 'id' and value then
							if not data[column] then data[column] = {} end
							local success, result = pcall(json.decode, value)
							if not success then
								error("Failed to decode JSON data")
							end
							result = type(result) == nil and value or result
							data[column][v.plate] = result
						end
					end
				end
			end
			return data
		end

		self.busycd = {}
		self.busy = {}
		self.save = function(column, where, string, data)
			if self.busycd[string] == nil then 
				self.busycd[string] = 0 
			end
			local vehicle = MySQL.prepare.await('SELECT plate FROM `'..vehicle_table..'` WHERE `plate` = ?', {string})
			if not vehicle and not config.debug then self.busycd[string] = nil return end
			while self.busy[string] and self.busycd[string] and self.busycd[string] < 100 do 
				if self.busycd[string] then self.busycd[string] += 1 end
				Wait(10) 
			end
			self.busy[string] = true
			local str = 'SELECT 1 FROM %s WHERE %s = ?'
			local success, result = pcall(MySQL.scalar.await, str:format('renzu_tuner',where),{string})
			if success and result then
				self.update(column, where, string, data)
			else
				self.insert(column, data, string)
			end
			self.busy[string] = false
			self.busycd[string] = nil
		end

		self.updateall = function(data,plate)
			if not plate then return end
			if self.busycd[plate] == nil then self.busycd[plate] = 0 end
			while self.busy[plate] and self.busycd[plate] and self.busycd[plate] < 100 do 
				if self.busycd[plate] then self.busycd[plate] += 1 end				
				Wait(1)
			end
			self.busy[plate] = true
			local str = 'SELECT 1 FROM %s WHERE %s = ?'
			local success, result = pcall(MySQL.scalar.await, str:format('renzu_tuner','plate'),{plate})
			if success and result then
				local str = 'UPDATE %s SET %s = ?, %s = ?, %s = ?, %s = ? WHERE %s = ?'
				MySQL.update(str:format('renzu_tuner','vehiclestats','defaulthandling','vehicleupgrades','mileages','plate'),{data.vehiclestats,data.defaulthandling,data.vehicleupgrades,data.mileages,plate})
			else
				local str = 'INSERT INTO %s (%s, %s, %s, %s, %s) VALUES(?, ?, ?, ?, ?)'
				MySQL.insert.await(str:format('renzu_tuner','vehiclestats','defaulthandling','vehicleupgrades','mileages','plate'),{data.vehiclestats,data.defaulthandling,data.vehicleupgrades,data.mileages,plate})
			end
			self.busy[plate] = false
			self.busycd[plate] = nil
		end

		return self
	end
})

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
			`currentengine` varchar(60) DEFAULT NULL
		)]])
		print("^2SQL INSTALL SUCCESSFULLY, dont forget to install the items. /install/ folder ^0")
	end
	-- query to fix column type
	pcall(MySQL.query.await, 'ALTER TABLE `renzu_tuner` CHANGE COLUMN `advancedflags` `advancedflags` LONGTEXT NULL') -- temp
	local success, result = pcall(MySQL.scalar.await,'SELECT `nodegrade` FROM renzu_tuner') -- check if nodegrade column is exist
	if not success then
		pcall(MySQL.query.await, 'ALTER TABLE renzu_tuner ADD COLUMN `nodegrade` int DEFAULT 0')
	end
end)
