local jestGlobals = require('@pkg/@jsdotlua/jest-globals')
local Map2D = require('./Map2D')

local expect = jestGlobals.expect
local it = jestGlobals.it

it('inserts an entry and get it back', function()
    local map = Map2D.new()
    local value = {}
    map:insert('a', 'b', value)
    expect(map:get('a', 'b')).toBe(value)
end)

it('inserts two entries at the same first key and get them back', function()
    local map = Map2D.new()
    local valueB = {}
    map:insert('a', 'b', valueB)
    local valueC = {}
    map:insert('a', 'c', valueC)
    expect(map:get('a', 'b')).toBe(valueB)
    expect(map:get('a', 'c')).toBe(valueC)
end)

it('inserts an entry, removes it and get is nil', function()
    local map = Map2D.new()
    local value = 8
    map:insert('a', 'b', value)
    map:remove('a', 'b')
    expect(map:get('a', 'b')).toEqual(nil)
end)

it('inserts into an entry and get it back', function()
    local map = Map2D.new()
    map:insert('a', 'b', false :: boolean | {})
    local value = {}
    map:insert('a', 'b', value)
    expect(map:get('a', 'b')).toBe(value)
end)

it('removes an entry that was not inserted', function()
    local map = Map2D.new()
    expect(function()
        map:remove('a', 'b')
    end).never.toThrow()
end)

it('removes all of content at the first key', function()
    local map = Map2D.new()
    map:insert('a', 'b', 1)
    map:insert('a', 'c', 2)
    expect(function()
        map:removeAll('a')
    end).never.toThrow()
    expect(map:get('a', 'b')).toEqual(nil)
    expect(map:get('a', 'c')).toEqual(nil)
end)
