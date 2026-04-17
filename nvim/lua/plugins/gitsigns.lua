return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    attach_to_untracked = true,
    signs = {
      add          = { text = "│" },
      change       = { text = "│" },
      delete       = { text = "_" },
      topdelete    = { text = "‾" },
      changedelete = { text = "~" },
      untracked    = { text = "┆" },
    },
    preview_config = {
      border   = "single",
      style    = "minimal",
      relative = "cursor",
      row      = 0,
      col      = 1,
    },
  },
}
