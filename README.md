# denim.nvim

**Denote + vim = denim**

A focused, [Denote](https://github.com/protesilaos/denote)-inspired note taking plugin for Neovim. Notes are plain markdown files with structured filenames - no proprietary formats, no database, just files you own.

## Features

- **Denote-style filenames** - `YYYYMMDD--title__tag1_tag2.md`
- **Todo tracking** - open (`-O-`) and done (`-X-`) status embedded in filename
- **Tag picker** - telescope UI with multi-select and new tag creation when writing notes
- **Tag search** - browse all tags used across your notes
- **Full-text search** - live grep across all note contents
- **Note linking** - insert markdown links to other notes, follow links with `<CR>`
- **Backlinks** - find all notes that link to the current note
- **Move note** - move a note to a different folder via picker; all notes linking to it are updated automatically
- **Retag** - change tags on the current note, file renamed automatically; all notes linking to it are updated automatically
- **Image paste** - paste clipboard images into `99_attachments/` via img-clip
- **Notes index** - virtual buffer listing all notes grouped by date with status indicators
- **Folder structure** - organised inbox, zettel, lists, todos, projects and attachments

## Requirements

- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [img-clip.nvim](https://github.com/HakonHarnes/img-clip.nvim)
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

  folders = {
    inbox       = "00_inbox",
    zettel      = "10_zettel",
    lists       = "20_lists",
    todos       = "30_todos",
    projects    = "40_projects",
    attachments = "99_attachments",
  },

  keymaps = {
    new_note     = "<leader>nn",
    search_notes = "<leader>nf",
    search_content = "<leader>ns",
    search_tags  = "<leader>nt",
    insert_link  = "<leader>nl",
    paste_image  = "<leader>np",
    new_todo     = "<leader>nTn",
    open_todos   = "<leader>nTo",
    done_todos   = "<leader>nTx",
    todo_done    = "<leader>nTd",
  },
})
```

## Keymaps

| Key | Action |
|---|---|
| `<leader>nn` | New note in inbox |
| `<leader>nf` | Find note by filename |
| `<leader>ns` | Search note contents (live grep) |
| `<leader>nt` | Browse and search tags |
| `<leader>nl` | Insert link to another note |
| `<leader>np` | Paste image from clipboard |
| `<leader>nTn` | New todo |
| `<leader>nTo` | List open todos |
| `<leader>nTx` | List done todos |
| `<leader>nTd` | Mark current todo as done |
| `<CR>` | Follow markdown link (inside note files) |
| `<leader>nb` | Show backlinks to current note |
| `<leader>nm` | Move current note to a different folder |
| `<leader>nr` | Retag current note |
| `<leader>ni` | Open notes index |

## File Naming

Filenames encode date, title, status and tags - no frontmatter required.

**Notes**
```
YYYYMMDD--title-slug__tag1_tag2.md
20260514--zettelkasten-intro__pkm_writing.md
```

**Todos**
```
YYYYMMDD-O-title-slug__tag1_tag2.md   ← open
YYYYMMDD-X-title-slug__tag1_tag2.md   ← done
20260514-O-fix-login-bug__backend.md
```

`<leader>nTd` renames the current file in place, swapping `-O-` for `-X-`.

## Tag Workflow

When creating a note or todo, after entering the title a telescope picker appears showing all tags already used across your notes. Use `<Tab>` to select multiple existing tags. Type a new tag name and press `<Enter>` to create it - both selected and typed tags are applied together.

`<leader>nt` opens the same picker for searching: selecting one tag shows all lines containing it, selecting multiple filters to files containing every selected tag.

## Notes Index

`<leader>ni` (or `:DenimIndex`) opens a virtual buffer listing all notes grouped by date, newest first:

```
# Notes Index

## 2026-05-14

- [ ] [Fix login bug](30_todos/20260514-O-fix-login-bug__backend.md)
- [Zettelkasten intro](10_zettel/20260514--zettelkasten-intro__pkm.md)

## 2026-05-13

- [x] [Write tests](30_todos/20260513-X-write-tests.md)
```

| Key | Action |
|---|---|
| `<CR>` | Open the note under the cursor |
| `r` | Refresh the index |
| `q` | Close the index |

## Folder Structure

Folders are created automatically on first launch:

```
notes/
├── 00_inbox/        ← new notes land here
├── 10_zettel/       ← permanent notes
├── 20_lists/        ← lists
├── 30_todos/        ← todos
├── 40_projects/     ← project notes
└── 99_attachments/  ← images and documents
```

## User Commands

All features are also available as commands, useful for custom keymaps or scripts:

| Command | Action |
|---|---|
| `:DenimNew` | New note in inbox |
| `:DenimNewInFolder` | New note with folder selection |
| `:DenimSearch` | Find notes by filename |
| `:DenimSearchContent` | Search note contents |
| `:DenimTags` | Search tags |
| `:DenimInsertLink` | Insert link to another note |
| `:DenimPasteImage` | Paste image from clipboard |
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
