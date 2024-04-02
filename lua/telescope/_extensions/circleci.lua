local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local state = require("telescope.state")
local conf = require("telescope.config").values
local previewers = require("telescope.previewers")
local action_set = require "telescope.actions.set"
local action_state = require "telescope.actions.state"

local auth = require'nvim-circleci.auth'
local utils = require'nvim-circleci.utils'
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

local createPreview = function(bufnr, entry)
  vim.defer_fn(function()
    local workflow = auth.getWorkflowById(entry.id)
    for k,v in ipairs(workflow) do
      vim.api.nvim_buf_set_lines(bufnr, 0, k+1, false, {string.format(
        '%s, %s', v["name"], v["status"]
      )})
      auth.run(auth.getWorkflowJobs, v['id'], function(workflowJobs)
          for jobsKey, jobsValue in ipairs(workflowJobs) do
            vim.api.nvim_buf_set_lines(bufnr, k+jobsKey-1, k+jobsKey, false, {string.format(
              '    %s, %s, %s, %s', jobsValue["name"], jobsValue["status"], jobsValue['job_number'], jobsValue['started_at']
            )})
          end
      end)
    end
  end, 0)
end

local get_pipelines = function(opts, mineOrAll)
  opts = opts or {}
  local pipelines = mineOrAll == "mine" and auth.getMyPipelineIds() or auth.getAllPipelineIds()
  local widths = {
    branch = 20,
    user = 16,
    updated_at = 16,
    number = 6,
  }
  local displayer = require("telescope.pickers.entry_display").create {
        separator = " ",
        items = {
            { width = widths.number },
            { width = mineOrAll == "all" and widths.branch or widths.branch + widths.user },
            { width = mineOrAll == "all" and widths.user or 0 },
            { remaining = true },
        },
    }
  local make_display = function(entry)
    -- local workflow = auth.getWorkflowById(entry.id)
    return displayer {
      { tostring(entry.number), "TelescopeResultsNumber" },
      { entry.branch, remaining = true },
      { mineOrAll == "all" and entry.user or "" },
      { utils.prettyDateTime(entry.updated_at), "Comment" }
    }
  end
  pickers.new(opts or {}, {
    prompt_title = "CircleCI pipelines",
    finder = finders.new_table {
      results = pipelines,
      entry_maker = function(entry)
          entry.value = entry.branch
          entry.ordinal = tostring(entry.number)
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
        local bufnr = self.state.bufnr
        if vim.api.nvim_buf_is_valid(bufnr) then
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
        end
        createPreview(bufnr, entry)
      end,
    }

  }):find()
end

local get_workflows_for_branch = function(opts, branch)
  local workflows = {}
  vim.defer_fn(function()
    workflows = auth.getWorkflowForBranch(branch)
  end)
  local widths = {
    workflow = 36,
    number = 6,
  }
  local displayer = require("telescope.pickers.entry_display").create {
        separator = " ",
        items = {
            { width = widths.number },
            { remaining = true },
        },
    }
  local make_display = function(entry)
    -- local workflow = auth.getWorkflowById(entry.id)
    return displayer {
      { tostring(entry.number), "TelescopeResultsNumber" },
      { entry.name, remaining = true },
    }
  end
  pickers.new(opts or {}, {
    prompt_title = "Workflows",
    finder = finders.new_table {
      results = workflows,
      entry_maker = function(entry)
          entry.value = entry.name
          entry.ordinal = tostring(entry.number)
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
      end
  })
end

return require("telescope").register_extension({
  exports = {
      get_my_pipelines = function(opts)
        get_pipelines(opts, "mine")
      end,
      get_all_pipelines = function(opts)
        get_pipelines(opts, "all")
      end,
      get_workflows_for_branch = function(opts)
        get_workflows_for_branch(opts, "bouncing-icon")
      end
      -- get_workflows_for_current_branch
      -- get_master_workflows
      -- get_workflows_for_branch
  }
})
