local install_infos = {
  ['moonbit'] = {
    url = 'https://github.com/moonbitlang/tree-sitter-moonbit',
    revision = 'de40c86923fc456419085a70e1dc8aa92d20a3a1',
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
    local uninstall = install.uninstall

    for filetype, install_info in pairs(install_infos) do
      parsers.get_parser_configs()[filetype] = {
        filetype = filetype,
        install_info = install_info,
      }
      if auto_install then
        if not parsers.has_parser(filetype) or needs_update(utils, configs, filetype) then
          uninstall(filetype)
          update(filetype)
        end
      end
    end
  end,

}
