QBCore = exports['qb-core']:GetCoreObject()

local function checkDisabled(Employee, type, job, fire)
    if fire then
        if tonumber(Employee[type]) == 0 then
            return true
        else
            return false
        end
    else
        if tonumber(Employee[type]) < #job then
            return false
        else
            return true
        end
    end
end

local function checkdata(ClubData, dataType, category, name)
    if ClubData.Metadata[dataType] == nil then
        return false
    end
    if ClubData.Metadata[dataType] == Config.Price['Upgrades'][category][name].name then
        return true
    else
        return false
    end
end

local function buyObject(ClubData, dataType, category, name)
    TriggerServerEvent('nightclubs:server:buyObj', ClubData, dataType, category, name)
end

RegisterNetEvent('nightclubs:client:entranceMenu', function(args)
    lib.registerContext({
        id = 'entrance_menu',
        title = 'Entrance Menu',
        options = {
            {
                title = 'Buy, Enter, or Vist a Club',
            },
            {
                title = 'Buy',
                description = Config.Entrance[args.clubKey].description,
                icon = 'coins',
                disabled = args.owned,
                image = "html/img/"..args.clubKey..".webp",
                onSelect = function()
                    TriggerServerEvent('nightclubs:server:buy', args.clubKey)
                end,
            },
            {
                title = 'Go To Nightclub',
                description = 'Enter your night club',
                icon = 'arrow-right',
                disabled = not args.owned,
                onSelect = function()
                    TriggerServerEvent('nightclubs:server:create')
                end,

            },
            {
                title = 'Visit',
                description = 'Visit a friends club',
                icon = 'handshake',
                disavbled = false,
                onSelect = function()
                    TriggerEvent('nightclubs:client:visitClub')
                end,
            },
        }
    })

    lib.showContext('entrance_menu')
end)

RegisterNetEvent('nightclubs:client:leavemenu', function()
    lib.registerContext({
        id = 'leave_menu',
        title = 'Exit Menu',
        options = {
            {
                title = 'Leave the club',
            },
            {
                title = 'Leave',
                description = 'Leave and go back outside',
                icon = 'person-walking-arrow-right',
                onSelect = function()
                    TriggerEvent('nightclubs:client:removeipl')
                    TriggerServerEvent('nightclubs:server:returnEntrance')
                end,
            },
        }
    })

    lib.showContext('leave_menu')
end)

