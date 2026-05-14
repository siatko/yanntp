# denim.nvim

**Denote + vim = denim**

A focused, [Denote](https://github.com/protesilaos/denote)-inspired note taking plugin for Neovim. Notes are plain markdown files with structured filenames - no proprietary formats, no database, just files you own.

## Features

- **Flat structure** - all notes, todos and attachments live in one directory
- **Denote-style filenames** - `YYYYMMDD--title__tag1_tag2.md`
- **Todo tracking** - open (`-O-`) and done (`-X-`) status embedded in filename
- **Tag picker** - telescope UI with multi-select and new tag creation when writing notes
- **Tag search** - browse all tags used across your notes
- **Full-text search** - live grep across all note contents
- **Note linking** - insert markdown links to other notes, follow links with `<CR>`
- **Backlinks** - find all notes that link to the current note
- **Retag** - change tags on the current note, file renamed automatically; all notes linking to it are updated automatically
- **Image paste** - paste clipboard images via img-clip, saved as `YYYYMMDD--name.ext`
- **Notes index** - virtual buffer listing all notes grouped by date with status indicators

## Requirements

- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [img-clip.nvim](https://github.com/HakonHarnes/img-clip.nvim) (optional, for image paste)
- `ripgrep` (for content search)
- `find` (for file listing)

## Installation

```lua
-- lazy.nvim
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

## Configuration

These are the defaults - only set what you want to override:

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
| `<leader>nTx` | List done todos |
| `<leader>nTd` | Mark current todo as done |
| `<leader>ni` | Open notes index |
| `<CR>` | Follow markdown link (inside note files) |

## File Naming

Filenames encode date, title, status and tags - no frontmatter required. Everything lives flat in `notes_dir`.

**Notes**
```
YYYYMMDD--title-slug__tag1_tag2.md
20260514--zettelkasten-intro__pkm_writing.md
```

**Todos**
```
YYYYMMDD-O-title-slug__tag1_tag2.md   <- open
YYYYMMDD-X-title-slug__tag1_tag2.md   <- done
20260514-O-fix-login-bug__backend.md
```

**Attachments**
```
YYYYMMDD--name.ext
20260514--architecture-diagram.png
```

`<leader>nTd` renames the current file in place, swapping `-O-` for `-X-`.

## Tag Workflow

When creating a note or todo, after entering the title a telescope picker appears showing all tags already used across your notes. Use `<Tab>` to select multiple existing tags. Type a new tag name and press `<Enter>` to create it - both selected and typed tags are applied together.

`<leader>nt` opens the same picker for searching: selecting one tag shows all files containing it, selecting multiple filters to files containing every selected tag.

## Notes Index

`<leader>ni` (or `:DenimIndex`) opens a virtual buffer listing all notes grouped by date, newest first:

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
| `<CR>` | Open the note under the cursor |
| `r` | Refresh the index |
| `q` | Close the index |

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
| `:DenimRetag` | Retag current note |
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

The tests cover the pure helper functions in `lua/denim/utils.lua` and the index line builder in `lua/denim/index.lua`. UI and filesystem operations are not tested.
