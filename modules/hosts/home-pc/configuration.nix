{self, inputs, ...}: {
	flake.nixosModules.homePcConfiguration = { config, lib, pkgs, inputs, ... }: let
		custom-elegant-sddm = pkgs.elegant-sddm.override {
			themeConfig.General.background = "${self.wallpaper}";
		};
	in {
		imports = [
			# hardware
			self.nixosModules.homePcHardware
			# system programs
			self.nixosModules.nvidia-10
			self.nixosModules.gaming
			self.nixosModules.ghostty
			self.nixosModules.niri
			self.nixosModules.neovim
			self.nixosModules.cursor
			self.nixosModules.tmux-nu
			self.nixosModules.nushell
			self.nixosModules.gnome-integration
			self.nixosModules.nix-ld

			# user programs
			self.nixosModules.user-apps
			self.nixosModules.scientific-suite
		];

		boot.loader.systemd-boot.enable = true;
		boot.loader.efi.canTouchEfiVariables = true;

		networking.networkmanager.enable = true;
		networking.networkmanager.plugins = with pkgs; [ networkmanager-openconnect ];

		time.timeZone = "Europe/Vienna";

		services.power-profiles-daemon.enable = true;
		services.upower.enable = true;
		services.system76-scheduler.settings.cfsProfiles.enable = true;

		services.xserver.enable = true;
		services.displayManager.sddm = {
			enable = true;
			wayland.enable = true;
			theme = "Elegant";
			extraPackages = [ custom-elegant-sddm ];
		};
		services.displayManager = {
			enable = true;
			autoLogin = {
				enable = false;
				user = "jay";
			};
		};

		programs.niri = {
			enable = true;
		};
		programs.niri.custom = {
			outputMonitorName = "DP-2";
			outputMode = "2560x1440@165";
		};

		environment.sessionVariables = {
			NIXOS_OZONE_WL = "1";
		};

		services.keyd = {
			enable = true;
			keyboards = {
				default = {
					ids = [ "*" ];
					settings = {
						global = {
							overload_tap_timeout = "500";
						};
						main = {
							capslock = "overload(control, esc)";
						};
					};
				};
			};
		};

		services.printing = {
			enable = true;
			drivers = with pkgs; [
				gutenprint
				gutenprintBin
				cups-filters
			]; 
		};

		services.avahi = {
			enable = true;
			nssmdns4 = true;
			openFirewall = true;
		};

		services.xserver = { xkb.layout = "us"; xkb.variant = ""; };
		console.useXkbConfig = true;

		security.rtkit.enable = true;
		services.pipewire = {
			enable = true;
			alsa.enable = true;
			alsa.support32Bit = true;
			pulse.enable = true;
			jack.enable = true;
		};

		hardware.bluetooth.enable = true;
		hardware.bluetooth.powerOnBoot = false;

		systemd.user.services.mpris-proxy = {
			description = "Mpris proxy";
			after = [ "network.target" "sound.target" ];
			wantedBy = [ "default.target" ];
			serviceConfig.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
		};

		virtualisation.docker.enable = true;
		users.users.jay = {
			isNormalUser = true; 
			extraGroups = [ "wheel" "networkmanager" "docker" "input" "audio" ];
			shell = self.packages.${pkgs.system}.zsh;
		};

		virtualisation.libvirtd.enable = true;

		hardware.uinput.enable = true;
		users.groups.uinput.members = [ "jay" ];
		users.groups.input.members = [ "jay" ];

		programs.zsh.enable = true;

		hardware.keyboard.zsa.enable = true;

		environment.systemPackages = with pkgs; [ 
			alsa-utils
			binutils
			blueman
			gcc
			git 
			jujutsu
			keyd
			pavucontrol
			pulseaudio
			qemu
			ripgrep
			ripgrep
			tldr
			unzip
			wget
			custom-elegant-sddm
		];

		fonts.packages = with pkgs; [
			iosevka
			noto-fonts-color-emoji
		];

		nixpkgs.config = {
			allowUnfree = true;
		};

		services.openssh = {
			enable = true;
			extraConfig = ''
			UseDNS no
			'';
		};

		system.stateVersion = "23.11"; # Did you read the comment?

		nix.settings = {
			experimental-features = [ "nix-command" "flakes" ];
			substituters = [
				"https://cache.nixos.org/"
				"https://hyprland.cachix.org"
				"https://nix-community.cachix.org"
			];
		};
	};
}
