return function(ServerRemotes, private)
	return function(eventName, callback)
		assert(type(eventName) == 'string', 'eventName must be a string')
		assert(type(callback) == 'function', 'callback must be a function')

		if eventName == 'FunctionError' then
			private.onFunctionError = callback

		elseif eventName == 'KeyError' then
			private.onKeyError = callback

		elseif eventName == 'SecondPlayerRequest' then
			private.onSecondPlayerRequest = callback

		elseif eventName == 'KeyMissing' then
			private.onKeyMissing = callback

		elseif eventName == 'PlayerReady' then
			private.onPlayerReady = callback

		else
			error(('Can not subscribe to event <%s>'):format(eventName))
		end
	end
end