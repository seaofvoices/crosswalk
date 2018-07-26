return function(ServerRemotes, private)
	return function(duration)
		private.remoteCallMaxDelay = duration
	end
end