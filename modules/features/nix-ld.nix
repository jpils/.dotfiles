{ self, inputs, ... }:{

	flake.nixosModules.nix-ld = { pkgs, ... }: {
		programs.nix-ld.enable = true;

		programs.nix-ld.libraries = with pkgs; [
			stdenv.cc.cc
			zlib
			glib
		];
	};
}
