return function()
	local loader = require(script.Parent[script.Name:match('(.+)%.spec$')])

	local basicPrivate = {
		remotesToServer = {},
		remotesToClient = {},
		playerKeys = {},
		nameServerMap = {},
		GetRemoteName = function() return 'remoteName' end,
		GetKey = function() return 'secret' end
	}
	local function getPrivate()
		local new = {}
		for k, v in pairs(basicPrivate) do
			new[k] = type(v) == 'table' and {} or v
		end
		return new
	end

	local plrMock = {}

	it('should return a table with the correct fields', function()
		local private = getPrivate()
		local GetRemoteData = loader({}, private)

		local data = GetRemoteData(plrMock)
		expect(data).to.be.a('table')
		expect(data.Keys).to.be.a('table')
		expect(data.Names).to.be.a('table')
		expect(data.WaitForKeyNames).to.be.a('table')
		expect(data.NameServerMap).to.be.a('table')
		expect(data.NameServerMap).to.equal(private.nameServerMap)
	end)

	it('should save the new keys in `private.playerKeys[player]`', function()
		local private = getPrivate()
		local GetRemoteData = loader({}, private)

		GetRemoteData(plrMock)
		expect(private.playerKeys[plrMock]).to.be.a('table')
	end)

	it('should add the data for a remote to server when security is set to `High`', function()
		local private = getPrivate()
		private.nameSecurityMap = {remoteName = 'High'}
		private.nameIdMap = {remoteName = 'remoteId'}
		private.remotesToServer.module = {
			foo = function() end
		}
		local GetRemoteData = loader({}, private)

		local data = GetRemoteData(plrMock)

		expect(data.Keys.module).to.be.a('table')
		expect(data.Keys.module.foo).to.equal('secret')
		expect(data.Names.module).to.be.a('table')
		expect(data.Names.module.foo).to.equal('remoteId')
		expect(data.WaitForKeyNames.module).to.be.a('table')
		expect(data.WaitForKeyNames.module.foo).to.equal(true)
	end)

	it('should add the data for a remote to server when security is set to `Low`', function()
		local private = getPrivate()
		private.nameSecurityMap = {remoteName = 'Low'}
		private.nameIdMap = {remoteName = 'remoteId'}
		private.remotesToServer.module = {
			foo = function() end
		}
		local GetRemoteData = loader({}, private)

		local data = GetRemoteData(plrMock)

		expect(data.Keys.module).to.be.a('table')
		expect(data.Keys.module.foo).to.equal('secret')
		expect(data.Names.module).to.be.a('table')
		expect(data.Names.module.foo).to.equal('remoteId')
		expect(data.WaitForKeyNames.module).to.be.a('table')
		expect(data.WaitForKeyNames.module.foo).to.equal(nil)
	end)

	it('should add the data for a remote to server when security is set to `None`', function()
		local private = getPrivate()
		private.nameSecurityMap = {remoteName = 'None'}
		private.nameIdMap = {remoteName = 'remoteId'}
		private.remotesToServer.module = {
			foo = function() end
		}
		local GetRemoteData = loader({}, private)

		local data = GetRemoteData(plrMock)

		expect(data.Keys.module).to.be.a('table')
		expect(data.Keys.module.foo).to.equal(nil)
		expect(data.Names.module).to.be.a('table')
		expect(data.Names.module.foo).to.equal('remoteId')
		expect(data.WaitForKeyNames.module).to.be.a('table')
		expect(data.WaitForKeyNames.module.foo).to.equal(nil)
	end)

	it('should add the data for a remote to client', function()
		local private = getPrivate()
		private.nameIdMap = {remoteName = 'remoteId'}
		private.remotesToClient.module = {
			foo = function() end
		}
		local GetRemoteData = loader({}, private)

		local data = GetRemoteData(plrMock)

		expect(data.Keys.module).to.equal(nil)
		expect(data.Names.module).to.be.a('table')
		expect(data.Names.module.foo).to.equal('remoteId')
		expect(data.WaitForKeyNames.module).to.equal(nil)
	end)
end