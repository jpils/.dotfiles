{self, inputs, ...}: {
	flake.nixosModules.homePcConfiguration = { config, lib, pkgs, inputs, ... }: let
		sddm-blurred-wallpaper = pkgs.runCommand "sddm-blurred-wallpaper.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
			magick ${self.wallpaper} -blur 0x7 -blur 0x7 -blur 0x7 $out
		'';
		custom-sddm-theme = pkgs.sddm-astronaut.override {
			themeConfig = {
				Background = "${sddm-blurred-wallpaper}";
				PartialBlur = "false";
				FullBlur = "false";
			};
		};
	in {
		imports = [
			# hardware
			self.nixosModules.homePcHardware
			self.nixosModules.homePcDisko
			self.nixosModules.preservation

			# system programs
			self.nixosModules.nvidia-10
			self.nixosModules.gaming
			self.nixosModules.ghostty
			self.nixosModules.niri
			self.nixosModules.noctalia
			self.nixosModules.neovim
			self.nixosModules.cursor
			self.nixosModules.tmux-nu
			self.nixosModules.nushell
			self.nixosModules.gnome-integration
			self.nixosModules.nix-ld
			self.nixosModules.sops
			self.nixosModules.userSecurity
			self.nixosModules.scanner
			self.nixosModules.swaylock-effects

			# user programs
			self.nixosModules.user-apps
			self.nixosModules.scientific-suite
		];

		jay.userSecurity.sudo.u2f = {
			enable = true;
			unixFallback = false;
		};

		boot.initrd.systemd.enable = true;

		boot.initrd.luks.devices.cryptroot = {
			device = "/dev/disk/by-partlabel/disk-main-root";
			crypttabExtraOpts = [
				"fido2-device=auto"
			];
		};
		boot.loader.systemd-boot.enable = true;
		boot.loader.efi.canTouchEfiVariables = true;

		networking.networkmanager.enable = true;
		networking.networkmanager.plugins = with pkgs; [ networkmanager-openconnect ];

		time.timeZone = "Europe/Vienna";

		services.power-profiles-daemon.enable = true;
		services.upower.enable = true;
		services.system76-scheduler.settings.cfsProfiles.enable = true;

		jay.swaylock-effects = {
			lockTimeout = 300;
			monitorOffTimeout = 360;
			suspendTimeout = 2100;
			suspend = true;
			hibernate = false;
		};

		services.xserver.enable = true;
		services.displayManager.sddm = {
			enable = true;
			wayland.enable = true;
			theme = "sddm-astronaut-theme";
			extraPackages = [ custom-sddm-theme ];
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
		programs.noctalia.systemMonitorBar.widthPercent = 30;

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

		services.accounts-daemon.enable = true;
		users.users.jay = {
			hashedPasswordFile = config.sops.secrets.jay-password.path;
			isNormalUser = true; 
			extraGroups = [ "wheel" "networkmanager" "docker" "input" "audio" ];
			shell = pkgs.zsh;
		};

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
			custom-sddm-theme
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

		system.stateVersion = "26.05";

		nix.settings = {
			experimental-features = [ "nix-command" "flakes" ];
			substituters = [
				"https://cache.nixos.org/"
				"https://nix-community.cachix.org"
			];
		};
	};
}
