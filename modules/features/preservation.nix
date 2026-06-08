# preservation.nix
{ self, inputs, ... }: {
	flake.nixosModules.preservation = { config, pkgs, ... }:
	{
	  imports = [
	    inputs.preservation.nixosModules.default
	  ];

	  preservation = {
	    enable = true;
	
	    preserveAt."/persistent" = {
	      directories = [
	        "/etc/nixos"
			"/etc/ssh"
			"/etc/shadow"
			"/var/db/sudo"
			"/var/lib/systemd/random-seed"
			"/var/lib/systemd/timers"
				"/var/lib/bluetooth"
			"/var/log"
				{
				  directory = "/var/lib/nixos";
				  inInitrd = true;
				}
			"/etc/NetworkManager/system-connections"
			"/var/lib/AccountsService"
	    ];
	
	      files = [
	        {
	          file = "/etc/machine-id";
	          inInitrd = true;
	        }
	      ];
	
	      users.jay = {
	        directories = [
			  ".cache/noctalia"
			  ".cache/noctalia-qs"
			  ".cache/zen"
			  ".config/jj"
			  ".config/noctalia"
			  ".config/zen"
			  ".local/share/Steam"
			  ".local/share/keyrings"
			  ".local/share/nvim/harpoon"
			  ".local/share/zoxide"
			  ".local/state/wireplumber"
			  ".mozilla"
			  ".steam"
			  ".zen"
			  "Documents"
			  "Pictures"
			  "Projects"
			  "nixconf"
	          ".ssh"
	        ];
			files = [
			  ".config/nushell/history.txt"
			];
	      };
	    };
	  };
	  systemd.suppressedSystemUnits =  [ "systemd-machine-id-commit.service" ];
	};
}
