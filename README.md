# conduct.nvim

A project manager for Neovim

## Features

- Intuitive and easy to manage projects
- Run commands or Lua functions on keybindings
- Presets for multiple projects that share some similarities
- Easy to use API
- Telescope intergration

## Requirements

- Neovim >= 0.8.0 (might work with earlier version)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

## Installation

```lua
{
    "https://github.com/nvim-lua/plenary.nvim",
    cmd = {
        "ConductNewProject",
        "ConductLoadProject",
        "ConductLoadLastProject",
        "ConductLoadProjectConfig",
        "ConductReloadProjectConfig",
        "ConductDeleteProject",
        "ConductRenameProject",
        "ConductProjectNewSession",
        "ConductProjectLoadSession",
        "ConductProjectDeleteSession",
        "ConductProjectRenameSession",
    },
}
```

## Configuration

```lua
require("conduct").setup({
    -- define function that you bind to a key in a project config
    functions = {},

    -- define presets for projects
    presets = {},

    hooks = {
        before_session_save = function() end,
        before_session_load = function() end,
        after_session_load = function() end,
        before_project_load = function() end,
        after_project_load = function() end,
    }
})
```

## Usage

### Projects

| Command                    | Args                   | Function                                          |
| -------------------------- | ---------------------- | ------------------------------------------------- |
| ConductNewProject          | `name`                 | Creates a new project with the supplied name      |
| ConductLoadProject         | `name`                 | Loads the suppied project                         |
| ConductLoadLastProject     | none                   | Loads the last opened project                     |
| ConductRenameProject       | `old_name`, `new_name` | Renames the project with `old_name` to `new_name` |
| ConductDeleteProject       | `name`                 | Deletes the project with the supplied name        |
| ConductLoadProjectConfig   | none                   | Loads the project config file                     |
| ConductReloadProjectConfig | none                   | Reloads the config file of the active project     |

#### ConductNewProject [name]

Creates a new project with the supplied name

#### ConductLoadProject [name]

Loads the suppied project

#### ConductLoadLastProject

Loads the last opened project

#### ConductLoadProjectConfig

Loads the project config file

#### ConductReloadProjectConfig

Reloads the config file of the active project

#### ConductDeleteProject [name]

Deletes the project with the supplied name

#### ConductRenameProject [old_name] [new_name]

Renames the project with `old_name` to `new_name`

### Sessions

_These commands only work when a project is active_

#### ConductProjectNewSession [session_name]

Saves current session and creates a new session with the supplied name. The new session is made the active session

#### ConductProjectLoadSession [session_name]

Saves the current session and loads the supplied session

#### ConductProjectDeleteSession [session_name]

Deletes the supplied session

##### ConductProjectRenameSession [old_name] [new_name]

Renames `old_name` session to `new_name` even if `old_name` is the active session

### Functions

Define functions when setting up conduct.nvim and bind keys to them in the project config

```lua
require("conduct").setup({
    functions = {
        run_npm_server = function()
            local tm = require("termnames")
            if not tm.terminal_exists("server") then
                tm.create_terminal("server")
            end

            tm.run_terminal_cmd({"server", "npm run dev"})
        end,
    },
})
```

```json
{
  "name": "personal-blog-react",
  "cwd": "/home/user/project/blog",
  "variables": [],
  "preset": "",
  "keybinds": [["<leader>so", "run_npm_server", "function"]]
}
```
