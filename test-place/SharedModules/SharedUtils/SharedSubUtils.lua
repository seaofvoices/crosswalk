return function(SharedModules, Services, isServer)
    local module = {}

    function module.GetSubUtilsValue()
        return 10
    end

    function module.Verify()
        print('Verify SharedSubUtils')
        assert(SharedModules.SharedTest ~= nil)
        assert(SharedModules.SharedUtils ~= nil)
        assert(SharedModules.SharedUtils.GetName() == 'utility')
    end

    return module
end
