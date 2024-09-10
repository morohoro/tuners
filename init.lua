local PlayerData = {}
local localhandling = {}
local invehicle = false
local gtirehealth = nil
local turboconfig = nil
local ecu = {}
local indyno = false
local efficiency = 1.0
local upgrade = {}
local stats = {}
local tune = {}
local ramp = {}
local engineswapper = {}
local winches = {}
local manual = false
local zoffset = 1
local mode = 'NORMAL'
local lastdis = 0
local boostpergear = {}
local handlingcache = {}
local fInitialDriveMaxFlatVel = nil
local fDriveInertia = nil
local fInitialDriveForce = nil
local nInitialDriveGears = nil
local tiresave = {}
local vehiclestats = {}
local vehicletires = {}
local mileages = {}
local imagepath = 'nui://qb-inventory/html/images/'

local tuning_inertia = nil
local vehicle_table = {}

if GetResourceState('qb-core') == 'started' then
	QBCore = exports['qb-core']:GetCoreObject()
	PlayerData = QBCore.Functions.GetPlayerData()

	if lib.addRadialItem then
		SetTimeout(100, function()
			local access = HasAccess()
			return access and HasRadialMenu()
		end)
	end

	RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
		PlayerData = QBCore.Functions.GetPlayerData()
		PlayerData.job.grade = PlayerData.job.grade.level or 1
		return HasRadialMenu()
	end)

	RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
		PlayerData.job = job
		PlayerData.job.grade = PlayerData.job.grade.level or 1
		HasRadialMenu()
	end)
else
	PlayerData = { job = 'mechanic', grade = 9 }
	if lib.addRadialItem then
		SetTimeout(100, function()
			return HasRadialMenu()
		end)
	end
	print('you are not using any supported framework')
end

if PlayerData.job then
	PlayerData.job.grade = PlayerData.job.grade.level or 1
end
