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
M.hooks = {
    before_project_load = function() end,
    after_project_load = function() end,
    before_session_load = function() end,
    after_session_load = function() end,
    before_session_save = function() end,
}

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

    local hooks = opts.hooks
    if type(hooks) == "table" then
        if type(hooks.before_project_load) == "function" then
            M.hooks.before_project_load = hooks.before_project_load
        end

        if type(hooks.after_project_load) == "function" then
            M.hooks.after_project_load = hooks.after_project_load
        end

        if type(hooks.before_session_load) == "function" then
            M.hooks.before_session_load = hooks.before_session_load
        end

        if type(hooks.after_session_load) == "function" then
            M.hooks.after_session_load = hooks.after_session_load
        end

        if type(hooks.before_session_save) == "function" then
            M.hooks.before_session_save = hooks.before_session_save
        end
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

    M.hooks.before_project_load()

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
        M.hooks.before_session_load()

        vim.cmd("silent source " .. last_session)

        local session_name = vim.fs.basename(last_session)
        M.current_session = session_name:gsub(".vim$", "")

        M.hooks.after_session_load()
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

    M.hooks.after_project_load()
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
end

function M.load_last_project()
    local last_project_data_file = data_folder .. "__last__"
    local last_data_file = Path:new(last_project_data_file)
    local last_data = vim.json.decode(last_data_file:read())
    last_data_file:close()

    local last_project_name = last_data[1]
    M.load_project(last_project_name)
end

function M.load_cwd_project()
    local cwd = vim.fn.getcwd()
    local project = ""
    for _, project_data in ipairs(M.get_all_project_data()) do
        if project_data.cwd == cwd then
            project = project_data.name
            break
        end
    end

    if project ~= "" then
        M.load_project(project)
        return
    end

    print("no project with the current cwd")
end

function M.reload_current_project_config()
    if next(M.current_project) == nil then
        print("no project active")
        return
    end

    M.load_project(M.current_project.name)
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

function M.get_all_project_data()
    local all_projects = vim.split(vim.fn.glob(data_folder .. "*/"), "\n")
    local project_data = {}
    for _, project in ipairs(all_projects) do
        local data = vim.json.decode(Path:new(project .. "data.json"):read())
        table.insert(project_data, data)
    end

    return project_data
end

function M.get_last_opened_projects()
    local last_project_data_file = data_folder .. "__last__"
    local last_data_file = Path:new(last_project_data_file)
    local last_data = vim.json.decode(last_data_file:read())
    last_data_file:close()

    return last_data
end

function M.delete_project(project_name)
    local project_to_be_deleted
    if project_name ~= "" then
        project_to_be_deleted = project_name
    elseif next(M.current_project) ~= nil then
        vim.ui.input({
            prompt = "delete current project y/n: ",
        }, function(input)
            if input == "y" then
                project_to_be_deleted = M.current_project.name
                CleanUpProject()
                M.current_project = {}
            else
                project_to_be_deleted = ""
                print("aborting")
            end
        end)
    else
        print("project doesn't exists")
        return
    end

    if project_to_be_deleted == "" then
        return
    end

    local project_path = GetProjectDataFolder(project_to_be_deleted)
    local project_folder = Path:new(project_path)
    if not project_folder:exists() then
        print("project doesn't exists")
        return
    end

    RemoveItemsFromFolder(project_path)
    project_folder:rmdir()

    local last_file = Path:new(data_folder .. "__last__")
    if last_file:exists() then
        local data = vim.json.decode(last_file:read())
        local index = GetIndexOfItem(data, project_to_be_deleted)
        if index ~= nil then
            table.remove(data, index)
        end
        last_file:write(vim.json.encode(data), "w")
    else
        last_file:touch()
        last_file:write(vim.json.encode({}), "w")
    end
end

