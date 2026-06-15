{ pkgs, ... }:

{
	plugins = with pkgs.vimPlugins; [
		fine-cmdline-nvim
		nui-nvim
	];

	lua = /* lua */ ''
		require('fine-cmdline').setup({
            cmdline = {
                enable_keymaps = true,
                smart_history = true,
                prompt = '  '
            },
            popup = {
                position = {
                    row = '50%',
                    col = '50%',
                },
                size = {
                    width = '50%', 
                    height = 3,
                },
                border = {
                    style = 'rounded',
                },
                win_options = {
                    winhighlight = 'Normal:NormalFloat,FloatBorder:Special',
                },
            },
        })

        vim.keymap.set('n', ':', '<cmd>FineCmdline<CR>', { 
            noremap = true, 
            desc = "Floating Command Line" 
        })

        vim.keymap.set('v', ':', ':<C-u>FineCmdline<CR>', { 
            noremap = true, 
            desc = "Floating Command Line (Visual)" 
        })
	'';
}
