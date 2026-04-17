return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  lazy = false,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "<leader>\\", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file tree" },
  },
  opts = {},
}
