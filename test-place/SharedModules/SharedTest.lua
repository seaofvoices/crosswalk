return function(SharedModules, Services, isServer)
	local module = {}
	local private = {}

	function module.Init()
		print('SharedTest.Init() from ' .. (isServer and 'server' or 'client'))
	end

	function module.Start()
		print('SharedTest.Start() from ' .. (isServer and 'server' or 'client'))
	end

	function module.PrintShared(...)
		print('SharedTest.PrintShared(' .. (isServer and 'server' or 'client') .. '):', ...)
	end

	return module, private
end
