return {
    'nvim-telescope/telescope.nvim', tag = '0.1.2',
     dependencies = { 'nvim-lua/plenary.nvim' },
     keys = {
	{ '<leader>ff', function() require('telescope.builtin').find_files() end, { desc = '(TS) Find files' } },
	{ '<leader>fb', function() require('telescope.builtin').buffers() end, { desc = '(TS) Find buffers'} },
	{ '<leader>fg', function() require('telescope.builtin').live_grep() end, { desc = '(TS) Fuzzy finder'} }
     }
}
