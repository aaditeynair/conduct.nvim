local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local M = {}

function M.search_projects(opts)
    opts = opts or {}
    opts.layout_config = {
        horizontal = { width = 0.5 },
    }
    local all_projects = require("conduct").list_all_projects()
    pickers
        .new(opts, {
            prompt_title = "Projects",
            finder = finders.new_table({
                results = all_projects,
            }),
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(prompt_bufnr, map)
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    require("conduct").load_project(selection[1])
                end)

                map({ "i", "n" }, "<C-d>", function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()

                    if selection == nil then
                        print("no project selected")
                        return
                    end

                    local project_name = selection[1]
                    vim.ui.input({ prompt = "confirm project delete [y/n]: " }, function(confirm)
                        if confirm ~= "y" then
                            print("aborting...")
                            return
                        end

                        print("deleting " .. project_name .. "...")
                        require("conduct").delete_project(project_name)
                    end)
                end)

                return true
            end,
        })
        :find()
end

function M.search_sessions(opts)
    opts = opts or {}
    opts.layout_config = {
        horizontal = { width = 0.5 },
    }
    local all_sessions = require("conduct").list_all_sessions()
    pickers
        .new(opts, {
            prompt_title = "Sessions",
            finder = finders.new_table({
                results = all_sessions,
            }),
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(prompt_bufnr, _)
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    require("conduct").load_session(selection[1])
                end)
                return true
            end,
        })
        :find()
end

return M
