local opt = vim.opt
local keymap = vim.keymap

-- Encoding
vim.scriptencoding = 'utf-8'
opt.encoding = 'utf-8'
opt.fileencoding = 'utf-8'

-- Options
opt.swapfile = false
opt.backup = false
opt.hidden = true
opt.number = true
opt.cursorline = true
opt.shortmess:append({ I = true })
opt.clipboard:append({ 'unnamedplus' })
opt.list = true
opt.listchars = { tab = '»-', trail = '·', eol = '¬', extends = '»', precedes = '«', nbsp = '%' }
opt.tabstop = 4
opt.expandtab = true
opt.autoindent = true
opt.shiftwidth = 4
opt.background = 'dark'

-- Keymap
keymap.set('i', 'jj', '<ESC>', { noremap = true, silent = true})
keymap.set('', '<Up>', '<nop>')
keymap.set('', '<Down>', '<nop>')
keymap.set('', '<Left>', '<nop>')
keymap.set('', '<Right>', '<nop>')

-- Plugins
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
require("lazy").setup({
  { "ellisonleao/gruvbox.nvim", priority = 1000, config = true, opts = ...}
})

vim.cmd([[colorscheme gruvbox]])
