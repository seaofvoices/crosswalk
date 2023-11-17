local function filterArray<T, U>(array: { T }, filter: (T, number) -> boolean): { T }
    local resultArray = {}

    for i, element in array do
        if filter(element, i) then
            table.insert(resultArray, element)
        end
    end

    return resultArray
end
return filterArray
