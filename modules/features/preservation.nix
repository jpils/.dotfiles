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
			  ".local/state/wireplumber"
			  ".local/share/nvim/harpoon"
			  ".local/share/zoxide"
	          ".ssh"
			  ".mozilla"
			  ".zen"
			  ".config/zen"
			  ".cache/zen"
			  ".config/noctalia"
			  ".cache/noctalia"
			  ".cache/noctalia-qs"
			  ".config/jj"
			  "Documents"
			  "Projects"
			  "Pictures"
			  "nixconf"
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
