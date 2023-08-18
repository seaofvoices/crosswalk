return function(SharedModules, Services, isServer)
    local module = {}

    function module.GetName()
        return 'utility'
    end

    function module.Verify()
        print('Verify SharedUtils')
        assert(SharedModules.SharedTest ~= nil)
        assert(SharedModules.SharedSubUtils ~= nil)
        assert(SharedModules.SharedSubUtils.GetSubUtilsValue() == 10)
        SharedModules.SharedSubUtils.Verify()
    end

    return module
end
