return function()
	local loader = require(script.Parent[script.Name:match('(.+)%.spec$')])
	local GetKey = loader()

	it('should return a string', function()
		expect(GetKey()).to.be.a('string')
	end)
end