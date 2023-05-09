# conduct.nvim

A project management plugin for Neovim with session support

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
  - [Projects](#projects)
  - [Sessions](#sessions)
- [Project Config Structure](#project-config-structure)
  - [Keybinds](#keybinds)
  - [Variables](#variables)
- [Presets](#presets)
- [Functions](#functions)
- [Telescope](#telescope)

## Features

- Intuitive and easy to manage projects
- Run commands or Lua functions on keybindings
- Presets for multiple projects that share some similarities
- Easy to use API
- Telescope integration

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

| Command                    | Args                  | Function                                          |
| -------------------------- | --------------------- | ------------------------------------------------- |
| ConductNewProject          | `name`                | Creates a new project with the supplied name      |
| ConductLoadProject         | `name`                | Loads the supplied project                        |
| ConductLoadLastProject     | none                  | Loads the last opened project                     |
| ConductRenameProject       | `old_name` `new_name` | Renames the project with `old_name` to `new_name` |
| ConductDeleteProject       | `name`                | Deletes the project with the supplied name        |
| ConductLoadProjectConfig   | none                  | Loads the project config file                     |
| ConductReloadProjectConfig | none                  | Reloads the config file of the active project     |

### Sessions

One of the main differences between conduct.nvim and other project management plugins, is its ability to store multiple session for a single project. This allows you to switch between different contexts in the code.

_These commands only work when a project is active_

| Command                     | Args                  | Function                                                                                                           |
| --------------------------- | --------------------- | ------------------------------------------------------------------------------------------------------------------ |
| ConductProjectNewSession    | `session_name`        | Saves current session and creates a new session with the supplied name. The new session is made the active session |
| ConductProjectLoadSession   | `session_name`        | Saves the current session and loads the supplied session                                                           |
| ConductProjectDeleteSession | `session_name`        | Deletes the supplied session                                                                                       |
| ConductProjectRenameSession | `old_name` `new_name` | Renames `old_name` session to `new_name` even if `old_name` is the active session                                  |

## Project Config Structure

```json
{
  "name": "project name",
  "cwd": "/home/user/project/foo",
  "variables": [],
  "preset": "",
  "keybinds": []
}
```

| Field     | Value                                                                                       |
| --------- | ------------------------------------------------------------------------------------------- |
| name      | project name. only change the project name via the rename command. this is only for the API |
| cwd       | path to project                                                                             |
| variables | object with keys as variable names and value as the variable value                          |
| preset    | name of preset                                                                              |
| keybinds  | list containing a keybindings                                                               |

### Keybinds

The keybinds property should be a list that contains data in the following manner:

```json
{
  "keybinds": [["keybinding", "command", "type"]]
}
```

- keybinding: the key combination of the binding ("<leader>hi", "<leader>so")
- command: can be a vim command or the name of a function
- type: can be either `command` or `function`. If not provided, it is assumed as command

### Variables

Variables can only be used in the `command` type keybindings. They can be mentioned using the `${variable_name}` syntax.

```json
{
  "variables": {
    "flags": "-la"
  },
  "keybinds": [["<leader>so", "TermOpen control ls ${flags}"]]
}
```

## Presets

Presets can be used to setup keybinds for multiple projects that might share similarities

```lua
require("conduct").setup({
    presets = {
        node = {
            keybinds = {
                {"<leader>sd", "TermOpen dev-server npm run dev", "command"}
                {"<leader>sb", "TermOpen build npm run build", "command"}
            }
        }
    }
})
```

```json
{
  "name": "personal-blog-react",
  "cwd": "/home/user/project/blog",
  "variables": [],
  "preset": "node",
  "keybinds": []
}
```

## Functions

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

## Telescope

Conduct.nvim provides telescope integration for switching between projects and sessions.

```lua
telescope.load_extension("conduct")
```

Run `:Telescope conduct projects` to search and load a project and run `:Telescope conduct sessions` to switch between project sessions.
