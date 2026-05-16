local M = {}

M.defaults = {
  notes_dir = "~/notes",
  keymaps = {
    new_note          = "<leader>nn",
    search_notes      = "<leader>nf",
    search_content    = "<leader>ns",
    refactor          = "<leader>nr",
    paste_image       = "<leader>np",
    insert_link       = "<leader>nl",
    backlinks         = "<leader>nb",
    new_from_template = "<leader>ntn",
    new_template      = "<leader>ntN",
    search_templates  = "<leader>nte",
    search_tags       = "<leader>ngs",
    search_untagged   = "<leader>ngu",
    rename_tag        = "<leader>ngr",
    new_todo          = "<leader>nxn",
    new_todo_from_template = "<leader>nxt",
    open_todos        = "<leader>nxo",
    done_todos        = "<leader>nxd",
    todo_done         = "<leader>nxx",
    todo_undone       = "<leader>nxu",
    open_index        = "<leader>nvi",
    open_stats        = "<leader>nvs",
  },
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
  M.options.notes_dir = vim.fn.expand(M.options.notes_dir)
end

return M
