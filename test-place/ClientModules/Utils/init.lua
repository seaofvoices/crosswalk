return function(Modules, ServerModules, Services)
    local module = {}

    function module.GetName()
        return 'utility'
    end

    function module.Verify()
        print('Verify Utils')
        assert(Modules.ClientTest ~= nil)
        assert(Modules.SubUtils ~= nil)
        assert(Modules.SubUtils.GetSubUtilsValue() == 10)
        assert(ServerModules.ServerTest ~= nil)
        Modules.SubUtils.Verify()

        Modules.SharedUtils.Verify()
    end

    return module
end
