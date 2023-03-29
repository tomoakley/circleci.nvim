local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local conf = require("telescope.config").values
local utils = require("telescope.utils")
local previewers = require("telescope.previewers")

local auth = require'nvim-circleci.auth'
--local previewers = require 'nvim-circleci.telescope.previewers'

local get_pipelines = function(opts)
  opts = opts or {}
  local pipelines = auth.getMyPipelineIds()
  local widths = {
    branch = 50,
    updated_at = 16,
    number = 10,
  }
  local displayer = require("telescope.pickers.entry_display").create {
        separator = " ",
        items = {
            { width = widths.branch },
            { width = widths.number },
        },
    }
  local make_display = function(entry)
    -- local workflow = auth.getWorkflowById(entry.id)
    return displayer {
      { entry.branch },
      { tostring(entry.number) },
    }
  end
  pickers.new(opts or {}, {
    prompt_title = "CircleCI pipelines",
    finder = finders.new_table {
      results = pipelines,
      entry_maker = function(entry)
          entry.value = entry.branch
          entry.ordinal = entry.branch
          entry.display = make_display
          return entry
      end,
    },
    sorter = conf.generic_sorter(opts),
    -- previewer = conf.file_previewer(opts),
    previewer = previewers.new_buffer_previewer{
      title = 'Workflow Preview',
      get_buffer_by_name = function(_, entry)
        return entry.value
      end,
      define_preview = function(self, entry)
        local workflow = auth.getWorkflowById(entry.id)
        local bufnr = self.state.bufnr
        if vim.api.nvim_buf_is_valid(bufnr) then
          for k,v in ipairs(workflow) do
            vim.api.nvim_buf_set_lines(bufnr, 0, k, false, {string.format(
              '%s, %s', v["name"], v["status"]
            )})
            local workflowJobs = auth.getWorkflowJobs(v['id'])
            for jobsKey, jobsValue in ipairs(workflowJobs) do
              vim.api.nvim_buf_set_lines(bufnr, k+jobsKey-1, k+jobsKey, false, {string.format(
                '    %s, %s, %s, %s', jobsValue["name"], jobsValue["status"], jobsValue['job_number'], jobsValue['started_at']
              )})
            end
          end
          vim.api.nvim_buf_set_option(bufnr, "filetype", "circleci")
        end
      end,
    }

  }):find()
end

return require("telescope").register_extension({
  exports = {
      get_pipelines = get_pipelines
  }
})
