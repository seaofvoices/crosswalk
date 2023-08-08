local process = require('@lune/process')

local function darkluaProcess(options: {
    input: string,
    output: string?,
    config: string?,
    verbosity: number?,
}): process.SpawnResult
    local args = { 'process' }

    if options.verbosity and options.verbosity > 0 then
        table.insert(args, '-' .. string.rep('v', options.verbosity))
    end

    if options.config then
        table.insert(args, '--config')
        table.insert(args, options.config)
    end

    table.insert(args, options.input)
    table.insert(args, options.output or options.input)

    local darkluaResult = process.spawn('darklua', args)

    if not darkluaResult.ok then
        print(darkluaResult.stdout)
        error('failed to run darklua: ' .. darkluaResult.stderr)
    end

    return darkluaResult
end

return {
    process = darkluaProcess,
}
