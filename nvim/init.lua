local opt = vim.opt

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
opt.listchars = { tab = '»-', trail = '·', eol = '¬', extends = '»', precedes = '«', nbsp = '%'}

-- Keymap
vim.keymap.set('i', 'jj', '<ESC>', { noremap = true, silent = true})
