-- Vim filetype plugin file
-- Language: MoonBit
-- Maintainer: Tony Fettes (https://github.com/tonyfettes/moonbit.nvim)
-- Last Change: 2023 Dec 9

if vim.b.did_ftplugin == 1 then
  return
end
vim.b.did_ftplugin = 1

local opt = vim.opt_local
opt.formatoptions:remove("t")
opt.formatoptions:append("ro")
opt.comments = ":///,://"
opt.commentstring = "//%s"

local undo = { "setlocal formatoptions< comments< commentstring<" }

if vim.treesitter and vim.treesitter.start then
  vim.treesitter.start()
  if vim.treesitter.stop then
    table.insert(undo, "lua vim.treesitter.stop()")
  end
end

vim.b.undo_ftplugin = table.concat(undo, " | ")
