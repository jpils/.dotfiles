{ inputs, ... }: {
	flake.nixosModules.walker = { config, pkgs, ... }: {
		imports = [
			inputs.walker.nixosModules.default
		];

		programs.walker = {
			enable = true;
		};

		nix.settings = {
			extra-substituters = [ "https://walker-git.cachix.org" ];
			extra-trusted-public-keys = [ "walker-git.cachix.org-1:vmC0ocfPWh0S/vRAQGtChuiZBTAe4wiKDeyyXM0/7pM=" ];
		};
	};
}
