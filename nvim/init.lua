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
opt.clipboard = 'unnamed'
opt.list = true
opt.listchars = {tab = '»-', trail = '·', eol = '¬', extends = '»', precedes = '«', nbsp = '%'}
opt.tabstop = 4
opt.expandtab = true
opt.autoindent = true
opt.shiftwidth = 4

-- Keymap
keymap.set('i', 'jj', '<ESC>', { noremap = true, silent = true})
