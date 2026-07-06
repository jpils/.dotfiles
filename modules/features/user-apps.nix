{ self, inputs, ... }:{

	flake.nixosModules.user-apps = { pkgs, ... }: let
		ssh-askpass-notify = pkgs.writeShellScriptBin "ssh-askpass-notify" ''
			${pkgs.libnotify}/bin/notify-send "SSH / YubiKey" "$1"
			exit 0
		'';
	in {
		services.pcscd.enable = true;

		programs.ssh.askPassword = "${ssh-askpass-notify}/bin/ssh-askpass-notify";

		programs.browserpass.enable = true;

		programs.git = {
			enable = true;
			config = {
				user = {
					name = "jpils";
					email = "pilsj00@gmail.com";
				};
				init.defaultBranch = "master";
			};
		};

		programs.gnupg.agent = {
			enable = true;
			enableSSHSupport = true;
			pinentryPackage = pkgs.pinentry-gnome3;
			settings = {
				default-cache-ttl = 600;
				max-cache-ttl = 7200;
			};
		};

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
			baobab
			browserpass
			celluloid
			evince
			file-roller
			geary              
			gnome-calculator
			gnome-calendar    
			gnome-text-editor
			gnupg
			loupe
			mission-center
			mpv
			nautilus
			networkmanagerapplet
			pass
			pi-coding-agent
			spotify
			sshfs
			step-cli
			sushi
			telegram-desktop
			tree
			vesktop
			vlc
			wl-mirror
			yubioath-flutter
			yubikey-manager
			xournalpp
			zip

			inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
	    ];
	};
}
