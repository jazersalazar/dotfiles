return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- LazyVim puts a clock in the last section; the tmux status bar already
      -- shows the time, so drop it rather than showing it twice.
      opts.sections.lualine_z = {}
    end,
  },
}
