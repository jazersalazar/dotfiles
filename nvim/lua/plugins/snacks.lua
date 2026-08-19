return {
  {
    "folke/snacks.nvim",
    event = "VimEnter",
    init = function()
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          vim.schedule(function()
            -- Only on a bare `nvim`. Opening a file or directory explicitly
            -- passes an argument, and the explorer would otherwise open
            -- alongside it.
            if vim.fn.argc() == 0 then
              Snacks.explorer()
            end
          end)
        end,
      })
    end,
    keys = {
      {
        "<leader>e",
        function()
          Snacks.explorer()
        end,
        desc = "File Explorer",
      },
    },
    opts = {
      picker = {
        sources = {
          explorer = {
            layout = {
              layout = {
                width = 25,
                min_width = 25,
              },
            },
          },
        },
      },
    },
  },
}
