local Path = require("plenary.path")
local data_folder = vim.fn.stdpath("data") .. "/conduct/"

local conduct_augroup = vim.api.nvim_create_augroup("CONDUCT_NVIM", {
    clear = true,
})

local M = {}

M.presets = {}
M.functions = {}
M.current_project = {}
M.current_session = ""

M.after_project_load = function() end
M.before_project_load = function() end

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

    if type(opts.functions) == "nil" then
        M.functions = {}
    elseif type(opts.functions) == "table" then
        M.functions = opts.functions
    else
        M.functions = {}
        print("functions must be a table")
    end

    if type(opts.after_load_function) == "function" then
        M.after_project_load = opts.after_load_function
    end

    -- hi
    if type(opts.before_load_function) == "function" then
        M.before_project_load = opts.before_load_function
    end
end

-- Projects

function M.create_project(project_name)
    local new_project = {
        name = project_name,
        cwd = vim.fn.getcwd(),
        keybinds = {},
        preset = "",
        variables = {},
    }

    Path:new(data_folder):mkdir()

    local project_folder = GetProjectDataFolder(project_name)
    Path:new(project_folder):mkdir()

    local project_data_file = project_folder .. "data.json"
    local project_file = Path:new(project_data_file)

    Path:new(project_folder .. "sessions/"):mkdir()

    if not project_file:exists() then
        project_file:touch()
    else
        print("Overwriting existing project")
    end

    local data = vim.json.encode(new_project)
    project_file:write(data, "w")

    project_file:close()
    M.load_project(new_project.name)
end

