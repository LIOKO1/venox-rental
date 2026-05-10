local Bridge = {
    framework = 'standalone',
    object = nil
}

local function resourceStarted(resource)
    return GetResourceState(resource) == 'started'
end

local function detectFramework()
    if Config.Framework ~= 'auto' then
        return Config.Framework
    end

    if resourceStarted('qbx_core') then
        return 'qbox'
    end

    if resourceStarted('qb-core') then
        return 'qb'
    end

    if resourceStarted('es_extended') then
        return 'esx'
    end

    return 'standalone'
end

function Bridge.Init()
    Bridge.framework = detectFramework()

    if Bridge.framework == 'qb' then
        Bridge.object = exports['qb-core']:GetCoreObject()
    elseif Bridge.framework == 'qbox' then
        Bridge.object = exports.qbx_core
    elseif Bridge.framework == 'esx' then
        Bridge.object = exports['es_extended']:getSharedObject()
    end

    print(('[venox-rental] Framework: %s'):format(Bridge.framework))
end

function Bridge.GetFramework()
    return Bridge.framework
end

function Bridge.GetPlayer(source)
    if Bridge.framework == 'qb' then
        return Bridge.object.Functions.GetPlayer(source)
    end

    if Bridge.framework == 'qbox' then
        return Bridge.object:GetPlayer(source)
    end

    if Bridge.framework == 'esx' then
        return Bridge.object.GetPlayerFromId(source)
    end

    return { source = source }
end

function Bridge.GetMoney(source, account)
    local player = Bridge.GetPlayer(source)
    if not player then
        return 0
    end

    if Bridge.framework == 'qb' then
        return player.PlayerData.money[account] or 0
    end

    if Bridge.framework == 'qbox' then
        return player.PlayerData.money[account] or 0
    end

    if Bridge.framework == 'esx' then
        if account == 'cash' then
            return player.getMoney()
        end

        local xAccount = player.getAccount(account)
        return xAccount and xAccount.money or 0
    end

    return Config.StandaloneFree and 999999999 or 0
end

function Bridge.RemoveMoney(source, account, amount, reason)
    amount = tonumber(amount) or 0
    if amount <= 0 then
        return true
    end

    local player = Bridge.GetPlayer(source)
    if not player then
        return false
    end

    if Bridge.framework == 'qb' then
        return player.Functions.RemoveMoney(account, amount, reason or 'vehicle-rental')
    end

    if Bridge.framework == 'qbox' then
        return player.Functions.RemoveMoney(account, amount, reason or 'vehicle-rental')
    end

    if Bridge.framework == 'esx' then
        if account == 'cash' then
            player.removeMoney(amount)
        else
            player.removeAccountMoney(account, amount)
        end

        return true
    end

    return Config.StandaloneFree
end

function Bridge.AddMoney(source, account, amount, reason)
    amount = tonumber(amount) or 0
    if amount <= 0 then
        return true
    end

    local player = Bridge.GetPlayer(source)
    if not player then
        return false
    end

    if Bridge.framework == 'qb' then
        player.Functions.AddMoney(account, amount, reason or 'vehicle-rental-refund')
        return true
    end

    if Bridge.framework == 'qbox' then
        player.Functions.AddMoney(account, amount, reason or 'vehicle-rental-refund')
        return true
    end

    if Bridge.framework == 'esx' then
        if account == 'cash' then
            player.addMoney(amount)
        else
            player.addAccountMoney(account, amount)
        end

        return true
    end

    return true
end

function Bridge.Notify(source, message, notifyType)
    TriggerClientEvent('venox-rental:client:notify', source, message, notifyType or 'primary')
end

Bridge.Init()
VenoxRental.Bridge = Bridge
