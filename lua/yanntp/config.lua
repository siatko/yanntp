local M = {}

M.defaults = {
  notes_dir = "~/notes",
  folders = {
    inbox = "00_inbox",
    zettel = "10_zettel",
    lists = "20_lists",
    todos = "30_todos",
    projects = "40_projects",
    attachments = "99_attachments",
  },
  keymaps = {
    new_note = "<leader>nn",
    search_notes = "<leader>nf",
    search_content = "<leader>ns",
    search_tags = "<leader>nt",
    paste_image = "<leader>np",
    insert_link = "<leader>nl",
    new_todo = "<leader>nTn",
    open_todos = "<leader>nTo",
    done_todos = "<leader>nTx",
    todo_done = "<leader>nTd",
  },
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
  M.options.notes_dir = vim.fn.expand(M.options.notes_dir)
end

return M
