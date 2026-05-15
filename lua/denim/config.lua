local M = {}

M.defaults = {
  notes_dir = "~/notes",
  keymaps = {
    new_note          = "<leader>nn",
    new_from_template = "<leader>nN",
    search_templates  = "<leader>ne",
    search_notes = "<leader>nf",
    search_content = "<leader>ns",
    search_tags = "<leader>nt",
    rename_tag  = "<leader>nR",
    paste_image = "<leader>np",
    insert_link = "<leader>nl",
    backlinks   = "<leader>nb",
    refactor    = "<leader>nr",
    new_todo = "<leader>nTn",
    open_todos = "<leader>nTo",
    done_todos = "<leader>nTx",
    todo_done = "<leader>nTd",
    open_index = "<leader>ni",
  },
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
  M.options.notes_dir = vim.fn.expand(M.options.notes_dir)
end

return M
