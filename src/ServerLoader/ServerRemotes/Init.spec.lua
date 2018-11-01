return function()
	local loader = require(script.Parent[script.Name:match('(.+)%.spec$')])
	local private = {
		GetUniqueId = function()
			return 'uniqueId'
		end
	}
	local Init = loader({}, private)

	Init()

	it('should create a folder for the remotes', function()
		expect(private.remoteFolder).to.be.a('userdata')
		expect(private.remoteFolder:IsA('Folder')).to.equal(true)
	end)

	it('should create a RemoteFunction to send the remotes data', function()
		expect(private.dataSender).to.be.a('userdata')
		expect(private.dataSender:IsA('RemoteFunction')).to.equal(true)
	end)

	it('should create a RemoteEvent to notify the server that the player is ready', function()
		expect(private.playerReady).to.be.a('userdata')
		expect(private.playerReady:IsA('RemoteEvent')).to.equal(true)
	end)

	it('should create a RemoteEvent to send the keys update', function()
		expect(private.keySender).to.be.a('userdata')
		expect(private.keySender:IsA('RemoteEvent')).to.equal(true)
	end)

	it('should initialize tables', function()
		expect(private.nameIdMap).to.be.a('table')
		expect(private.nameSecurityMap).to.be.a('table')
		expect(private.nameServerMap).to.be.a('table')
		expect(private.remotesToClient).to.be.a('table')
		expect(private.remotesToServer).to.be.a('table')
		expect(private.playerKeys).to.be.a('table')
	end)

	it('should set a default to the timeout duration when invoking multiple clients', function()
		expect(private.remoteCallMaxDelay).to.be.a('number')
	end)
end