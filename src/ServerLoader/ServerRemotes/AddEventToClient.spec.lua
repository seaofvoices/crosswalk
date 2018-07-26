return function()
	local loader = require(script.Parent[script.Name:match('(.+)%.spec$')])

	it('should map `false` to `nameServerMap[module name]`', function()
		local private = {
			nameServerMap = {},
			nameIdMap = {},
			remotesToClient = {},
			GetRemoteName = function() return 'remoteName' end,
			GetUniqueId = function() return 'publicId' end
		}
		local AddEventToClient = loader({}, private)
		AddEventToClient('moduleName', 'funcName')

		expect(private.nameServerMap.moduleName).to.equal(false)
	end)

	describe('should create a new RemoteEvent object', function()
		local private = {
			nameServerMap = {},
			nameIdMap = {},
			remotesToClient = {},
			remoteFolder = Instance.new('Folder'),
			GetRemoteName = function() return 'remoteName' end,
			GetUniqueId = function() return 'publicId' end
		}
		local AddEventToClient = loader({}, private)
		AddEventToClient('moduleName', 'funcName')

		local remote = private.remoteFolder:FindFirstChildOfClass('RemoteEvent')

		it('should parent it to the remoteFolder', function()
			expect(#private.remoteFolder:GetChildren()).to.equal(1)
			expect(remote).never.to.equal(nil)
		end)

		it('should map the remote to `remotesToClient[module name][function name]`', function()
			expect(private.remotesToClient.moduleName).never.to.equal(nil)
			expect(private.remotesToClient.moduleName.funcName).to.equal(remote)
		end)

		it('should be named by calling `GetUniqueId()`', function()
			expect(remote.Name).to.equal('publicId')
		end)

		it('should map the name with the id', function()
			expect(private.nameIdMap.remoteName).to.equal('publicId')
		end)
	end)

	describe('should return two functions (first wraps `FireClient(plr, ...)`'
		.. ' and the other `FireAllClients(...)`', function()
		local private = {
			nameServerMap = {},
			nameIdMap = {},
			remotesToClient = {},
			remoteFolder = Instance.new('Folder'),
			GetRemoteName = function() return 'remoteName' end,
			GetUniqueId = function() return 'publicId' end
		}
		local AddEventToClient = loader({}, private)
		local fire, fireAll = AddEventToClient('moduleName', 'funcName')

		local remote = private.remoteFolder:FindFirstChildOfClass('RemoteEvent')

		it('should be functions', function()
			expect(fire).to.be.a('function')
			expect(fireAll).to.be.a('function')
		end)

		it('should throw when calling without a player', function()
			expect(fire).to.throw()
		end)

		it('should call `FireAllClients()`', function()
			local called = false
			remote.OnClientEvent:Connect(function()
				called = true
			end)
			fireAll()
			expect(called).to.equal(true)
		end)
	end)
end