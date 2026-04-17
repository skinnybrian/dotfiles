local opt = vim.opt

-- Encoding
vim.scriptencoding = 'utf-8'
opt.encoding = 'utf-8'
opt.fileencodings = 'utf-8'

-- Language
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
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true
opt.background = 'dark'
opt.fixeol = false
