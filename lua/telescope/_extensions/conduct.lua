local telescope = require("telescope")
local pickers = require("conduct.telescope")

return telescope.register_extension({
    exports = {
        conduct = pickers.search_projects,
    },
})
