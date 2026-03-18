local valid_targets = { 'native', 'js', 'wasm', 'llvm', 'wasm-gc' }
local valid_set = { native = true, js = true, wasm = true, ['wasm-gc'] = true, llvm = true }
local current_target = nil

local function set_target(target)
  if not valid_set[target] then
    vim.notify(("Invalid MoonBit target: %q (native/llvm/js/wasm/wasm-gc)"):format(target),
      vim.log.levels.ERROR)
    return
  end

  local curr_win = vim.api.nvim_get_current_win()
  local curr_buf = vim.api.nvim_get_current_buf()

  vim.fn.jobstart({ 'moon', 'check', '--target', target }, {
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code == 0 then
          current_target = target

          for _, client in ipairs(vim.lsp.get_clients()) do
            if client.name:match('moonbit') then
              client.stop()
            end
          end

          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf)
                and vim.bo[buf].buflisted then
              vim.api.nvim_buf_call(buf, function()
                vim.cmd('silent! edit')
              end)
            end
          end

          if vim.api.nvim_win_is_valid(curr_win) then
            vim.api.nvim_set_current_win(curr_win)
          end
          if vim.api.nvim_buf_is_valid(curr_buf) then
            vim.api.nvim_set_current_buf(curr_buf)
          end

          vim.notify(("moonbit target set to %s"):format(target),
            vim.log.levels.INFO)
        else
          vim.notify(("moon check failed (exit code %d)"):format(exit_code),
            vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

local function complete_targets(lead)
  return vim.tbl_filter(function(t) return vim.startswith(t, lead) end, valid_targets)
end

return {
  setup_moonbit_target = function()
    -- MoonbitTarget: show current target
    vim.api.nvim_create_user_command('MoonbitTarget', function()
      if current_target then
        vim.notify(("Current moonbit target: %s"):format(current_target), vim.log.levels.INFO)
      else
        vim.notify("No moonbit target has been set in this session", vim.log.levels.INFO)
      end
    end, {
      nargs = 0,
      desc = 'Show current moonbit target',
    })

    -- MoonbitSetTarget: set target (with vim.ui.select picker if no args)
    vim.api.nvim_create_user_command('MoonbitSetTarget', function(opts)
      if opts.args == '' then
        vim.ui.select(valid_targets, { prompt = 'Select MoonBit target:' }, function(choice)
          if choice then
            set_target(choice)
          end
        end)
      else
        set_target(opts.args)
      end
    end, {
      nargs = '?',
      desc = 'Set moonbit target (native/llvm/js/wasm/wasm-gc) and restart LSP',
      complete = function(lead)
        return complete_targets(lead)
      end,
    })

    -- Deprecated alias
    vim.api.nvim_create_user_command('MoonBitTarget', function(opts)
      vim.notify('MoonBitTarget is deprecated, use MoonbitSetTarget instead', vim.log.levels.WARN)
      set_target(opts.args)
    end, {
      nargs = 1,
      desc = '[Deprecated] use MoonbitSetTarget instead',
      complete = function(lead)
        return complete_targets(lead)
      end,
    })
  end
}
