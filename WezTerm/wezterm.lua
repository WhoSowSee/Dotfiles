local wezterm = require("wezterm")
local act = wezterm.action

local pwsh_path = "C:\\Users\\whosowsee\\AppData\\Local\\Microsoft\\WindowsApps\\pwsh.exe"

-- Флаг для отслеживания ручного изменения заголовка вкладки
local tab_title_set_manually = {}

local config = {}
-- Use config builder object if possible
if wezterm.config_builder then config = wezterm.config_builder() end

-- Settings
config.default_prog = { pwsh_path, "-l", "-NoLogo" }
config.initial_rows = 20 -- height
config.initial_cols = 90 -- width

config.color_scheme = "Tokyo Night"
config.color_scheme = "MaterialOcean"
config.font = wezterm.font_with_fallback({
  { family = "JetBrainsMono Nerd Font", scale = 1.1, weight = "Medium", },
})
config.window_background_opacity = 0.7
config.window_decorations = "RESIZE"
config.scrollback_lines = 3000
config.default_workspace = "main"
config.default_cursor_style = "BlinkingBar"
config.cursor_thickness = '1.9px'
config.animation_fps = 120
config.cursor_blink_rate = 700

config.disable_default_key_bindings = true
config.show_tab_index_in_tab_bar = false
config.window_close_confirmation = "NeverPrompt"
-- config.hide_tab_bar_if_only_one_tab = true

config.window_padding = {
  top = '0.2cell',
  left = '0.8cell',
}

if config.color_scheme == "MaterialOcean" then
  config.colors = {
    tab_bar = {
      background = '#10121b',

      active_tab = {
        bg_color = '#10121b',
        fg_color = '#c0c0c0',
      },

      inactive_tab = {
        bg_color = '#10121b',
        fg_color = '#5e5e5e',
      },

      inactive_tab_hover = {
        bg_color = '#16161e',
        fg_color = '#c0c0c0',
        italic = false,
      },

      new_tab = {
        bg_color = '#10121b',
        fg_color = '#808080',
      },

      new_tab_hover = {
        bg_color = '#1a1a22',
        fg_color = '#909090',
        italic = false,
      }
    }
  }
end

