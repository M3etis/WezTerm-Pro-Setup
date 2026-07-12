-- config/workspace.lua
-- Workspace management configuration

local M = {}

--- Apply workspace configuration
--- @param config table WezTerm config
--- @return table Modified config
function M.apply(config)
  config.switch_to_last_active_tab_when_closing_tab = true
  config.window_close_confirmation = 'AlwaysPrompt'

  return config
end

return M
