if vim.g.conduct_loaded then
    return
end

vim.g.conduct_loaded = 1

vim.api.nvim_create_user_command("ConductNewProject", function(opts)
    require("conduct").create_project(opts.args)
end, { nargs = 1 })
