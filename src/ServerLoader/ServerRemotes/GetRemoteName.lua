return function()
	return function(module, functionName)
		return string.format('%s.%s', module, functionName)
	end
end