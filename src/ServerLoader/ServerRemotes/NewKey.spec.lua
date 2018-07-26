return function()
	local loader = require(script.Parent[script.Name:match('(.+)%.spec$')])

	local mockPlr = {}

	it('should call NewKey to obtain a new key', function()
		local called = false
		local private = {
			GetKey = function()
				called = true
				return 'secret'
			end,
			playerKeys = {
				[mockPlr] = {TestModule = {}}
			}
		}
		local NewKey = loader({}, private)

		NewKey(mockPlr, 'TestModule', 'TestFunction')

		expect(called).to.equal(true)
	end)

	it('should save the returned key in playerKeys[plr]', function()
		local key = 'secret'
		local private = {
			GetKey = function()
				return key
			end,
			playerKeys = {
				[mockPlr] = {TestModule = {}}
			}
		}
		local NewKey = loader({}, private)

		NewKey(mockPlr, 'TestModule', 'TestFunction')

		expect(private.playerKeys[mockPlr].TestModule.TestFunction).to.equal(key)
	end)
end