local menuOpen = false
local activeLocationIndex = nil
local currentRental = nil
local spawnedPeds = {}
local targetZones = {}
local activeTextUI = nil
local interactionMode = nil

local function notify(message, notifyType)
    notifyType = notifyType or 'primary'

    if GetResourceState('qbx_core') == 'started' then
        exports.qbx_core:Notify(message, notifyType)
        return
    end

    if GetResourceState('qb-core') == 'started' then
        TriggerEvent('QBCore:Notify', message, notifyType)
        return
    end

    if GetResourceState('es_extended') == 'started' then
        TriggerEvent('esx:showNotification', message)
        return
    end

    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end

RegisterNetEvent('venox-rental:client:notify', notify)

local function getInteractionMode()
    if interactionMode then
        return interactionMode
    end

    if Config.Interaction ~= 'auto' then
        interactionMode = Config.Interaction
        return interactionMode
    end

    if GetResourceState('ox_target') == 'started' then
        interactionMode = 'ox_target'
    elseif GetResourceState('qb-target') == 'started' then
        interactionMode = 'qb-target'
    else
        interactionMode = 'textui'
    end

    return interactionMode
end

local function drawText3d(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then
        return
    end

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 230)
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x, y)

    local factor = string.len(text) / 370
    DrawRect(x, y + 0.013, 0.018 + factor, 0.032, 0, 0, 0, 140)
end

local function getTextUIProvider()
    local provider = Config.TextUI.provider
    if provider ~= 'auto' then
        return provider
    end

    if GetResourceState('ox_lib') == 'started' and lib and lib.showTextUI then
        return 'ox_lib'
    end

    if GetResourceState('qb-core') == 'started' then
        return 'qb-core'
    end

    if GetResourceState('esx_textui') == 'started' then
        return 'esx_textui'
    end

    return 'draw3d'
end

local function showTextUI(text)
    if activeTextUI == text then
        return
    end

    local provider = getTextUIProvider()
    activeTextUI = text

    if provider == 'ox_lib' and lib and lib.showTextUI then
        lib.showTextUI(text, { position = Config.TextUI.position or 'left-center' })
    elseif provider == 'qb-core' and GetResourceState('qb-core') == 'started' then
        exports['qb-core']:DrawText(text, Config.TextUI.position or 'left')
    elseif provider == 'esx_textui' and GetResourceState('esx_textui') == 'started' then
        exports['esx_textui']:TextUI(text)
    else
        activeTextUI = nil
    end
end

local function hideTextUI()
    if not activeTextUI then
        return
    end

    local provider = getTextUIProvider()
    activeTextUI = nil

    if provider == 'ox_lib' and lib and lib.hideTextUI then
        lib.hideTextUI()
    elseif provider == 'qb-core' and GetResourceState('qb-core') == 'started' then
        exports['qb-core']:HideText()
    elseif provider == 'esx_textui' and GetResourceState('esx_textui') == 'started' then
        exports['esx_textui']:HideUI()
    end
end

local function closeMenu()
    menuOpen = false
    activeLocationIndex = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function openRentalMenu(locationIndex)
    menuOpen = true
    activeLocationIndex = locationIndex
    hideTextUI()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        title = Config.Text.menuTitle,
        location = Config.Locations[locationIndex] and Config.Locations[locationIndex].label or 'Rental',
        vehicles = Config.Vehicles
    })
end

local function isSpawnClear(coords)
    return not IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 3.0)
end

local function tryRent(locationIndex)
    local location = Config.Locations[locationIndex]

    if not location or not isSpawnClear(location.spawn) then
        notify(Config.Text.spawnBlocked, 'error')
        closeMenu()
        return
    end

    openRentalMenu(locationIndex)
end

local function tryReturn()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    local plate = VenoxRental.TrimPlate(GetVehicleNumberPlateText(vehicle))
    TriggerServerEvent('venox-rental:server:returnVehicle', plate)
end

RegisterNUICallback('close', function(_, cb)
    closeMenu()
    cb({ ok = true })
end)

RegisterNUICallback('rent', function(data, cb)
    local vehicleIndex = tonumber(data and data.vehicleIndex)
    local locationIndex = activeLocationIndex
    local location = Config.Locations[locationIndex]

    if not vehicleIndex or not Config.Vehicles[vehicleIndex] then
        notify(Config.Text.invalidVehicle, 'error')
        cb({ ok = false })
        return
    end

    if not location or not isSpawnClear(location.spawn) then
        notify(Config.Text.spawnBlocked, 'error')
        closeMenu()
        cb({ ok = false })
        return
    end

    closeMenu()
    TriggerServerEvent('venox-rental:server:rentVehicle', locationIndex, vehicleIndex)
    cb({ ok = true })
end)

local function requestModel(model)
    local hash = joaat(model)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        return nil
    end

    RequestModel(hash)
    local timeout = GetGameTimer() + 8000

    while not HasModelLoaded(hash) do
        Wait(0)
        if GetGameTimer() > timeout then
            return nil
        end
    end

    return hash
