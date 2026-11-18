-- Rex config. Migrated from tmux (~/.config/tmux/tmux.reset.conf) and Herdr
-- (~/.config/herdr/config.toml) by Rex's migration prompt, 2026-11-18.
-- Prefix is ctrl+space, as in tmux and Herdr. Where both bound the same key to
-- the same action, the line is attributed to Herdr.

-- Prefix passthrough (tmux.reset.conf:13)
rex.bind("ctrl+space>ctrl+space", "pane.send_key", { key = "ctrl+space" })

-- Panes
rex.bind("ctrl+space>x", "pane.close")                                   -- tmux.reset.conf:19
rex.bind("ctrl+space>shift+\\", "pane.split", { direction = "right" })   -- herdr config.toml:38
rex.bind("ctrl+space>-", "pane.split", { direction = "down" })           -- herdr config.toml:39
rex.bind("ctrl+space>.", "pane.split", { direction = "down" })           -- tmux.reset.conf:128
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
