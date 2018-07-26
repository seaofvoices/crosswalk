return function()
	local loader = require(script.Parent[script.Name:match('(.+)%.spec$')])
	local GetUniqueId = loader()

	it('should return a string', function()
		expect(GetUniqueId()).to.be.a('string')
	end)
end