local opt = vim.opt
local keymap = vim.keymap

-- Encoding
vim.scriptencoding = 'utf-8'
opt.encoding = 'utf-8'
opt.fileencodings = 'utf-8'

-- Software Language
vim.cmd('language C')
vim.cmd('lang en_US.UTF-8')

-- Options
opt.swapfile = false
opt.backup = false
opt.hidden = true
opt.number = true
opt.cursorline = true
opt.shortmess:append({ I = true })
opt.clipboard:append({ 'unnamed', 'unnamedplus' })
opt.list = true
opt.listchars = { tab = '»-', trail = '·', eol = '¬', extends = '»', precedes = '«', nbsp = '%' }
opt.tabstop = 4
opt.expandtab = true
opt.autoindent = true
opt.shiftwidth = 4
opt.background = 'dark'
vim.cmd('set nofixeol')

-- Keymap
keymap.set('i', 'jj', '<ESC>', { noremap = true, silent = true})
keymap.set('', '<Up>', '<nop>')
keymap.set('', '<Down>', '<nop>')
keymap.set('', '<Left>', '<nop>')
keymap.set('', '<Right>', '<nop>')

vim.g.mapleader = " "
vim.keymap.set('n', '<leader>F', "<cmd>lua require('fzf-lua').files()<CR>")
vim.keymap.set('n', '<leader>b', "<cmd>lua require('fzf-lua').buffers()<CR>")
vim.keymap.set('n', '<leader>f', "<cmd>lua require('fzf-lua').git_files()<CR>")
vim.keymap.set('n', '<leader>g', "<cmd>lua require('fzf-lua').live_grep()<CR>")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugins
require("lazy").setup({
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    config = true,
    opts = ...
  },
  {
    "ibhagwan/fzf-lua",
    -- optional for icon support
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      -- calling `setup` is optional for customization
      require("fzf-lua").setup({})
    end
  },
  {
    'neoclide/coc.nvim'
  },
  {
    'rebelot/kanagawa.nvim'
  },
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' }
  },
  {
    'ryanoasis/vim-devicons'
  },
  {
    'lambdalisue/fern.vim'
  }
})

-- Theme
vim.cmd('colorscheme gruvbox')
-- vim.cmd('colorscheme kanagawa')

require('lualine').setup {
  options = {
    icons_enabled = true,
    theme = 'auto',
    component_separators = { left = '', right = ''},
    section_separators = { left = '', right = ''},
    disabled_filetypes = {
      statusline = {},
      winbar = {},
    },
    ignore_focus = {},
    always_divide_middle = true,
    globalstatus = false,
    refresh = {
      statusline = 1000,
      tabline = 1000,
      winbar = 1000,
    }
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff', 'diagnostics'},
    lualine_c = {'filename'},
    lualine_x = {'encoding', 'fileformat', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filename'},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {}
}
