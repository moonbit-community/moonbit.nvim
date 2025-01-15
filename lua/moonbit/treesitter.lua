local install_infos = {
  ['moonbit'] = {
    url = 'https://github.com/moonbitlang/tree-sitter-moonbit',
    revision = '05bb5dbbe9b3b80c74113b791883fa2b85f0e14e',
    files = { 'src/parser.c', 'src/scanner.c' },
    branch = 'main',
  },
}

local function get_installed_revision(utils, configs, lang)
  local lang_file = utils.join_path(configs.get_parser_info_dir(), lang .. ".revision")
  if vim.fn.filereadable(lang_file) == 1 then
    return vim.fn.readfile(lang_file)[1]
  end
end

local function needs_update(utils, configs, lang)
  local installed_revision = get_installed_revision(utils, configs, lang)
  if not installed_revision then
    return true
  end
  local info = install_infos[lang]
  return installed_revision ~= info.revision
end

return {
  setup = function(opts)
    local auto_install = opts.auto_install or true
    local has_treesitter, parsers = pcall(require, 'nvim-treesitter.parsers')
    if not has_treesitter then return end
    local utils = require "nvim-treesitter.utils"
    local configs = require "nvim-treesitter.configs"
    local install = require "nvim-treesitter.install"
    local update = install.update {}

    for filetype, install_info in pairs(install_infos) do
      local o = opts[filetype] or {}
      local enabled = o.enabled or true
      if enabled then
        o.install_info = o.install_info or install_info
        o.filetype = o.filetype or filetype
        parsers.get_parser_configs()[filetype] = o
        if auto_install then
          if not parsers.has_parser(filetype) or needs_update(utils, configs, filetype) then
            update(filetype)
          end
        end
      end
    end
  end
}
