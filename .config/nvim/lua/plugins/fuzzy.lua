return {
  { -- mini.pick
    "echasnovski/mini.pick",
    main = "mini.pick",
    dependencies = {
      { "echasnovski/mini.extra",  config = true },
      { "echasnovski/mini.visits", config = true, event = "LazyFile" },
      -- { "echasnovski/mini.fuzzy",  config = true },
    },
    cmd = "Pick",
    lazy = true,
    init = function()
      -- vim.keymap.set(
      --   { "n" },
      --   "<leader>f",
      --   "<cmd>Pick files tool='fd'<CR>",
      --   -- "<cmd>Pick files<CR>",
      --   { desc = "Search files" }
      -- )
      vim.keymap.set(
        { "n" },
        "<leader>f",
        "<cmd>Pick frecency tool='fd'<CR>",
        { desc = "Search files" }
      )
      vim.keymap.set(
        { "n" },
        "<leader>b",
        "<cmd>Pick buffers<CR>",
        { desc = "Search buffers" }
      )
      vim.keymap.set(
        { "n" },
        "<leader>g",
        "<cmd>Pick grep_live<CR>",
        { desc = "Grep files" }
      )
      vim.keymap.set(
        { "n" },
        "<leader>h",
        "<cmd>Pick help<CR>",
        { desc = "Search help" }
      )
      vim.keymap.set(
        { "n" },
        "<leader>:",
        "<cmd>Pick history<CR>",
        { desc = "Search history" }
      )

      vim.keymap.set(
        { "n" },
        "<leader>/",
        "<cmd>Pick buf_lines scope='current'<CR>",
        { desc = "Search inside buffer" }
      )
      -- vim.keymap.set(
      --   { "n" },
      --   '<leader>s"',
      --   "<cmd>Pick registers<CR>",
      --   { desc = "Search registers" }
      -- )
      -- vim.keymap.set(
      --   { "n" },
      --   "<leader>?",
      --   "<cmd>Pick keymaps<CR>",
      --   { desc = "Search keymaps" }
      -- )
      vim.keymap.set(
        { "n" },
        "<leader>r",
        '<cmd>Pick resume<CR>',
        { desc = "Search resume" }
      )
    end,
    opts = {
      mappings = {
        c_j_nop = {
          char = "<C-j>",
          func = function() end
        },
        scroll_up = "<C-u>",
        scroll_down = "<C-d>",
        to_quickfix = {
          char = "<C-q>",
          func = function()
            local items = MiniPick.get_picker_items() or {}
            MiniPick.default_choose_marked(items)
            return true  -- stop picker
          end,
        },
      },
    },
    config = function(_, opts)
      require("mini.pick").setup(opts)

      -- Use mini pick instead of builtin select
      vim.ui.select = MiniPick.ui_select

      -- MiniPick.registry.frecency = function()
      --   local items = MiniVisits.list_paths()
      --   local source = {
      --     name = "Files (MRU)",
      --     items = items,
      --   }
      --   return MiniPick.builtin.files(nil, { source = source })
      -- end


      MiniPick.registry.frecency = function()
        local inf = math.huge

        local visit_paths = MiniVisits.list_paths()
        -- relative paths
        visit_paths = vim.tbl_map(function(path) return vim.fn.fnamemodify(path, ":.") end, visit_paths)
        vim.tbl_add_reverse_lookup(visit_paths)

        -- current file last
        local current_file = vim.fn.expand("%:.")
        if visit_paths[current_file] then
          visit_paths[current_file] = inf
        end

        MiniPick.builtin.files(nil, {
          source = {
            name = "Files (MRU)",
            match = function(stritems, indices, query)
              local filtered = MiniPick.default_match(stritems, indices, query, true) or {}

              table.sort(filtered,
                function(item1, item2)
                  local path1 = stritems[item1]
                  local path2 = stritems[item2]
                  local score1 = visit_paths[path1] or inf    -- inf for paths not visited
                  local score2 = visit_paths[path2] or inf    -- inf for paths not visited
                  return score1 < score2
                end
              )

              return filtered
            end,
          },
        })
      end
    end,
  }
}
