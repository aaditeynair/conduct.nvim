local M = {}

M.presets = {}

function M.setup(opts)
    if type(opts) ~= "table" then
        return
    end

    if type(opts.presets) == "nil" then
        M.presets = {}
    elseif type(opts.presets) == "table" then
        M.presets = opts.presets
    else
        M.presets = {}
        print("presets must be a table")
    end
end

return M
