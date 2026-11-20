-- Rex config. Migrated from tmux (~/.config/tmux/tmux.reset.conf) and Herdr
-- (~/.config/herdr/config.toml) by Rex's migration prompt, 2026-11-18.
-- Prefix is ctrl+space, as in tmux and Herdr. Where both bound the same key to
-- the same action, the line is attributed to Herdr.

-- Prefix passthrough (tmux.reset.conf:13)
rex.bind("ctrl+space>ctrl+space", "pane.send_key", { key = "ctrl+space" })

-- Move (ctrl+hjkl) and resize (ctrl+alt+hjkl) across Neovim splits and Rex
-- panes. The Neovim half is smart-splits.nvim + rawnly/smart-splits-backend-rex
-- (nvim/lua/exact_plugins/windows.lua): when Neovim is in front the key goes
-- to it, and it hands off to Rex at its edge. Not alt+hjkl: AeroSpace owns it.
-- In other panes these keys no longer reach the program (same as under herdr).
local function is_vim(block_id)
  local proc = rex.block.call("com.superlogical.terminal", "process", { block_id = block_id })
  local fg = proc and proc.foreground
  if not fg then
    return false
  end
  -- `name` can be a version string (e.g. claude's), so check argv0 too
  for _, s in ipairs({ fg.name or "", (fg.argv0 or ""):match("[^/]*$") }) do
    if s:match("^n?vim") then
      return true
    end
  end
  return false
end

-- rex.client.queue only works inside actions, so resize is an action that
-- forwards the key itself when Neovim is in front.
rex.action({
  name = "smart_splits_resize",
  title = "Smart Splits: Resize Pane",
  run = function(ctx, args)
    if is_vim(ctx.block_id) then
      rex.client.queue("pane.send_key", { key = args.key })
    else
      rex.client.queue("pane.resize", { direction = args.direction, amount = 3 })
    end
  end,
})

for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  rex.bind("ctrl+" .. key, function(ctx)
    if is_vim(ctx.block_id) then
      return false -- fall through to Neovim
    end
    rex.session.focus_direction({ direction = direction, wrap = true })
    return true
  end)
  rex.bind("ctrl+alt+" .. key, "smart_splits_resize", { key = "ctrl+alt+" .. key, direction = direction })
end

-- Panes
rex.bind("ctrl+space>x", "pane.close")                                   -- tmux.reset.conf:19
rex.bind("ctrl+space>shift+\\", "pane.split", { direction = "right" })   -- herdr config.toml:38
rex.bind("ctrl+space>-", "pane.split", { direction = "down" })           -- herdr config.toml:39
rex.bind("ctrl+space>ctrl+left", "pane.focus", { direction = "left" })   -- tmux.reset.conf:38
rex.bind("ctrl+space>ctrl+down", "pane.focus", { direction = "down" })   -- tmux.reset.conf:39
rex.bind("ctrl+space>ctrl+up", "pane.focus", { direction = "up" })       -- tmux.reset.conf:40
rex.bind("ctrl+space>ctrl+right", "pane.focus", { direction = "right" }) -- tmux.reset.conf:41
rex.bind("ctrl+space>z", "pane.zoom")                                    -- tmux.reset.conf:43
rex.bind("ctrl+space>shift+[", "pane.move", { direction = "up" })        -- tmux.reset.conf:50
rex.bind("ctrl+space>shift+]", "pane.move", { direction = "down" })      -- tmux.reset.conf:51

-- Tabs
rex.bind("ctrl+space>shift+x", "client.tab.close")  -- tmux.reset.conf:20
rex.bind("ctrl+space>n", "client.tab.new")          -- herdr config.toml:43
rex.bind("ctrl+space>shift+n", "client.tab.new")    -- tmux.reset.conf:59
rex.bind("ctrl+space>w", "client.tab.close")        -- herdr config.toml:44
rex.bind("ctrl+space>r", "client.tab.rename")       -- herdr config.toml:45
rex.bind("ctrl+space>1", "client.tab.goto", { index = 1 })   -- tmux.reset.conf:67
rex.bind("ctrl+space>2", "client.tab.goto", { index = 2 })   -- tmux.reset.conf:68
rex.bind("ctrl+space>3", "client.tab.goto", { index = 3 })   -- tmux.reset.conf:69
rex.bind("ctrl+space>4", "client.tab.goto", { index = 4 })   -- tmux.reset.conf:70
rex.bind("ctrl+space>5", "client.tab.goto", { index = 5 })   -- tmux.reset.conf:71
rex.bind("ctrl+space>6", "client.tab.goto", { index = 6 })   -- tmux.reset.conf:72
rex.bind("ctrl+space>7", "client.tab.goto", { index = 7 })   -- tmux.reset.conf:73
rex.bind("ctrl+space>8", "client.tab.goto", { index = 8 })   -- tmux.reset.conf:74
rex.bind("ctrl+space>9", "client.tab.goto", { index = 9 })   -- tmux.reset.conf:75
rex.bind("ctrl+space>0", "client.tab.goto", { index = 10 })  -- tmux.reset.conf:76

-- Move panes and tabs (herdr: drovr + break-pane commands, same keys)
rex.bind("ctrl+space>m", "pane.move_to_tab")                  -- pick a tab to move this pane to
rex.bind("ctrl+space>shift+m", "client.tab.move_to_new_window") -- herdr: tab to another workspace
rex.bind("ctrl+space>t", "pane.move_to_new_tab")              -- break pane into a new tab
rex.bind("ctrl+space>shift+t", "client.tab.move_to_new_window") -- break tab out into its own window

-- navi cheatsheet (tmux/herdr prefix+.): a floating pane runs ,rex-navi, which
-- types the picked snippet into the pane it was opened over.
rex.action({
  name = "navi",
  title = "navi: Cheatsheet",
  run = function(ctx)
    rex.session.new_layer({
      session_id = ctx.session_id,
      bounds = { 0.05, 0.05, 0.9, 0.9 },
      focus = true,
      layout = {
        block = {
          flavor = "com.superlogical.terminal.shell",
          label = "navi",
          options = { command = { os.getenv("HOME") .. "/.local/bin/,rex-navi", ctx.session_id, ctx.block_id } },
        },
      },
    })
  end,
})
rex.bind("ctrl+space>.", "navi")

-- Pickers (trial, 2026-11-19). Written by hand from what `raptor init` and
-- `rex-launch setup` would add: both installers edit this file in place, so
-- don't run them. After `brew upgrade rex-launch`, diff rex-launch.lua against
-- the one `HOME=$(mktemp -d) rex-launch setup` writes.
--   Raptor (alienxp03/raptor): sessions, projects, worktrunk worktrees, PRs.
--   Its agent is off (~/.config/raptor/config.toml), so its instant-agent
--   action (cmd+opt+n, starts pi) is left unbound; rex-launch has that key.
dofile("/opt/homebrew/opt/raptor/share/raptor/init.lua").setup{}
rex.bind("shift+cmd+o", "raptor")
rex.bind("ctrl+cmd+c", "raptor_pr_open") -- Raptor's default is shift+cmd+c: Rex's copy mode
rex.bind("ctrl+cmd+n", "raptor_worktree_new") -- Raptor's shift+cmd+n is Rex's new window here
for i = 1, 9 do
  rex.bind("ctrl+cmd+" .. i, "raptor_pin_" .. i)
end
--   rex-launch (nicosuave/rex-launch): prompt + project -> worktree + agent tab.
require("rex-launch").setup{ bin = "/opt/homebrew/bin/rex-launch", key = false }
-- Not its default shift+cmd+n: Settings > Keyboard (Shortcuts/shortcuts.json,
-- which beats init.lua) has that as new window and cmd+n as new session.
rex.bind("alt+cmd+n", "new_task")

-- Sessions
rex.bind("ctrl+space>shift+'", "session.switch")    -- tmux.reset.conf:81
rex.bind("ctrl+space>shift+r", "session.rename")    -- herdr config.toml:57

-- Config
rex.bind("ctrl+space>shift+c", "client.config.reload")  -- herdr config.toml:65

-- Resize: tmux `bind -r` — tmux.reset.conf:45-48. Single press only: the
-- migration's repeat mode was entered with ctrl+space>alt+r, which AeroSpace
-- grabs globally (workspace R), so it was dropped.
rex.bind("ctrl+space>j", "pane.resize", { amount = 5, direction = "down" })
rex.bind("ctrl+space>k", "pane.resize", { amount = 5, direction = "up" })
rex.bind("ctrl+space>l", "pane.resize", { amount = 5, direction = "right" })
rex.bind("ctrl+space>h", "pane.resize", { amount = 5, direction = "left" })

-- Resize: Herdr resize mode — config.toml:64
rex.mode("resize", { exclusive = true })
rex.bind("resize/enter", "client.mode.exit")
rex.bind("resize/escape", "client.mode.exit")
rex.bind("ctrl+space>ctrl+r", "client.mode.enter", { name = "resize" })
rex.bind("resize/left", "pane.resize", { direction = "left" })
rex.bind("resize/down", "pane.resize", { direction = "down" })
rex.bind("resize/up", "pane.resize", { direction = "up" })
rex.bind("resize/right", "pane.resize", { direction = "right" })
