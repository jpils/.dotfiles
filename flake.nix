{
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

		flake-parts.url = "github:hercules-ci/flake-parts";
		import-tree.url = "github:vic/import-tree";

		wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

		noctalia-v5 = {
			url = "github:noctalia-dev/noctalia/v5.0.0-beta2";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		disko.url = "github:nix-community/disko";
		disko.inputs.nixpkgs.follows = "nixpkgs";

		preservation.url = "github:nix-community/preservation";
	  
		sops-nix.url = "github:Mic92/sops-nix";
		sops-nix.inputs.nixpkgs.follows = "nixpkgs";

		zen-browser = {
			url = "github:youwen5/zen-browser-flake";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = inputs: inputs.flake-parts.lib.mkFlake 
	{inherit inputs;} 
	(inputs.import-tree ./modules);
}
