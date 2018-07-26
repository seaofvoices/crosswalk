return function()
	local loader = require(script.Parent[script.Name:match('(.+)%.spec$')])

	local plrMock = {
		Name = 'jeparlefrancais'
	}

	it('should return false when plr is not found', function()
		local private = {
			onKeyError = function() end,
			onKeyMissing = function() end,
			playerKeys = {}
		}
		local VerifyKey = loader({}, private)
		local result = VerifyKey(plrMock, 'mod', 'func', 'secret')

		expect(result).to.equal(false)
	end)

	it('should call `onKeyMissing` when plr is not found', function()
		local called = false
		local keyErrorCalled = false
		local private = {
			onKeyError = function()
				keyErrorCalled = true
			end,
			onKeyMissing = function(plr, moduleName, funcName)
				called = true
			end,
			playerKeys = {}
		}
		local VerifyKey = loader({}, private)
		VerifyKey(plrMock, 'mod', 'func', 'secret')

		expect(called).to.equal(true)
		expect(keyErrorCalled).to.equal(false)
	end)

	it('should call `onKeyMissing` with the correct arguments when player is not found', function()
		local private = {
			onKeyError = function()	end,
			onKeyMissing = function(plr, moduleName, funcName)
				expect(plr).to.equal(plrMock)
				expect(moduleName).to.equal('mod')
				expect(funcName).to.equal('func')
			end,
			playerKeys = {}
		}
		local VerifyKey = loader({}, private)
		VerifyKey(plrMock, 'mod', 'func', 'secret')
	end)

	it('should return false when the module name is not found', function()
		local private = {
			onKeyError = function() end,
			onKeyMissing = function() end,
			playerKeys = {[plrMock] = {}}
		}
		local VerifyKey = loader({}, private)
		local result = VerifyKey(plrMock, 'mod', 'func', 'secret')

		expect(result).to.equal(false)
	end)

	it('should call `onKeyMissing` when the module name is not found', function()
		local called = false
		local keyErrorCalled = false
		local private = {
			onKeyError = function()
				keyErrorCalled = true
			end,
			onKeyMissing = function(plr, moduleName, funcName)
				called = true
			end,
			playerKeys = {[plrMock] = {}}
		}
		local VerifyKey = loader({}, private)
		VerifyKey(plrMock, 'mod', 'func', 'secret')

		expect(called).to.equal(true)
		expect(keyErrorCalled).to.equal(false)
	end)

	it('should call `onKeyMissing` with the correct arguments when the module name is not found', function()
		local private = {
			onKeyError = function()	end,
			onKeyMissing = function(plr, moduleName, funcName)
				expect(plr).to.equal(plrMock)
				expect(moduleName).to.equal('mod')
				expect(funcName).to.equal('func')
			end,
			playerKeys = {[plrMock] = {}}
		}
		local VerifyKey = loader({}, private)
		VerifyKey(plrMock, 'mod', 'func', 'secret')
	end)

	it('should return false when the function name is not found', function()
		local private = {
			onKeyError = function() end,
			onKeyMissing = function() end,
			playerKeys = {
				[plrMock] = {mod = {}}
			}
		}
		local VerifyKey = loader({}, private)
		local result = VerifyKey(plrMock, 'mod', 'func', 'secret')

		expect(result).to.equal(false)
	end)

	it('should call `onKeyMissing` when the function name is not found', function()
		local called = false
		local keyErrorCalled = false
		local private = {
			onKeyError = function()
				keyErrorCalled = true
			end,
			onKeyMissing = function(plr, moduleName, funcName)
				called = true
			end,
			playerKeys = {[plrMock] = {
				mod = {}
			}}
		}
		local VerifyKey = loader({}, private)
		VerifyKey(plrMock, 'mod', 'func', 'secret')

		expect(called).to.equal(true)
		expect(keyErrorCalled).to.equal(false)
	end)

	it('should call `onKeyMissing` with the correct arguments when the function name is not found', function()
		local private = {
			onKeyError = function()	end,
			onKeyMissing = function(plr, moduleName, funcName)
				expect(plr).to.equal(plrMock)
				expect(moduleName).to.equal('mod')
				expect(funcName).to.equal('func')
			end,
			playerKeys = {[plrMock] = {
				mod = {}
			}}
		}
		local VerifyKey = loader({}, private)
		VerifyKey(plrMock, 'mod', 'func', 'secret')
	end)

	it('should call `onKeyError` when the keys do not match', function()
		local called = false
		local missingKeyCalled = false
		local private = {
			onKeyError = function()
				called = true
			end,
			onKeyMissing = function()
				missingKeyCalled = true
			end,
			playerKeys = {[plrMock] = {
				mod = {func = 'no secret'}
			}}
		}
		local VerifyKey = loader({}, private)
		VerifyKey(plrMock, 'mod', 'func', 'secret')

		expect(called).to.equal(true)
		expect(missingKeyCalled).to.equal(false)
	end)

	it('should call `onKeyError` with the correct arguments when the keys do not match', function()
		local called = false
		local private = {
			onKeyError = function(plr, moduleName, funcName)
				called = true
				expect(plr).to.equal(plrMock)
				expect(moduleName).to.equal('mod')
				expect(funcName).to.equal('func')
			end,
			onKeyMissing = function() end,
			playerKeys = {[plrMock] = {
				mod = {func = 'no secret'}
			}}
		}
		local VerifyKey = loader({}, private)
		VerifyKey(plrMock, 'mod', 'func', 'secret')

		expect(called).to.equal(true)
	end)

	it('should return true when the keys match', function()
		local private = {
			onKeyError = function() end,
			onKeyMissing = function() end,
			playerKeys = {[plrMock] = {
				mod = {func = 'secret'}
			}}
		}
		local VerifyKey = loader({}, private)
		local result = VerifyKey(plrMock, 'mod', 'func', 'secret')

		expect(result).to.equal(true)
	end)
end