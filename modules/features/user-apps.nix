{ self, inputs, ... }:{

	flake.nixosModules.user-apps = { pkgs, ... }: {
		system.activationScripts.pi-agent-config.text = ''
			install -d -m 700 -o jay -g users /home/jay/.pi/agent/extensions /home/jay/.pi/agent/themes
			install -m 600 -o jay -g users ${../../config/pi/settings.json} /home/jay/.pi/agent/settings.json
			install -m 600 -o jay -g users ${../../config/pi/keybindings.json} /home/jay/.pi/agent/keybindings.json
			install -m 600 -o jay -g users ${../../config/pi/APPEND_SYSTEM.md} /home/jay/.pi/agent/APPEND_SYSTEM.md
			install -m 600 -o jay -g users ${../../config/pi/extensions/confirm-file-mutations.ts} /home/jay/.pi/agent/extensions/confirm-file-mutations.ts
			install -m 600 -o jay -g users ${../../config/pi/extensions/modal-editor.ts} /home/jay/.pi/agent/extensions/modal-editor.ts
			install -m 600 -o jay -g users ${../../config/pi/themes/jay-dark.json} /home/jay/.pi/agent/themes/jay-dark.json
		'';

	    users.users.jay.packages = with pkgs; [
			pi-coding-agent
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
			wl-mirror

			inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
	    ];
	};
}