-- Keys
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1200 }
config.keys = {
  -- Send C-a when pressing C-a twice
  { key = "a",          mods = "LEADER|CTRL", action = act.SendKey { key = "a", mods = "CTRL" } },
  { key = "c",          mods = "LEADER",      action = act.ActivateCopyMode },
  { key = "phys:Space", mods = "LEADER",      action = act.ActivateCommandPalette },

  -- Pane keybindings
  { key = "s",          mods = "LEADER",      action = act.SplitVertical { domain = "CurrentPaneDomain" } },
  { key = "v",          mods = "LEADER",      action = act.SplitHorizontal { domain = "CurrentPaneDomain" } },

  { key = "LeftArrow",  mods = "ALT|SHIFT",   action = act.ActivatePaneDirection "Left" },
  { key = "RightArrow", mods = "ALT|SHIFT",   action = act.ActivatePaneDirection "Right" },
  { key = "UpArrow",    mods = "ALT|SHIFT",   action = act.ActivatePaneDirection "Up" },
  { key = "DownArrow",  mods = "ALT|SHIFT",   action = act.ActivatePaneDirection "Down" },

  { key = "q",          mods = "LEADER",      action = act.CloseCurrentPane { confirm = false } },
  { key = "z",          mods = "LEADER",      action = act.TogglePaneZoomState },
  { key = "o",          mods = "LEADER",      action = act.RotatePanes "Clockwise" },
  -- We can make separate keybindings for resizing panes
  -- But Wezterm offers custom "mode" in the name of "KeyTable"
  { key = "r",          mods = "LEADER",      action = act.ActivateKeyTable { name = "resize", one_shot = false } },

  -- Tab keybindings
  { key = "t",          mods = "LEADER",      action = act.SpawnTab("CurrentPaneDomain") },
  { key = "[",          mods = "LEADER",      action = act.ActivateTabRelative(-1) },
  { key = "]",          mods = "LEADER",      action = act.ActivateTabRelative(1) },
  { key = "n",          mods = "LEADER",      action = act.ShowTabNavigator },
  { key = "Tab",        mods = "CTRL",        action = act.ShowTabNavigator },

  -- Default key bindings
  { key = "Enter",      mods = "ALT",         action = act.ToggleFullScreen },
  { key = "w",          mods = "ALT",         action = act.CloseCurrentTab {confirm=false} },
  { key = "ц",          mods = "ALT",         action = act.CloseCurrentTab {confirm=false} },
  { key = "с",          mods = "CTRL",        action = act.CopyTo("Clipboard") },
  { key = "м",          mods = "CTRL",        action = act.PasteFrom("Clipboard") },

  -- Mine
  { key = "LeftArrow",  mods = "LEADER",      action = act.ActivateTabRelative(-1) },
  { key = "RightArrow", mods = "LEADER",      action = act.ActivateTabRelative(1) },
  { key = "t",          mods = "ALT",         action = act.SpawnTab("CurrentPaneDomain") },
  { key = "v",          mods = "CTRL",        action = wezterm.action.PasteFrom("Clipboard") },

  {
    key = "q",
    mods = "LEADER|CTRL",
    action = act.PromptInputLine {
      description = wezterm.format({
        { Foreground = { Color = "#e0af68" } },
        { Text = "Press Enter to confirm quit:" },
      }),
      action = wezterm.action_callback(function(window, pane, _)
        window:perform_action(act.QuitApplication, pane)
      end),
    }
  },
  {
    key = "l",
    mods = "LEADER",
    action = act.SpawnCommandInNewTab {
      domain = "CurrentPaneDomain",
      args = { "wsl.exe", "-d", "Arch" }
    }
  },
  {
    key = "u",
    mods = "LEADER",
    action = act.SpawnCommandInNewTab {
      domain = "CurrentPaneDomain",
      args = { "wsl.exe", "-d", "Ubuntu" }
    }
  },
  {
    key = "e",
    mods = "LEADER",
    action = act.PromptInputLine {
      description = wezterm.format {
        { Attribute = { Intensity = "Bold" } },
        -- { Foreground = { AnsiColor = "Fuchsia" } },
        { Foreground = { Color = "#a3be8c" } },
        { Text = "Renaming Tab Title:\n" },
      },

      action = wezterm.action_callback(function(window, pane, line)
        if line then
          window:active_tab():set_title(" " .. line .. " ")
          -- Устанавливаем флаг, чтобы функция update-status не перезаписывала заголовок
          tab_title_set_manually[window:active_tab():tab_id()] = true
        end
      end)
    }
  },

  -- Key table for moving tabs around
  { key = "m",          mods = "LEADER",           action = act.ActivateKeyTable { name = "move_tab", one_shot = false } },
  -- Or shortcuts to move tab w/o move_tab table. SHIFT is for when caps lock is on
  { key = "{",          mods = "LEADER|SHIFT",     action = act.MoveTabRelative(-1) },
  { key = "}",          mods = "LEADER|SHIFT",     action = act.MoveTabRelative(1) },

  -- Lastly, workspace
  { key = "w",          mods = "LEADER",           action = act.ShowLauncherArgs { flags = "FUZZY|WORKSPACES" } },

  -- Scrolling keybindings
  { key = "UpArrow",    mods = "CTRL|ALT|SHIFT",   action = act.ScrollByLine(-1) },
  { key = "DownArrow",  mods = "CTRL|ALT|SHIFT",   action = act.ScrollByLine(1) },
}

-- I can use the tab navigator (LDR t), but I also want to quickly navigate tabs with index
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = "ALT",
    action = act.ActivateTab(i - 1)
  })
end

config.key_tables = {
  resize = {
    { key = "h",           action = act.AdjustPaneSize { "Left", 1 } },
    { key = "j",           action = act.AdjustPaneSize { "Down", 1 } },
    { key = "k",           action = act.AdjustPaneSize { "Up", 1 } },
    { key = "l",           action = act.AdjustPaneSize { "Right", 1 } },

    { key = "LeftArrow",   action = act.AdjustPaneSize { "Left", 1 } },
    { key = "DownArrow",   action = act.AdjustPaneSize { "Down", 1 } },
    { key = "UpArrow",     action = act.AdjustPaneSize { "Up", 1 } },
    { key = "RightArrow",  action = act.AdjustPaneSize { "Right", 1 } },

	  { key = "Escape",      action = "PopKeyTable" },
    { key = "Enter",       action = "PopKeyTable" },
  },
  move_tab = {
    { key = "LeftArrow",   action = act.MoveTabRelative(-1) },
    { key = "RightArrow",  action = act.MoveTabRelative(1) },

	  { key = "Escape",      action = "PopKeyTable" },
    { key = "Enter",       action = "PopKeyTable" },
  },
}

-- Tab bar
-- I don't like the look of "fancy" tab bar
config.use_fancy_tab_bar = false
config.status_update_interval = 1000
config.tab_bar_at_bottom = false

