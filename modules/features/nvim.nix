{ self, inputs, ... }: {
	flake.nixosModules.neovim = { pkgs, lib, ... }: {
		environment.variables = {
			EDITOR = "nvim";
			VISUAL = "nvim";
		};
		
		environment.systemPackages = [ 
			self.packages.${pkgs.stdenv.hostPlatform.system}.neovim 
		];
	};

	perSystem = { pkgs, lib, self', ... }: 
		let 
			pluginDir = ../../config/nvim-plugins;
			
			getPlugins = pkgs: [
				(import "${pluginDir}/opts.nix" { inherit pkgs; })
				(import "${pluginDir}/remap.nix" { inherit pkgs; })
				(import "${pluginDir}/colorscheme.nix" { inherit pkgs; })
				(import "${pluginDir}/autopairs.nix" { inherit pkgs; })
				(import "${pluginDir}/lsp.nix" { inherit pkgs; })
				(import "${pluginDir}/dap.nix" { inherit pkgs; })
				(import "${pluginDir}/harpoon.nix" { inherit pkgs; })
				(import "${pluginDir}/zenmode.nix" { inherit pkgs; })
				(import "${pluginDir}/ibl.nix" { inherit pkgs; })
				(import "${pluginDir}/surround.nix" { inherit pkgs; })
				(import "${pluginDir}/lualine.nix" { inherit pkgs; })
				(import "${pluginDir}/luasnip.nix" { inherit pkgs; })
				(import "${pluginDir}/telescope.nix" { inherit pkgs; })
				(import "${pluginDir}/treesitter.nix" { inherit pkgs; })
				(import "${pluginDir}/vimtex.nix" { inherit pkgs; })
				(import "${pluginDir}/trouble.nix" { inherit pkgs; })
				(import "${pluginDir}/neogen.nix" { inherit pkgs; })
				(import "${pluginDir}/markdown.nix" { inherit pkgs; })
				#(import "${pluginDir}/cmdline.nix" { inherit pkgs; })
			];

			modules = getPlugins pkgs;

			mergedConfig = {
				plugins = lib.concatMap (m: m.plugins or []) modules;
				runtimePkgs = lib.concatMap (m: m.extraPackages or []) modules;
				lua = lib.concatStringsSep "\n" (map (m: m.lua or "") modules);
			};

		in {
			packages.neovim = inputs.wrapper-modules.wrappers.neovim.wrap {
				inherit pkgs;
				specs.allPlugins = mergedConfig.plugins;
				runtimePkgs = mergedConfig.runtimePkgs;
				settings.config_directory = pkgs.writeTextDir "init.lua" mergedConfig.lua;
			};		
		};
}
