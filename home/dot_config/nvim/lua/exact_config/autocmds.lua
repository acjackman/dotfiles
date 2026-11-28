-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
--
vim.api.nvim_create_autocmd("InsertEnter", {
  pattern = "*.md",
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = "*.md",
  callback = function()
    vim.opt_local.conceallevel = 2
  end,
})

-- Disable autoformat for lua files
-- vim.api.nvim_create_autocmd({ "FileType" }, {
--   -- pattern = { "lua" },
--   pattern = {},
--   callback = function()
--     vim.b.autoformat = false
--   end,
-- })

-- Reload buffers changed outside nvim (agents, git, etc.)
-- LazyVim already runs checktime on FocusGained/TermClose/TermLeave; add idle + buffer switch,
-- plus an event-driven fs watcher (kqueue on macOS) per file buffer.
vim.o.autoread = true

vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = vim.api.nvim_create_augroup("user_checktime", { clear = true }),
  callback = function()
    if vim.fn.mode() ~= "c" and vim.fn.getcmdwintype() == "" then
      vim.cmd("checktime")
    end
  end,
})

local watchers = {}

local function unwatch(buf)
  local w = watchers[buf]
  if w then
    w:stop()
    if not w:is_closing() then
      w:close()
    end
    watchers[buf] = nil
  end
end

local function watch(buf)
  unwatch(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
    return
  end
  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" or not vim.uv.fs_stat(path) then
    return
  end
  local w = vim.uv.new_fs_event()
  if not w then
    return
  end
  watchers[buf] = w
  w:start(
    path,
    {},
    vim.schedule_wrap(function(err, _, events)
      if err or not vim.api.nvim_buf_is_valid(buf) then
        return unwatch(buf)
      end
      vim.cmd("checktime " .. buf)
      -- atomic saves (write temp + rename) orphan the kqueue watch; re-arm on the new file
      if events.rename then
        watch(buf)
      end
    end)
  )
end

local watch_group = vim.api.nvim_create_augroup("user_fs_watch", { clear = true })
vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "BufFilePost" }, {
  group = watch_group,
  callback = function(a)
    watch(a.buf)
  end,
})
vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
  group = watch_group,
  callback = function(a)
    unwatch(a.buf)
  end,
})

-- this file loads on VeryLazy, after buffers from the command line were already read
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_is_loaded(buf) then
    watch(buf)
  end
end
