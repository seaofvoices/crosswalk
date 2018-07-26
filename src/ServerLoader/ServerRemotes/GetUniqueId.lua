return function()
	local HttpService = game:GetService('HttpService')

	return function()
		return HttpService:GenerateGUID()
	end
end