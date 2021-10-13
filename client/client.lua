local lastSelectedVehicleEntity
local startCountDown
local testDriveEntity
local lastPlayerCoords
local hashListLoadedOnMemory = {}
local vehcategory
local cameracoords
local pointcamera
local spawnvehicle
local buyspawn
local blip
local inTheShop = false
local profileName
local profileMoney
local vehiclesTable = {}
local provisoryObject = {}
local rgbColorSelected = {255,255,255,}
local rgbSecondaryColorSelected = {255,255,255,}

local QBCore = exports['qb-core']:GetCoreObject()

Citizen.CreateThread(function ()
	while QBCore == nil do
		TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
		Citizen.Wait(200)
	end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(3)
        local ped = PlayerPedId()
        local sleep = true
        for i = 1, #Config.Shops do
        local actualShop = Config.Shops[i].coords
        local dist = #(actualShop - GetEntityCoords(ped))
            if dist <= 5 then
                sleep = false
                DrawMarker(2, actualShop.x, actualShop.y, actualShop.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.2, 0.1, 255, 0, 0, 155, 0, 0, 0, 1, 0, 0, 0)
                if dist <= 2.5 then
                    DrawText3Ds(actualShop.x, actualShop.y, actualShop.z + 0.2, '[~g~E~w~] - Browse Vehicle Shop')
                    if IsControlJustPressed(0, 38) then
                        vehcategory = Config.Shops[i].category
                        cameracoords = Config.Shops[i].cameracoords
                        pointcamera = Config.Shops[i].pointcamera
                        spawnvehicle = Config.Shops[i].spawnvehicle
                        buyspawn = Config.Shops[i].buyspawn
                        testdrive = Config.Shops[i].testdrive
                        OpenVehicleShop()
                    end
                end
            end
        end
        if sleep then
            Wait(500)
        end
    end
end)


RegisterNetEvent('qb-vehicleshop.receiveInfo')
AddEventHandler('qb-vehicleshop.receiveInfo', function(bank, name)
    if name then
        profileName = name
    end
    profileMoney = bank
end)


RegisterNetEvent('qb-vehicleshop.successfulbuy')
AddEventHandler('qb-vehicleshop.successfulbuy', function(vehicleName,vehiclePlate,value)    
    SendNUIMessage(
        {
            type = "successful-buy",
            vehicleName = vehicleName,
            vehiclePlate = vehiclePlate,
            value = value
        }
    )       
    CloseNui()
end)

RegisterNetEvent('qb-vehicleshop.notify')
AddEventHandler('qb-vehicleshop.notify', function(type, message)    
    SendNUIMessage(
        {
            type = "notify",
            typenotify = type,
            message = message,
        }
    ) 
end)

RegisterNetEvent('qb-vehicleshop.vehiclesInfos')
AddEventHandler('qb-vehicleshop.vehiclesInfos', function() 
    for k,v in pairs(QBCore.Shared.Vehicles) do 
        if v.shop == vehcategory then
            vehiclesTable[v.category] = {}   
        end
    end 

    for k,v in pairs(QBCore.Shared.Vehicles) do
        if v.shop == vehcategory then
            provisoryObject = {
                brand = v.brand,
                name = v.name,
                price = v.price,
                model = v.model,
                qtd = 5000,
            }
            table.insert(vehiclesTable[v.category], provisoryObject)
        end
    end
end)

function OpenVehicleShop()
    inTheShop = true
    TriggerServerEvent("qb-vehicleshop.requestInfo")
    TriggerEvent('qb-vehicleshop.vehiclesInfos')
    Citizen.Wait(1000)
    SendNUIMessage(
        {
            data = vehiclesTable,
            type = "display",
            playerName = profileName,
            playerMoney = profileMoney,
            testDrive = Config.TestDrive
        }
    )
    SetNuiFocus(true, true)
    RequestCollisionAtCoord(x, y, z)
    cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", cameracoords.x, cameracoords.y, cameracoords.z, 0.00, 0.00, 0.00, 50.00, false, 0)
    PointCamAtCoord(cam, pointcamera.x, pointcamera.y, pointcamera.z)
    SetFocusPosAndVel(cameracoords.x, cameracoords.y, cameracoords.z, 0.0, 0.0, 0.0)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1, true, true)
    DisplayHud(false)
    DisplayRadar(false)

    if lastSelectedVehicleEntity ~= nil then
        DeleteEntity(lastSelectedVehicleEntity)
    end
end

