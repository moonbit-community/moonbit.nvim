local virt = require("moonbit.mooncakes.virtualtext")
local act  = require("moonbit.mooncakes.actions")

local function setup_ui(enable_ui)
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern  = { "moon.mod.json", "moon.pkg" },
    group    = vim.api.nvim_create_augroup("Mooncakes", { clear = false }),
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      act.attach(buf)
      local filename = vim.fs.basename(vim.api.nvim_buf_get_name(buf))
      if enable_ui and filename == "moon.mod.json" then
        virt.attach(buf)
      end
    end,
    desc     = "mooncakes: UI attach",
  })
end


local M   = {}
local cfg = {
  virtual_text = true,
  use_local = true,
}

function M.setup(opts)
  cfg = vim.tbl_deep_extend("force", cfg, opts or {})
  require('moonbit.mooncakes.api').setup({ use_local = cfg.use_local })
  setup_ui(cfg.virtual_text)
end

return M
