return {
    'nvim-telescope/telescope.nvim', tag = '0.1.5',
     dependencies = { 'nvim-lua/plenary.nvim' },
     keys = {
	{ '<leader>sg', function() require('telescope.builtin').git_files() end, { desc = '(TS) Find  Git files' } },
	{ '<leader>sf', function() require('telescope.builtin').find_files() end, { desc = '(TS) Find files' } },
	{ '<leader>sb', function() require('telescope.builtin').buffers() end, { desc = '(TS) Find buffers'} },
	{ '<leader>slg', function() require('telescope.builtin').live_grep() end, { desc = '(TS) Fuzzy finder'} }
     }
}
