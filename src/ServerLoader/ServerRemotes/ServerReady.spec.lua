return function()
	local loader = require(script.Parent[script.Name:match('(.+)%.spec$')])

	it('should parent the remote folder to ReplicatedStorage', function()
		local private = {
			remoteFolder = {}
		}
		local MockServerReady = loader({}, private)

		MockServerReady()
		expect(private.remoteFolder.Parent).to.equal(game:GetService('ReplicatedStorage'))
	end)
end