end

local function createRentalVehicle(data)
    local spawn = data.spawn

    if not isSpawnClear(spawn) then
        notify(Config.Text.spawnBlocked, 'error')
        return
    end

    local model = requestModel(data.model)
    if not model then
        notify(Config.Text.invalidVehicle, 'error')
        return
    end

    local vehicle = CreateVehicle(model, spawn.x, spawn.y, spawn.z, spawn.w, true, false)
    SetModelAsNoLongerNeeded(model)

    SetVehicleNumberPlateText(vehicle, data.plate)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleDirtLevel(vehicle, Config.VehicleDirtLevel or 0.0)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetPedIntoVehicle(PlayerPedId(), vehicle, -1)

    if Config.SetFuel then
        Config.SetFuel(vehicle, Config.FuelLevel or 100.0)
    end

    if Config.GiveKeys then
        Config.GiveKeys(vehicle, data.plate, data.model)
    end

    currentRental = {
        vehicle = vehicle,
        plate = VenoxRental.TrimPlate(data.plate),
        model = data.model
    }

    notify(Config.Text.rented, 'success')
end

RegisterNetEvent('venox-rental:client:spawnVehicle', createRentalVehicle)

RegisterNetEvent('venox-rental:client:finishReturn', function(plate)
    plate = VenoxRental.TrimPlate(plate)

    if Config.ReturnDeletesVehicle and currentRental and currentRental.vehicle and DoesEntityExist(currentRental.vehicle) then
        DeleteEntity(currentRental.vehicle)
    end

    if currentRental and currentRental.plate == plate then
        currentRental = nil
    end
end)

