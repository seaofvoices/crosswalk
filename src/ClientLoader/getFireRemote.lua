local function getFireRemoteEvent(remote, key)
    if key then
        local function fireRemote(...)
            remote:FireServer(key, ...)
        end
        return fireRemote
    else
        local function fireRemote(...)
            remote:FireServer(...)
        end
        return fireRemote
    end
end

local function getFireRemoteFunction(remote, key)
    if key then
        local function fireRemote(...)
            return remote:InvokeServer(key, ...)
        end
        return fireRemote
    else
        local function fireRemote(...)
            return remote:InvokeServer(...)
        end
        return fireRemote
    end
end

local function getFireRemote(remote, key)
    if remote:IsA('RemoteEvent') then
        return getFireRemoteEvent(remote, key)
    else
        return getFireRemoteFunction(remote, key)
    end
end

return getFireRemote
