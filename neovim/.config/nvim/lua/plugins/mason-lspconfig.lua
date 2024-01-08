return {
	'williamboman/mason-lspconfig.nvim',
	dependencies = { 'neovim/nvim-lspconfig' },
	config = function()
		require('mason-lspconfig').setup({
			ensure_installed = { 'lua_ls' }
		})

		require('lspconfig').ruby_ls.setup {}
	end
}
