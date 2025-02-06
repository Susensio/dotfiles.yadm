return {
   { -- mini.pick
      "echasnovski/mini.pick",
      main = "mini.pick",
      dependencies = {
         { "echasnovski/mini.extra",  config = true },
         { "echasnovski/mini.visits", config = true, event = "LazyFile" },
         { "echasnovski/mini.align" },
         -- { "echasnovski/mini.fuzzy",  config = true },
      },
      cmd = "Pick",
      lazy = true,
      init = function(plugin)
         -- Use mini pick instead of builtin select
         vim.ui.select = require('lazy-require').require_on_exported_call(plugin.main).ui_select

         -- vim.keymap.set(
         --    { "n" },
         --    "<leader>v",
         --    "<cmd>Pick visit_paths<CR>",
         --    { desc = "Search files" }
         -- )
         -- vim.keymap.set(
         --    { "n" },
         --    "<leader>f",
         --    "<cmd>Pick files tool='fd'<CR>",
         --    { desc = "Search files" }
         -- )
         vim.keymap.set(
            { "n" },
            "<leader>f",
            "<cmd>Pick frecency tool='fd'<CR>",
            { desc = "Search recent files" }
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
            "<cmd>Pick grep_live_align<CR>",
            { desc = "Grep files" }
         )
         vim.keymap.set(
            { "x" },
            "<leader>g",
            "<cmd>Pick grep pattern='<cword>' <CR>",
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
            "<cmd>Pick buf_lines_colored<CR>",
            { desc = "Search inside buffer" }
         )

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
                  return true -- stop picker
               end,
            },
         },
         options = {
            use_cache = true,
         },
      },
      config = function(_, opts)
         require("mini.pick").setup(opts)

         MiniPick.registry.frecency = function()
            local function sort(stritems, indices)
               local inf = math.huge

               local minivisits = require("mini.visits")
               local visit_paths = minivisits.list_paths(nil, { sort = minivisits.gen_sort.z() })

               -- relative paths to cwd
               visit_paths = vim.tbl_map(function(path) return vim.fn.fnamemodify(path, ":.") end, visit_paths)
               local scores = {}
               for i, path in ipairs(visit_paths) do
                  scores[path] = i
               end

               -- current file last
               local current_file = vim.fn.expand("%:.")
               if scores[current_file] then
                  scores[current_file] = inf
               end

               indices = vim.deepcopy(indices)
               table.sort(indices,
                  function(item1, item2)
                     local path1 = stritems[item1]
                     local path2 = stritems[item2]

                     local score1 = scores[path1] or inf -- inf for paths not visited
                     local score2 = scores[path2] or inf -- inf for paths not visited

                     return score1 < score2
                  end
               )
               return indices
            end

            local function get_keyword_matches(path, keywords, local_opts)
               local_opts = vim.tbl_extend("force", { force_last = true }, local_opts or {})

               local matches = {}

               if #keywords == 0 then
                  return nil -- No keywords, return empty list
               end

               path = path:lower() -- Convert to lowercase for case-insensitive matching

               -- Get the last keyword and remaining ones
               local keywords_last = keywords[#keywords]

               local last_path_separator = path:match("^.*()" .. "/") or 0
               local last_start, last_end = path:find(keywords_last, last_path_separator + 1, true)

               if last_start == nil then
                  if local_opts.force_last then
                     return nil -- Last keyword not found
                  end
               else
                  -- Store last keyword match and remove it from the list
                  keywords = vim.list_slice(keywords, 1, #keywords - 1)
                  table.insert(matches, { last_start, last_end })
                  path = path:sub(1, last_start - 1) -- Truncate before last keyword
               end



               -- Find remaining keywords in reverse order
               for i = #keywords, 1, -1 do
                  local keyword = keywords[i]
                  local start_idx, end_idx = path:find(keyword, 1, true)
                  if not start_idx then
                     return nil -- Missing keyword
                  end

                  -- Store match
                  table.insert(matches, { start_idx, end_idx })

                  -- Truncate path before this keyword
                  path = path:sub(1, start_idx - 1)
               end

               -- Reverse order of matches (since we inserted in reverse)
               return matches
            end

            local function match_filter(stritems, indices, query)
               if #query == 0 or query == nil then
                  return indices
               end
               local keywords = vim.split(query, " ")
               -- if #keywords == 0 or keywords == nil then
               --    return indices
               -- end
               local should_reset_indices = keywords[#keywords] == ""
               if should_reset_indices then
                  for i = 1, #stritems do
                     indices[i] = i
                  end
               end
               local filtered = {}
               for _, index in ipairs(indices) do
                  local item = stritems[index]
                  if item ~= nil then
                     local match = get_keyword_matches(item, keywords)
                     if match ~= nil then
                        table.insert(filtered, index)
                     end
                  end
               end
               return filtered
            end

            local function show(buf_id, items, query, local_opts)
               local ns = vim.api.nvim_get_namespaces()["MiniPickRanges"]

               local icons = {}
               local lines = {}
               for i, item in ipairs(items) do
                  local icon_text, icon_hl_group = require("mini.icons").get("file", item)
                  icons[i] = { text = icon_text, hl_group = icon_hl_group }
                  lines[i] = icons[i].text .. ' ' .. item
               end

               vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)

               -- vim.api.nvim_buf_clear_namespace(buf_id, ns, 0, -1)

               -- Highlight icons
               for i, icon in ipairs(icons) do
                  local row = i - 1
                  vim.api.nvim_buf_set_extmark(buf_id, ns, row, 0, {
                     end_col = 1,
                     end_row = row,
                     hl_group = icon.hl_group,
                     hl_mode = "combine",
                     priority = 200,
                  })
               end

               query = table.concat(query)
               -- Highlight matched ranges
               for i, item in ipairs(items) do
                  local keywords = vim.split(query, " ")
                  local ranges = get_keyword_matches(item, keywords, { force_last = false })
                  if ranges == nil then return end
                  for _, range in ipairs(ranges) do
                     local row = i - 1
                     local start_col = range[1] - 1 + icons[i].text:len() + 1
                     local end_col = range[2] + icons[i].text:len() + 1
                     vim.api.nvim_buf_set_extmark(buf_id, ns, row, start_col, {
                        end_col = end_col,
                        end_row = row,
                        hl_group = "MiniPickMatchRanges",
                        hl_mode = "combine",
                        priority = 200,
                     })
                  end
               end
            end

            MiniPick.builtin.files(nil, {
               source = {
                  name = "Files (MRU)",
                  match = function(stritems, indices, query)
                     query = table.concat(query)
                     indices = match_filter(stritems, indices, query)
                     if #indices == 0 then
                        -- If no matches, try again without forcing the last keyword
                        indices = match_filter(stritems, indices, query .. " ")
                     end
                     indices = sort(stritems, indices)
                     return indices
                  end,
                  show = show,
               },
               options = {
                  use_cache = false,
               },
            })
         end

         MiniPick.registry.buf_lines_colored = function()
            local ns_digit_prefix = vim.api.nvim_create_namespace("cur-buf-pick-show")
            local show_cur_buf_lines = function(buf_id, items, query, opts)
               if items == nil or #items == 0 then
                  return
               end

               -- Show as usual
               MiniPick.default_show(buf_id, items, query, opts)

               -- Move prefix line numbers into inline extmarks
               local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
               local digit_prefixes = {}
               for i, l in ipairs(lines) do
                  local _, prefix_end, prefix = l:find("^(%s*%d+│)")
                  if prefix_end ~= nil then
                     digit_prefixes[i], lines[i] = prefix, l:sub(prefix_end + 1)
                  end
               end

               vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
               for i, pref in pairs(digit_prefixes) do
                  local opts = { virt_text = { { pref, "MiniPickNormal" } }, virt_text_pos = "inline" }
                  vim.api.nvim_buf_set_extmark(buf_id, ns_digit_prefix, i - 1, 0, opts)
               end

               -- Set highlighting based on the curent filetype
               local ft = vim.bo[items[1].bufnr].filetype
               local has_lang, lang = pcall(vim.treesitter.language.get_lang, ft)
               local has_ts, _ = pcall(vim.treesitter.start, buf_id, has_lang and lang or ft)
               if not has_ts and ft then vim.bo[buf_id].syntax = ft end
            end

            local local_opts = { scope = "current", preserve_order = true }
            require("mini.extra").pickers.buf_lines(local_opts, { source = { show = show_cur_buf_lines } })
         end

         MiniPick.registry.grep_live_align = function()
            local sep = package.config:sub(1, 1)
            local function truncate_path(path)
               local parts = vim.split(path, sep)
               if #parts > 2 then
                  parts = { parts[1], "…", parts[#parts] }
               end
               return table.concat(parts, sep)
            end

            local function map_gsub(items, pattern, replacement)
               return vim.tbl_map(function(item)
                  item, _ = string.gsub(item, pattern, replacement)
                  return item
               end, items)
            end

            local show_align_on_nul = function(buf_id, items, query, opts)
               -- Shorten the pathname to keep the width of the picker window to something
               -- a bit more reasonable for longer pathnames.
               items = map_gsub(items, "^%Z+", truncate_path)

               -- Because items is an array of blobs (contains a NUL byte), align_strings
               -- will not work because it expects strings. So, convert the NUL bytes to a
               -- unique (hopefully) separator, then align, and revert back.
               items = map_gsub(items, "%z", "#|#")
               items = require("mini.align").align_strings(items, {
                  justify_side = { "left", "right", "right" },
                  merge_delimiter = { "", " ", "", " ", "" },
                  split_pattern = "#|#",
               })
               items = map_gsub(items, "#|#", "\0")

               -- Back to the regularly scheduled program :-)
               MiniPick.default_show(buf_id, items, query, opts)
            end

            MiniPick.builtin.grep_live({}, {
               source = { show = show_align_on_nul },
               window = { config = { width = math.floor(0.816 * vim.o.columns) } },
            })
         end
      end,
   }
}