local function createBlipsAndPeds()
    for index, location in ipairs(Config.Locations) do
        if Config.Blip.enabled then
            local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
            SetBlipSprite(blip, Config.Blip.sprite)
            SetBlipColour(blip, Config.Blip.color)
            SetBlipScale(blip, Config.Blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(Config.Blip.label)
            EndTextCommandSetBlipName(blip)
        end

        if Config.Ped.enabled then
            CreateThread(function()
                local model = joaat(Config.Ped.model)
                RequestModel(model)
                while not HasModelLoaded(model) do
                    Wait(0)
                end

                local ped = CreatePed(0, model, location.coords.x, location.coords.y, location.coords.z - 1.0, location.coords.w, false, true)
                SetEntityHeading(ped, location.coords.w)
                FreezeEntityPosition(ped, true)
                SetEntityInvincible(ped, true)
                SetBlockingOfNonTemporaryEvents(ped, true)

                if Config.Ped.scenario then
                    TaskStartScenarioInPlace(ped, Config.Ped.scenario, 0, true)
                end

                spawnedPeds[index] = ped
                SetModelAsNoLongerNeeded(model)
            end)
        end
    end
end

CreateThread(createBlipsAndPeds)

local function addOxTargets()
    for index, location in ipairs(Config.Locations) do
        local ped = spawnedPeds[index]

        if ped and DoesEntityExist(ped) then
            exports.ox_target:addLocalEntity(ped, {
                {
                    name = ('venox_rental_rent_%s'):format(index),
                    icon = Config.Target.icon,
                    label = Config.Target.rentLabel,
                    distance = Config.Target.distance,
                    onSelect = function()
                        tryRent(index)
                    end
                }
            })
        else
            local zoneId = exports.ox_target:addSphereZone({
                coords = vec3(location.coords.x, location.coords.y, location.coords.z),
                radius = Config.Target.distance,
                debug = Config.Debug,
                options = {
                    {
                        name = ('venox_rental_rent_%s'):format(index),
                        icon = Config.Target.icon,
                        label = Config.Target.rentLabel,
                        onSelect = function()
                            tryRent(index)
                        end
                    }
                }
            })

            targetZones[#targetZones + 1] = { type = 'ox', id = zoneId }
        end

        if location.returnCoords then
            local zoneId = exports.ox_target:addSphereZone({
                coords = location.returnCoords,
                radius = 3.0,
                debug = Config.Debug,
                options = {
                    {
                        name = ('venox_rental_return_%s'):format(index),
                        icon = Config.Target.icon,
                        label = Config.Target.returnLabel,
                        canInteract = function()
                            return IsPedInAnyVehicle(PlayerPedId(), false)
                        end,
                        onSelect = tryReturn
                    }
                }
            })

            targetZones[#targetZones + 1] = { type = 'ox', id = zoneId }
        end
    end
end

local function addQbTargets()
    for index, location in ipairs(Config.Locations) do
        local ped = spawnedPeds[index]

        if ped and DoesEntityExist(ped) then
            exports['qb-target']:AddTargetEntity(ped, {
                options = {
                    {
                        icon = Config.Target.icon,
                        label = Config.Target.rentLabel,
                        action = function()
                            tryRent(index)
                        end
                    }
                },
                distance = Config.Target.distance
            })
        else
            local name = ('venox_rental_rent_%s'):format(index)
            exports['qb-target']:AddCircleZone(name, vec3(location.coords.x, location.coords.y, location.coords.z), Config.Target.distance, {
                name = name,
                debugPoly = Config.Debug
            }, {
                options = {
                    {
                        icon = Config.Target.icon,
                        label = Config.Target.rentLabel,
                        action = function()
                            tryRent(index)
                        end
                    }
                },
                distance = Config.Target.distance
            })

            targetZones[#targetZones + 1] = { type = 'qb', id = name }
        end

        if location.returnCoords then
            local name = ('venox_rental_return_%s'):format(index)
            exports['qb-target']:AddCircleZone(name, location.returnCoords, 3.0, {
                name = name,
                debugPoly = Config.Debug
            }, {
                options = {
                    {
                        icon = Config.Target.icon,
                        label = Config.Target.returnLabel,
                        canInteract = function()
                            return IsPedInAnyVehicle(PlayerPedId(), false)
                        end,
                        action = tryReturn
                    }
                },
                distance = 3.0
            })

            targetZones[#targetZones + 1] = { type = 'qb', id = name }
        end
    end
end

local function waitForRentalPeds()
    if not Config.Ped.enabled then
        return
    end

    local timeout = GetGameTimer() + 8000
    while GetGameTimer() < timeout do
        local ready = true

        for index in ipairs(Config.Locations) do
            if not spawnedPeds[index] or not DoesEntityExist(spawnedPeds[index]) then
                ready = false
                break
            end
        end

        if ready then
            return
        end

        Wait(100)
    end
end

CreateThread(function()
    Wait(1500)
    waitForRentalPeds()

    local mode = getInteractionMode()
    if mode == 'ox_target' and GetResourceState('ox_target') == 'started' then
        addOxTargets()
    elseif mode == 'qb-target' and GetResourceState('qb-target') == 'started' then
        addQbTargets()
    elseif mode ~= 'textui' then
        interactionMode = 'textui'
        notify(('Interaction resource not found. Using text UI.'), 'primary')
    end
end)

CreateThread(function()
    while true do
        if getInteractionMode() == 'textui' then
            local sleep = 1000
            local ped = PlayerPedId()
            local playerCoords = GetEntityCoords(ped)
            local textShown = false

            for index, location in ipairs(Config.Locations) do
                local rentCoords = vec3(location.coords.x, location.coords.y, location.coords.z)
                local rentDistance = #(playerCoords - rentCoords)

                if Config.ShowMarkers and rentDistance < Config.MarkerDistance then
                    sleep = 0
                    DrawMarker(2, rentCoords.x, rentCoords.y, rentCoords.z + 0.15, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.25, 0.25, 40, 140, 210, 180, false, true, 2, nil, nil, false)
                end

                if rentDistance < Config.InteractDistance and not menuOpen then
                    sleep = 0
                    textShown = true
                    showTextUI(Config.Text.rentPrompt)

                    if getTextUIProvider() == 'draw3d' then
                        drawText3d(vec3(rentCoords.x, rentCoords.y, rentCoords.z + 1.0), Config.Text.rentPrompt)
                    end

                    if IsControlJustPressed(0, Config.OpenKey) then
                        tryRent(index)
                    end
                end

                if location.returnCoords then
                    local returnDistance = #(playerCoords - location.returnCoords)

                    if Config.ShowMarkers and returnDistance < Config.MarkerDistance then
                        sleep = 0
                        DrawMarker(1, location.returnCoords.x, location.returnCoords.y, location.returnCoords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.8, 2.8, 0.5, 120, 220, 145, 110, false, true, 2, nil, nil, false)
                    end

                    if returnDistance < 3.0 and IsPedInAnyVehicle(ped, false) then
                        sleep = 0
                        textShown = true
                        showTextUI(Config.Text.returnPrompt)

                        if getTextUIProvider() == 'draw3d' then
                            drawText3d(vec3(location.returnCoords.x, location.returnCoords.y, location.returnCoords.z + 0.8), Config.Text.returnPrompt)
                        end

                        if IsControlJustPressed(0, Config.OpenKey) then
                            tryReturn()
                        end
                    end
                end
            end

            if not textShown then
                hideTextUI()
            end

            Wait(sleep)
        else
            hideTextUI()
            Wait(1000)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end

    for _, ped in pairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            if getInteractionMode() == 'ox_target' and GetResourceState('ox_target') == 'started' then
                exports.ox_target:removeLocalEntity(ped)
            elseif getInteractionMode() == 'qb-target' and GetResourceState('qb-target') == 'started' then
                exports['qb-target']:RemoveTargetEntity(ped)
            end

            DeleteEntity(ped)
        end
    end

    for _, zone in ipairs(targetZones) do
        if zone.type == 'ox' and GetResourceState('ox_target') == 'started' then
            exports.ox_target:removeZone(zone.id)
        elseif zone.type == 'qb' and GetResourceState('qb-target') == 'started' then
            exports['qb-target']:RemoveZone(zone.id)
        end
    end

    hideTextUI()
    closeMenu()
end)
