Config = {}

Config.Framework = 'auto' -- auto, qb, qbox, esx, standalone
Config.Locale = 'en'
Config.Debug = false

Config.InteractDistance = 2.0
Config.MarkerDistance = 18.0
Config.DrawDistance = 60.0
Config.OpenKey = 38 -- E

Config.Interaction = 'auto' -- auto, textui, qb-target, ox_target
Config.ShowMarkers = true

Config.TextUI = {
    provider = 'auto', -- auto, ox_lib, qb-core, esx_textui, draw3d
    position = 'left-center'
}

Config.Target = {
    distance = 2.5,
    icon = 'fas fa-car',
    rentLabel = 'Rent Vehicle',
    returnLabel = 'Return Rental'
}

Config.OneRentalPerPlayer = true
Config.PaymentAccount = 'cash' -- cash, bank
Config.StandaloneFree = true
Config.ReturnDeletesVehicle = true
Config.RefundOnReturn = false
Config.RefundPercent = 50

Config.PlatePrefix = 'RENT'
Config.FuelLevel = 100.0
Config.VehicleDirtLevel = 0.0

Config.Blip = {
    enabled = true,
    sprite = 225,
    color = 3,
    scale = 0.75,
    label = 'Vehicle Rental'
}

Config.Ped = {
    enabled = true,
    model = 'a_m_y_business_03',
    scenario = 'WORLD_HUMAN_CLIPBOARD'
}

Config.Vehicles = {
    { label = 'Blista', model = 'blista', price = 250 },
    { label = 'Panto', model = 'panto', price = 200 },
    { label = 'Faggio', model = 'faggio', price = 100 },
    { label = 'Sanchez', model = 'sanchez', price = 350 },
    { label = 'Buffalo', model = 'buffalo', price = 500 }
}

Config.Locations = {
    {
        label = 'Legion Square Rental',
        coords = vec4(220.41, -860.18, 30.20, 341.0),
        spawn = vec4(229.14, -800.82, 30.57, 158.5),
        returnCoords = vec3(232.47, -793.71, 30.58)
    },
    {
        label = 'Airport Rental',
        coords = vec4(-1037.62, -2737.88, 20.17, 330.0),
        spawn = vec4(-1024.68, -2733.61, 20.07, 241.0),
        returnCoords = vec3(-1028.97, -2730.62, 20.07)
    }
}

Config.Text = {
    rentPrompt = '[E] Rent Vehicle',
    returnPrompt = '[E] Return Rental',
    menuTitle = 'Vehicle Rental',
    menuHint = 'Arrow Keys: Navigate  Enter: Select  Backspace: Close',
    noMoney = 'You do not have enough money.',
    rented = 'Vehicle rented. Drive safe.',
    alreadyRented = 'You already have an active rental.',
    rentFailed = 'Could not rent this vehicle.',
    returnSuccess = 'Rental returned.',
    returnFailed = 'This is not your active rental.',
    spawnBlocked = 'The spawn point is blocked.',
    invalidVehicle = 'Invalid rental vehicle.',
    paidRefund = 'Rental returned. Refund received.'
}

Config.GiveKeys = function(vehicle, plate, model)
    if GetResourceState('qb-vehiclekeys') == 'started' then
        TriggerEvent('vehiclekeys:client:SetOwner', plate)
    end

    if GetResourceState('qbx_vehiclekeys') == 'started' then
        TriggerEvent('vehiclekeys:client:SetOwner', plate)
    end
end

Config.SetFuel = function(vehicle, fuel)
    if GetResourceState('LegacyFuel') == 'started' then
        exports['LegacyFuel']:SetFuel(vehicle, fuel)
        return
    end

    if GetResourceState('cdn-fuel') == 'started' then
        exports['cdn-fuel']:SetFuel(vehicle, fuel)
        return
    end

    SetVehicleFuelLevel(vehicle, fuel)
end
