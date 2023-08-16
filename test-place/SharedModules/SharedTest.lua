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

    function module.Verify()
        print('Verify SharedTest')
        assert(SharedModules.SharedUtils ~= nil)
        assert(SharedModules.SharedUtils.GetName() == 'utility')
        SharedModules.SharedUtils.Verify()
        assert(SharedModules.SharedSubUtils == nil)
    end

    return module, private
end
