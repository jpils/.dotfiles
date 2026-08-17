{ pkgs, ... }:

{
	extraPackages = with pkgs; [
		texliveFull
		zathura
	];

	plugins = with pkgs.vimPlugins; [
		vimtex
	];
	lua = /* lua */ ''
		vim.g.vimtex_view_method = "zathura"
		vim.g.vimtex_view_general_viewer = "zathura"
		vim.g.vimtex_compiler_method = "latexmk"
		vim.keymap.set("n", "<leader>cc", ":VimtexCompile<CR>")
		vim.keymap.set("n", "<leader>cs", ":VimtexCompileSS<CR>")
	'';
}
