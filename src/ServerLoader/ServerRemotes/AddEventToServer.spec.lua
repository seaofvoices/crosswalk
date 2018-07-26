return function()
	local loader = require(script.Parent[script.Name:match('(.+)%.spec$')])
	local basicPrivate = {
		nameServerMap = {},
		nameIdMap = {},
		nameSecurityMap = {},
		remotesToServer = {},
		GetRemoteName = function() return 'remoteName' end,
		GetUniqueId = function() return 'publicId' end
	}
	local function getPrivate()
		local new = {}
		for k, v in pairs(basicPrivate) do
			new[k] = type(v) == 'table' and {} or v
		end
		new.remoteFolder = Instance.new('Folder')
		return new
	end
	local function ReturnTrue()
		return true
	end
	local function ReturnFalse()
		return false
	end

	it('should map `true` to `nameServerMap[module name]`', function()
		local private = getPrivate()
		local AddEventToServer = loader({}, private)
		AddEventToServer('moduleName', 'funcName', function() end, 'High')

		expect(private.nameServerMap.moduleName).to.equal(true)
	end)

	it('should map `High` to `nameSecurityMap` by default', function()
		local private = getPrivate()
		local AddEventToServer = loader({}, private)
		AddEventToServer('moduleName', 'funcName', function() end)

		expect(private.nameSecurityMap.remoteName).to.equal('High')
	end)

	it('should map the given security level string to `nameSecurityMap`', function()
		local private = getPrivate()
		local AddEventToServer = loader({}, private)
		AddEventToServer('moduleName', 'funcName', function() end, 'Low')

		expect(private.nameSecurityMap.remoteName).to.equal('Low')
	end)

	describe('should create a new RemoteEvent object', function()
		local private = getPrivate()

		local AddEventToServer = loader({}, private)
		AddEventToServer('moduleName', 'funcName', function() end)

		local remote = private.remoteFolder:FindFirstChildOfClass('RemoteEvent')

		it('should parent it to the remoteFolder', function()
			expect(#private.remoteFolder:GetChildren()).to.equal(1)
			expect(remote).never.to.equal(nil)
		end)

		it('should map the remote to `remotesToServer[module name][function name]`', function()
			expect(private.remotesToServer.moduleName).never.to.equal(nil)
			expect(private.remotesToServer.moduleName.funcName).to.equal(remote)
		end)

		it('should be named by calling `GetUniqueId()`', function()
			expect(remote.Name).to.equal('publicId')
		end)

		it('should map the name with the id', function()
			expect(private.nameIdMap.remoteName).to.equal('publicId')
		end)
	end)

	describe('should connect the given function to the `OnServerEvent` event', function()
		it('should work when security is set to `None`', function()
			local private = getPrivate()
			local called = false
			local function toConnect()
				called = true
				return true
			end

			local AddEventToServer = loader({}, private)
			AddEventToServer('moduleName', 'funcName', toConnect, 'None')

			local remote = private.remoteFolder:FindFirstChildOfClass('RemoteEvent')
			remote:FireServer()
			expect(called).to.equal(true)
		end)

		it('should work when security is set to `Low`', function()
			local private = getPrivate()
			private.VerifyKey = ReturnTrue
			local called = false
			local function toConnect()
				called = true
				return true
			end

			local AddEventToServer = loader({}, private)
			AddEventToServer('moduleName', 'funcName', toConnect, 'Low')

			local remote = private.remoteFolder:FindFirstChildOfClass('RemoteEvent')
			remote:FireServer()
			expect(called).to.equal(true)
		end)

		it('should work when security is set to `High`', function()
			local private = getPrivate()
			private.VerifyKey = ReturnTrue
			private.NewKey = function()	end
			private.keySender = {FireClient = function() end}
			local called = false
			local function toConnect()
				called = true
				return true
			end

			local AddEventToServer = loader({}, private)
			AddEventToServer('moduleName', 'funcName', toConnect, 'High')

			local remote = private.remoteFolder:FindFirstChildOfClass('RemoteEvent')
			remote:FireServer()
			expect(called).to.equal(true)
		end)
	end)

	describe('should call `onFunctionError` when the given function returns false', function()
		it('should work when security is set to `None`', function()
			local private = getPrivate()
			local called = false
			private.onFunctionError = function()
				called = true
			end

			local AddEventToServer = loader({}, private)
			AddEventToServer('moduleName', 'funcName', ReturnFalse, 'None')

			local remote = private.remoteFolder:FindFirstChildOfClass('RemoteEvent')
			remote:FireServer()

			expect(called).to.equal(true)
		end)

		it('should work when security is set to `Low`', function()
			local private = getPrivate()
			private.VerifyKey = function()
				return true
			end
			local called = false
			private.onFunctionError = function()
				called = true
			end

			local AddEventToServer = loader({}, private)
			AddEventToServer('moduleName', 'funcName', ReturnFalse, 'Low')

			local remote = private.remoteFolder:FindFirstChildOfClass('RemoteEvent')
			remote:FireServer()

			expect(called).to.equal(true)
		end)

		it('should work when security is set to `High`', function()
			local private = getPrivate()
			private.VerifyKey = function()
				return true
			end
			private.NewKey = function()	end
			private.keySender = {FireClient = function() end}
			local called = false
			private.onFunctionError = function()
				called = true
			end

			local AddEventToServer = loader({}, private)
			AddEventToServer('moduleName', 'funcName', ReturnFalse, 'High')

			local remote = private.remoteFolder:FindFirstChildOfClass('RemoteEvent')
			remote:FireServer()

			expect(called).to.equal(true)
		end)
	end)

	describe('should not call `onFunctionError` when the given function returns true', function()
		it('should work when security is set to `None`', function()
			local private = getPrivate()
			local called = false
			private.onFunctionError = function()
				called = true
			end

			local AddEventToServer = loader({}, private)
			AddEventToServer('moduleName', 'funcName', ReturnTrue, 'None')

			local remote = private.remoteFolder:FindFirstChildOfClass('RemoteEvent')
			remote:FireServer()

			expect(called).to.equal(false)
		end)

		it('should work when security is set to `Low`', function()
			local private = getPrivate()
			private.VerifyKey = function()
				return true
			end
			local called = false
			private.onFunctionError = function()
				called = true
			end

			local AddEventToServer = loader({}, private)
			AddEventToServer('moduleName', 'funcName', ReturnTrue, 'Low')

			local remote = private.remoteFolder:FindFirstChildOfClass('RemoteEvent')
			remote:FireServer()

			expect(called).to.equal(false)
		end)

		it('should work when security is set to `High`', function()
			local private = getPrivate()
			private.VerifyKey = function()
				return true
			end
			private.NewKey = function()	end
			private.keySender = {FireClient = function() end}
			local called = false
			private.onFunctionError = function()
				called = true
			end

			local AddEventToServer = loader({}, private)
			AddEventToServer('moduleName', 'funcName', ReturnTrue, 'High')

			local remote = private.remoteFolder:FindFirstChildOfClass('RemoteEvent')
			remote:FireServer()

			expect(called).to.equal(false)
		end)
	end)

	describe('should verify the key correctly', function()
		it('should verify the key when security is set to `Low`', function()
			local private = getPrivate()
			local called = false
			private.VerifyKey = function()
				called = true
				return true
			end

			local AddEventToServer = loader({}, private)
			AddEventToServer('moduleName', 'funcName', ReturnTrue, 'Low')

			local remote = private.remoteFolder:FindFirstChildOfClass('RemoteEvent')
			remote:FireServer()

			expect(called).to.equal(true)
		end)

		it('should verify the key when security is set to `High`', function()
			local private = getPrivate()
			local called = false
			private.VerifyKey = function()
				called = true
				return true
			end
			private.NewKey = function()	end
			private.keySender = {FireClient = function() end}

			local AddEventToServer = loader({}, private)
			AddEventToServer('moduleName', 'funcName', ReturnTrue, 'High')

			local remote = private.remoteFolder:FindFirstChildOfClass('RemoteEvent')
			remote:FireServer()

			expect(called).to.equal(true)
		end)

		it('should not verify the key when security is set to `None`', function()
			local private = getPrivate()
			local called = false
			private.VerifyKey = function()
				called = true
				return true
			end

			local AddEventToServer = loader({}, private)
			AddEventToServer('moduleName', 'funcName', ReturnTrue, 'None')

			local remote = private.remoteFolder:FindFirstChildOfClass('RemoteEvent')
			remote:FireServer()

			expect(called).to.equal(false)
		end)
	end)

	describe('should send new keys correctly', function()
		it('should send a new key when the security is set to `High`', function()
			local private = getPrivate()
			private.VerifyKey = function()
				return true
			end
			private.NewKey = function()	end
			local called = false
			private.keySender = {
				FireClient = function()
					called = true
				end
			}

			local AddEventToServer = loader({}, private)
			AddEventToServer('moduleName', 'funcName', ReturnTrue, 'High')

			local remote = private.remoteFolder:FindFirstChildOfClass('RemoteEvent')
			remote:FireServer()

			expect(called).to.equal(true)
		end)

		it('should not send a new key when the security is set to `Low`', function()
			local private = getPrivate()
			private.VerifyKey = function()
				return true
			end
			private.NewKey = function()	end
			local called = false
			private.keySender = {
				FireClient = function()
					called = true
				end
			}

			local AddEventToServer = loader({}, private)
			AddEventToServer('moduleName', 'funcName', ReturnTrue, 'Low')

			local remote = private.remoteFolder:FindFirstChildOfClass('RemoteEvent')
			remote:FireServer()

			expect(called).to.equal(false)
		end)

		it('should not send a new key when the security is set to `None`', function()
			local private = getPrivate()
			private.VerifyKey = function()
				return true
			end
			private.NewKey = function()	end
			local called = false
			private.keySender = {
				FireClient = function()
					called = true
				end
			}

			local AddEventToServer = loader({}, private)
			AddEventToServer('moduleName', 'funcName', ReturnTrue, 'None')

			local remote = private.remoteFolder:FindFirstChildOfClass('RemoteEvent')
			remote:FireServer()

			expect(called).to.equal(false)
		end)
	end)
end
