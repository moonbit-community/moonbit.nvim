local M = {}

function M.open_url(url)
  local cmd
  if vim.fn.has("macunix") == 1 then
    cmd = { "open", url }
  elseif vim.fn.has("win32") == 1 then
    cmd = { "cmd.exe", "/C", "start", "", url }
  else
    cmd = { "xdg-open", url }
  end
  vim.fn.jobstart(cmd, { detach = true })
end

return M
