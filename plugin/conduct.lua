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

vim.api.nvim_create_user_command("ConductNewProject", function(opts)
    require("conduct").create_project(opts.args)
end, { nargs = 1 })

vim.api.nvim_create_user_command("ConductLoadProject", function(opts)
    require("conduct").load_project(opts.args)
end, {
    nargs = 1,
    complete = function(lead)
        GetProjectNames(lead)
    end,
})

vim.api.nvim_create_user_command("ConductLoadLastProject", function()
    require("conduct").load_last_project()
end, { nargs = 0 })

vim.api.nvim_create_user_command("ConductLoadProjectConfig", function(opts)
    require("conduct").load_project_config_file(opts.args)
end, {
    nargs = "?",
    complete = function(lead)
        GetProjectNames(lead)
    end,
})
