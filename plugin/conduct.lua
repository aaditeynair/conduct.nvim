if vim.g.conduct_loaded then
    return
end

vim.g.conduct_loaded = 1

vim.api.nvim_create_user_command("ConductNewProject", function(opts)
    require("conduct").create_project(opts.args)
end, { nargs = 1 })

vim.api.nvim_create_user_command("ConductLoadProject", function(opts)
    require("conduct").load_project(opts.args)
end, { nargs = 1 })

vim.api.nvim_create_user_command("ConductLoadProjectConfig", function(opts)
    require("conduct").load_project_config_file(opts.args)
end, { nargs = "?" })
