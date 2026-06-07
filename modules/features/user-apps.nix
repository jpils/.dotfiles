{ self, inputs, ... }:{

	flake.nixosModules.user-apps = { pkgs, ... }: {
	    users.users.jay.packages = with pkgs; [
			sshfs
			baobab
			celluloid
			vesktop
			evince
			file-roller
			geary              
			gnome-calculator
			gnome-calendar    
			gnome-text-editor
			loupe
			mission-center
			mpv
			nautilus
			networkmanagerapplet
			spotify
			step-cli
			sushi
			telegram-desktop
			tree
			vlc
			xournalpp
			zip

			inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
	    ];
	};
}
