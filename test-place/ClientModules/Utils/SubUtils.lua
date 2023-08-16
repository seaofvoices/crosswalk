return function(Modules, ServerModules, Services)
    local module = {}

    function module.GetSubUtilsValue()
        return 10
    end

    function module.Verify()
        print("Verify SubUtils")
        assert(Modules.ClientTest ~= nil)
        assert(Modules.SubUtils ~= nil)
        assert(Modules.Utils ~= nil)
		assert(Modules.Utils.GetName() == "utility")
        assert(ServerModules.ServerTest ~= nil)
    end

    return module
end
