{ pkgs, ... }:

{
	extraPackages = with pkgs; [
		clang-tools
		marksman
		nil
		nixd
		pyright
		rust-analyzer
		texlab
	];

	plugins = with pkgs.vimPlugins; [
		cmp-buffer
		cmp_luasnip
		cmp-nvim-lsp
		cmp-nvim-lua
		cmp-path
		lsp-zero-nvim
		nvim-cmp
		nvim-lspconfig
	];

	lua = /* lua */ ''
		local lsp_zero = require('lsp-zero')

		lsp_zero.on_attach(function(client, bufnr)
		  local opts = {buffer = bufnr, remap = false}

		  vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
		  vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
		  vim.keymap.set("n", "<leader>ws", function() vim.lsp.buf.workspace_symbol() end, opts)
		  vim.keymap.set("n", "<leader>dd", function() vim.diagnostic.open_float() end, opts)
		  vim.keymap.set("n", "<leader>dn", function() vim.diagnostic.goto_next() end, opts)
		  vim.keymap.set("n", "<leader>dp", function() vim.diagnostic.goto_prev() end, opts)
		  vim.keymap.set("n", "<leader>ca", function() vim.lsp.buf.code_action() end, opts)
		  vim.keymap.set("n", "<leader>rr", function() vim.lsp.buf.references() end, opts)
		  vim.keymap.set("n", "<leader>rn", function() vim.lsp.buf.rename() end, opts)
		  vim.keymap.set("i", "<A-k>", function() vim.lsp.buf.signature_help() end, opts)
		end)

		local cmp_nvim_lsp = require('cmp_nvim_lsp')
		local capabilities = cmp_nvim_lsp.default_capabilities()

		vim.lsp.config('rust_analyzer', {
		  on_attach = lsp_zero.on_attach,
		  capabilities = capabilities,
		})
		vim.lsp.enable('rust_analyzer')

		vim.lsp.config('marksman', {
		  on_attach = lsp_zero.on_attach,
		  capabilities = capabilities,
		  -- Use initialization_options for server-start settings
		  options = {
			initialization_options = {
			  core = {
				title_from_heading = false,
			  },
			},
		  },
		})
		vim.lsp.enable('marksman')

		vim.lsp.config('nixd', {
		  on_attach = lsp_zero.on_attach,
		  capabilities = capabilities,
		})
		vim.lsp.enable('nixd')

		vim.lsp.enable('pyright')

		local cmp = require('cmp')
		local cmp_select = { behavior = cmp.SelectBehavior.Select }

		require('luasnip.loaders.from_vscode').lazy_load()

		cmp.setup({
		  sources = {
			{name = 'path'},
			{name = 'nvim_lsp'},
			{name = 'nvim_lua'},
			{name = 'luasnip', keyword_length = 2},
			{name = 'buffer', keyword_length = 3},
		  },
		  formatting = lsp_zero.cmp_format(),
		  mapping = cmp.mapping.preset.insert({
			['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
			['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
			['<C-h>'] = cmp.mapping.confirm({ select = true }),
			['<C-Space>'] = cmp.mapping.complete(),
		  }),
		})
	'';
}
