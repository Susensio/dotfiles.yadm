local function comment_ai_spec(ai_type, id, opts)
  local ts = require("mini.ai").gen_spec.treesitter
  local comment_ranges = ts({ a = '@comment.outer', i = '@comment.outer' })('a')

  if ai_type == "a" then
    -- entire block of comment
    -- require("mini.comment").textobject()

    -- by ChatGPT
    local grouped_ranges = {}
    local current_group = nil

    for i, range in ipairs(comment_ranges) do
      if current_group == nil then
        -- Start a new group
        current_group = {from = range.from, to = range.to}
      else
        -- Check if the current range is adjacent to the previous one
        if current_group.to.line + 1 == range.from.line and current_group.from.col == range.from.col then
          -- Extend the current group
          current_group.to = range.to
        else
          -- Current range is not adjacent, add the current group to the list and start a new group
          table.insert(grouped_ranges, current_group)
          current_group = {from = range.from, to = range.to}
        end
      end

      -- Add the last group to the list (if it exists)
      if i == #comment_ranges and current_group then
        table.insert(grouped_ranges, current_group)
      end
    end

    return grouped_ranges
  else
    -- inner text of line comment without commentstring
    -- it does not work for block comments, wait until this gets resolved:
    -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects/issues/133

    local cs = string.gsub(vim.bo.commentstring, '%%s', '')
    return vim.tbl_map(
      function(region)
        region.from.col = region.from.col + string.len(cs)
        return region
      end,
      comment_ranges
    )
  end
end

return {
  { -- mini.ai
    "echasnovski/mini.ai",
    -- event = "VeryLazy",
    keys = {
      {"a", mode = {"o", "x"}},
      {"i", mode = {"o", "x"}},
    },
    dependencies = {
      -- "nvim-treesitter-textobjects"
      "echasnovski/mini.extra",
    },
    enabled = true,
    opts = function(plugin)
      local ts = require("mini.ai").gen_spec.treesitter
      local extra = require("mini.extra").gen_ai_spec
      return {
        mappings = {
          around_next = "",
          inside_next = "",
          around_last = "",
          inside_last = "",
          goto_left = "",
          goto_right = "",
        },
        custom_textobjects = {
          f = ts({ a = "@function.outer", i = "@function.inner" }),
          -- f = ts({ a = "@call.outer", i = "@call.inner" }),
          o = ts({
            a = { "@conditional.outer", "@loop.outer" },
            i = { "@conditional.inner", "@loop.inner" },
          }),
          c = ts({ a = "@class.outer", i = "@class.inner" }),
          a = ts({ a = "@parameter.outer", i = "@parameter.inner" }),
          i = extra.indent(),
          g = extra.buffer(),
          -- c = ts({ a = "@comment.outer", i = "@comment.inner" }),
          -- c = comment_ai_spec,
          -- B = ts({ a = "@scope.outer", i = "@scope.inner" })
        },
        search_method = "cover_or_next",
        n_lines = 250,
      }
    end,
  },

}
