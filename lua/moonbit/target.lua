return {
  setup_moonbit_target = function()
    vim.api.nvim_create_user_command('MoonBitTarget', function(opts)
      local target = opts.args
      local valid  = { native = true, js = true, wasm = true, ['wasm-gc'] = true, llvm = true }
      if not valid[target] then
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

              vim.notify(("moonbit target switched to %s"):format(target),
                vim.log.levels.INFO)
            else
              vim.notify(("moon check failed (exit code %d)"):format(exit_code),
                vim.log.levels.ERROR)
            end
          end)
        end,
      })
    end, {
      nargs    = 1,
      desc     = 'MoonBitTarget: switch moonbit target (native/llvm/js/wasm/wasm-gc) and restart LSP',
      complete = function(lead)
        return vim.tbl_filter(function(t) return vim.startswith(t, lead) end,
          { 'native', 'js', 'wasm', 'llvm', 'wasm-gc' })
      end,
    })
  end
}
