local telescope = require("telescope")
local pickers = require("conduct.telescope")

return telescope.register_extension({
    exports = {
        projects = pickers.search_projects,
        sessions = pickers.search_sessions,
    },
})
