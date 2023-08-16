return function(Modules, ClientModules, Services)
    local module = {}
    local private = {}

    function module.Init()
        print('ServerTest.Init()')
    end

    function module.Start()
        print('ServerTest.Start()')
    end

    function module.OnPlayerReady(player)
        print('ServerTest.OnPlayerReady()')
        print('Starting tests from server to', player.Name)
        ClientModules.ClientTest.RunTests(player)
    end

    function module.OnUnapprovedExecution(player, info)
        print('OnUnapprovedExecution', player.Name, '-', info.functionName)
    end

    function module.GetValueFromServer_func(_player)
        return true, 'server value'
    end

    function module.GetValueFromServerDanger_danger_func(_player)
        return true, 'server danger value'
    end

    function module.GetValueFromServerRisky_risky_func(_player)
        return true, 'server risky value'
    end

    function module.TriggerUnapproved_event(player, ...)
        print('TriggerUnapproved:', player, ...)
        return false
    end

    function module.PrintToServer_event(player, ...)
        print('PrintToServer:', player, ...)
        return true
    end

    function module.PrintToServerDanger_danger_event(player, ...)
        print('PrintToServerDanger:', player, ...)
        return true
    end

    function module.PrintToServerRisky_risky_event(player, ...)
        print('PrintToServerRisky:', player, ...)
        return true
    end

    function module.TestCanCallSharedModule()
        Modules.SharedTest.PrintShared('This is a message sent by the server')
    end

    function module.TestCanCallClientFunction()
        print('TestClientCanCallServerFunction got ', ClientModules.ClientTest.GetValueFromServer())
    end

    function module.RunTests_event(player)
        print('Verify ServerTest')
        assert(Modules.ServerUtils ~= nil)
        assert(Modules.ServerUtils.GetName() == 'utility')
        Modules.ServerUtils.Verify()
        assert(Modules.SubUtils == nil)

        warn('STARTING SERVER TESTS FROM ' .. player.Name)
        print('\n')

        print('SharedTest.PrintShared(server):', 'hello from server')
        Modules.SharedTest.PrintShared('hello from server')
        print('\n')

        print('server value')
        print(module.GetValueFromServer())
        print('\n')

        print('server danger value')
        print(module.GetValueFromServerDanger())
        print('\n')

        print('server risky value')
        print(module.GetValueFromServerRisky())
        print('\n')

        print('PrintToServer:', player, '- success')
        module.PrintToServer(player, '- success')
        print('\n')

        print('PrintToServerDanger:', player, '- success')
        module.PrintToServerDanger(player, '- success')
        print('\n')

        print('PrintToServerRisky:', player, '- success')
        module.PrintToServerRisky(player, '- success')
        print('\n')

        print('client value')
        print(ClientModules.ClientTest.GetValueFromClient(player))
        print('\n')

        print('Client print:', player, 'hello!')
        ClientModules.ClientTest.PrintToClient(player, player, 'hello!')
        print('\n')

        print('Ask client to trigger unapproved rquest', player)
        ClientModules.ClientTest.AskTriggerUnapproved(player, player, 'hello!')
        print('\n')

        warn('END OF SERVER TESTS.')

        return true
    end

    return module, private
end
