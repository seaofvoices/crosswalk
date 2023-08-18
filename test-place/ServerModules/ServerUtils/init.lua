return function(Modules, ClientModules, Services)
    local module = {}

    function module.GetName()
        return 'utility'
    end

    function module.Verify()
        print('Verify ServerUtils')
        assert(Modules.ServerTest ~= nil)
        assert(Modules.ServerSubUtils ~= nil)
        assert(Modules.ServerSubUtils.GetSubUtilsValue() == 10)
        assert(ClientModules.ClientTest ~= nil)
        Modules.ServerSubUtils.Verify()

        Modules.SharedUtils.Verify()
    end

    return module
end
