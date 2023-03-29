local previewers = require("telescope.previewers")
local ts_utils = require "telescope.utils"
local defaulter = ts_utils.make_default_callable

local workflow = defaulter(function(opts)
  return previewers.new_buffer_previewer{
    title = 'workflow preview',
    get_buffer_by_name = function(_, entry)
      return entry.value
    end,
    define_preview = function(self, entry)
      print(entry)
      local bufnr = self.state.bufnr
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_add_highlight(bufnr, -1, "OctoIssueTitle", 0, 0, -1)
        vim.api.nvim_buf_set_option(bufnr, "filetype", "circleci")
      end
    end,
  }
end)

return {
  workflow = workflow
}
