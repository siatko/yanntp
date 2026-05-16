# denim.nvim

```
   o   o   o   o   o
  ___________________
 |                   |
 | 20260514T143022-- |
 | my-note__pkm.md   |   denim.nvim
 |                   |
 |  # MY NOTE        |   no database.
 |                   |   no frontmatter.
 |  _______________  |   just a really
 |  _______________  |   long filename.
 |  _______          |
 |                   |   yet another denote
 |___________________|   plugin nobody asked for.
```

![Tests](https://github.com/siatko/denim.nvim/actions/workflows/test.yml/badge.svg)
![License](https://img.shields.io/github/license/siatko/denim.nvim)
![Latest release](https://img.shields.io/github/v/release/siatko/denim.nvim)

> A [Denote](https://protesilaos.com/emacs/denote)-inspired note-taking plugin for Neovim.
> Plain markdown files, structured filenames, no database, no proprietary formats.

## Features

- **Flat structure** - all notes, todos and attachments live in one directory
- **Denote-style filenames** - `YYYYMMDDTHHMMSS--title__tag1_tag2.md`
- **Todo tracking** - open (`-O-`) and done (`-X-`) status embedded in filename; todos can be marked done or reopened
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
  event = "VeryLazy",
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
    new_todo_from_template = "<leader>nxt",
    open_todos        = "<leader>nxo",
    done_todos        = "<leader>nxd",
    todo_done         = "<leader>nxx",
    todo_undone       = "<leader>nxu",
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
| `<leader>nxt` | New todo from template |
| `<leader>nxo` | List open todos |
| `<leader>nxd` | List done todos |
| `<leader>nxx` | Mark current todo as done |
| `<leader>nxu` | Reopen a done todo |
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
20260514T143022--architecture-diagram__pkm.png
```

## Linking Philosophy

Denote (the Emacs plugin that inspired the filename format) uses ID-based links:

```
[[denote:20260514T143022]]
```

The ID never changes, so links never break - even after a rename. denim takes a different approach and uses standard markdown links pointing to the full filename:

```markdown
[My Note](20260514T143022--my-note__pkm.md)
```

This means denim has to rewrite backlinks whenever a file is renamed (which it does automatically). That is a small price to pay for a significant gain: your notes are **plain readable markdown** that works everywhere - GitHub, Obsidian, any static site generator, or a plain text editor - with no plugin needed to resolve links. ID-based links are opaque outside of Emacs and lock your notes to the tool that created them. denim's goal is the opposite: the plugin is a convenience layer, and your notes should outlive it.

## Tag Workflow

When creating a note or todo, a Telescope picker appears after entering the title. Use `<Tab>` to toggle existing tags. To add new tags, type one or more space-separated names and press `<Enter>` - the picker re-opens with all previously-selected and newly-typed tags pre-selected, so you can keep selecting or deselecting. Press `<Enter>` with an empty prompt to finalize. Press `<Esc>` at any point to cancel without creating the note.

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
| `:DenimTodoUndone` | Reopen a done todo |
| `:DenimIndex` | Open notes index |
| `:DenimStats` | Open notes statistics |

## Development

Clone the repo and point lazy.nvim at the local path:

```lua
{
  dir = "~/path/to/denim.nvim",
  event = "VeryLazy",
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

## Contributing

PRs and issues are very welcome. One rule: **every change must be covered by tests.** This is the most important thing. Tests are what keep the plugin reliable as it grows, and no PR will be merged without them.

- Bug fix - **always** add a regression test that reproduces the bug before the fix. This is non-negotiable: a bug fix without a test is just a bug waiting to come back
- New feature in `notes.lua` - add integration specs in `tests/integration_spec.lua`
- New pure helper in `utils.lua` - add unit specs in `tests/utils_spec.lua`

Tests are run automatically on every push and pull request via GitHub Actions. You can run them locally with `make test` (requires plenary.nvim at `~/.local/share/nvim/lazy/plenary.nvim`).

See `CLAUDE.md` for a full overview of the architecture and testing conventions.

## A Note on How This Was Built

I'm a dad with a full-time job and approximately 45 minutes of free time per week. This plugin exists because I pair programmed it with [Claude Code](https://claude.ai/code) - which turns out to be a pretty good way to ship a Neovim plugin when your other option is waiting until your child moves out.

If you're using this plugin or thinking about contributing - you should know that. The ideas, design decisions, and direction are mine; Claude helped me get them out of my head and into working Lua faster than I could have alone. Issues and PRs are very welcome either way.

