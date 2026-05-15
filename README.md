# denim.nvim

```
   o   o   o   o   o
  ___________________
 |                   |
 |  20260514--       |
 |  my-note__pkm.md  |     denim.nvim
 |                   |
 |  # MY NOTE        |
 |                   |
 |  _______________  |
 |  _______________  |
 |  _______          |
 |                   |
 |___________________|
```

> A [Denote](https://github.com/protesilaos/denote)-inspired note-taking plugin for Neovim.
> Plain markdown files, structured filenames, no database, no proprietary formats.

## Features

- **Flat structure** - all notes, todos and attachments live in one directory
- **Denote-style filenames** - `YYYYMMDD--title__tag1_tag2.md`
- **Todo tracking** - open (`-O-`) and done (`-X-`) status embedded in filename
- **Tag picker** - Telescope UI with multi-select and inline tag creation
- **Tag search** - browse all tags across your notes and filter by one or more
- **Tag rename** - rename a tag across all notes in one step; all affected files and backlinks updated automatically
- **Templates** - create notes from `.md` files in `notes_dir/.templates/`; templates are excluded from all search results
- **Full-text search** - live grep across all note contents
- **Note linking** - insert markdown links to other notes, follow links with `<CR>`
- **Backlinks** - find all notes that link to the current note
- **Refactor** - rename and retag the current note in one step; all linking notes updated automatically
- **Image paste** - paste clipboard images via img-clip, saved as `YYYYMMDD--name__tags.ext`
- **Notes index** - virtual buffer listing all notes grouped by date with status indicators
- **Statistics** - note counts, todo counts, tag usage and monthly activity at a glance

## Requirements

- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [img-clip.nvim](https://github.com/HakonHarnes/img-clip.nvim) (optional, for image paste)
- `ripgrep` (for content search)
- `find` (for file listing)

## Installation

**lazy.nvim:**

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

## Configuration

All keys are optional - only set what you want to override:

```lua
require("denim").setup({
  notes_dir = "~/notes",

  keymaps = {
    new_note          = "<leader>nn",
    new_from_template = "<leader>nN",
    search_notes      = "<leader>nf",
    search_content    = "<leader>ns",
    search_tags       = "<leader>nt",
    search_templates  = "<leader>ne",
    rename_tag        = "<leader>nR",
    insert_link       = "<leader>nl",
    backlinks         = "<leader>nb",
    paste_image       = "<leader>np",
    refactor          = "<leader>nr",
    new_todo          = "<leader>nTn",
    open_todos        = "<leader>nTo",
    done_todos        = "<leader>nTx",
    todo_done         = "<leader>nTd",
    open_index        = "<leader>ni",
    open_stats        = "<leader>nS",
  },
})
```

## Keymaps

| Key | Action |
|---|---|
| `<leader>nn` | New note |
| `<leader>nN` | New note from template |
| `<leader>nf` | Find note by filename |
| `<leader>ns` | Search note contents (live grep) |
| `<leader>nt` | Browse and search tags |
| `<leader>ne` | Browse and edit templates |
| `<leader>nR` | Rename a tag across all notes |
| `<leader>nl` | Insert link to another note |
| `<leader>nb` | Show backlinks to current note |
| `<leader>np` | Paste image from clipboard |
| `<leader>nr` | Refactor current note (rename + retag) |
| `<leader>nTn` | New todo |
| `<leader>nTo` | List open todos |
| `<leader>nTx` | List done todos |
| `<leader>nTd` | Mark current todo as done |
| `<leader>ni` | Open notes index |
| `<leader>nS` | Open notes statistics |
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
YYYYMMDD-O-title-slug__tag1_tag2.md   (open)
YYYYMMDD-X-title-slug__tag1_tag2.md   (done)
20260514-O-fix-login-bug__backend.md
```

**Attachments**
```
YYYYMMDD--name.ext
20260514--architecture-diagram.png
```

## Tag Workflow

When creating a note or todo, a Telescope picker appears after entering the title. Use `<Tab>` to select multiple existing tags. Type a new tag name and press `<Enter>` to create it on the fly - selected and typed tags are combined.

`<leader>nt` opens a search picker: selecting one or more tags filters to notes that carry all of them.

`<leader>nN` opens a template picker showing all `.md` files from `notes_dir/.templates/`. After selecting, the usual title and tag prompts follow. The template's body is used as the note's initial content; an H1 heading in the template is replaced by the generated title. Templates are never shown in note search or content grep results. If `.templates/` is empty or missing, denim notifies and bails. Create and edit templates with `<leader>ne`.

`<leader>nR` opens a single-select tag picker. After selecting a tag, enter a new name and every file carrying that tag is renamed and every backlink pointing to any of those files is rewritten. A notification reports how many files were renamed and how many link references were updated.

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

## Statistics

`<leader>nS` (or `:DenimStats`) opens a virtual buffer with an overview of your notes:

```
# Notes Statistics

## Overview

  Total          42
  Notes          27
  Open todos      7
  Done todos      8
  Tags           23

## Activity

  This month      8
  Last month     14

## Top Tags

  pkm            12
  writing         8
  backend         6
```

| Key | Action |
|---|---|
| `r` | Refresh |
| `q` | Close |

## User Commands

| Command | Action |
|---|---|
| `:DenimNew` | New note |
| `:DenimNewFromTemplate` | New note from template |
| `:DenimSearch` | Find notes by filename |
| `:DenimSearchContent` | Search note contents |
| `:DenimTags` | Search tags |
| `:DenimTemplates` | Browse and edit templates |
| `:DenimRenameTag` | Rename a tag across all notes |
| `:DenimInsertLink` | Insert link to another note |
| `:DenimBacklinks` | Show backlinks to current note |
| `:DenimPasteImage` | Paste image from clipboard |
| `:DenimRefactor` | Refactor current note (rename + retag) |
| `:DenimNewTodo` | New todo |
| `:DenimOpenTodos` | List open todos |
| `:DenimDoneTodos` | List done todos |
| `:DenimTodoDone` | Mark current todo as done |
| `:DenimIndex` | Open notes index |
| `:DenimStats` | Open notes statistics |

## Development

Clone the repo and point lazy.nvim at the local path:

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

Run the test suite from the project root (requires plenary.nvim):

```
make test
```

Tests cover pure helpers in `utils.lua`, the index line builder in `index.lua`, and integration tests for all user-facing operations.

## TODO

- [ ] Refactor from a link - run refactor while the cursor is on a `[title](path)` link in any note, not only when the target file is the active buffer
- [x] Integration tests for rename_tag
