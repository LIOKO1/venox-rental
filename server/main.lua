local activeRentals = {}

local function notify(source, message, notifyType)
    VenoxRental.Bridge.Notify(source, message, notifyType)
end

RegisterNetEvent('venox-rental:server:rentVehicle', function(locationIndex, vehicleIndex)
    local source = source
    local location = VenoxRental.GetLocation(locationIndex)
    local rental = VenoxRental.GetVehicle(vehicleIndex)

    if not location or not rental then
        notify(source, Config.Text.invalidVehicle, 'error')
        return
    end

    if Config.OneRentalPerPlayer and activeRentals[source] then
        notify(source, Config.Text.alreadyRented, 'error')
        return
    end

    local price = tonumber(rental.price) or 0
    local account = Config.PaymentAccount or 'cash'

    if VenoxRental.Bridge.GetMoney(source, account) < price then
        notify(source, Config.Text.noMoney, 'error')
        return
    end

    if not VenoxRental.Bridge.RemoveMoney(source, account, price, 'vehicle-rental') then
        notify(source, Config.Text.rentFailed, 'error')
        return
    end

    local plate = VenoxRental.MakePlate(source)

    activeRentals[source] = {
        plate = plate,
        model = rental.model,
        price = price,
        account = account,
        rentedAt = os.time()
    }

    TriggerClientEvent('venox-rental:client:spawnVehicle', source, {
        model = rental.model,
        label = rental.label,
        plate = plate,
        spawn = location.spawn,
        price = price
    })
end)

RegisterNetEvent('venox-rental:server:returnVehicle', function(plate)
    local source = source
    local rental = activeRentals[source]
    plate = VenoxRental.TrimPlate(plate)

    if not rental or VenoxRental.TrimPlate(rental.plate) ~= plate then
        notify(source, Config.Text.returnFailed, 'error')
        return
    end

    activeRentals[source] = nil

    if Config.RefundOnReturn then
        local refund = math.floor((rental.price or 0) * ((Config.RefundPercent or 0) / 100))
        VenoxRental.Bridge.AddMoney(source, rental.account or Config.PaymentAccount or 'cash', refund, 'vehicle-rental-refund')
        notify(source, Config.Text.paidRefund, 'success')
    else
        notify(source, Config.Text.returnSuccess, 'success')
    end

    TriggerClientEvent('venox-rental:client:finishReturn', source, plate)
end)

AddEventHandler('playerDropped', function()
    activeRentals[source] = nil
end)
