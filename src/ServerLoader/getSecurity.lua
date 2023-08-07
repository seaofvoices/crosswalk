local function getSecurity(functionName: string): 'None' | 'Low' | 'High'
    if functionName:match('_danger') then
        return 'None'
    elseif functionName:match('_risky') then
        return 'Low'
    else
        return 'High'
    end
end

return getSecurity
