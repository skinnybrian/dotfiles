return {
  "mrjones2014/smart-splits.nvim",
  lazy = false,
  config = function()
    local splits = require("smart-splits")
    splits.setup({})

    local set = vim.keymap.set
    -- Movement (BS fallback for Ghostty CSI u: ctrl+h=csi:104;5u)
    set("n", "<C-h>", splits.move_cursor_left,  { silent = true })
    set("n", "<BS>",  splits.move_cursor_left,  { silent = true })
    set("n", "<C-j>", splits.move_cursor_down,  { silent = true })
    set("n", "<C-k>", splits.move_cursor_up,    { silent = true })
    set("n", "<C-l>", splits.move_cursor_right, { silent = true })
    -- Resize
    set("n", "<A-h>", splits.resize_left,  { silent = true })
    set("n", "<A-j>", splits.resize_down,  { silent = true })
    set("n", "<A-k>", splits.resize_up,    { silent = true })
    set("n", "<A-l>", splits.resize_right, { silent = true })
  end,
}
