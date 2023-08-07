return function()
    local Map2D = require('./Map2D')

    -- local map = nil
    -- beforeEach(function()
    --     map = Map2D.new()
    -- end)

    it('inserts an entry and get it back', function()
        local map = Map2D.new()
        local value = {}
        map:insert('a', 'b', value)
        expect(map:get('a', 'b')).to.equal(value)
    end)

    it('inserts two entries at the same first key and get them back', function()
        local map = Map2D.new()
        local valueB = {}
        map:insert('a', 'b', valueB)
        local valueC = {}
        map:insert('a', 'c', valueC)
        expect(map:get('a', 'b')).to.equal(valueB)
        expect(map:get('a', 'c')).to.equal(valueC)
    end)

    it('inserts an entry, removes it and get is nil', function()
        local map = Map2D.new()
        local value = 8
        map:insert('a', 'b', value)
        map:remove('a', 'b')
        expect(map:get('a', 'b')).to.equal(nil)
    end)

    it('inserts into an entry and get it back', function()
        local map = Map2D.new()
        map:insert('a', 'b', false :: boolean| {})
        local value = {}
        map:insert('a', 'b', value)
        expect(map:get('a', 'b')).to.equal(value)
    end)

    it('removes an entry that was not inserted', function()
        local map = Map2D.new()
        expect(function()
            map:remove('a', 'b')
        end).never.to.throw()
    end)

    it('removes all of content at the first key', function()
        local map = Map2D.new()
        map:insert('a', 'b', 1)
        map:insert('a', 'c', 2)
        expect(function()
            map:removeAll('a')
        end).never.to.throw()
        expect(map:get('a', 'b')).to.equal(nil)
        expect(map:get('a', 'c')).to.equal(nil)
    end)
end