function M.rename_project(old_name, new_name)
    if type(old_name) ~= "string" or type(new_name) ~= "string" then
        print("please supply all args")
        return
    end

    local abort = false
    vim.ui.input({
        prompt = "this will delete all your saved sessions. proceed [y/n]: ",
    }, function(confirm)
        if confirm ~= "y" then
            print("aborting...")
            abort = true
        end
    end)

    if abort then
        return
    end

    local old_project_path = GetProjectDataFolder(old_name)
    local new_project_path = GetProjectDataFolder(new_name)
    local project_folder = Path:new(old_project_path)
    project_folder:rename({ new_name = new_project_path })

    local project_data = Path:new(new_project_path .. "data.json")
    local data = vim.json.decode(project_data:read())
    data.name = new_name
    project_data:write(vim.json.encode(data), "w")
    project_data:close()

    local last_session_file = new_project_path .. "sessions/__last__"
    vim.loop.fs_unlink(last_session_file)
    RemoveItemsFromFolder(new_project_path .. "sessions/")

    if old_name == M.current_project.name then
        M.current_project = data
        M.store_current_session()
    end

    local last_project_file = data_folder .. "__last__"
    local last_file = Path:new(last_project_file)
    local last_projects = vim.json.decode(last_file:read())
    local index = GetIndexOfItem(last_projects, old_name)
    if index ~= nil then
        last_projects[index] = new_name
    end
    last_file:write(vim.json.encode(last_projects), "w")
    last_file:close()
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
        session_file = sessions_folder:absolute() .. "default.vim"
        M.current_session = "default"
    else
        session_file = sessions_folder:absolute() .. M.current_session .. ".vim"
    end

    M.hooks.before_session_save()
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
    M.hooks.before_session_load()

    local project_data_folder = GetProjectDataFolder(M.current_project.name)
    local sessions_folder = Path:new(project_data_folder .. "sessions/")
    sessions_folder:mkdir()

    local session_file = sessions_folder:absolute() .. session_name .. ".vim"
    local session = Path:new(session_file)
    if session:exists() then
        vim.cmd("silent source " .. session_file)
        M.current_session = session_name

        local last_session = sessions_folder:absolute() .. "__last__"
        local last_session_file = Path:new(last_session)
        if last_session_file:exists() then
            last_session_file:rm()
        end

        vim.loop.fs_symlink(session_file, last_session)
    else
        print("session doesn't exists")
    end

    session:close()

    M.hooks.after_session_load()
end

function M.delete_session(session_name)
    if next(M.current_project) == nil then
        print("no project loaded")
        return
    end

    local projects_folder = GetProjectDataFolder(M.current_project.name)
    local sessions_folder = projects_folder .. "sessions/"

    local session_file = Path:new(sessions_folder .. session_name .. ".vim")
    if not session_file:exists() then
        print("session doesn't exists")
        return
    end

    session_file:rm()

    local last_session = vim.loop.fs_readlink(sessions_folder .. "__last__")
    if last_session == session_file:absolute() then
        vim.loop.fs_unlink(sessions_folder .. "__last__")
        Path:new(sessions_folder .. "__last__"):rm()
    end

    if M.current_session == session_name then
        M.current_session = ""
    end
end

function M.rename_session(old_name, new_name)
    if type(old_name) ~= "string" or type(new_name) ~= "string" then
        print("please supply all args")
        return
    end

    local projects_folder = GetProjectDataFolder(M.current_project.name)
    local sessions_folder = projects_folder .. "sessions/"

    local old_session_path = sessions_folder .. old_name .. ".vim"
    local session_file = Path:new(old_session_path)
    if not session_file:exists() then
        print("session doesn't exists")
        return
    end

    local new_session = sessions_folder .. new_name .. ".vim"
    session_file:rename({ new_name = new_session })

    local last_session = vim.loop.fs_readlink(sessions_folder .. "__last__")
    if last_session == old_session_path then
        local last_session_file = sessions_folder .. "__last__"
        vim.loop.fs_unlink(last_session_file)
        Path:new(last_session_file):rm()
        vim.loop.fs_symlink(session_file:absolute(), last_session_file)
    end

    if M.current_session == old_name then
        M.current_session = new_name
    end
end

function M.list_all_sessions()
    if next(M.current_project) == nil then
        return
    end

    local projects_folder = GetProjectDataFolder(M.current_project.name)
    local sessions_path = projects_folder .. "sessions/"
    local all_sessions = vim.split(vim.fn.glob(sessions_path .. "*.vim"), "\n")

    local sessions = {}
    for _, file in ipairs(all_sessions) do
        local path = sessions_path:gsub("[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1")
        local session = file:gsub(path, ""):gsub(".vim$", "")
        table.insert(sessions, session)
    end

    return sessions
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
    if next(M.current_project) ~= nil then
        M.store_current_session()

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

function RemoveItemsFromFolder(folder)
    for _, val in ipairs(vim.split(vim.fn.glob(folder .. "*"), "\n")) do
        if val ~= "" then
            local contents = Path:new(val)
            if not contents:is_dir() then
                contents:rm()
            else
                RemoveItemsFromFolder(contents:absolute() .. "/")
                contents:rmdir()
            end
            contents:close()
        end
    end
end

-- Autocmds

vim.api.nvim_create_autocmd("QuitPre", {
    desc = "Delete the keybindings set by the project",
    group = conduct_augroup,
    callback = function()
        CleanUpProject()
    end,
    pattern = "*",
})

return M
