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
      -- neopywal при background=light считает палитру тёмной и инвертирует её
      -- (utils/light.lua: convert_dark2light_theme) → наш светлый текст #181C20 становился почти белым.
      -- binc/theme уже отдаёт готовую светлую палитру с контрастом ≥ 4.5 — берём её как есть.
      -- Через preload, а не подмену функции: neopywal.load() выгружает neopywal.utils.* при каждой перезагрузке.
      package.preload["neopywal.utils.light"] = function()
        return { convert_dark2light_theme = function(p) return vim.deepcopy(p) end }
      end
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
      -- Тема lualine считается из палитры при require — после смены палитры/режима пересобрать.
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "neopywal*",
        callback = function()
          if not package.loaded["lualine"] then return end
          package.loaded["lualine.themes.neopywal"] = nil
          local lualine = require("lualine")
          lualine.setup(lualine.get_config())
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

  -- theme = "auto" ищет lualine-тему по имени схемы (neopywal-light/-dark) — такой нет, и auto
  -- собирает тему из прозрачного фона → середина статусной строки чёрная. У neopywal своя тема.
  {
    "nvim-lualine/lualine.nvim",
    opts = { options = { theme = "neopywal" } },
  },
}
