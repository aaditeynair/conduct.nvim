if vim.g.conduct_loaded then
    return
end

vim.g.conduct_loaded = 1

function GetProjectNames(lead)
    local all_projects = require("conduct").list_all_projects()
    local projects = {}
    for _, project in ipairs(all_projects) do
        if project:find("^" .. lead) ~= nil then
            table.insert(projects, project)
        end
    end

    return projects
end

function GetSessionsName(lead)
    local all_sessions = require("conduct").list_all_sessions()
    local sessions = {}
    for _, session in ipairs(all_sessions) do
        if session:find("^" .. lead) ~= nil then
            table.insert(sessions, session)
        end
    end

    return sessions
end

vim.api.nvim_create_user_command("ConductNewProject", function(opts)
    require("conduct").create_project(opts.args)
end, { nargs = 1 })

vim.api.nvim_create_user_command("ConductLoadProject", function(opts)
    require("conduct").load_project(opts.args)
end, {
    nargs = 1,
    complete = function(lead)
        return GetProjectNames(lead)
    end,
})

vim.api.nvim_create_user_command("ConductLoadLastProject", function()
    require("conduct").load_last_project()
end, { nargs = 0 })

vim.api.nvim_create_user_command("ConductLoadCwdProject", function()
    require("conduct").load_cwd_project()
end, { nargs = 0 })

vim.api.nvim_create_user_command("ConductLoadProjectConfig", function(opts)
    require("conduct").load_project_config_file(opts.args)
end, {
    nargs = "?",
    complete = function(lead)
        return GetProjectNames(lead)
    end,
})

vim.api.nvim_create_user_command("ConductReloadProjectConfig", function()
    require("conduct").reload_current_project_config()
end, {
    nargs = 0,
})

vim.api.nvim_create_user_command("ConductDeleteProject", function(opts)
    require("conduct").delete_project(opts.args)
end, {
    nargs = "?",
    complete = function(lead)
        return GetProjectNames(lead)
    end,
})

vim.api.nvim_create_user_command("ConductRenameProject", function(opts)
    local old_name = opts.fargs[1]
    local new_name = opts.fargs[2]
    require("conduct").rename_project(old_name, new_name)
end, {
    nargs = "*",
    complete = function(lead)
        return GetProjectNames(lead)
    end,
})

vim.api.nvim_create_user_command("ConductProjectNewSession", function(opts)
    require("conduct").create_new_session(opts.args)
end, { nargs = 1 })

vim.api.nvim_create_user_command("ConductProjectLoadSession", function(opts)
    require("conduct").load_session(opts.args)
end, {
    nargs = 1,
    complete = function(lead)
        return GetSessionsName(lead)
    end,
})

vim.api.nvim_create_user_command("ConductProjectDeleteSession", function(opts)
    require("conduct").delete_session(opts.args)
end, {
    nargs = 1,
    complete = function(lead)
        return GetSessionsName(lead)
    end,
})

vim.api.nvim_create_user_command("ConductProjectRenameSession", function(opts)
    local old_name = opts.fargs[1]
    local new_name = opts.fargs[2]
    require("conduct").rename_session(old_name, new_name)
end, {
    nargs = "*",
    complete = function(lead)
        return GetSessionsName(lead)
    end,
})
