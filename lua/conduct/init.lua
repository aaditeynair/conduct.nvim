local Path = require("plenary.path")
local data_folder = vim.fn.stdpath("data") .. "/conduct/"

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

function M.create_project(project_name)
    local new_project = {
        name = project_name,
        cwd = vim.fn.getcwd(),
        keybinds = {},
        preset = "",
    }

    Path:new(data_folder):mkdir()

    local project_file_location = data_folder .. "/" .. project_name .. ".json"
    local project_file = Path:new(project_file_location)

    if not project_file:exists() then
        project_file:touch()
    else
        print("Overwriting existing project")
    end

    local data = vim.json.encode(new_project)
    project_file:write(data, "w")

    vim.cmd("e " .. project_file_location)
    project_file:close()
end

function M.load_project(project_name)
    Path:new(data_folder):mkdir()

    local project_file_location = data_folder .. "/" .. project_name .. ".json"
    local project_file = Path:new(project_file_location)

    if not project_file:exists() then
        print("project doesn't exists")
        return
    end

    local project_data = vim.json.decode(project_file:read())

    vim.api.nvim_set_current_dir(project_data.cwd)

    for lhs, rhs in pairs(project_data.keybinds) do
        vim.keymap.set("n", lhs, "<CMD>" .. rhs .. "<CR>")
    end

    project_file:close()
end

return M