function M.load_project(project_name)
    if next(M.current_project) ~= nil then
        CleanUpProject()
    end

    Path:new(data_folder):mkdir()

    local project_data_folder = GetProjectDataFolder(project_name)
    local project_folder = Path:new(project_data_folder)

    if not project_folder:exists() then
        print("project doesn't exists")
        return
    end

    local project_file_location = project_data_folder .. "data.json"
    local project_file = Path:new(project_file_location)

    local project_data = vim.json.decode(project_file:read())
    project_file:close()

    if not CheckProjectData(project_data) then
        print("project data file is not properly formatted")
        return
    end
    M.current_project = project_data

    M.before_project_load()

    vim.api.nvim_set_current_dir(project_data.cwd)
    LoadKeybinds(project_data.keybinds, project_data.variables)

    if project_data.preset ~= "" then
        local preset = M.presets[project_data.preset]
        if preset == nil then
            print("preset '" .. project_data.preset .. "' doesn't exist")
        else
            LoadKeybinds(preset.keybinds, project_data.variables)
        end
    end

    local sessions_folder = Path:new(project_data_folder .. "sessions/")
    sessions_folder:mkdir()

    local last_session_file = sessions_folder:absolute() .. "__last__"
    local last_session = vim.loop.fs_readlink(last_session_file)
    if last_session ~= nil then
        vim.cmd("silent source " .. last_session)
        local list = vim.split(last_session, "/")
        local session_name = list[#list]
        M.current_session = session_name:gsub(".vim$", "")
    end

    sessions_folder:close()

    local last_file = Path:new(data_folder .. "__last__")
    if not last_file:exists() then
        last_file:touch()
        last_file:write(vim.json.encode({}), "w")
    end

    local last_file_data = vim.json.decode(last_file:read())
    local current_proj_index = GetIndexOfItem(last_file_data, project_data.name)
    if current_proj_index ~= nil then
        table.remove(last_file_data, current_proj_index)
    end
    table.insert(last_file_data, 1, project_data.name)

    last_file:write(vim.json.encode(last_file_data), "w")
    last_file:close()

    M.after_project_load()
end

function M.load_project_config_file(project_name)
    local project_to_be_opened = project_name
    if project_name == "" then
        if next(M.current_project) == nil then
            print("please specify project name")
            return
        else
            project_to_be_opened = M.current_project.name
        end
    end

    local project_folder = GetProjectDataFolder(project_to_be_opened)
    local project_file_location = project_folder .. "data.json"
    vim.cmd("e " .. project_file_location)

    if
        next(vim.api.nvim_get_autocmds({
            event = "BufWritePost",
            buffer = 0,
            group = conduct_augroup,
        })) == nil
    then
        vim.api.nvim_create_autocmd("BufWritePost", {
            buffer = 0,
            group = conduct_augroup,
            callback = function()
                if M.current_project.name == project_to_be_opened then
                    print("reloading project config...")
                    M.reload_current_project_config()
                end
            end,
        })
    end
end

function M.load_last_project()
    local last_project_data_file = data_folder .. "__last__"
    local last_data_file = Path:new(last_project_data_file)
    local last_data = vim.json.decode(last_data_file:read())
    last_data_file:close()

    local last_project_name = last_data[1]
    M.load_project(last_project_name)
end

function M.reload_current_project_config()
    if next(M.current_project) == nil then
        print("no project active")
        return
    end

    M.load_project(M.current_project.name)

    M.after_project_load()
end

function M.list_all_projects()
    local all_files = vim.split(vim.fn.glob(data_folder .. "*/"), "\n")
    local all_project_names = {}
    for _, file in ipairs(all_files) do
        local project_name = file:gsub(data_folder, ""):gsub("/", "")
        table.insert(all_project_names, project_name)
    end

    return all_project_names
end

function M.get_last_opened_projects()
    local last_project_data_file = data_folder .. "__last__"
    local last_data_file = Path:new(last_project_data_file)
    local last_data = vim.json.decode(last_data_file:read())
    last_data_file:close()

    return last_data
end

-- Sessions

function M.store_current_session()
    if next(M.current_project) == nil then
        return
    end

    local project_name = M.current_project.name
    local project_folder = GetProjectDataFolder(project_name)
    local sessions_folder = Path:new(project_folder .. "sessions/")
    sessions_folder:mkdir()

    local session_file
    if M.current_session == "" then
        session_file = sessions_folder:absolute() .. "Session.vim"
        M.current_session = "Session"
    else
        session_file = sessions_folder:absolute() .. M.current_session .. ".vim"
    end

    vim.cmd("silent mksession! " .. session_file)

    local last_session = sessions_folder:absolute() .. "__last__"
    local last_session_file = Path:new(last_session)
    if last_session_file:exists() then
        last_session_file:rm()
    end

    vim.loop.fs_symlink(session_file, last_session)
end

function M.create_new_session(session_name)
    M.store_current_session()

    M.current_session = session_name

    M.store_current_session()
end

function M.load_session(session_name)
    if next(M.current_project) == nil then
        return
    end

    M.store_current_session()

    local project_data_folder = GetProjectDataFolder(M.current_project.name)
    local sessions_folder = Path:new(project_data_folder .. "sessions/")
    sessions_folder:mkdir()

    local session_file = sessions_folder:absolute() .. session_name .. ".vim"
    local session = Path:new(session_file)
    if session:exists() then
        vim.cmd("silent source " .. session_file)
        M.current_session = session_name
    else
        print("session doesn't exists")
    end

    session:close()
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

function GetProjectDataFolder(project_name)
    return data_folder .. project_name .. "/"
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
            local user_function = M.functions[rhs]
            if user_function == nil then
                print("function " .. rhs .. " is not defined")
                return
            end
            vim.keymap.set("n", lhs, user_function)
        end
    end
end

function GetIndexOfItem(list, item_name)
    for i, item in ipairs(list) do
        if item == item_name then
            return i
        end
    end

    return nil
end

function CleanUpProject()
    M.store_current_session()

    if M.current_project ~= {} then
        if type(M.current_project.keybinds) == "table" then
            for _, keybinding in ipairs(M.current_project.keybinds) do
                local lhs = keybinding[1]
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
end

-- Autocmds

vim.api.nvim_create_autocmd("ExitPre", {
    desc = "Delete the keybindings set by the project",
    group = conduct_augroup,
    callback = function()
        CleanUpProject()
    end,
    pattern = "*",
})

return M
