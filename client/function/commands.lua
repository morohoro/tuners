-- Define a function to check if the player has access
    local function HasAccess()
        -- Your access check logic here
        -- For demonstration purposes, I'll assume it's a simple function
        return true
    end
    
    -- Define a function to get the player's vehicle
    local function GetPlayerVehicle()
        return GetVehiclePedIsIn(cache.ped)
    end
    
    -- Define a function to get the player's entity
    local function GetPlayerEntity()
        local src = source
        local player = QBCore.Functions.GetPlayer(src)
        return player
    end
    
    -- Register commands
   RegisterCommand('repair', function(source, args, rawCommand)
       if HasAccess() then
           TriggerServerEvent('RenzuTuners:Repair')
       end
   end)
   
   RegisterCommand('upgrades', function(source, args, rawCommand)
       if HasAccess() then
           TriggerServerEvent('RenzuTuners:UpgradePackage')
       end
   end)
   
   RegisterCommand('checkvehicle', function(source, args, rawCommand)
       if HasAccess() then
           local player = GetPlayerEntity()
           if player then
               TriggerServerEvent('RenzuTuners:CheckVehicle', source, player.PlayerData.citizenid)
           else
               print('Error: Player not found')
           end
       end
   end)
    
    if config.debug then
        RegisterCommand('setmileage', function(source, args, rawCommand)
            -- This command is currently not implemented
        end)
    
        RegisterCommand('setfuel', function(source, args)
            if not args[1] then return end
            local vehicle = GetPlayerVehicle()
            local ent = Entity(vehicle).state
            ent:set('fuel', tonumber(args[1]), true)
            print(ent.fuel)
        end)
    
        RegisterCommand('sethandling', function(source, args)
            if not args[1] then return end
            local vehicle = GetPlayerVehicle()
            local ent = Entity(vehicle).state
            for k,v in ipairs(config.engineparts) do
                ent:set(v.item, tonumber(args[1]), true)
                print('new value for '..v.item..' '..args[1])
            end
        end)
    end
    
    RegisterCommand('manualgear', function(source)
        local vehicle = GetPlayerVehicle()
        TriggerServerEvent('RenzuTuners:SetManualGears', vehicle)
    end)
    
    RegisterCommand('autogear', function(source, args)
        local vehicle = GetPlayerVehicle()
        TriggerServerEvent('RenzuTuners:SetAutoGears', vehicle, args[1] and true)
    end)
    
    RegisterCommand('tuning', function(source)
        TriggerServerEvent('RenzuTuners:TuningMenu')
    end)