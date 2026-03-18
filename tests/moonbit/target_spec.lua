local target = require('moonbit.target')

describe('target', function()
  before_each(function()
    -- Re-register commands for each test
    -- (setup_moonbit_target overwrites existing commands)
    target.setup_moonbit_target()
  end)

  describe('MoonbitTarget', function()
    it('is registered', function()
      local ok = pcall(vim.api.nvim_parse_cmd, 'MoonbitTarget', {})
      assert.is_true(ok)
    end)
  end)

  describe('MoonbitSetTarget', function()
    it('is registered', function()
      local ok = pcall(vim.api.nvim_parse_cmd, 'MoonbitSetTarget', {})
      assert.is_true(ok)
    end)

    it('rejects invalid target', function()
      local notified = nil
      local orig_notify = vim.notify
      vim.notify = function(msg, level)
        notified = { msg = msg, level = level }
      end

      vim.cmd('MoonbitSetTarget invalid')

      assert.is_not_nil(notified)
      assert.are.equal(vim.log.levels.ERROR, notified.level)
      assert.is_truthy(notified.msg:match('Invalid'))

      vim.notify = orig_notify
    end)

    it('opens vim.ui.select when called with no args', function()
      local select_called = false
      local orig_select = vim.ui.select
      vim.ui.select = function(items, opts, on_choice)
        select_called = true
        assert.are.same({ 'native', 'js', 'wasm', 'llvm', 'wasm-gc' }, items)
        -- Don't actually pick anything
      end

      vim.cmd('MoonbitSetTarget')
      assert.is_true(select_called)

      vim.ui.select = orig_select
    end)
  end)

  describe('MoonBitTarget (deprecated)', function()
    it('is registered', function()
      local ok = pcall(vim.api.nvim_parse_cmd, 'MoonBitTarget native', {})
      assert.is_true(ok)
    end)

    it('shows deprecation warning', function()
      local notified = nil
      local orig_notify = vim.notify
      local orig_jobstart = vim.fn.jobstart
      vim.notify = function(msg, level)
        if level == vim.log.levels.WARN then
          notified = { msg = msg, level = level }
        end
      end
      -- Stub jobstart to avoid actually running moon check
      vim.fn.jobstart = function() return 0 end

      vim.cmd('MoonBitTarget native')

      assert.is_not_nil(notified)
      assert.is_truthy(notified.msg:match('deprecated'))
      assert.is_truthy(notified.msg:match('MoonbitSetTarget'))

      vim.notify = orig_notify
      vim.fn.jobstart = orig_jobstart
    end)
  end)
end)
