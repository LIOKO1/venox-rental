VenoxRental = VenoxRental or {}

function VenoxRental.Debug(message)
    if Config.Debug then
        print(('[venox-rental] %s'):format(message))
    end
end

function VenoxRental.TrimPlate(plate)
    return (plate or ''):gsub('^%s*(.-)%s*$', '%1')
end

function VenoxRental.MakePlate(source)
    local prefix = tostring(Config.PlatePrefix or 'RENT'):upper():sub(1, 4)
    local random = math.random(100, 999)
    local id = tonumber(source) or 0

    return ('%s%03d%d'):format(prefix, id % 1000, random):sub(1, 8)
end

function VenoxRental.GetLocation(index)
    index = tonumber(index)
    if not index or not Config.Locations[index] then
        return nil
    end

    return Config.Locations[index]
end

function VenoxRental.GetVehicle(index)
    index = tonumber(index)
    if not index or not Config.Vehicles[index] then
        return nil
    end

    return Config.Vehicles[index]
end
