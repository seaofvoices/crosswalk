return function(Modules, ServerModules, Services)
    local module = {}
    local private = {}

    function module.Init()
        print('ClientTest.Init()')
    end

    function module.Start()
        print('ClientTest.Start()')
    end

    function module.GetValueFromClient_func()
        return 'client value'
    end

    function module.PrintToClient_event(...)
        print('Client print:', ...)
    end

    function module.TestCanCallSharedModule()
        Modules.SharedTest.PrintShared('This is a message sent by the client')
    end

    function module.TestClientCanCallServerFunction()
        print('TestClientCanCallServerFunction got', ServerModules.ServerTest.GetValueFromServer())
    end

    function module.TestClientCanCallServerDangerFunction()
        print(
            'TestClientCanCallServerFunction (danger) got',
            ServerModules.ServerTest.GetValueFromServerDanger()
        )
    end

    function module.TestClientCanCallServerRiskyFunction()
        print(
            'TestClientCanCallServerFunction (risky) got',
            ServerModules.ServerTest.GetValueFromServerRisky()
        )
    end

    function module.AskTriggerUnapproved_event()
        ServerModules.ServerTest.TriggerUnapproved()
    end

    function module.RunTests_event()
        print("Verify ClientTest")
        assert(Modules.Utils ~= nil)
		assert(Modules.Utils.GetName() == "utility")
		Modules.Utils.Verify()
        assert(Modules.SubUtils == nil)

        warn('CLIENT HAS STARTED TESTS. CHECK IF ALL STRINGS ARE EQUAL')
        print(' ')

        print('client value')
        print(module.GetValueFromClient())
        print('\n')

        print('Client print: Hello')
        module.PrintToClient('Hello')
        print('\n')

        print('SharedTest.PrintShared(client): This is a message sent by the client')
        module.TestCanCallSharedModule()
        print('\n')

        print('TestClientCanCallServerFunction got server value')
        module.TestClientCanCallServerFunction()
        print('\n')

        print('TestClientCanCallServerFunction (danger) got server danger value')
        module.TestClientCanCallServerDangerFunction()
        print('\n')

        print('TestClientCanCallServerFunction (risky) got server risky value')
        module.TestClientCanCallServerRiskyFunction()
        print('\n')

        print('PrintToServer:', Services.Players.LocalPlayer, 'Hello from client !')
        ServerModules.ServerTest.PrintToServer('Hello from client', '!')
        print('\n')

        print('PrintToServerDanger:', Services.Players.LocalPlayer, 'Hello from danger client !')
        ServerModules.ServerTest.PrintToServerDanger('Hello from danger client', '!')
        print('\n')

        print('PrintToServerRisky:', Services.Players.LocalPlayer, 'Hello from risky client !')
        ServerModules.ServerTest.PrintToServerRisky('Hello from risky client', '!')
        print('\n')

        warn('END OF CLIENT TESTS. Client should start the server test now.')

        ServerModules.ServerTest.RunTests()
    end

    return module, private
end
