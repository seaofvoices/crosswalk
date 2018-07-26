return function()
	local loader = require(script.Parent[script.Name:match('(.+)%.spec$')])

	local mockPlr = {}

	it('should return true when playerKeys[plr] contains a table', function()
		local private = {
			playerKeys = {
				[mockPlr] = {}
			}
		}
		local IsRemoteDataSent = loader({}, private)

		expect(IsRemoteDataSent(mockPlr)).to.equal(true)
	end)

	it('should return false when playerKeys[plr] is empty', function()
		local private = {
			playerKeys = {}
		}
		local IsRemoteDataSent = loader({}, private)

		expect(IsRemoteDataSent(mockPlr)).to.equal(false)
	end)
end