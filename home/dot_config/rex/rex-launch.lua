-- rex-launch: a composer popup that creates a git worktree and starts an
-- agent in it. https://github.com/nicosuave/rex-launch
--
-- `rex-launch setup` copies this file beside your Rex init.lua and adds:
--
--   require("rex-launch").setup{ bin = "/path/to/rex-launch" }
--
-- Options:
--   bin      the rex-launch executable. Rex runs it without your interactive
--            shell's PATH, so an absolute path is safest.
--   key      the shortcut, "cmd+shift+n" by default; false for none. The
--            command palette lists it as "rex-launch: new task" either way.
--   columns  the popup's size in cells, title bar included (108 by 17).
--   rows

local M = {}

local TERMINAL = "com.superlogical.terminal"

local defaults = {
  bin = "rex-launch",
  key = "cmd+shift+n",
  columns = 108,
  rows = 17,
}

local function find_rect(node, block_id)
  if type(node) ~= "table" then return nil end
  if node.block_id == block_id and node.rect then return node.rect end
  for _, child in pairs(node) do
    local rect = find_rect(child, block_id)
    if rect then return rect end
  end
end

-- Layer bounds are fractions of the window, so the window's size in cells is
-- worked out from the focused pane's size and its share of the window.
local function popup_bounds(ctx, opts)
  local fallback = { 0.15, 0.2, 0.7, 0.6 }
  if ctx.block_id == nil then return fallback end
  local view = rex.session.view{}
  local rect = view and find_rect(view.windows, ctx.block_id)
  local size = rect and rex.block.call(TERMINAL, "size", { block_id = ctx.block_id })
  if size == nil then return fallback end
  local window_columns = size.columns / rect[3]
  local window_rows = size.rows / rect[4]
  local w = math.min(opts.columns, window_columns - 8) / window_columns
  local h = math.min(opts.rows, window_rows - 4) / window_rows
  return { (1 - w) / 2, (1 - h) * 0.4, w, h }
end

function M.setup(options)
  local opts = {}
  for name, value in pairs(defaults) do opts[name] = value end
  for name, value in pairs(options or {}) do opts[name] = value end

  rex.action{
    name        = "new_task",
    title       = "rex-launch: new task",
    description = "Write a prompt, pick a project, and start an agent in a new worktree",
    category    = "rex-launch",
    keywords    = "rex-launch new task worktree agent prompt launch claude codex",
    run         = function(ctx, args)
      -- No window_id: a layer created with one was placed but not drawn by
      -- the Rex app, while one in the active window was.
      local _, err = rex.session.new_layer{
        bounds = popup_bounds(ctx, opts),
        focus  = true,
        layout = {
          block = {
            flavor  = TERMINAL .. ".shell",
            label   = "new task",
            options = {
              command = { opts.bin, "--client", ctx.client_id or "" },
              cwd     = os.getenv("HOME"),
            },
          },
        },
      }
      if err ~= nil then error(err, 0) end
    end,
  }

  if opts.key then rex.bind(opts.key, "new_task") end
end

return M
