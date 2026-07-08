{ pkgs, ... }:

{
	extraPackages = with pkgs; [
		clang-tools
		marksman
		nil
		nixd
		texlab
	];

	plugins = with pkgs.vimPlugins; [
		blink-cmp
		nvim-lspconfig
	];

	lua = /* lua */ ''
		vim.api.nvim_set_hl(0, 'LspInlayHint', { fg = '#a9a9a9', bg = 'NONE', italic = true })

		-- 1. Strip inner token backgrounds to ensure complete transparency inside floats
		local function apply_seamless_highlights()
		  local groups = {
		    'BlinkCmpLabel', 'BlinkCmpLabelDetail', 'BlinkCmpLabelDescription',
		    'BlinkCmpKind', 'BlinkCmpSource', 'BlinkCmpNormal',
		    '@markup.block.markdown', 'markdownCodeBlock', 'markdownCode'
		  }
		  for _, group in ipairs(groups) do
		    vim.api.nvim_set_hl(0, group, { bg = 'NONE' })
		  end
		end

		apply_seamless_highlights()
		vim.api.nvim_create_autocmd('ColorScheme', {
		  pattern = '*',
		  callback = apply_seamless_highlights,
		})

		-- 2. Global Interceptor for LSP Floats (Forces hover/diagnostics to inherit your main editor bg)
		local orig_open_floating_preview = vim.lsp.util.open_floating_preview
		vim.lsp.util.open_floating_preview = function(contents, syntax, opts)
		  opts = opts or {}
		  opts.border = opts.border or 'rounded'
		  opts.max_width = opts.max_width or math.floor(vim.o.columns * 0.85)
		  -- Re-maps the floating window's core colors to your editor's standard background
		  opts.winhighlight = opts.winhighlight or 'Normal:Normal,FloatBorder:Normal'
		  
		  local bufnr, winnr = orig_open_floating_preview(contents, syntax, opts)
		  if winnr then
		    vim.wo[winnr].wrap = true
		  end
		  return bufnr, winnr
		end

		-- Diagnostic UI configs
		vim.diagnostic.config({
		  float = { border = 'rounded' },
		})

		-- 3. Initialize blink.cmp with layout restrictions
		require('blink.cmp').setup({
		  -- Map Ctrl+h to accept the suggestion
		  keymap = {
		    preset = 'default',
		    ['<C-h>'] = { 'accept', 'fallback' },
		  },

		  completion = {
		    menu = {
		      border = 'rounded',
		      winhighlight = 'Normal:Normal,FloatBorder:Normal,CursorLine:Visual,Search:None',
		      draw = {
		        columns = { { "kind_icon" }, { "label" } },
		      },
		    },
		    documentation = {
		      auto_show = true,
		      auto_show_delay_ms = 200,
		      window = {
		        border = 'rounded',
		        winhighlight = 'Normal:Normal,FloatBorder:Normal,Search:None',
		      },
		    },
		  },

		  signature = {
		    enabled = true,
		    window = {
		      border = 'rounded',
		      winhighlight = 'Normal:Normal,FloatBorder:Normal,Search:None',
		    },
		  },
		})

		-- Global LSP Attachment Hook
		vim.api.nvim_create_autocmd('LspAttach', {
		  desc = 'LSP keymaps and actions',
		  callback = function(event)
		    local opts = { buffer = event.buf, remap = false }

		    vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
		    vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
		    vim.keymap.set("n", "<leader>ws", function() vim.lsp.buf.workspace_symbol() end, opts)
		    vim.keymap.set("n", "<leader>dd", function() vim.diagnostic.open_float() end, opts)
		    vim.keymap.set("n", "<leader>dn", function() vim.diagnostic.goto_next() end, opts)
		    vim.keymap.set("n", "<leader>dp", function() vim.diagnostic.goto_prev() end, opts)
		    vim.keymap.set("n", "<leader>ca", function() vim.lsp.buf.code_action() end, opts)
		    vim.keymap.set("n", "<leader>rr", function() vim.lsp.buf.references() end, opts)
		    vim.keymap.set("n", "<leader>rn", function() vim.lsp.buf.rename() end, opts)

		    vim.keymap.set("n", "<leader>th", function()
		      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
		    end, opts)
		  end,
		})

		-- Native Server Configurations
		vim.lsp.config('rust_analyzer', {
		  settings = {
		    ['rust-analyzer'] = {
		      files = {
		        exclude = { '.pixi', '.direnv', '.git' },
		      },
		    },
		  },
		})
		vim.lsp.enable('rust_analyzer')

		vim.lsp.config('marksman', {
		  options = {
			init_options = {
			  core = { title_from_heading = false },
			},
		  },
		})
		vim.lsp.enable('marksman')

		vim.lsp.config('nixd', {})
		vim.lsp.enable('nixd')

		vim.lsp.config('pyright', {
		  before_init = function(_, config)
			local root = config.root_dir
			if not root then return end

			local pixi_python = vim.fn.glob(root .. '/.pixi/envs/*/bin/python', false, true)[1]
			local venv_python = root .. '/.venv/bin/python'
			local python = pixi_python
			  or (vim.fn.executable(venv_python) == 1 and venv_python)
			  or nil

			if python then
			  config.settings = config.settings or {}
			  config.settings.python = config.settings.python or {}
			  config.settings.python.pythonPath = python
			end
		  end,
		})
		vim.lsp.enable('pyright')
	'';
}
