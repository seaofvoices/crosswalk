return function()
	local loader = require(script.Parent[script.Name:match('(.+)%.spec$')])
	local GetRemoteName = loader()

	it('should return a string', function()
		expect(GetRemoteName('testmodule', 'testfunction')).to.be.a('string')
	end)

	it('should return the correct remote name', function()
		expect(GetRemoteName('test', 'func')).to.equal('test.func')
	end)
end