return function(Modules, ClientModules, Services)
    local module = {}

    function module.GetSubUtilsValue()
        return 10
    end

    function module.Verify()
        print('Verify ServerSubUtils')
        assert(Modules.ServerTest ~= nil)
        assert(Modules.ServerUtils ~= nil)
        assert(Modules.ServerUtils.GetName() == 'utility')
        assert(ClientModules.ClientTest ~= nil)
    end

    return module
end