wezterm.on("update-status", function(window, pane)
  -- Workspace name
  local stat = window:active_workspace()
  local stat_color = "#6f88c8"
  -- It's a little silly to have workspace name all the time
  -- Utilize this to display LDR or current key table name
  if window:active_key_table() then
    stat = window:active_key_table()
    stat_color = "#7dcfff"
  end
  if window:leader_is_active() then
    stat = "LDR"
    stat_color = "#bb9af7"
  end

  local basename = function(s)
    -- Nothing a little regex can't fix
    return string.gsub(s, "(.*[/\\])(.*)", "%2")
  end

  local battery_status = ""
  local icon = ""
  for _, b in ipairs(wezterm.battery_info()) do
    local charge = b.state_of_charge * 100
    local base_icon = b.state == "Charging" and "md_battery_charging_" or "md_battery_"

    for i = 10, 100, 10 do
      if charge <= i then
        icon = wezterm.nerdfonts[base_icon .. tostring(i)]
        break
      end
    end

    if charge > 90 then
      icon = wezterm.nerdfonts[b.state == "Charging" and "md_battery_charging" or "md_battery"]
    end

    battery_status = string.format("%.0f%%", charge)
  end

  -- Current working directory
  -- On Windows, this only works with Shell Integration. See the documentation for more details: https://wezfurlong.org/wezterm/shell-integration.html

  local cwd = pane:get_current_working_dir()
  if cwd then
    if type(cwd) == "userdata" then
      -- Wezterm introduced the URL object in 20240127-113634-bbcac864
      cwd = cwd.file_path
    else
      -- 20230712-072601-f4abf8fd or earlier version
      cwd = cwd
    end

    if cwd:match("/C:") then
      cwd = cwd:sub(2, 2)
    elseif cwd:match("/D:") then
      cwd = cwd:sub(2, 2)
    elseif cwd == "/" then
      cwd = cwd
    else
      cwd = basename(cwd)
    end
  else
    cwd = ""
  end

  -- Current command
  local cmd = pane:get_foreground_process_name()
  -- CWD and CMD could be nil (e.g. viewing log using Ctrl-Alt-l)
  cmd = cmd and basename(cmd):gsub("%.exe$", "") or ""

  -- Определяем иконку процесса

  if cmd == "go" or cmd == "zoxide" or cmd == "git" or cmd == "starship" then
    cmd = "pwsh"
  elseif cmd == "wslhost" then
    cmd = "wsl"
  end

  local process_icon = wezterm.nerdfonts.cod_server_process
  if cmd == "wsl" then
    process_icon = wezterm.nerdfonts.cod_terminal_linux
  elseif cmd == "pwsh" then
    process_icon = wezterm.nerdfonts.oct_terminal
  elseif cmd == "ssh" then
    process_icon = wezterm.nerdfonts.fa_github
  end

  -- Обновляем заголовок вкладки только если он не был установлен вручную
  if not tab_title_set_manually[window:active_tab():tab_id()] then
    if cmd ~= "" then
      window:active_tab():set_title(" " .. cmd .. " ")
    end
  end

  -- Time
  local time = wezterm.strftime("%H:%M")

  -- Left status (left of the tab line)
  window:set_left_status(wezterm.format({
    { Text = "  " },
    { Text = icon .. " " .. battery_status },
    "ResetAttributes",
    { Text = " | " },
    { Foreground = { Color = stat_color } },
    { Text = wezterm.nerdfonts.oct_table .. "  " .. stat },
    "ResetAttributes",
    { Text = " |" },
    "ResetAttributes",
  }))

  -- Right status
  window:set_right_status(wezterm.format({
    -- Wezterm has a built-in nerd fonts
    -- https://wezfurlong.org/wezterm/config/lua/wezterm/nerdfonts.html
    { Text = wezterm.nerdfonts.md_folder_outline .. "  " .. cwd },
    { Text = " | " },
    { Foreground = { Color = "#e0af68" } },
    { Text = process_icon .. "  " .. cmd },
    "ResetAttributes",
    { Text = " | " },
    { Text = wezterm.nerdfonts.md_clock_outline .. "  " .. time },
    { Text = "  " },
  }))
end)

wezterm.on("update-right-status", function(window, pane)
  local cmd = pane:get_foreground_process_name()

  if cmd:match("nvim") then
    config.window_padding = {
      top = '0cell',
      left = '0cell',
      right = '0cell',
      bottom = '0cell',
    }
  else
    config.window_padding = {
      top = '0.2cell',
      left = '0.8cell',
    }
  end

  window:set_config_overrides(config)
end)

wezterm.on("tab-created", function(tab)
  -- Сбрасываем флаг при создании новой вкладки
  tab_title_set_manually[tab:tab_id()] = false
end)

--[[ Appearance setting for when I need to take pretty screenshots
config.enable_tab_bar = false
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'
config.cursor_blink_rate = 1500
-- config.window_padding = {
  -- left = '0.5cell',
  -- right = '0.5cell',
  -- top = '0.5cell',
  -- top = '-0.7cell',
  -- bottom = '0cell',
  -- }
-- ]]

return config
