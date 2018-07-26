return function(functionName)
	if functionName:match('_danger') then
		return 'None'
	elseif functionName:match('_risky') then
		return 'Low'
	else
		return 'High'
	end
end