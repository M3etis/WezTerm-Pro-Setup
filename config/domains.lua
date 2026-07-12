-- config/domains.lua
-- Domain and remote connection configuration

local M = {}

--- Apply domain configuration
--- @param config table WezTerm config
--- @return table Modified config
function M.apply(config)
  -- Default domain
  config.default_domain = 'local'

  -- SSH domains
  --[[
    Example SSH domains:
    config.ssh_domains = {
      {
        name = 'my-server',
        remote_address = '192.168.1.100',
        username = 'user',
      },
      {
        name = 'dev-box',
        remote_address = 'dev.example.com',
        username = 'developer',
        multiplexing = 'None',
      },
    }
  ]]
  config.ssh_domains = {}

  -- WSL domains (Windows only)
  --[[
    Example WSL domains:
    config.wsl_domains = {
      {
        name = 'WSL:Ubuntu',
        distribution = 'Ubuntu',
        default_cwd = '/home/user',
      },
    }
  ]]
  config.wsl_domains = {}

  return config
end

return M
