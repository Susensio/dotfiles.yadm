return {
	{
		"ellisonleao/gruvbox.nvim",
		init = function()
			vim.o.background = "light"
		end,
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "gruvbox",
		},
	},
}
