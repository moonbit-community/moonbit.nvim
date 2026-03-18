local root = vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ':p:h:h')
local deps = root .. '/.deps'

vim.opt.rtp:append(root)
vim.opt.rtp:append(deps .. '/plenary.nvim')
vim.opt.swapfile = false

vim.cmd('runtime! plugin/plenary.vim')
