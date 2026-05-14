# yanntp

**Yet Another Neovim Note Taking Plugin**

A focused, [Denote](https://github.com/protesilaos/denote)-inspired note taking plugin for Neovim. Notes are plain markdown files with structured filenames — no proprietary formats, no database, just files you own.

## Features

- **Denote-style filenames** — `YYYYMMDD--title__tag1_tag2.md`
- **Todo tracking** — open (`-O-`) and done (`-X-`) status embedded in filename
- **Tag picker** — telescope UI with multi-select and new tag creation when writing notes
- **Tag search** — browse all tags used across your notes
- **Full-text search** — live grep across all note contents
- **Note linking** — insert markdown links to other notes, follow links with `<CR>`
- **Backlinks** — find all notes that link to the current note
- **Move note** — move a note to a different folder via picker
- **Retag** — change tags on the current note, file renamed automatically
- **Image paste** — paste clipboard images into `99_attachments/` via img-clip
- **Folder structure** — organised inbox, zettel, lists, todos, projects and attachments

## Requirements

- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [img-clip.nvim](https://github.com/HakonHarnes/img-clip.nvim)
- `ripgrep` (for content search)
- `find` (for file listing)

## Installation

```lua
-- lazy.nvim
{
  "siatko/yanntp",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "HakonHarnes/img-clip.nvim",
  },
  config = function()
    require("yanntp").setup({
      notes_dir = "~/notes",
    })
  end,
}
```

## Configuration

These are the defaults — only set what you want to override:

```lua
require("yanntp").setup({
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

## File Naming

Filenames encode date, title, status and tags — no frontmatter required.

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

When creating a note or todo, after entering the title a telescope picker appears showing all tags already used across your notes. Use `<Tab>` to select multiple existing tags. Type a new tag name and press `<Enter>` to create it — both selected and typed tags are applied together.

`<leader>nt` opens the same picker for searching: selecting one tag shows all lines containing it, selecting multiple filters to files containing every selected tag.

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
| `:YanntpNew` | New note in inbox |
| `:YanntpNewInFolder` | New note with folder selection |
| `:YanntpSearch` | Find notes by filename |
| `:YanntpSearchContent` | Search note contents |
| `:YanntpTags` | Search tags |
| `:YanntpInsertLink` | Insert link to another note |
| `:YanntpPasteImage` | Paste image from clipboard |
| `:YanntpNewTodo` | New todo |
| `:YanntpOpenTodos` | List open todos |
| `:YanntpDoneTodos` | List done todos |
| `:YanntpTodoDone` | Mark current todo as done |
