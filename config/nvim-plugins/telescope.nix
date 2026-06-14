{ pkgs, ... }:

{
    plugins = with pkgs; [
        fd
        vimPlugins.telescope-nvim
        vimPlugins.telescope-ui-select-nvim
        vimPlugins.telescope-undo-nvim 
        ripgrep        
    ];

    lua = /* lua */ ''
        local undodir = vim.fn.stdpath("data") .. "/undo"
        if vim.fn.isdirectory(undodir) == 0 then
            vim.fn.mkdir(undodir, "p")
        end
        vim.opt.undodir = undodir
        vim.opt.undofile = true
        vim.opt.undolevels = 1000

        require("telescope").setup({
            extensions = {
                ["ui-select"] = {},
                undo = { 
                    side_by_side = true,
                    layout_strategy = "horizontal",
                    layout_config = {
                        preview_width = 0.6,
                    },
                },
            }
        })
        
        -- Load extensions
        require("telescope").load_extension("ui-select")
        require("telescope").load_extension("undo") 

        local builtin = require('telescope.builtin')
        
        vim.keymap.set("n", "<leader>ff", function()
            builtin.find_files({
                hidden = false,
                no_ignore = true,
                no_ignore_parent = true,
                follow = true,
            })
        end, { desc = "Files (ALL, incl. ignored)" })
        
        vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
        vim.keymap.set('n', '<leader>fg', builtin.git_files, {})
        vim.keymap.set('n', '<leader>fs', function()
            builtin.grep_string({ search = vim.fn.input("Grep > ") })
        end)

        -- Undo picker map (Ctrl+r or Ctrl+Enter to revert, Enter to yank)
        vim.keymap.set('n', '<leader>u', '<cmd>Telescope undo<cr>', { 
            desc = "Undo History" 
        })
    '';
}
