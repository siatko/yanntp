local M = {}

function M.setup(opts)
  require("yanntp.config").setup(opts)

  local notes = require("yanntp.notes")
  notes.ensure_folders()

  local keymaps = require("yanntp.config").options.keymaps
  if keymaps then
    if keymaps.new_note then
      vim.keymap.set("n", keymaps.new_note, notes.new_note, {
        desc = "yanntp: new note",
      })
    end
    if keymaps.search_notes then
      vim.keymap.set("n", keymaps.search_notes, function()
        require("yanntp.telescope").search_notes()
      end, { desc = "yanntp: search notes" })
    end
    if keymaps.search_content then
      vim.keymap.set("n", keymaps.search_content, function()
        require("yanntp.telescope").search_content()
      end, { desc = "yanntp: search note contents" })
    end
    if keymaps.search_tags then
      vim.keymap.set("n", keymaps.search_tags, function()
        require("yanntp.telescope").search_tags()
      end, { desc = "yanntp: search tags" })
    end
    if keymaps.paste_image then
      vim.keymap.set("n", keymaps.paste_image, notes.paste_image, {
        desc = "yanntp: paste image from clipboard",
      })
    end
    if keymaps.insert_link then
      vim.keymap.set("n", keymaps.insert_link, function()
        require("yanntp.telescope").insert_link()
      end, { desc = "yanntp: insert link to note" })
    end
    if keymaps.backlinks then
      vim.keymap.set("n", keymaps.backlinks, function()
        require("yanntp.telescope").backlinks()
      end, { desc = "yanntp: show backlinks" })
    end
    if keymaps.move_note then
      vim.keymap.set("n", keymaps.move_note, notes.move_note, {
        desc = "yanntp: move note to folder",
      })
    end
    if keymaps.retag then
      vim.keymap.set("n", keymaps.retag, notes.retag, {
        desc = "yanntp: retag current note",
      })
    end
    if keymaps.new_todo then
      vim.keymap.set("n", keymaps.new_todo, notes.new_todo, {
        desc = "yanntp: new todo",
      })
    end
    if keymaps.open_todos then
      vim.keymap.set("n", keymaps.open_todos, function()
        require("yanntp.telescope").list_open_todos()
      end, { desc = "yanntp: list open todos" })
    end
    if keymaps.done_todos then
      vim.keymap.set("n", keymaps.done_todos, function()
        require("yanntp.telescope").list_done_todos()
      end, { desc = "yanntp: list done todos" })
    end
    if keymaps.todo_done then
      vim.keymap.set("n", keymaps.todo_done, notes.todo_done, {
        desc = "yanntp: mark current todo as done",
      })
    end
    if keymaps.open_index then
      vim.keymap.set("n", keymaps.open_index, function()
        require("yanntp.index").open()
      end, { desc = "yanntp: open notes index" })
    end
  end

  local notes_dir = require("yanntp.config").options.notes_dir
  vim.api.nvim_create_augroup("yanntp", { clear = true })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = "yanntp",
    pattern = "*.md",
    callback = function()
      if vim.startswith(vim.fn.expand("%:p"), notes_dir) then
        vim.keymap.set("n", "<CR>", function()
          require("yanntp.notes").follow_link()
        end, { buffer = true, desc = "yanntp: follow link" })
      end
    end,
  })

  vim.api.nvim_create_user_command("YanntpInsertLink", function()
    require("yanntp.telescope").insert_link()
  end, { desc = "Insert link to another note" })
  vim.api.nvim_create_user_command("YanntpBacklinks", function()
    require("yanntp.telescope").backlinks()
  end, { desc = "Show backlinks to current note" })
  vim.api.nvim_create_user_command("YanntpMoveNote", notes.move_note, {
    desc = "Move current note to a different folder",
  })
  vim.api.nvim_create_user_command("YanntpRetag", notes.retag, {
    desc = "Retag current note",
  })
  vim.api.nvim_create_user_command("YanntpNew", notes.new_note, {
    desc = "Create a new note in inbox",
  })
  vim.api.nvim_create_user_command("YanntpNewInFolder", notes.new_note_in_folder, {
    desc = "Create a new note (select folder)",
  })
  vim.api.nvim_create_user_command("YanntpSearch", function()
    require("yanntp.telescope").search_notes()
  end, { desc = "Search notes by filename" })
  vim.api.nvim_create_user_command("YanntpSearchContent", function()
    require("yanntp.telescope").search_content()
  end, { desc = "Search note contents" })
  vim.api.nvim_create_user_command("YanntpTags", function()
    require("yanntp.telescope").search_tags()
  end, { desc = "Search tags in notes" })
  vim.api.nvim_create_user_command("YanntpPasteImage", notes.paste_image, {
    desc = "Paste image from clipboard into attachments",
  })
  vim.api.nvim_create_user_command("YanntpNewTodo", notes.new_todo, {
    desc = "Create a new todo",
  })
  vim.api.nvim_create_user_command("YanntpTodoDone", notes.todo_done, {
    desc = "Mark current todo as done",
  })
  vim.api.nvim_create_user_command("YanntpOpenTodos", function()
    require("yanntp.telescope").list_open_todos()
  end, { desc = "List open todos" })
  vim.api.nvim_create_user_command("YanntpDoneTodos", function()
    require("yanntp.telescope").list_done_todos()
  end, { desc = "List done todos" })
  vim.api.nvim_create_user_command("YanntpIndex", function()
    require("yanntp.index").open()
  end, { desc = "Open notes index" })
end

return M
