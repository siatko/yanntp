vim.opt.rtp:prepend(vim.fn.expand("~/.local/share/nvim/lazy/plenary.nvim"))
vim.opt.rtp:prepend(vim.fn.getcwd())

vim.g.clipboard = {
  name = "test-clipboard",
  copy = {
    ["+"] = { "sh", "-c", "cat > /tmp/nvim_test_clipboard_plus" },
    ["*"] = { "sh", "-c", "cat > /tmp/nvim_test_clipboard_star" },
  },
  paste = {
    ["+"] = { "sh", "-c", "cat /tmp/nvim_test_clipboard_plus 2>/dev/null || true" },
    ["*"] = { "sh", "-c", "cat /tmp/nvim_test_clipboard_star 2>/dev/null || true" },
  },
  cache_enabled = 0,
}
