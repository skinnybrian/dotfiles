return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "<leader>F", function() require("fzf-lua").files() end, desc = "Files (all)" },
    { "<leader>b", function() require("fzf-lua").buffers() end, desc = "Buffers" },
    {
      "<leader>f",
      function()
        require("fzf-lua").git_files({
          cmd = "git ls-files --exclude-standard --cached --others --deduplicate",
        })
      end,
      desc = "Git files",
    },
    { "<leader>g", function() require("fzf-lua").live_grep() end, desc = "Live grep" },
  },
  opts = {},
}