function updateSelectedVehicle(model)
    local hash = GetHashKey(model)

    if not HasModelLoaded(hash) then
        RequestModel(hash)
        while not HasModelLoaded(hash) do
            Citizen.Wait(10)
        end
    end

    if lastSelectedVehicleEntity ~= nil then
        DeleteEntity(lastSelectedVehicleEntity)
    end

    lastSelectedVehicleEntity = CreateVehicle(hash, spawnvehicle.x, spawnvehicle.y, spawnvehicle.z, spawnvehicle.w, 0, 1)

    local vehicleData = {}

    
    vehicleData.traction = GetVehicleMaxTraction(lastSelectedVehicleEntity)


    vehicleData.breaking = GetVehicleMaxBraking(lastSelectedVehicleEntity) * 0.9650553    
    if vehicleData.breaking >= 1.0 then
        vehicleData.breaking = 1.0
    end

    vehicleData.maxSpeed = GetVehicleEstimatedMaxSpeed(lastSelectedVehicleEntity) * 0.9650553
    if vehicleData.maxSpeed >= 50.0 then
        vehicleData.maxSpeed = 50.0
    end

    vehicleData.acceleration = GetVehicleAcceleration(lastSelectedVehicleEntity) * 2.6
    if  vehicleData.acceleration >= 1.0 then
        vehicleData.acceleration = 1.0
    end


    SendNUIMessage(
        {
            data = vehicleData,
            type = "updateVehicleInfos",        
        }
    )

    SetVehicleCustomPrimaryColour(lastSelectedVehicleEntity,  rgbColorSelected[1], rgbColorSelected[2], rgbColorSelected[3])
    SetVehicleCustomSecondaryColour(lastSelectedVehicleEntity,  rgbSecondaryColorSelected[1], rgbSecondaryColorSelected[2], rgbSecondaryColorSelected[3])
    SetEntityHeading(lastSelectedVehicleEntity, 89.5)
end


function rotation(dir)
    local entityRot = GetEntityHeading(lastSelectedVehicleEntity) + dir
    SetEntityHeading(lastSelectedVehicleEntity, entityRot % 360)
end

RegisterNUICallback(
    "rotate",
    function(data, cb)
        if (data["key"] == "left") then
            rotation(2)
        else
            rotation(-2)
        end
        cb("ok")
    end
)


RegisterNUICallback(
    "SpawnVehicle",
    function(data, cb)
        updateSelectedVehicle(data.modelcar)
    end
)



RegisterNUICallback(
    "RGBVehicle",
    function(data, cb)
        if data.primary then
            rgbColorSelected = data.color
            SetVehicleCustomPrimaryColour(lastSelectedVehicleEntity, math.ceil(data.color[1]), math.ceil(data.color[2]), math.ceil(data.color[3]))
        else
            rgbSecondaryColorSelected = data.color
            SetVehicleCustomSecondaryColour(lastSelectedVehicleEntity, math.ceil(data.color[1]), math.ceil(data.color[2]), math.ceil(data.color[3]))
        end
    end
)

RegisterNUICallback(
    "Buy",
    function(data, cb)
        local newPlate     = GeneratePlate()
        local vehicleProps = QBCore.Functions.GetVehicleProperties(lastSelectedVehicleEntity)
        vehicleProps.plate = newPlate
        TriggerServerEvent('qb-vehicleshop.CheckMoneyForVeh',data.modelcar, data.sale, data.name, vehicleProps)
        Wait(1500)        
    end
)


RegisterNetEvent('qb-vehicleshop.spawnVehicle')
AddEventHandler('qb-vehicleshop.spawnVehicle', function(model, plate)    
    local hash = GetHashKey(model)

    lastPlayerCoords = GetEntityCoords(PlayerPedId())
    
    if not HasModelLoaded(hash) then
        RequestModel(hash)
        while not HasModelLoaded(hash) do
            Citizen.Wait(10)
        end
    end
    local vehicleBuy = CreateVehicle(hash, buyspawn.x, buyspawn.y, buyspawn.z, buyspawn.w, 1, 1)
    SetPedIntoVehicle(PlayerPedId(), vehicleBuy, -1)
    SetVehicleNumberPlateText(vehicleBuy, plate)
    TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(vehicleBuy))
    
    SetVehicleCustomPrimaryColour(vehicleBuy,  math.ceil(rgbColorSelected[1]), math.ceil(rgbColorSelected[2]), math.ceil(rgbColorSelected[3]))
    SetVehicleCustomSecondaryColour(vehicleBuy,  math.ceil(rgbSecondaryColorSelected[1]), math.ceil(rgbSecondaryColorSelected[2]), math.ceil(rgbSecondaryColorSelected[3]))
