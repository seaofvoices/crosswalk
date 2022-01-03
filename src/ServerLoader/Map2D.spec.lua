return function()
    local Map2D = require(script.Parent.Map2D)

    local map = nil
    beforeEach(function()
        map = Map2D.new()
    end)

    it('inserts an entry and get it back', function()
        local value = {}
        map:insert('a', 'b', value)
        expect(map:get('a', 'b')).to.equal(value)
    end)

    it('inserts two entries at the same first key and get them back', function()
        local valueB = {}
        map:insert('a', 'b', valueB)
        local valueC = {}
        map:insert('a', 'c', valueC)
        expect(map:get('a', 'b')).to.equal(valueB)
        expect(map:get('a', 'c')).to.equal(valueC)
    end)

    it('inserts an entry, removes it and get is nil', function()
        local value = 8
        map:insert('a', 'b', value)
        map:remove('a', 'b')
        expect(map:get('a', 'b')).to.equal(nil)
    end)

    it('inserts into an entry and get it back', function()
        map:insert('a', 'b', false)
        local value = {}
        map:insert('a', 'b', value)
        expect(map:get('a', 'b')).to.equal(value)
    end)

    it('removes an entry that was not inserted', function()
        expect(function()
            map:remove('a', 'b')
        end).never.to.throw()
    end)

    it('removes all of content at the first key', function()
        map:insert('a', 'b', 1)
        map:insert('a', 'c', 2)
        expect(function()
            map:remove('a')
        end).never.to.throw()
        expect(map:get('a', 'b')).to.equal(nil)
        expect(map:get('a', 'c')).to.equal(nil)
    end)
end
