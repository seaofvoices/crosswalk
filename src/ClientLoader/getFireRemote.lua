local function getFireRemoteEvent<T...>(remote: RemoteEvent, key: string?): (T...) -> ()
    if key then
        local function fireRemote(...: T...)
            remote:FireServer(key, ...)
        end
        return fireRemote
    else
        local function fireRemote(...: T...)
            remote:FireServer(...)
        end
        return fireRemote
    end
end

local function getFireRemoteFunction<T..., U...>(remote: RemoteFunction, key: string?): (T...) -> U...
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

local function getFireRemote<T..., U...>(remote: RemoteEvent | RemoteFunction, key: string?): (T...) -> U...
    if remote:IsA('RemoteEvent') then
        return getFireRemoteEvent(remote, key) :: any
    else
        return getFireRemoteFunction(remote, key)
    end
end

return getFireRemote
