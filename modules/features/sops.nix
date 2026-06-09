{ self, inputs, ... }: {
	flake.nixosModules.sops = { config, lib, pkgs, ... }: {
		imports = [
			inputs.sops-nix.nixosModules.sops
		];

		environment.systemPackages = [ pkgs.sops ];	

		sops = {
			#age.sshKeyPaths = [ "/persistent/etc/ssh/ssh_host_ed25519_key" ];

			defaultSopsFile = ../../secrets/secrets.yaml; 
			defaultSopsFormat = "yaml";

			age.keyFile = "/persistent/home/jay/.config/sops/age/keys.txt";

			secrets.jay-password.neededForUsers = true;
		};
	};
}
