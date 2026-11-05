-- Светлая/тёмная — как у всей системы: ~/.cache/theme/mode пишет ~/.config/binc/theme
-- и шлёт запущенным nvim SIGUSR1 (палитру neopywal перечитывает сам по изменению файла wallust).
local function theme_mode()
  local cache = vim.env.XDG_CACHE_HOME or (vim.env.HOME .. "/.cache")
  local f = io.open(cache .. "/theme/mode")
  if not f then return "dark" end
  local m = f:read("l")
  f:close()
  return m == "light" and "light" or "dark"
end

return {
  {
    "RedsXDD/neopywal.nvim",
    name = "neopywal",
    lazy = false,
    priority = 1000,

    init = function()
      vim.o.background = theme_mode()
      vim.api.nvim_create_autocmd("Signal", {
        pattern = "SIGUSR1",
        desc = "binc/theme: светлая/тёмная",
        callback = function()
          vim.schedule(function()
            local mode = theme_mode()
            if vim.o.background ~= mode or not (vim.g.colors_name or ""):match("^neopywal") then
              vim.o.background = mode
              pcall(vim.cmd.colorscheme, "neopywal")
            end
          end)
        end,
      })
    end,

    opts = {
      use_palette = "wallust",
      transparent_background = true,
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "neopywal",
    },
  },
}
