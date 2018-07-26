return function(Modules, ClientModules, Services)
	local module = {}
	local private = {}

	function module.Init()
		print('ServerTest.Init()')
	end

	function module.Start()
		print('ServerTest.Start()')
	end

	function module.GetValueFromServer_func(plr)
		return true, 'server value'
	end

	function module.GetValueFromServerDanger_danger_func(plr)
		return true, 'server danger value'
	end

	function module.GetValueFromServerRisky_risky_func(plr)
		return true, 'server risky value'
	end

	function module.PrintToServer_event(plr, ...)
		print('PrintToServer:', plr, ...)
		return true
	end

	function module.PrintToServerDanger_danger_event(plr, ...)
		print('PrintToServerDanger:', plr, ...)
		return true
	end

	function module.PrintToServerRisky_risky_event(plr, ...)
		print('PrintToServerRisky:', plr, ...)
		return true
	end

	function module.TestCanCallSharedModule()
		Modules.SharedTest.PrintShared('This is a message sent by the server')
	end

	function module.TestCanCallClientFunction()
		print('TestClientCanCallServerFunction got ', ClientModules.ClientTest.GetValueFromServer())
	end

	function module.RunTests_event(plr)
		warn('STARTING SERVER TESTS FROM ' .. plr.Name)
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

		print('PrintToServer:', plr, '- success')
		module.PrintToServer(plr, '- success')
		print('\n')

		print('PrintToServerDanger:', plr, '- success')
		module.PrintToServerDanger(plr, '- success')
		print('\n')

		print('PrintToServerRisky:', plr, '- success')
		module.PrintToServerRisky(plr, '- success')
		print('\n')

		print('client value')
		print(ClientModules.ClientTest.GetValueFromClient(plr))
		print('\n')

		print('Client print:', plr, 'hello!')
		ClientModules.ClientTest.PrintToClient(plr, plr, 'hello!')
		print('\n')

		warn('END OF SERVER TESTS.')

		return true
	end

	return module, private
end
