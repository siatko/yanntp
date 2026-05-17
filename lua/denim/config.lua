local M = {}

M.defaults = {
  notes_dir = "~/notes",
  workflow = {
    todo = "todo",
    done = "done",
  },
  keymaps = {
    new_note          = "<leader>nn",
    search_notes      = "<leader>nf",
    search_content    = "<leader>ns",
    refactor          = "<leader>nr",
    paste_image       = "<leader>np",
    insert_link       = "<leader>nl",
    insert_url_link   = "<leader>nu",
    backlinks         = "<leader>nb",
    new_from_template = "<leader>ntn",
    new_template      = "<leader>ntN",
    search_templates  = "<leader>nte",
    search_tags       = "<leader>ngs",
    search_untagged   = "<leader>ngu",
    rename_tag        = "<leader>ngr",
    mark_todo         = "<leader>nxx",
    mark_done         = "<leader>nxu",
    open_index        = "<leader>nvi",
    open_stats        = "<leader>nvs",
  },
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
  M.options.notes_dir = vim.fn.resolve(vim.fn.expand(M.options.notes_dir))
end

return M
