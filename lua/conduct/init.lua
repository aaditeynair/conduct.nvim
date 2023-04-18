local Path = require("plenary.path")
local data_folder = vim.fn.stdpath("data") .. "/conduct/"

local M = {}

M.presets = {}
M.current_project = {}

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
        variables = {},
    }

    Path:new(data_folder):mkdir()

    local project_file_location = GetDataFileLocation(project_name)
    local project_file = Path:new(project_file_location)

    if not project_file:exists() then
        project_file:touch()
    else
        print("Overwriting existing project")
    end

    local data = vim.json.encode(new_project)
    project_file:write(data, "w")

    project_file:close()
    vim.cmd("e " .. project_file_location)
end

function M.load_project(project_name)
    Path:new(data_folder):mkdir()

    local project_file_location = GetDataFileLocation(project_name)
    local project_file = Path:new(project_file_location)

    if not project_file:exists() then
        print("project doesn't exists")
        return
    end

    local project_data = vim.json.decode(project_file:read())
    if not CheckProjectData(project_data) then
        print("project data file is not properly formatted")
        return
    end

    vim.api.nvim_set_current_dir(project_data.cwd)

    LoadKeybinds(project_data.keybinds, project_data.variables)

    if project_data.preset ~= "" then
        local preset = M.presets[project_data.preset]
        if preset == nil then
            print("preset '" .. project_data.preset .. "' doesn't exist")
            return
        end

        LoadKeybinds(preset.keybinds, project_data.variables)
    end

    M.current_project = project_data

    project_file:close()
end

function M.load_project_config_file(project_name)
    if project_name == "" then
        if next(M.current_project) == nil then
            print("please specify project name")
        else
            local current_project_name = M.current_project.name
            local project_file = GetDataFileLocation(current_project_name)
            vim.cmd("e " .. project_file)
        end
        return
    end

    local project_file_location = GetDataFileLocation(project_name)
    vim.cmd("e " .. project_file_location)
end

-- Util functions

function CheckProjectData(project_data)
    if type(project_data.name) ~= "string" then
        return false
    end

    if type(project_data.cwd) ~= "string" then
        return false
    end

    if type(project_data.keybinds) ~= "table" then
        return false
    end

    if type(project_data.preset) ~= "string" then
        return false
    end

    if type(project_data.variables) ~= "table" then
        return false
    end

    return true
end

function GetDataFileLocation(project_name)
    return data_folder .. "/" .. project_name .. ".json"
end

function LoadKeybinds(keybindings, variables)
    for _, keybinding in ipairs(keybindings) do
        local lhs, rhs, type = keybinding[1], keybinding[2], keybinding[3]

        if type == nil then
            print("Keybinding type is not defined. Assumed as 'command'")
            type = "command"
        end

        if type == "command" then
            for var, value in pairs(variables) do
                rhs = string.gsub(rhs, "${" .. var .. "}", value)
            end

            vim.keymap.set("n", lhs, "<CMD>" .. rhs .. "<CR>")
        elseif type == "function" then
            vim.keymap.set("n", lhs, rhs)
        end
    end
end

-- Autocmds

vim.api.nvim_create_autocmd("ExitPre", {
    desc = "Delete the keybindings set by the project",
    callback = function()
        if M.current_project ~= {} then
            if type(M.current_project.keybinds) == "table" then
                for lhs, _ in pairs(M.current_project.keybinds) do
                    vim.api.nvim_del_keymap("n", lhs)
                end
            end

            local preset = M.current_project.preset
            if preset ~= "" and M.presets[preset] ~= nil then
                for lhs, _ in pairs(M.presets[preset].keybinds) do
                    vim.keymap.del("n", lhs)
                end
            end
        end
    end,
    pattern = "*",
})

return M
