# denim.nvim

```
   o   o   o   o   o
  ___________________
 |                   |
 | 20260514T143022-- |
 | my-note__pkm.md   |     denim.nvim
 |                   |
 |  # MY NOTE        |   no database.
 |                   |   no frontmatter.
 |  _______________  |   just a really
 |  _______________  |   long filename.
 |  _______          |
 |                   |
 |___________________|
```

> A [Denote](https://protesilaos.com/emacs/denote)-inspired note-taking plugin for Neovim.
> Plain markdown files, structured filenames, no database, no proprietary formats.

## Features

- **Flat structure** - all notes, todos and attachments live in one directory
- **Denote-style filenames** - `YYYYMMDDTHHMMSS--title__tag1_tag2.md`
- **Todo tracking** - open (`-O-`) and done (`-X-`) status embedded in filename
- **Tag picker** - Telescope UI with multi-select and inline tag creation
- **Tag search** - browse all tags across your notes and filter by one or more
- **Tag rename** - rename a tag across all notes in one step; all affected files and backlinks updated automatically
- **Templates** - create notes from `.md` files in `notes_dir/.templates/`; place `$` in a template for cursor stops - Tab steps through each one; templates are excluded from all search results
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
- [which-key.nvim](https://github.com/folke/which-key.nvim) (optional, for keymap group labels)
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
    -- basic
    new_note          = "<leader>nn",
    search_notes      = "<leader>nf",
    search_content    = "<leader>ns",
    refactor          = "<leader>nr",
    paste_image       = "<leader>np",
    insert_link       = "<leader>nl",
    backlinks         = "<leader>nb",
    -- templates
    new_from_template = "<leader>ntn",
    new_template      = "<leader>ntN",
    search_templates  = "<leader>nte",
    -- tags
    search_tags       = "<leader>ngs",
    search_untagged   = "<leader>ngu",
    rename_tag        = "<leader>ngr",
    -- todos
    new_todo          = "<leader>nxn",
    open_todos        = "<leader>nxo",
    done_todos        = "<leader>nxd",
    todo_done         = "<leader>nxx",
    -- views
    open_index        = "<leader>nvi",
    open_stats        = "<leader>nvs",
  },
})
```

## Keymaps

| Key | Action |
|---|---|
| `<leader>nn` | New note |
| `<leader>nf` | Find note by filename |
| `<leader>ns` | Search note contents (live grep) |
| `<leader>nr` | Refactor current note (rename + retag) |
| `<leader>np` | Paste image from clipboard |
| `<leader>nl` | Insert link to another note |
| `<leader>nb` | Show backlinks to current note |
| `<leader>ntn` | New note from template |
| `<leader>ntN` | New template |
| `<leader>nte` | Browse and edit templates |
| `<leader>ngs` | Browse and search tags |
| `<leader>ngu` | List notes without any tags |
| `<leader>ngr` | Rename a tag across all notes |
| `<leader>nxn` | New todo |
| `<leader>nxo` | List open todos |
| `<leader>nxd` | List done todos |
| `<leader>nxx` | Mark current todo as done |
| `<leader>nvi` | Open notes index |
| `<leader>nvs` | Open notes statistics |
| `<CR>` | Follow markdown link (inside note files) |

## File Naming

denim follows the [Denote](https://protesilaos.com/emacs/denote) file naming convention, pioneered by Protesilaos Stavrou for Emacs. The core idea: **the filename is the metadata**. No frontmatter, no database, no proprietary format - just a name you can grep, sort, move, or open with any editor on any OS, forever.

Every filename is built from four parts:

```
20260514T143022--zettelkasten-intro__pkm_writing.md
│       │      │                   │
│       │      │                   └─ tags, separated by _
│       │      └─ -- separates timestamp from title
│       └─ T separates date from time
└─ YYYYMMDDTHHMMSS — unique timestamp, sorts chronologically
```

The timestamp makes every note unique even if you create two with the same title. The double-dash `--` and double-underscore `__` separators are unambiguous delimiters that survive any shell quoting, URL encoding, or overzealous autocorrect.

**Notes**
```
20260514T143022--zettelkasten-intro__pkm_writing.md
20260514T161500--meeting-notes.md
```

**Todos** — status lives between the timestamp and the title
```
20260514T143022-O-fix-login-bug__backend.md   (open)
20260514T143022-X-fix-login-bug__backend.md   (done)
```

**Attachments**
```
20260514T143022--architecture-diagram.png
```

## Tag Workflow

When creating a note or todo, a Telescope picker appears after entering the title. Use `<Tab>` to select multiple existing tags. Type a new tag name and press `<Enter>` to create it on the fly - selected and typed tags are combined.

`<leader>ngs` opens a search picker: selecting one or more tags filters to notes that carry all of them.

`<leader>ntn` opens a template picker showing all `.md` files from `notes_dir/.templates/`. After selecting, the usual title and tag prompts follow. The template's body is used as the note's initial content; an H1 heading in the template is replaced by the generated title. Templates are never shown in note search or content grep results. If `.templates/` is empty or missing, denim notifies and bails. Create a new template with `<leader>ntN` (prompts for a name, opens a blank buffer in `.templates/`). Browse and edit existing templates with `<leader>nte`.

Place `$` anywhere in a template to mark cursor stops. When the note opens, the cursor lands on the first `$` (which is deleted) in insert mode. Press `<Tab>` to jump to each subsequent `$`. Once all stops are visited `<Tab>` returns to its normal behavior.

```
## Meeting: $

Attendees: $

## Action items

- $
```

`<leader>ngu` opens a picker listing all notes that have no tags - useful for a quick tagging pass.

`<leader>ngr` opens a single-select tag picker. After selecting a tag, enter a new name and every file carrying that tag is renamed and every backlink pointing to any of those files is rewritten. A notification reports how many files were renamed and how many link references were updated.

## Notes Index

`<leader>nvi` (or `:DenimIndex`) opens a virtual buffer listing all notes grouped by date, newest first:

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

`<leader>nvs` (or `:DenimStats`) opens a virtual buffer with an overview of your notes:

```
# Notes Statistics

## Overview

  Total          42
  Notes          27
  Open todos      7
  Done todos      8
  Tags           23
  Linked         18  (43%)

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
| `:DenimNewTemplate` | Create a new template |
| `:DenimSearch` | Find notes by filename |
| `:DenimSearchContent` | Search note contents |
| `:DenimTags` | Search tags |
| `:DenimTemplates` | Browse and edit templates |
| `:DenimUntagged` | List notes without tags |
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
