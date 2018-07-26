return function()
	local loader = require(script.Parent[script.Name:match('(.+)%.spec$')])

	it('should set the given duration', function()
		local private = {
			remoteCallMaxDelay = 'override'
		}

		local SetClientCallMaxDelay = loader({}, private)
		SetClientCallMaxDelay(2)

		expect(private.remoteCallMaxDelay).to.equal(2)
	end)
end