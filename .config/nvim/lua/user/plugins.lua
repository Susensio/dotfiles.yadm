-- Automatically install packer
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()
local in_headless = #vim.api.nvim_list_uis() == 0

if in_headless then
    function vim.notify(msg, _, _)
        vim.api.nvim_chan_send(vim.v.stderr, msg .. '\n') -- This add the line break
    end
end

-- Run PackerSync if there are changes in this file, not deattached

local packer_grp = vim.api.nvim_create_augroup('packer_user_config', { clear = true })
vim.api.nvim_create_autocmd(
  'BufWritePost',
  { pattern = 'plugins.lua',
    nested = true,
    -- Someday, when PackerSync can be waited for, this should work on `:wq` as well
    callback = function(args)
      -- Newer vim 8 syntax
      -- vim.cmd.source(args.file)
      -- vim.cmd.PackerSync()
      vim.cmd('source ' .. args.file)

      -- local timeout = 5000   -- ms
      -- vim.g.packer_completed = false
      --
      -- vim.api.nvim_create_autocmd(
      --   'PackerComplete',
      --   { pattern = 'plugins.lua',
      --     callback = function()
      --       vim.g.packer_completed = true
      --       print('hi')
      --     end,
      --     nested = true,
      --     group = user_grp } 
      -- )
      --
      vim.cmd('PackerSync')

      -- vim.wait(timeout, function() return vim.g.packer_completed end)
      --
      -- vim.g.packer_completed = nil
    end,
    -- command = 'source | PackerSync ',
    
    -- Meanwhile, a background job is launched
    -- command = 'silent !nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync' &', 
    desc = 'Sync Packer plugins source.',
    group = packer_grp 
  }
)

-- packer = require('packer')
-- This doesn't seem necessary

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, 'packer')
if not status_ok then
  return
end

-- Have packer use a popup window
packer.init {
  display = {
    open_fn = function()
      return require('packer.util').float { border = 'rounded' }
    end,
  },
  git = {
    clone_timeout = 300, -- Timeout, in seconds, for git clones
  },
  log = { level = in_headless and 'info' or 'warn' }
}


-- LIST OF PLUGINS --

return packer.startup(function(use)
  use 'wbthomason/packer.nvim'

  -- -- Escape inser mode with jk kj
  -- use { 'max397574/better-escape.nvim',
  --   config = function() require('better_escape').setup({
  --     mapping = {'jk', 'kj'},
  --     timeout = 100,
  --     clear_empty_lines = true,
  --   }) end,
  -- }
  
  -- -- Side tree explorer
  -- use {'kyazdani42/nvim-tree.lua',
  --   requires = 'nvim-tree/nvim-web-devicons',
  --   config = function() require('nvim-tree').setup() end
  -- }

  --   -- Auto close brackets
--   use {'windwp/nvim-autopairs',
--     config = function() require('nvim-autopairs').setup() end
--   }
--   
--   -- Surround with pairs of ''[]()... with command ysiw)
--   use {'kylechui/nvim-surround',
-- --    tag = '*', -- Use for stability; omit to use `main` branch for the latest features
--     config = function() require('nvim-surround').setup() end
--   }
  
  -- TMUX integration
  use { 'numToStr/Navigator.nvim',
    config = function()
        require('Navigator').setup()
    end
  }
  -- Better alternative
  use {'echasnovski/mini.nvim',
    config = function()
      require('mini.pairs').setup()
      require('mini.surround').setup()
    end
  }

  use {'lukas-reineke/indent-blankline.nvim',
    config = function() require('indent_blankline').setup({
      char = '⎸',
      show_current_context = true,
      space_char_blankline = " ",
      indent_blankline_strict_tabs = true,
      show_end_of_line = true,
      -- use_treesitter = true,
    }) end
  }


  -- Toggle comments with gcc for line, gbc for block
  use {'numToStr/Comment.nvim',
    config = function() require('Comment').setup() end
}

  -- Open with cursor in last place
  use {'ethanholz/nvim-lastplace',
    config = function() require('nvim-lastplace').setup() end
  }
  
  -- use 'samirettali/shebang.nvim'
  -- Automatic shebang
  use {'~/Projects/shebang.nvim',
    config = function() require('magic-bang').setup() end
  }

  -- use {'dag/vim-fish'}

  -- Infer indent in current file
  use {'nmac427/guess-indent.nvim',
    config = function() require('guess-indent').setup() end,
  }

  -- Treesitter
  use {'nvim-treesitter/nvim-treesitter',
    config = function() require('nvim-treesitter.configs').setup({
      -- ensure_installed = 'all',
      ensure_installed =  {
        'bash', 'fish',
        'dockerfile', 'regex',
        -- 'gitignore', 'gitcommit',
        'help', 'comment',
        'python', 'lua', 'vim',
        'yaml',
      },
      sync_install = false,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = { 
        enable = true,
        -- disable = { 'fish' },
      },
    }) end,
    run = function()
      local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
      ts_update()
    end,
  }
  -- -- LSP
  -- use {'williamboman/mason.nvim',
  --   config = function() require('mason').setup() end
  -- }
  -- use {'williamboman/mason-lspconfig.nvim',
  --   config = function() require('manson-lspconfig').setup({
  --     ensure_installed={}
  --     automatic_installation = false,
  --   })
  -- }
  -- use 'neovim/nvim-lspconfig'


  -- Startup time profile pretty viewer
  -- use 'dstein64/vim-startuptime'

  -- Colorscheme
  use 'tanvirtin/monokai.nvim'

  -- Vim learning game
  use 'ThePrimeagen/vim-be-good'

  -- For testing
  use 'nvim-lua/plenary.nvim'

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if (packer_bootstrap and not in_headless) then
    packer.sync()
  end
end)
