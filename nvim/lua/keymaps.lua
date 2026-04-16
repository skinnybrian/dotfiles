vim.g.mapleader = " "

local set = vim.keymap.set

-- Escape insert mode
set('i', 'jj', '<ESC>', { noremap = true, silent = true })

-- Disable arrow keys
set('', '<Up>', '<nop>')
set('', '<Down>', '<nop>')
set('', '<Left>', '<nop>')
set('', '<Right>', '<nop>')
