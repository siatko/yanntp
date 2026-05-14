# denim.nvim

**Denote + vim = denim**

A [Denote](https://github.com/protesilaos/denote)-inspired note-taking plugin for Neovim. Plain markdown files, structured filenames, no database, no proprietary formats - just files you own and a plugin you'll actually understand when it breaks.

Finally, a reason to open Neovim other than accidentally.

## Features

- **Flat structure** - all notes, todos and attachments live in one directory (one folder to rule them all)
- **Denote-style filenames** - `YYYYMMDD--title__tag1_tag2.md` (ugly at first, beautiful once you get it)
- **Todo tracking** - open (`-O-`) and done (`-X-`) status embedded in filename, so your shame is visible in the filesystem
- **Tag picker** - Telescope UI with multi-select and new tag creation when writing notes
- **Tag search** - browse all tags used across your notes, confront how many you have
- **Full-text search** - live grep across all note contents
- **Note linking** - insert markdown links to other notes, follow links with `<CR>`
- **Backlinks** - find all notes that link to the current note (someone out there cares)
- **Refactor** - rename and retag the current note in one step, file renamed automatically; all notes linking to it are updated automatically (this one actually works)
- **Image paste** - paste clipboard images via img-clip, saved as `YYYYMMDD--name__tags.ext`
- **Notes index** - virtual buffer listing all notes grouped by date with status indicators

## Requirements

- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [img-clip.nvim](https://github.com/HakonHarnes/img-clip.nvim) (optional, for image paste)
- `ripgrep` (for content search)
- `find` (for file listing)
- A vague sense that this time, you'll actually keep your notes organized

## Installation

**lazy.nvim** - add to your plugin list:

```lua
{
  "siatko/denim.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "HakonHarnes/img-clip.nvim",
  },
  config = function()
    require("denim").setup({
      notes_dir = "~/notes",
    })
  end,
}
```

**LazyVim** - create `~/.config/nvim/lua/plugins/denim.lua`:

```lua
return {
  "siatko/denim.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "HakonHarnes/img-clip.nvim",
  },
  config = function()
    require("denim").setup({
      notes_dir = "~/notes",
    })
  end,
}
```

## Configuration

These are the defaults - only set what you want to override. Don't override everything just because you can.

```lua
require("denim").setup({
  notes_dir = "~/notes",

  keymaps = {
    new_note       = "<leader>nn",
    search_notes   = "<leader>nf",
    search_content = "<leader>ns",
    search_tags    = "<leader>nt",
    insert_link    = "<leader>nl",
    backlinks      = "<leader>nb",
    paste_image    = "<leader>np",
    refactor       = "<leader>nr",
    new_todo       = "<leader>nTn",
    open_todos     = "<leader>nTo",
    done_todos     = "<leader>nTx",
    todo_done      = "<leader>nTd",
    open_index     = "<leader>ni",
  },
})
```

## Keymaps

| Key | Action |
|---|---|
| `<leader>nn` | New note |
| `<leader>nf` | Find note by filename |
| `<leader>ns` | Search note contents (live grep) |
| `<leader>nt` | Browse and search tags |
| `<leader>nl` | Insert link to another note |
| `<leader>nb` | Show backlinks to current note |
| `<leader>np` | Paste image from clipboard |
| `<leader>nr` | Refactor current note (rename + retag) |
| `<leader>nTn` | New todo |
| `<leader>nTo` | List open todos |
| `<leader>nTx` | List done todos (look at all the things you did!) |
| `<leader>nTd` | Mark current todo as done |
| `<leader>ni` | Open notes index |
| `<CR>` | Follow markdown link (inside note files) |

## File Naming

Filenames encode date, title, status and tags - no frontmatter required. Everything lives flat in `notes_dir`. It looks weird. You'll get used to it. Then you'll love it. Then you'll evangelize it at parties and lose friends.

**Notes**
```
YYYYMMDD--title-slug__tag1_tag2.md
20260514--zettelkasten-intro__pkm_writing.md
```

**Todos**
```
YYYYMMDD-O-title-slug__tag1_tag2.md   <- open (you will get to this)
YYYYMMDD-X-title-slug__tag1_tag2.md   <- done (you actually did it!)
20260514-O-fix-login-bug__backend.md
```

**Attachments**
```
YYYYMMDD--name.ext
20260514--architecture-diagram.png
```

`<leader>nTd` renames the current file in place, swapping `-O-` for `-X-`. Instant dopamine.

## Tag Workflow

When creating a note or todo, after entering the title a Telescope picker appears showing all tags already used across your notes. Use `<Tab>` to select multiple existing tags. Type a new tag name and press `<Enter>` to create it - both selected and typed tags are applied together.

`<leader>nt` opens the same picker for searching: selecting one tag shows all files containing it, selecting multiple filters to files containing every selected tag. Great for rediscovering notes you forgot you wrote.

## Notes Index

`<leader>ni` (or `:DenimIndex`) opens a virtual buffer listing all notes grouped by date, newest first. A bird's-eye view of your brain:

```
# Notes Index

## 2026-05-14

- [ ] [Fix login bug](20260514-O-fix-login-bug__backend.md)
- [Zettelkasten intro](20260514--zettelkasten-intro__pkm.md)

## 2026-05-13

- [x] [Write tests](20260513-X-write-tests.md)
```

| Key | Action |
|---|---|
| `<CR>` | Open the note under the cursor - works anywhere on the line, not just on the link text |
| `r` | Refresh the index |
| `q` | Close the index (and pretend you didn't see all those open todos) |

## User Commands

All features are also available as commands, useful for custom keymaps or scripts:

| Command | Action |
|---|---|
| `:DenimNew` | New note |
| `:DenimSearch` | Find notes by filename |
| `:DenimSearchContent` | Search note contents |
| `:DenimTags` | Search tags |
| `:DenimInsertLink` | Insert link to another note |
| `:DenimBacklinks` | Show backlinks to current note |
| `:DenimPasteImage` | Paste image from clipboard |
| `:DenimRefactor` | Refactor current note (rename + retag) |
| `:DenimNewTodo` | New todo |
| `:DenimOpenTodos` | List open todos |
| `:DenimDoneTodos` | List done todos |
| `:DenimTodoDone` | Mark current todo as done |
| `:DenimIndex` | Open notes index |

## Development

### Setup

Clone the repo and point lazy.nvim at the local path instead of GitHub:

```lua
{
  dir = "~/path/to/denim.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "HakonHarnes/img-clip.nvim",
  },
  config = function()
    require("denim").setup({ notes_dir = "~/notes" })
  end,
}
```

Changes to the Lua files take effect after reloading Neovim (or `:source %` on the changed file).

### Testing

Tests use [plenary.nvim](https://github.com/nvim-lua/plenary.nvim), which must be installed in your Neovim setup. Run the suite from the project root:

```
make test
```

The tests cover the pure helper functions in `lua/denim/utils.lua`, the index line builder in `lua/denim/index.lua`, and integration tests for all user-facing operations: note creation, todo creation and completion, refactor, link following, and more.

## TODO

*(Yes, a todo section. In a todo plugin. The irony is not lost on us.)*

- [x] **Filesystem tests** - add integration tests that create real files and clean up after themselves, covering note creation, refactor, and link-update flows
- [x] **Image link navigation** - following a `<CR>` link to an image file currently errors with "no such file"; show a friendly message instead
- [x] **Pre-selected tags in refactor** - visually mark the current note's tags as already selected when the tag picker opens during refactor
- [ ] **Refactor from a link** - allow running refactor while the cursor is on a `[title](path)` link in any note, not only when the target file is the active buffer
