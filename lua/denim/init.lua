local M = {}

function M.setup(opts)
  require("denim.config").setup(opts)

  local notes = require("denim.notes")
  notes.ensure_notes_dir()

  local keymaps = require("denim.config").options.keymaps
  if keymaps then
    if keymaps.new_note then
      vim.keymap.set("n", keymaps.new_note, notes.new_note, {
        desc = "denim: new note",
      })
    end
    if keymaps.search_notes then
      vim.keymap.set("n", keymaps.search_notes, function()
        require("denim.telescope").search_notes()
      end, { desc = "denim: search notes" })
    end
    if keymaps.search_content then
      vim.keymap.set("n", keymaps.search_content, function()
        require("denim.telescope").search_content()
      end, { desc = "denim: search note contents" })
    end
    if keymaps.search_tags then
      vim.keymap.set("n", keymaps.search_tags, function()
        require("denim.telescope").search_tags()
      end, { desc = "denim: search tags" })
    end
    if keymaps.paste_image then
      vim.keymap.set("n", keymaps.paste_image, notes.paste_image, {
        desc = "denim: paste image from clipboard",
      })
    end
    if keymaps.insert_link then
      vim.keymap.set("n", keymaps.insert_link, function()
        require("denim.telescope").insert_link()
      end, { desc = "denim: insert link to note" })
    end
    if keymaps.backlinks then
      vim.keymap.set("n", keymaps.backlinks, function()
        require("denim.telescope").backlinks()
      end, { desc = "denim: show backlinks" })
    end
    if keymaps.retag then
      vim.keymap.set("n", keymaps.retag, notes.retag, {
        desc = "denim: retag current note",
      })
    end
    if keymaps.new_todo then
      vim.keymap.set("n", keymaps.new_todo, notes.new_todo, {
        desc = "denim: new todo",
      })
    end
    if keymaps.open_todos then
      vim.keymap.set("n", keymaps.open_todos, function()
        require("denim.telescope").list_open_todos()
      end, { desc = "denim: list open todos" })
    end
    if keymaps.done_todos then
      vim.keymap.set("n", keymaps.done_todos, function()
        require("denim.telescope").list_done_todos()
      end, { desc = "denim: list done todos" })
    end
    if keymaps.todo_done then
      vim.keymap.set("n", keymaps.todo_done, notes.todo_done, {
        desc = "denim: mark current todo as done",
      })
    end
    if keymaps.open_index then
      vim.keymap.set("n", keymaps.open_index, function()
        require("denim.index").open()
      end, { desc = "denim: open notes index" })
    end
  end

  local notes_dir = require("denim.config").options.notes_dir
  vim.api.nvim_create_augroup("denim", { clear = true })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = "denim",
    pattern = "*.md",
    callback = function()
      if vim.startswith(vim.fn.expand("%:p"), notes_dir) then
        vim.keymap.set("n", "<CR>", function()
          require("denim.notes").follow_link()
        end, { buffer = true, desc = "denim: follow link" })
      end
    end,
  })

  vim.api.nvim_create_user_command("DenimInsertLink", function()
    require("denim.telescope").insert_link()
  end, { desc = "Insert link to another note" })
  vim.api.nvim_create_user_command("DenimBacklinks", function()
    require("denim.telescope").backlinks()
  end, { desc = "Show backlinks to current note" })
  vim.api.nvim_create_user_command("DenimRetag", notes.retag, {
    desc = "Retag current note",
  })
  vim.api.nvim_create_user_command("DenimNew", notes.new_note, {
    desc = "Create a new note in inbox",
  })
  vim.api.nvim_create_user_command("DenimSearch", function()
    require("denim.telescope").search_notes()
  end, { desc = "Search notes by filename" })
  vim.api.nvim_create_user_command("DenimSearchContent", function()
    require("denim.telescope").search_content()
  end, { desc = "Search note contents" })
  vim.api.nvim_create_user_command("DenimTags", function()
    require("denim.telescope").search_tags()
  end, { desc = "Search tags in notes" })
  vim.api.nvim_create_user_command("DenimPasteImage", notes.paste_image, {
    desc = "Paste image from clipboard",
  })
  vim.api.nvim_create_user_command("DenimNewTodo", notes.new_todo, {
    desc = "Create a new todo",
  })
  vim.api.nvim_create_user_command("DenimTodoDone", notes.todo_done, {
    desc = "Mark current todo as done",
  })
  vim.api.nvim_create_user_command("DenimOpenTodos", function()
    require("denim.telescope").list_open_todos()
  end, { desc = "List open todos" })
  vim.api.nvim_create_user_command("DenimDoneTodos", function()
    require("denim.telescope").list_done_todos()
  end, { desc = "List done todos" })
  vim.api.nvim_create_user_command("DenimIndex", function()
    require("denim.index").open()
  end, { desc = "Open notes index" })
end

return M
