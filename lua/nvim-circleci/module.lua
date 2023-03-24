local auth = require'nvim-circleci.auth'
local Job = require'plenary.job'
-- module represents a lua module for the plugin
local M = {}
local api = vim.api
local buf, win

local function center(str)
  local width = api.nvim_win_get_width(0)
  local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
  return string.rep(' ', shift) .. str
end

local function open_window()
  buf = api.nvim_create_buf(false, true)
  local border_buf = api.nvim_create_buf(false, true)

  api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  api.nvim_buf_set_option(buf, 'filetype', 'whid')

  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")

  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  local border_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width + 2,
    height = win_height + 2,
    row = row - 1,
    col = col - 1
  }

  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col
  }

  local border_lines = { '╔' .. string.rep('═', win_width) .. '╗' }
  local middle_line = '║' .. string.rep(' ', win_width) .. '║'
  for i=1, win_height do
    table.insert(border_lines, middle_line)
  end
  table.insert(border_lines, '╚' .. string.rep('═', win_width) .. '╝')
  api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

  local border_win = api.nvim_open_win(border_buf, true, border_opts)
  win = api.nvim_open_win(buf, true, opts)
  api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "'..border_buf)

  api.nvim_win_set_option(win, 'cursorline', true) -- it highlight line with the cursor on it

  -- we can add title already here, because first line will never change
  api.nvim_buf_set_lines(buf, 0, -1, false, { center('Pipelines'), '', ''})
  api.nvim_buf_add_highlight(buf, -1, 'WhidHeader', 0, 0, -1)
end

local function update_view(direction)
  api.nvim_buf_set_option(buf, 'modifiable', true)
  position = position + direction
  if position < 0 then position = 0 end

  --local branch = vim.fn.system('git rev-parse --abbrev-ref HEAD')
  local result = auth.getMyPipelineIds()
  if #result == 0 then table.insert(result, {}) end -- add  an empty line to preserve layout if there is no results

  for k,v in ipairs(result) do
    api.nvim_buf_set_lines(buf, k, -1, false, {string.format(
      "Branch: %s, Pipeline Number: %s, ID: %s", v["branch"], v["number"], v["id"]
    )})
  end

  api.nvim_buf_set_option(buf, 'modifiable', false)
end

local function close_window()
  api.nvim_win_close(win, true)
end

function mysplit (inputstr, sep)
  if sep == nil then
          sep = "%s"
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
          table.insert(t, str)
  end
  return t
end

local function get_workflow()
  local line = api.nvim_get_current_line()
  local r,c = unpack(vim.api.nvim_win_get_cursor(0))
  local str = mysplit(line, ', ')
  local id = str[7]
  local workflow = auth.getWorkflowById(id)
  local ns = api.nvim_create_namespace('circleci')
  api.nvim_buf_set_option(buf, 'modifiable', true)
  for k,v in ipairs(workflow) do
    api.nvim_buf_set_lines(buf, r-1+k, r-1+k, false, {string.format(
      '  Workflow %s, Status: %s, Started at: %s, ID: %s', v["name"], v["status"], v["created_at"], v["id"]
    )})
    local workflowJobs = auth.getWorkflowJobs(v['id'])
    --local sortedJobs = table.sort(workflowJobs, function (a, b) return os.difftime(a.started_at, b.started_at) end)
    for jobsKey, jobsValue in ipairs(workflowJobs) do
      api.nvim_buf_set_lines(buf, r+jobsKey, r+jobsKey, false, {string.format(
        '    %s, Status: %s, Number: %s, Started at: %s', jobsValue["name"], jobsValue["status"], jobsValue['job_number'], jobsValue['started_at']
      )})
      vim.keymap.set('n', 'O', function ()
        auth.openJobUrl(jobsValue["job_number"])
      end, {
        nowait = true, noremap = true, silent = true, buffer = buf
      })
      --api.nvim_buf_set_extmark(buf, ns, r+jobsKey, c, {end_row = r+jobsKey, virt_text = {{jobsValue["status"]}}})
    end
  end
  api.nvim_buf_set_option(buf, 'modifiable',false)
end

local function move_cursor()
  local new_pos = math.max(2, api.nvim_win_get_cursor(win)[1] - 1)
  api.nvim_win_set_cursor(win, {new_pos, 0})
end

local function set_mappings()
  local mappings = {
    ['<cr>'] = get_workflow,
    q = close_window,
    k = move_cursor,
  }

  for k,v in pairs(mappings) do
    vim.keymap.set('n', k, v, {
      nowait = true, noremap = true, silent = true, buffer = buf
    })
  end
  local other_chars = {
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'i', 'n', 'p', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
  }
  for k,v in ipairs(other_chars) do
    api.nvim_buf_set_keymap(buf, 'n', v, '', { nowait = true, noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, 'n', v:upper(), '', { nowait = true, noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, 'n',  '<c-'..v..'>', '', { nowait = true, noremap = true, silent = true })
  end
end

local function setup()
  position = 0
  open_window()
  set_mappings()
  update_view(0)
  api.nvim_win_set_cursor(win, {2, 0})
end

local function my_first_function()
  setup()
end

return {
  my_first_function = my_first_function,
}
