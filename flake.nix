{
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

		flake-parts.url = "github:hercules-ci/flake-parts";
		import-tree.url = "github:vic/import-tree";

		wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

		disko.url = "github:nix-community/disko";
		disko.inputs.nixpkgs.follows = "nixpkgs";

		preservation.url = "github:nix-community/preservation";
	  
		sops-nix.url = "github:Mic92/sops-nix";
		sops-nix.inputs.nixpkgs.follows = "nixpkgs";

		zen-browser = {
			url = "github:youwen5/zen-browser-flake";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		elephant.url = "github:abenz1267/elephant";
		walker = {
			url = "github:abenz1267/walker";
			inputs.elephant.follows = "elephant";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = inputs: inputs.flake-parts.lib.mkFlake 
	{inherit inputs;} 
	(inputs.import-tree ./modules);
}
