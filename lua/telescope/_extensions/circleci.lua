local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local state = require("telescope.state")
local conf = require("telescope.config").values
local utils = require("telescope.utils")
local previewers = require("telescope.previewers")
local action_set = require "telescope.actions.set"
local action_state = require "telescope.actions.state"

local auth = require'nvim-circleci.auth'
--local previewers = require 'nvim-circleci.telescope.previewers'

local function open_preview_buffer(command)
  return function(prompt_bufnr)
    actions.close(prompt_bufnr)
    local preview_bufnr = require("telescope.state").get_global_key "last_preview_bufnr"
    if command == "default" then
      vim.cmd(string.format(":buffer %d", preview_bufnr))
    elseif command == "horizontal" then
      vim.cmd(string.format(":sbuffer %d", preview_bufnr))
    elseif command == "vertical" then
      vim.cmd(string.format(":vert sbuffer %d", preview_bufnr))
    elseif command == "tab" then
      vim.cmd(string.format(":tab sb %d", preview_bufnr))
    end

    vim.cmd [[stopinsert]]
  end
end

local open_branch_workflows_in_browser = function()
    local entry = action_state.get_selected_entry()
    print(vim.inspect(entry))
end

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
      attach_mappings = function(_, map)
        --action_set.select:replace(open_branch_workflows_in_browser)
        action_set.select:replace(function(prompt_bufnr, type)
          open_preview_buffer(type)(prompt_bufnr)
        end)
        map("i", "<c-b>", open_branch_workflows_in_browser)
        return true
      end,
    previewer = previewers.new_buffer_previewer{
      title = 'Workflow Preview',
      keep_last_buf = true,
      get_buffer_by_name = function(_, entry)
        return entry.value
      end,
      define_preview = function(self, entry)
        local workflow = auth.getWorkflowById(entry.id)
        local bufnr = self.state.bufnr
        if vim.api.nvim_buf_is_valid(bufnr) then
          for k,v in ipairs(workflow) do
            vim.api.nvim_buf_set_lines(bufnr, 0, k+1, false, {string.format(
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
