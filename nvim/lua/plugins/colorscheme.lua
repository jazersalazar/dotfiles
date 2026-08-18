return {
  {
    "Mofiqul/dracula.nvim",
    priority = 1000,
    opts = {
      transparent_bg = true,
      overrides = {
        NormalFloat = { bg = "NONE" },
        SnacksPickerInput = { bg = "NONE" },
      },
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "dracula",
    },
  },
}