RegisterNetEvent('nightclubs:client:bossMenu', function(ClubData, Employee)
    lib.registerContext({
        id = 'boss_menu',
        title = 'Boss Menu',
        options = {
            {
                title = 'Edit or Upgrade the Club',
            },
            {
                title = 'Buy Upgrades',
                description = 'Buy upgrades for the club',
                icon = 'coins',
                menu = 'buy_upgrades_menu'
            },
            {
                title = 'Gain Reputation Or Do Missions',
                description = 'Buy upgrades for the club or gain reputation',
                icon = 'money-check-dollar',
                menu = 'reputation_menu'
            },
            {
                title = 'Employees',
                description = 'Hire or fire employees',
                icon = 'person-circle-check',
                menu = 'employee_menu'
            },
        }
    })

    lib.showContext('boss_menu')
    for upgkey, upgrade in pairs(Config.Price['Upgrades']) do
        local upgradeOptions = {
            {
                title = 'Change '..upgkey,
                description = 'Buy upgrades for the club',
                icon = upgrade.icon,
                menu = 'buy_'..string.lower(upgkey)..'_upgrades',
            },
        }
        for k, v in pairs(upgrade.items) do
            upgradeOptions[upgradeOptions+1] = {
                {
                    title = v.title,
                    description = '$' .. tostring(v.price).. " "..(v.description or ""),
                    disabled = checkdata(ClubData, 'style', 'Style', 'Traditional'),
                    icon = 'coins',
                    onSelect = function()
                        buyObject(ClubData, upgkey:lower(), upgkey, k)
                    end,
                },
            }
        end
        lib.registerContext({
            id = upgrade.id,
            title = upgrade.title,
            options = upgradeOptions
        })
    end

    -- Reputation
    lib.registerContext({
        id = 'reputation_menu',
        title = 'Gain Reputation',
        options = {
            {
                title = 'Boost popularity within the club',
            },
            {
                title = 'Put up posters',
                description = 'Put posters around San Andreas to attract attention',
                icon = 'clipboard-user',
                onSelect = function()
                    TriggerServerEvent('nightclubs:server:posterGetMissionData')
                end,
            },
            {
                title = 'Steal Equiptment',
                description = 'Steal lights, speakers, and turntables from around San Andreas',
                icon = 'radio',
                onSelect = function()
                    TriggerServerEvent('nightclubs:server:equiptmentGetMissionData')
                end,
            },
            {
                title = 'Collect Food',
                description = 'Collect food for customers to buy, affects popularity',
                icon = 'utensils',
                onSelect = function()
                    TriggerServerEvent('nightclubs:server:foodGetData')
                end,
            },
        }
    })

    -- Employee
    lib.registerContext({
        id = 'employee_menu',
        title = 'Hire Employees for your club',
        options = {
            {
                title = 'Hire or Fire Employees',
            },
            {
                title = 'Dj',
                description = 'Hire a dj to play music, requires speakers and turntable',
                icon = 'music',
                menu = 'emoloyee_dj_menu',
                metadata = {
                    { label = 'Payment', value = Config.Employee.dj.price },
                },
            },
            {
                title = 'Dancers',
                description = 'Hire dancers to boost popularity',
                menu = 'emoloyee_dancer_menu',
                icon = 'person-dress',
                metadata = {
                    { label = 'Payment', value = Config.Employee.dancers.price },
                },
            },
            {
                title = 'Bar Tenders',
                description = 'Hire bar tenders and unlock the ability to sell food and drinks',
                icon = 'martini-glass-empty',
                menu = 'emoloyee_tender_menu',
                metadata = {
                    { label = 'Payment', value = Config.Employee.tenders.price },
                },
            },
        }
    })

    lib.registerContext({
        id = 'emoloyee_dj_menu',
        title = 'Hire the DJ',
        options = {
            {
                title = 'Click to hire or fire ' .. Employee['dj'] .. '/' .. #Config.Employee.dj.locations,
            },
            {
                title = 'Hire',
                description = 'Hire a dj to play music, requires speakers and turntable',
                icon = 'check',
                onSelect = function()
                    if ClubData.Metadata['speakers'] ~= tostring(nil) and ClubData.Metadata['turntables'] ~= tostring(nil) then
                        TriggerServerEvent('nightclubs:server:employeesFunction', 'dj', true)
                        QBCore.Functions.Notify('Hired dj sucessfully', "success")
                    else
                        QBCore.Functions.Notify('Could not hire, missing turntables or speakers', "error")
                    end
                    
                end,
                disabled = checkDisabled(Employee, 'dj', Config.Employee.dj.locations, false)
            },
            {
                title = 'Fire',
                description = 'Fire the DJ',
                icon = 'circle-xmark',
                onSelect = function()
                    TriggerServerEvent('nightclubs:server:employeesFunction', 'dj', false)
                    QBCore.Functions.Notify('Fired dj sucessfully', "success")
                end,
                disabled = checkDisabled(Employee, 'dj', Config.Employee.dj.locations, true)
            },
        }
    })

    lib.registerContext({
        id = 'emoloyee_dancer_menu',
        title = 'Hire the Dancers',
        options = {
            {
                title = 'Click to hire or fire '  .. Employee['dancers'] .. '/' .. #Config.Employee.dancers.locations,
            },
            {
                title = 'Hire',
                description = 'Hire the dancers, requires podiums',
                icon = 'check',
                onSelect = function()
                    if ClubData.Metadata['podium'] ~= tostring(nil) then
                        TriggerServerEvent('nightclubs:server:employeesFunction', 'dancers', true)
                        QBCore.Functions.Notify('Hired a dancer sucessfully', "success")
                    else
                        QBCore.Functions.Notify('Could not hire, missing podiums', "error")
                    end
                    
                end,
                disabled = checkDisabled(Employee, 'dancers', Config.Employee.dancers.locations, false)
            },
            {
                title = 'Fire',
                description = 'Fire a dancer',
                icon = 'circle-xmark',
                onSelect = function()
                    TriggerServerEvent('nightclubs:server:employeesFunction', 'dancers', false)
                    QBCore.Functions.Notify('Fired dancer sucessfully', "success")
                end,
                disabled = checkDisabled(Employee, 'dancers', Config.Employee.dancers.locations, true)
            },
        }
    })

    lib.registerContext({
        id = 'emoloyee_tender_menu',
        title = 'Hire the Bar Tenders',
        options = {
            {
                title = 'Click to hire or fire '  .. Employee['tenders'] .. '/' .. #Config.Employee.tenders.locations,
            },
            {
                title = 'Hire',
                description = 'Hire the bar tenders',
                icon = 'check',
                onSelect = function()
                        TriggerServerEvent('nightclubs:server:employeesFunction', 'tenders', true)
                        QBCore.Functions.Notify('Hired a bar tender sucessfully', "success")         
                end,
                disabled = checkDisabled(Employee, 'tenders', Config.Employee.tenders.locations, false)
            },
            {
                title = 'Fire',
                description = 'Fire a bar tender',
                icon = 'circle-xmark',
                onSelect = function()
                    TriggerServerEvent('nightclubs:server:employeesFunction', 'tenders', false)
                    QBCore.Functions.Notify('Fired bar tender sucessfully', "success")
                end,
                disabled = checkDisabled(Employee, 'tenders', Config.Employee.tenders.locations, true)
            },
        }
    })
end)