end)




RegisterNUICallback(
    "TestDrive",
    function(data, cb)        
        if Config.TestDrive then
            startCountDown = true

            local hash = GetHashKey(data.vehicleModel)

            lastPlayerCoords = GetEntityCoords(PlayerPedId())

            if not HasModelLoaded(hash) then
                RequestModel(hash)
                while not HasModelLoaded(hash) do
                    Citizen.Wait(10)
                end
            end
        
            if testDriveEntity ~= nil then
                DeleteEntity(testDriveEntity)
            end
            testDriveEntity = CreateVehicle(hash, testdrive.x, testdrive.y, testdrive.z, testdrive.w, 1, 1)
            SetPedIntoVehicle(PlayerPedId(), testDriveEntity, -1)
            TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(testDriveEntity))
            local timeGG = GetGameTimer()

            
            SetVehicleCustomPrimaryColour(testDriveEntity,  math.ceil(rgbColorSelected[1]), math.ceil(rgbColorSelected[2]), math.ceil(rgbColorSelected[3]))
            SetVehicleCustomSecondaryColour(testDriveEntity,  math.ceil(rgbSecondaryColorSelected[1]), math.ceil(rgbSecondaryColorSelected[2]), math.ceil(rgbSecondaryColorSelected[3]))

            CloseNui()

            while startCountDown do
                local countTime
                Citizen.Wait(1)
                if GetGameTimer() < timeGG+tonumber(1000*Config.TestDriveTime) then
                    local secondsLeft = GetGameTimer() - timeGG
                    drawTxt('Test Drive Time Remaining: ' .. math.ceil(Config.TestDriveTime - secondsLeft/1000),4,0.5,0.93,0.50,255,255,255,180)
                else
                    DeleteEntity(testDriveEntity)
                    SetEntityCoords(PlayerPedId(), lastPlayerCoords)
                    startCountDown = false
                end
            end        
        end
    end
)


RegisterNUICallback(
    "menuSelected",
    function(data, cb)
        local categoryVehicles

        local playerIdx = GetPlayerFromServerId(source)
        local ped = GetPlayerPed(playerIdx)
        
        if data.menuId ~= 'all' then
            categoryVehicles = vehiclesTable[data.menuId]
        else
            SendNUIMessage(
                {
                    data = vehiclesTable,
                    type = "display",
                    playerName = GetPlayerName(ped)
                }
            )
            return
        end

        SendNUIMessage(
            {
                data = categoryVehicles,
                type = "menu"
            }
        )
    end
)


RegisterNUICallback(
    "Close",
    function(data, cb)
        CloseNui()       
    end
)

function CloseNui()
    SendNUIMessage(
        {
            type = "hide"
        }
    )
    SetNuiFocus(false, false)
    if inTheShop then
        if lastSelectedVehicleEntity ~= nil then
            DeleteVehicle(lastSelectedVehicleEntity)
        end
        RenderScriptCams(false)
        DestroyAllCams(true)
        SetFocusEntity(GetPlayerPed(PlayerId())) 
        DisplayHud(true)
        DisplayRadar(true)
    end
    inTheShop = false
    vehiclesTable = {}
    provisoryObject = {}
end

function DrawText3Ds(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 370
    DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 41, 11, 41, 68)
end
-----------------------------------------------------------------------------------------------------------------------------------------
function drawTxt(text,font,x,y,scale,r,g,b,a)
	SetTextFont(font)
	SetTextScale(scale,scale)
	SetTextColour(r,g,b,a)
	SetTextOutline()
	SetTextCentre(1)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x,y)
end

-- Create Blips
Citizen.CreateThread(function ()
    for i = 1, #Config.Blips do    
        local actualShop = Config.Blips[i].blip
        if actualShop ~= nil then
            blip = AddBlipForCoord(actualShop.x, actualShop.y, actualShop.z)
            SetBlipSprite(blip, Config.Blips[i].blipsprite)
            SetBlipColour(blip, Config.Blips[i].blipcolor)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, 0.8)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(Config.Blips[i].blipname)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

AddEventHandler(
    "onResourceStop",
    function(resourceName)
        if resourceName == GetCurrentResourceName() then
           CloseNui()
           RemoveBlip(blip)
        end
    end
)