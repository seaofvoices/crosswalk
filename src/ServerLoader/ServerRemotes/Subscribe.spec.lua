return function()
	local loader = require(script.Parent[script.Name:match('(.+)%.spec$')])

	local Subscribe = loader({}, {})

	it('should work with event named `FunctionError`', function()
		expect(function()
			Subscribe('FunctionError', function() end)
		end).never.to.throw(true)
	end)

	it('should set the callback `onFunctionError` for event named `FunctionError`', function()
		local private = {}
		local MockSubscribe = loader({}, private)

		local callback = function() end
		MockSubscribe('FunctionError', callback)
		expect(private.onFunctionError).to.equal(callback)
	end)

	it('should work with event named `KeyError`', function()
		expect(function()
			Subscribe('KeyError', function() end)
		end).never.to.throw(true)
	end)

	it('should set the callback `onKeyError` for event named `KeyError`', function()
		local private = {}
		local MockSubscribe = loader({}, private)

		local callback = function() end
		MockSubscribe('KeyError', callback)
		expect(private.onKeyError).to.equal(callback)
	end)

	it('should work with event named `SecondPlayerRequest`', function()
		expect(function()
			Subscribe('SecondPlayerRequest', function() end)
		end).never.to.throw(true)
	end)

	it('should set the callback `onSecondPlayerRequest` for event named `SecondPlayerRequest`', function()
		local private = {}
		local MockSubscribe = loader({}, private)

		local callback = function() end
		MockSubscribe('SecondPlayerRequest', callback)
		expect(private.onSecondPlayerRequest).to.equal(callback)
	end)

	it('should work with event named `KeyMissing`', function()
		expect(function()
			Subscribe('KeyMissing', function() end)
		end).never.to.throw(true)
	end)

	it('should set the callback `onKeyMissing` for event named `KeyMissing`', function()
		local private = {}
		local MockSubscribe = loader({}, private)

		local callback = function() end
		MockSubscribe('KeyMissing', callback)
		expect(private.onKeyMissing).to.equal(callback)
	end)

	it('should work with event named `PlayerReady`', function()
		expect(function()
			Subscribe('PlayerReady', function() end)
		end).never.to.throw(true)
	end)

	it('should set the callback `onPlayerReady` for event named `PlayerReady`', function()
		local private = {}
		local MockSubscribe = loader({}, private)

		local callback = function() end
		MockSubscribe('PlayerReady', callback)
		expect(private.onPlayerReady).to.equal(callback)
	end)
end